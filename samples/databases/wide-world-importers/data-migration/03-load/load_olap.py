#!/usr/bin/env python3
"""
Phase 6: Data Migration and Validation
OLAP Data Loading Script

Loads transformed CSV data into PostgreSQL WideWorldImportersDW database
using efficient bulk loading with COPY command.
"""

import os
import sys
import csv
import logging
from datetime import datetime
from typing import Optional
from io import StringIO

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

try:
    import psycopg2
    from psycopg2 import sql
except ImportError:
    print("Error: psycopg2 is required. Install with: pip install psycopg2-binary")
    sys.exit(1)

from config import (
    POSTGRES_CONFIG,
    POSTGRES_OLAP_DB,
    DATA_DIR,
    LOGS_DIR,
    BATCH_SIZE,
    OLAP_TABLES,
    OLAP_SEQUENCES,
)


def setup_logging() -> logging.Logger:
    """Set up logging configuration."""
    os.makedirs(LOGS_DIR, exist_ok=True)
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    log_file = os.path.join(LOGS_DIR, f'load_olap_{timestamp}.log')
    
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(log_file),
            logging.StreamHandler()
        ]
    )
    return logging.getLogger(__name__)


def get_connection(logger: logging.Logger) -> Optional[psycopg2.extensions.connection]:
    """Establish connection to PostgreSQL."""
    try:
        conn = psycopg2.connect(
            host=POSTGRES_CONFIG['host'],
            port=POSTGRES_CONFIG['port'],
            user=POSTGRES_CONFIG['user'],
            password=POSTGRES_CONFIG['password'],
            database=POSTGRES_OLAP_DB
        )
        logger.info(f"Connected to PostgreSQL: {POSTGRES_CONFIG['host']}/{POSTGRES_OLAP_DB}")
        return conn
    except psycopg2.Error as e:
        logger.error(f"Failed to connect to PostgreSQL: {e}")
        return None


def disable_triggers(conn: psycopg2.extensions.connection, schema: str,
                     table: str, logger: logging.Logger) -> None:
    """Disable triggers on a table for faster loading."""
    try:
        cursor = conn.cursor()
        cursor.execute(
            sql.SQL("ALTER TABLE {}.{} DISABLE TRIGGER ALL").format(
                sql.Identifier(schema),
                sql.Identifier(table)
            )
        )
        conn.commit()
        cursor.close()
    except psycopg2.Error as e:
        logger.warning(f"Could not disable triggers on {schema}.{table}: {e}")
        conn.rollback()


def enable_triggers(conn: psycopg2.extensions.connection, schema: str,
                    table: str, logger: logging.Logger) -> None:
    """Re-enable triggers on a table after loading."""
    try:
        cursor = conn.cursor()
        cursor.execute(
            sql.SQL("ALTER TABLE {}.{} ENABLE TRIGGER ALL").format(
                sql.Identifier(schema),
                sql.Identifier(table)
            )
        )
        conn.commit()
        cursor.close()
    except psycopg2.Error as e:
        logger.warning(f"Could not enable triggers on {schema}.{table}: {e}")
        conn.rollback()


def truncate_table(conn: psycopg2.extensions.connection, schema: str,
                   table: str, logger: logging.Logger) -> bool:
    """Truncate a table before loading."""
    try:
        cursor = conn.cursor()
        cursor.execute(
            sql.SQL("TRUNCATE TABLE {}.{} CASCADE").format(
                sql.Identifier(schema),
                sql.Identifier(table)
            )
        )
        conn.commit()
        cursor.close()
        return True
    except psycopg2.Error as e:
        logger.error(f"Failed to truncate {schema}.{table}: {e}")
        conn.rollback()
        return False


def get_table_columns(conn: psycopg2.extensions.connection, schema: str,
                      table: str) -> list:
    """Get column names for a table from PostgreSQL."""
    cursor = conn.cursor()
    cursor.execute("""
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = %s AND table_name = %s
        ORDER BY ordinal_position
    """, (schema, table))
    columns = [row[0] for row in cursor.fetchall()]
    cursor.close()
    return columns


