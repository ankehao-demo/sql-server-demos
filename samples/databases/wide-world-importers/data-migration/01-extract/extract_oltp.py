#!/usr/bin/env python3
"""
Phase 6: Data Migration and Validation
OLTP Data Extraction Script

Extracts data from SQL Server WideWorldImporters database to CSV files
for subsequent transformation and loading into PostgreSQL.
"""

import os
import sys
import csv
import logging
import base64
from datetime import datetime
from typing import Optional

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

try:
    import pyodbc
except ImportError:
    print("Error: pyodbc is required. Install with: pip install pyodbc")
    sys.exit(1)

from config import (
    SQL_SERVER_CONFIG,
    SQL_SERVER_OLTP_DB,
    DATA_DIR,
    LOGS_DIR,
    BATCH_SIZE,
    OLTP_TABLES,
    ARCHIVE_TABLES,
    GEOGRAPHY_COLUMNS,
    BINARY_COLUMNS,
    COMPUTED_COLUMNS,
)


def setup_logging() -> logging.Logger:
    """Set up logging configuration."""
    os.makedirs(LOGS_DIR, exist_ok=True)
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    log_file = os.path.join(LOGS_DIR, f'extract_oltp_{timestamp}.log')
    
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(log_file),
            logging.StreamHandler()
        ]
    )
    return logging.getLogger(__name__)


def get_connection_string() -> str:
    """Build SQL Server connection string."""
    return (
        f"DRIVER={SQL_SERVER_CONFIG['driver']};"
        f"SERVER={SQL_SERVER_CONFIG['server']},{SQL_SERVER_CONFIG['port']};"
        f"DATABASE={SQL_SERVER_OLTP_DB};"
        f"UID={SQL_SERVER_CONFIG['username']};"
        f"PWD={SQL_SERVER_CONFIG['password']};"
        f"TrustServerCertificate={SQL_SERVER_CONFIG['trust_server_certificate']};"
    )


def connect_to_sql_server(logger: logging.Logger) -> Optional[pyodbc.Connection]:
    """Establish connection to SQL Server."""
    try:
        conn_str = get_connection_string()
        logger.info(f"Connecting to SQL Server: {SQL_SERVER_CONFIG['server']}")
        conn = pyodbc.connect(conn_str)
        logger.info("Successfully connected to SQL Server")
        return conn
    except pyodbc.Error as e:
        logger.error(f"Failed to connect to SQL Server: {e}")
        return None


def get_table_columns(conn: pyodbc.Connection, schema: str, table: str, 
                      logger: logging.Logger) -> list:
    """Get column names and types for a table."""
    cursor = conn.cursor()
    query = """
        SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ?
        ORDER BY ORDINAL_POSITION
    """
    cursor.execute(query, (schema, table))
    columns = [(row.COLUMN_NAME, row.DATA_TYPE, row.CHARACTER_MAXIMUM_LENGTH) 
               for row in cursor.fetchall()]
    cursor.close()
    return columns


def get_row_count(conn: pyodbc.Connection, schema: str, table: str) -> int:
    """Get the row count for a table."""
    cursor = conn.cursor()
    cursor.execute(f"SELECT COUNT(*) FROM [{schema}].[{table}]")
    count = cursor.fetchone()[0]
    cursor.close()
    return count


def build_select_query(schema: str, table: str, columns: list, 
                       pg_schema: str, pg_table: str) -> str:
    """Build SELECT query with proper column handling."""
    full_table = f"{pg_schema}.{pg_table}"
    
    # Get columns to skip (computed columns)
    skip_columns = set()
    if full_table in COMPUTED_COLUMNS:
        skip_columns = set(col.lower() for col in COMPUTED_COLUMNS[full_table])
    
    # Get geography columns
    geo_columns = set()
    if full_table in GEOGRAPHY_COLUMNS:
        geo_columns = set(col.lower() for col in GEOGRAPHY_COLUMNS[full_table])
    
    # Get binary columns
    bin_columns = set()
    if full_table in BINARY_COLUMNS:
        bin_columns = set(col.lower() for col in BINARY_COLUMNS[full_table])
    
    select_parts = []
    for col_name, col_type, col_length in columns:
        col_lower = col_name.lower()
        
        # Skip computed columns
        if col_lower in skip_columns:
            continue
        
        # Handle geography columns - convert to WKT
        if col_lower in geo_columns:
            select_parts.append(f"[{col_name}].STAsText() AS [{col_name}]")
        # Handle binary columns - convert to base64
        elif col_type in ('varbinary', 'binary', 'image'):
            select_parts.append(
                f"CASE WHEN [{col_name}] IS NULL THEN NULL "
                f"ELSE CAST('' AS VARCHAR(MAX)) END AS [{col_name}]"
            )
        else:
            select_parts.append(f"[{col_name}]")
    
    select_clause = ', '.join(select_parts)
    return f"SELECT {select_clause} FROM [{schema}].[{table}]"


