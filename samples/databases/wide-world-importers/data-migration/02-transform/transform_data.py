#!/usr/bin/env python3
"""
Phase 6: Data Migration and Validation
Data Transformation Script

Transforms extracted CSV data for PostgreSQL compatibility.
Handles data type conversions, encoding, and format adjustments.
"""

import os
import sys
import csv
import logging
import base64
import json
import re
from datetime import datetime
from typing import Optional, Any

# Increase CSV field size limit for large geography data (country borders)
csv.field_size_limit(sys.maxsize)

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from config import (
    DATA_DIR,
    LOGS_DIR,
    GEOGRAPHY_COLUMNS,
    BINARY_COLUMNS,
    JSON_COLUMNS,
)


def setup_logging() -> logging.Logger:
    """Set up logging configuration."""
    os.makedirs(LOGS_DIR, exist_ok=True)
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    log_file = os.path.join(LOGS_DIR, f'transform_{timestamp}.log')
    
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(log_file),
            logging.StreamHandler()
        ]
    )
    return logging.getLogger(__name__)


def convert_geography(value: str, logger: logging.Logger) -> Optional[str]:
    """
    Convert SQL Server geography WKT to PostGIS format.
    SQL Server geography uses (lat, long) while PostGIS uses (long, lat).
    """
    if not value or value == '':
        return None
    
    try:
        # SQL Server returns WKT like POINT (lat long) or POLYGON ((lat long, ...))
        # PostGIS expects POINT (long lat) or POLYGON ((long lat, ...))
        
        # For POINT
        point_match = re.match(r'POINT\s*\(\s*([-\d.]+)\s+([-\d.]+)\s*\)', value, re.IGNORECASE)
        if point_match:
            lat, lon = point_match.groups()
            return f"SRID=4326;POINT({lon} {lat})"
        
        # For POLYGON and other complex types, we need to swap coordinates
        # This is a simplified handler - complex geometries may need more work
        if value.upper().startswith('POLYGON') or value.upper().startswith('MULTIPOLYGON'):
            # Swap coordinate pairs in the WKT
            def swap_coords(match):
                coords = match.group(1).split(',')
                swapped = []
                for coord in coords:
                    parts = coord.strip().split()
                    if len(parts) >= 2:
                        swapped.append(f"{parts[1]} {parts[0]}")
                    else:
                        swapped.append(coord.strip())
                return '(' + ', '.join(swapped) + ')'
            
            # This regex finds coordinate sequences within parentheses
            result = re.sub(r'\(([^()]+)\)', swap_coords, value)
            return f"SRID=4326;{result}"
        
        # For other types, return as-is with SRID
        return f"SRID=4326;{value}"
        
    except Exception as e:
        logger.warning(f"Failed to convert geography value: {e}")
        return None


def convert_binary(value: str, logger: logging.Logger) -> Optional[str]:
    """
    Convert base64-encoded binary data to PostgreSQL bytea hex format.
    """
    if not value or value == '':
        return None
    
    try:
        # Decode base64 to bytes
        binary_data = base64.b64decode(value)
        # Convert to PostgreSQL hex format: \x followed by hex digits
        hex_str = '\\x' + binary_data.hex()
        return hex_str
    except Exception as e:
        logger.warning(f"Failed to convert binary value: {e}")
        return None


def convert_boolean(value: str) -> Optional[str]:
    """Convert SQL Server bit values to PostgreSQL boolean."""
    if value == '' or value is None:
        return None
    
    value_lower = str(value).lower()
    if value_lower in ('1', 'true', 't', 'yes', 'y'):
        return 'true'
    elif value_lower in ('0', 'false', 'f', 'no', 'n'):
        return 'false'
    return None


def convert_datetime(value: str) -> Optional[str]:
    """Convert SQL Server datetime formats to PostgreSQL timestamp."""
    if not value or value == '':
        return None
    
    # SQL Server datetime2 format: YYYY-MM-DD HH:MM:SS.nnnnnnn
    # PostgreSQL timestamp format: YYYY-MM-DD HH:MM:SS.nnnnnn
    
    # Handle the special "end of time" value
    if '9999-12-31' in value:
        return '9999-12-31 23:59:59.999999'
    
    # Truncate nanoseconds to microseconds if needed
    if '.' in value:
        parts = value.split('.')
        if len(parts) == 2 and len(parts[1]) > 6:
            value = parts[0] + '.' + parts[1][:6]
    
    return value


def convert_json(value: str, logger: logging.Logger) -> Optional[str]:
    """Validate and convert JSON data."""
    if not value or value == '':
        return None
    
    try:
        # Parse and re-serialize to ensure valid JSON
        parsed = json.loads(value)
        return json.dumps(parsed)
    except json.JSONDecodeError as e:
        logger.warning(f"Invalid JSON value: {e}")
        return None


def get_column_transformations(schema: str, table: str, columns: list) -> dict:
    """Determine which transformations to apply to each column."""
    full_table = f"{schema}.{table}"
    transformations = {}
    
    # Geography columns
    if full_table in GEOGRAPHY_COLUMNS:
        for col in GEOGRAPHY_COLUMNS[full_table]:
            transformations[col.lower()] = 'geography'
    
    # Binary columns
    if full_table in BINARY_COLUMNS:
        for col in BINARY_COLUMNS[full_table]:
            transformations[col.lower()] = 'binary'
    
    # JSON columns
    if full_table in JSON_COLUMNS:
        for col in JSON_COLUMNS[full_table]:
            transformations[col.lower()] = 'json'
    
    return transformations