def load_csv_to_table(conn: psycopg2.extensions.connection, csv_file: str,
                      schema: str, table: str, logger: logging.Logger) -> dict:
    """Load a CSV file into a PostgreSQL table using COPY."""
    result = {
        'schema': schema,
        'table': table,
        'csv_file': csv_file,
        'rows_loaded': 0,
        'status': 'success',
        'error': None
    }
    
    if not os.path.exists(csv_file):
        logger.warning(f"CSV file not found: {csv_file}")
        result['status'] = 'skipped'
        return result
    
    try:
        # Get table columns from PostgreSQL
        pg_columns = get_table_columns(conn, schema, table)
        if not pg_columns:
            logger.warning(f"No columns found for {schema}.{table}")
            result['status'] = 'skipped'
            return result
        
        # Read CSV header to get column mapping
        with open(csv_file, 'r', encoding='utf-8') as f:
            reader = csv.reader(f)
            csv_columns = next(reader)
        
        # Find matching columns (CSV columns that exist in PostgreSQL table)
        matching_columns = [col for col in csv_columns if col in pg_columns]
        
        if not matching_columns:
            logger.warning(f"No matching columns between CSV and table {schema}.{table}")
            result['status'] = 'skipped'
            return result
        
        # Disable triggers for faster loading
        disable_triggers(conn, schema, table, logger)
        
        # Truncate table
        if not truncate_table(conn, schema, table, logger):
            result['status'] = 'error'
            result['error'] = 'Failed to truncate table'
            return result
        
        # Load data using COPY
        cursor = conn.cursor()
        
        # Read CSV and prepare data
        with open(csv_file, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            
            # Process in batches
            batch = []
            rows_loaded = 0
            
            for row in reader:
                # Extract only matching columns and handle NULL values
                row_data = []
                for col in matching_columns:
                    value = row.get(col, '')
                    if value == '' or value == 'None':
                        row_data.append(None)
                    else:
                        row_data.append(value)
                batch.append(row_data)
                
                if len(batch) >= BATCH_SIZE:
                    # Use copy_from with StringIO for batch loading
                    buffer = StringIO()
                    for row_data in batch:
                        line = '\t'.join(
                            '\\N' if v is None else str(v).replace('\t', ' ').replace('\n', ' ')
                            for v in row_data
                        )
                        buffer.write(line + '\n')
                    buffer.seek(0)
                    
                    cursor.copy_from(
                        buffer,
                        f'{schema}.{table}',
                        columns=matching_columns,
                        null='\\N'
                    )
                    conn.commit()
                    
                    rows_loaded += len(batch)
                    batch = []
                    
                    if rows_loaded % 10000 == 0:
                        logger.info(f"  Loaded {rows_loaded} rows into {schema}.{table}")
            
            # Load remaining rows
            if batch:
                buffer = StringIO()
                for row_data in batch:
                    line = '\t'.join(
                        '\\N' if v is None else str(v).replace('\t', ' ').replace('\n', ' ')
                        for v in row_data
                    )
                    buffer.write(line + '\n')
                buffer.seek(0)
                
                cursor.copy_from(
                    buffer,
                    f'{schema}.{table}',
                    columns=matching_columns,
                    null='\\N'
                )
                conn.commit()
                rows_loaded += len(batch)
        
        cursor.close()
        
        # Re-enable triggers
        enable_triggers(conn, schema, table, logger)
        
        result['rows_loaded'] = rows_loaded
        logger.info(f"Completed {schema}.{table}: {rows_loaded} rows loaded")
        
    except Exception as e:
        logger.error(f"Error loading {schema}.{table}: {e}")
        conn.rollback()
        result['status'] = 'error'
        result['error'] = str(e)
        
        # Try to re-enable triggers even on error
        enable_triggers(conn, schema, table, logger)
    
    return result


def reset_sequence(conn: psycopg2.extensions.connection, sequence: str,
                   table_info, logger: logging.Logger) -> bool:
    """Reset a sequence to the max value in the table + 1."""
    try:
        cursor = conn.cursor()
        
        table, column = table_info
        cursor.execute(
            sql.SQL("SELECT COALESCE(MAX({}), 0) FROM {}").format(
                sql.Identifier(column),
                sql.SQL(table)
            )
        )
        max_val = cursor.fetchone()[0]
        
        # Set sequence to max + 1
        cursor.execute(
            sql.SQL("SELECT setval(%s, %s, true)"),
            (sequence, max_val)
        )
        conn.commit()
        cursor.close()
        
        logger.info(f"Reset sequence {sequence} to {max_val}")
        return True
        
    except psycopg2.Error as e:
        logger.error(f"Failed to reset sequence {sequence}: {e}")
        conn.rollback()
        return False


def main():
    """Main loading function."""
    logger = setup_logging()
    logger.info("=" * 60)
    logger.info("Starting OLAP Data Loading")
    logger.info("=" * 60)
    
    # Data directory
    data_dir = os.path.join(DATA_DIR, 'olap_transformed')
    if not os.path.exists(data_dir):
        # Fall back to non-transformed data
        data_dir = os.path.join(DATA_DIR, 'olap')
    
    if not os.path.exists(data_dir):
        logger.error(f"Data directory not found: {data_dir}")
        logger.error("Please run extraction and transformation scripts first.")
        sys.exit(1)
    
    # Connect to PostgreSQL
    conn = get_connection(logger)
    if not conn:
        logger.error("Failed to connect to PostgreSQL. Exiting.")
        sys.exit(1)
    
    results = []
    
    try:
        # Load dimension tables first (they are referenced by fact tables)
        logger.info("-" * 60)
        logger.info("Loading dimension tables")
        logger.info("-" * 60)
        
        for pg_table, sql_table in OLAP_TABLES.get('dimension', []):
            csv_file = os.path.join(data_dir, f"dimension_{pg_table}.csv")
            result = load_csv_to_table(conn, csv_file, 'dimension', pg_table, logger)
            results.append(result)
        
        # Load integration tables
        logger.info("-" * 60)
        logger.info("Loading integration tables")
        logger.info("-" * 60)
        
        for pg_table, sql_table in OLAP_TABLES.get('integration', []):
            csv_file = os.path.join(data_dir, f"integration_{pg_table}.csv")
            result = load_csv_to_table(conn, csv_file, 'integration', pg_table, logger)
            results.append(result)
        
        # Load fact tables
        logger.info("-" * 60)
        logger.info("Loading fact tables")
        logger.info("-" * 60)
        
        for pg_table, sql_table in OLAP_TABLES.get('fact', []):
            csv_file = os.path.join(data_dir, f"fact_{pg_table}.csv")
            result = load_csv_to_table(conn, csv_file, 'fact', pg_table, logger)
            results.append(result)
        
        # Reset sequences
        logger.info("-" * 60)
        logger.info("Resetting sequences")
        logger.info("-" * 60)
        
        for sequence, table_info in OLAP_SEQUENCES.items():
            reset_sequence(conn, sequence, table_info, logger)
        
    finally:
        conn.close()
        logger.info("Closed PostgreSQL connection")
    
    # Summary
    logger.info("=" * 60)
    logger.info("Loading Summary")
    logger.info("=" * 60)
    
    success_count = sum(1 for r in results if r['status'] == 'success')
    error_count = sum(1 for r in results if r['status'] == 'error')
    skipped_count = sum(1 for r in results if r['status'] == 'skipped')
    total_rows = sum(r['rows_loaded'] for r in results)
    
    logger.info(f"Tables processed: {len(results)}")
    logger.info(f"  Successful: {success_count}")
    logger.info(f"  Errors: {error_count}")
    logger.info(f"  Skipped: {skipped_count}")
    logger.info(f"Total rows loaded: {total_rows}")
    
    if error_count > 0:
        logger.error("Errors occurred during loading:")
        for r in results:
            if r['status'] == 'error':
                logger.error(f"  {r['schema']}.{r['table']}: {r['error']}")
    
    # Write results to JSON
    import json
    results_file = os.path.join(data_dir, 'loading_results.json')
    with open(results_file, 'w') as f:
        json.dump(results, f, indent=2)
    logger.info(f"Results written to {results_file}")
    
    return 0 if error_count == 0 else 1


if __name__ == '__main__':
    sys.exit(main())