def extract_table(conn: pyodbc.Connection, schema: str, sql_table: str,
                  pg_schema: str, pg_table: str, output_dir: str,
                  logger: logging.Logger) -> dict:
    """Extract a single table to CSV."""
    result = {
        'schema': schema,
        'table': sql_table,
        'pg_schema': pg_schema,
        'pg_table': pg_table,
        'rows_extracted': 0,
        'status': 'success',
        'error': None
    }
    
    try:
        # Get column information
        columns = get_table_columns(conn, schema, sql_table, logger)
        if not columns:
            logger.warning(f"No columns found for {schema}.{sql_table}")
            result['status'] = 'skipped'
            return result
        
        # Get row count
        row_count = get_row_count(conn, schema, sql_table)
        logger.info(f"Extracting {schema}.{sql_table} ({row_count} rows)")
        
        # Build query
        query = build_select_query(schema, sql_table, columns, pg_schema, pg_table)
        
        # Prepare output file
        output_file = os.path.join(output_dir, f"{pg_schema}_{pg_table}.csv")
        
        # Get column names for CSV header (excluding computed columns)
        full_table = f"{pg_schema}.{pg_table}"
        skip_columns = set()
        if full_table in COMPUTED_COLUMNS:
            skip_columns = set(col.lower() for col in COMPUTED_COLUMNS[full_table])
        
        csv_columns = [col[0].lower() for col in columns 
                       if col[0].lower() not in skip_columns]
        
        # Extract data
        cursor = conn.cursor()
        cursor.execute(query)
        
        with open(output_file, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f, quoting=csv.QUOTE_MINIMAL)
            writer.writerow(csv_columns)
            
            rows_written = 0
            while True:
                rows = cursor.fetchmany(BATCH_SIZE)
                if not rows:
                    break
                
                for row in rows:
                    # Convert row to list and handle special values
                    row_data = []
                    for i, value in enumerate(row):
                        if value is None:
                            row_data.append('')
                        elif isinstance(value, bytes):
                            # Base64 encode binary data
                            row_data.append(base64.b64encode(value).decode('ascii'))
                        elif isinstance(value, bool):
                            row_data.append('true' if value else 'false')
                        else:
                            row_data.append(str(value))
                    writer.writerow(row_data)
                    rows_written += 1
                
                if rows_written % 10000 == 0:
                    logger.info(f"  Extracted {rows_written}/{row_count} rows")
        
        cursor.close()
        result['rows_extracted'] = rows_written
        logger.info(f"Completed {schema}.{sql_table}: {rows_written} rows")
        
    except Exception as e:
        logger.error(f"Error extracting {schema}.{sql_table}: {e}")
        result['status'] = 'error'
        result['error'] = str(e)
    
    return result