def transform_value(value: str, transform_type: str, 
                    logger: logging.Logger) -> Optional[str]:
    """Apply transformation to a value based on its type."""
    if transform_type == 'geography':
        return convert_geography(value, logger)
    elif transform_type == 'binary':
        return convert_binary(value, logger)
    elif transform_type == 'json':
        return convert_json(value, logger)
    elif transform_type == 'boolean':
        return convert_boolean(value)
    elif transform_type == 'datetime':
        return convert_datetime(value)
    else:
        return value


def transform_csv_file(input_file: str, output_file: str, schema: str, 
                       table: str, logger: logging.Logger) -> dict:
    """Transform a single CSV file."""
    result = {
        'input_file': input_file,
        'output_file': output_file,
        'schema': schema,
        'table': table,
        'rows_transformed': 0,
        'status': 'success',
        'error': None
    }
    
    try:
        with open(input_file, 'r', encoding='utf-8') as infile:
            reader = csv.DictReader(infile)
            columns = reader.fieldnames
            
            if not columns:
                logger.warning(f"No columns found in {input_file}")
                result['status'] = 'skipped'
                return result
            
            # Get transformations for this table
            transformations = get_column_transformations(schema, table, columns)
            
            # Detect datetime columns by name pattern
            datetime_cols = set()
            for col in columns:
                col_lower = col.lower()
                if any(pattern in col_lower for pattern in 
                       ['validfrom', 'validto', 'lasteditedwhen', 'recordedwhen',
                        'transactionoccurredwhen', 'pickingcompletedwhen',
                        'lastmodifiedwhen', 'valid_from', 'valid_to']):
                    datetime_cols.add(col)
            
            with open(output_file, 'w', newline='', encoding='utf-8') as outfile:
                writer = csv.DictWriter(outfile, fieldnames=columns, 
                                        quoting=csv.QUOTE_MINIMAL)
                writer.writeheader()
                
                rows_written = 0
                for row in reader:
                    transformed_row = {}
                    for col, value in row.items():
                        col_lower = col.lower()
                        
                        # Apply specific transformation if defined
                        if col_lower in transformations:
                            transformed_row[col] = transform_value(
                                value, transformations[col_lower], logger
                            )
                        # Apply datetime transformation
                        elif col in datetime_cols:
                            transformed_row[col] = convert_datetime(value)
                        # Keep value as-is but handle empty strings
                        else:
                            transformed_row[col] = value if value != '' else None
                    
                    writer.writerow(transformed_row)
                    rows_written += 1
                
                result['rows_transformed'] = rows_written
                logger.info(f"Transformed {table}: {rows_written} rows")
        
    except Exception as e:
        logger.error(f"Error transforming {input_file}: {e}")
        result['status'] = 'error'
        result['error'] = str(e)
    
    return result


def transform_database(db_type: str, logger: logging.Logger) -> list:
    """Transform all CSV files for a database (oltp or olap)."""
    input_dir = os.path.join(DATA_DIR, db_type)
    output_dir = os.path.join(DATA_DIR, f'{db_type}_transformed')
    os.makedirs(output_dir, exist_ok=True)
    
    results = []
    
    if not os.path.exists(input_dir):
        logger.warning(f"Input directory does not exist: {input_dir}")
        return results
    
    for filename in os.listdir(input_dir):
        if not filename.endswith('.csv'):
            continue
        
        # Parse schema and table from filename (format: schema_table.csv)
        name_parts = filename[:-4].split('_', 1)
        if len(name_parts) != 2:
            logger.warning(f"Unexpected filename format: {filename}")
            continue
        
        schema, table = name_parts
        
        input_file = os.path.join(input_dir, filename)
        output_file = os.path.join(output_dir, filename)
        
        result = transform_csv_file(input_file, output_file, schema, table, logger)
        results.append(result)
    
    return results


def main():
    """Main transformation function."""
    logger = setup_logging()
    logger.info("=" * 60)
    logger.info("Starting Data Transformation")
    logger.info("=" * 60)
    
    all_results = []
    
    # Transform OLTP data
    logger.info("-" * 60)
    logger.info("Transforming OLTP data")
    logger.info("-" * 60)
    oltp_results = transform_database('oltp', logger)
    all_results.extend(oltp_results)
    
    # Transform OLAP data
    logger.info("-" * 60)
    logger.info("Transforming OLAP data")
    logger.info("-" * 60)
    olap_results = transform_database('olap', logger)
    all_results.extend(olap_results)
    
    # Summary
    logger.info("=" * 60)
    logger.info("Transformation Summary")
    logger.info("=" * 60)
    
    success_count = sum(1 for r in all_results if r['status'] == 'success')
    error_count = sum(1 for r in all_results if r['status'] == 'error')
    skipped_count = sum(1 for r in all_results if r['status'] == 'skipped')
    total_rows = sum(r['rows_transformed'] for r in all_results)
    
    logger.info(f"Files processed: {len(all_results)}")
    logger.info(f"  Successful: {success_count}")
    logger.info(f"  Errors: {error_count}")
    logger.info(f"  Skipped: {skipped_count}")
    logger.info(f"Total rows transformed: {total_rows}")
    
    if error_count > 0:
        logger.error("Errors occurred during transformation:")
        for r in all_results:
            if r['status'] == 'error':
                logger.error(f"  {r['schema']}.{r['table']}: {r['error']}")
    
    # Write results to JSON
    results_file = os.path.join(DATA_DIR, 'transformation_results.json')
    with open(results_file, 'w') as f:
        json.dump(all_results, f, indent=2)
    logger.info(f"Results written to {results_file}")
    
    return 0 if error_count == 0 else 1


if __name__ == '__main__':
    sys.exit(main())