def extract_archive_table(conn: pyodbc.Connection, schema: str, table: str,
                          pg_schema: str, output_dir: str,
                          logger: logging.Logger) -> dict:
    """Extract an archive table to CSV."""
    # Archive tables in SQL Server have _Archive suffix
    sql_table = table.replace('_archive', '_Archive')
    
    result = {
        'schema': schema,
        'table': sql_table,
        'pg_schema': pg_schema,
        'pg_table': table,
        'rows_extracted': 0,
        'status': 'success',
        'error': None
    }
    
    try:
        # Check if archive table exists
        cursor = conn.cursor()
        cursor.execute("""
            SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
            WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ?
        """, (schema, sql_table))
        
        if cursor.fetchone()[0] == 0:
            logger.info(f"Archive table {schema}.{sql_table} does not exist, skipping")
            result['status'] = 'skipped'
            cursor.close()
            return result
        
        cursor.close()
        
        # Get column information
        columns = get_table_columns(conn, schema, sql_table, logger)
        if not columns:
            logger.warning(f"No columns found for {schema}.{sql_table}")
            result['status'] = 'skipped'
            return result
        
        # Get row count
        row_count = get_row_count(conn, schema, sql_table)
        logger.info(f"Extracting archive {schema}.{sql_table} ({row_count} rows)")
        
        # Build simple select query for archive tables
        col_names = [col[0] for col in columns]
        select_clause = ', '.join([f"[{c}]" for c in col_names])
        query = f"SELECT {select_clause} FROM [{schema}].[{sql_table}]"
        
        # Prepare output file
        output_file = os.path.join(output_dir, f"{pg_schema}_{table}.csv")
        
        # Extract data
        cursor = conn.cursor()
        cursor.execute(query)
        
        with open(output_file, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f, quoting=csv.QUOTE_MINIMAL)
            writer.writerow([c.lower() for c in col_names])
            
            rows_written = 0
            while True:
                rows = cursor.fetchmany(BATCH_SIZE)
                if not rows:
                    break
                
                for row in rows:
                    row_data = []
                    for value in row:
                        if value is None:
                            row_data.append('')
                        elif isinstance(value, bytes):
                            row_data.append(base64.b64encode(value).decode('ascii'))
                        elif isinstance(value, bool):
                            row_data.append('true' if value else 'false')
                        else:
                            row_data.append(str(value))
                    writer.writerow(row_data)
                    rows_written += 1
        
        cursor.close()
        result['rows_extracted'] = rows_written
        logger.info(f"Completed archive {schema}.{sql_table}: {rows_written} rows")
        
    except Exception as e:
        logger.error(f"Error extracting archive {schema}.{sql_table}: {e}")
        result['status'] = 'error'
        result['error'] = str(e)
    
    return result


def main():
    """Main extraction function."""
    logger = setup_logging()
    logger.info("=" * 60)
    logger.info("Starting OLTP Data Extraction")
    logger.info("=" * 60)
    
    # Create data directory
    output_dir = os.path.join(DATA_DIR, 'oltp')
    os.makedirs(output_dir, exist_ok=True)
    
    # Connect to SQL Server
    conn = connect_to_sql_server(logger)
    if not conn:
        logger.error("Failed to connect to SQL Server. Exiting.")
        sys.exit(1)
    
    results = []
    
    try:
        # Extract main tables
        logger.info("-" * 60)
        logger.info("Extracting main tables")
        logger.info("-" * 60)
        
        for schema, tables in OLTP_TABLES.items():
            for pg_table, sql_table, is_temporal in tables:
                result = extract_table(
                    conn, schema.capitalize(), sql_table,
                    schema, pg_table, output_dir, logger
                )
                results.append(result)
        
        # Extract archive tables
        logger.info("-" * 60)
        logger.info("Extracting archive tables")
        logger.info("-" * 60)
        
        for schema, tables in ARCHIVE_TABLES.items():
            for table in tables:
                result = extract_archive_table(
                    conn, schema.capitalize(), table,
                    schema, output_dir, logger
                )
                results.append(result)
        
    finally:
        conn.close()
        logger.info("Closed SQL Server connection")
    
    # Summary
    logger.info("=" * 60)
    logger.info("Extraction Summary")
    logger.info("=" * 60)
    
    success_count = sum(1 for r in results if r['status'] == 'success')
    error_count = sum(1 for r in results if r['status'] == 'error')
    skipped_count = sum(1 for r in results if r['status'] == 'skipped')
    total_rows = sum(r['rows_extracted'] for r in results)
    
    logger.info(f"Tables processed: {len(results)}")
    logger.info(f"  Successful: {success_count}")
    logger.info(f"  Errors: {error_count}")
    logger.info(f"  Skipped: {skipped_count}")
    logger.info(f"Total rows extracted: {total_rows}")
    
    if error_count > 0:
        logger.error("Errors occurred during extraction:")
        for r in results:
            if r['status'] == 'error':
                logger.error(f"  {r['schema']}.{r['table']}: {r['error']}")
    
    # Write results to JSON
    import json
    results_file = os.path.join(output_dir, 'extraction_results.json')
    with open(results_file, 'w') as f:
        json.dump(results, f, indent=2)
    logger.info(f"Results written to {results_file}")
    
    return 0 if error_count == 0 else 1


if __name__ == '__main__':
    sys.exit(main())
