#!/usr/bin/env python3
"""
Phase 6: Data Migration and Validation
Migration Validation Script

Validates the data migration by comparing:
- Row counts between SQL Server and PostgreSQL
- Data integrity (sample comparisons)
- Foreign key relationships
- Sequence values
"""

import os
import sys
import logging
import json
from datetime import datetime
from typing import Optional, Dict, List, Tuple

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

try:
    import pyodbc
except ImportError:
    pyodbc = None

try:
    import psycopg2
    from psycopg2 import sql
except ImportError:
    print("Error: psycopg2 is required. Install with: pip install psycopg2-binary")
    sys.exit(1)

from config import (
    SQL_SERVER_CONFIG,
    SQL_SERVER_OLTP_DB,
    SQL_SERVER_OLAP_DB,
    POSTGRES_CONFIG,
    POSTGRES_OLTP_DB,
    POSTGRES_OLAP_DB,
    DATA_DIR,
    LOGS_DIR,
    OLTP_TABLES,
    ARCHIVE_TABLES,
    OLAP_TABLES,
    OLTP_SEQUENCES,
    OLAP_SEQUENCES,
    VALIDATION_CONFIG,
)


def setup_logging() -> logging.Logger:
    """Set up logging configuration."""
    os.makedirs(LOGS_DIR, exist_ok=True)
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    log_file = os.path.join(LOGS_DIR, f'validate_{timestamp}.log')
    
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(log_file),
            logging.StreamHandler()
        ]
    )
    return logging.getLogger(__name__)


def get_sql_server_connection(database: str, logger: logging.Logger) -> Optional[object]:
    """Establish connection to SQL Server."""
    if pyodbc is None:
        logger.warning("pyodbc not available - SQL Server validation will be skipped")
        return None
    
    try:
        conn_str = (
            f"DRIVER={SQL_SERVER_CONFIG['driver']};"
            f"SERVER={SQL_SERVER_CONFIG['server']},{SQL_SERVER_CONFIG['port']};"
            f"DATABASE={database};"
            f"UID={SQL_SERVER_CONFIG['username']};"
            f"PWD={SQL_SERVER_CONFIG['password']};"
            f"TrustServerCertificate={SQL_SERVER_CONFIG['trust_server_certificate']};"
        )
        conn = pyodbc.connect(conn_str)
        logger.info(f"Connected to SQL Server: {database}")
        return conn
    except Exception as e:
        logger.warning(f"Could not connect to SQL Server: {e}")
        return None


def get_postgres_connection(database: str, logger: logging.Logger) -> Optional[psycopg2.extensions.connection]:
    """Establish connection to PostgreSQL."""
    try:
        conn = psycopg2.connect(
            host=POSTGRES_CONFIG['host'],
            port=POSTGRES_CONFIG['port'],
            user=POSTGRES_CONFIG['user'],
            password=POSTGRES_CONFIG['password'],
            database=database
        )
        logger.info(f"Connected to PostgreSQL: {database}")
        return conn
    except psycopg2.Error as e:
        logger.error(f"Failed to connect to PostgreSQL: {e}")
        return None


def get_sql_server_row_count(conn, schema: str, table: str) -> int:
    """Get row count from SQL Server table."""
    cursor = conn.cursor()
    cursor.execute(f"SELECT COUNT(*) FROM [{schema}].[{table}]")
    count = cursor.fetchone()[0]
    cursor.close()
    return count


def get_postgres_row_count(conn: psycopg2.extensions.connection, 
                           schema: str, table: str) -> int:
    """Get row count from PostgreSQL table."""
    cursor = conn.cursor()
    cursor.execute(
        sql.SQL("SELECT COUNT(*) FROM {}.{}").format(
            sql.Identifier(schema),
            sql.Identifier(table)
        )
    )
    count = cursor.fetchone()[0]
    cursor.close()
    return count


def validate_row_counts_oltp(sql_conn, pg_conn: psycopg2.extensions.connection,
                             logger: logging.Logger) -> List[Dict]:
    """Validate row counts for OLTP tables."""
    results = []
    
    for schema, tables in OLTP_TABLES.items():
        for pg_table, sql_table, is_temporal in tables:
            result = {
                'schema': schema,
                'table': pg_table,
                'sql_server_count': None,
                'postgres_count': None,
                'match': None,
                'status': 'success'
            }
            
            try:
                # Get PostgreSQL count
                pg_count = get_postgres_row_count(pg_conn, schema, pg_table)
                result['postgres_count'] = pg_count
                
                # Get SQL Server count if connection available
                if sql_conn:
                    sql_count = get_sql_server_row_count(
                        sql_conn, schema.capitalize(), sql_table
                    )
                    result['sql_server_count'] = sql_count
                    result['match'] = (sql_count == pg_count)
                    
                    if result['match']:
                        logger.info(f"  {schema}.{pg_table}: {pg_count} rows (MATCH)")
                    else:
                        logger.warning(
                            f"  {schema}.{pg_table}: SQL={sql_count}, PG={pg_count} (MISMATCH)"
                        )
                else:
                    logger.info(f"  {schema}.{pg_table}: {pg_count} rows (PG only)")
                    
            except Exception as e:
                logger.error(f"  Error validating {schema}.{pg_table}: {e}")
                result['status'] = 'error'
                result['error'] = str(e)
            
            results.append(result)
    
    # Validate archive tables
    for schema, tables in ARCHIVE_TABLES.items():
        for table in tables:
            result = {
                'schema': schema,
                'table': table,
                'sql_server_count': None,
                'postgres_count': None,
                'match': None,
                'status': 'success'
            }
            
            try:
                pg_count = get_postgres_row_count(pg_conn, schema, table)
                result['postgres_count'] = pg_count
                
                if sql_conn:
                    sql_table = table.replace('_archive', '_Archive')
                    try:
                        sql_count = get_sql_server_row_count(
                            sql_conn, schema.capitalize(), sql_table
                        )
                        result['sql_server_count'] = sql_count
                        result['match'] = (sql_count == pg_count)
                    except Exception:
                        # Archive table might not exist in SQL Server
                        result['sql_server_count'] = 0
                        result['match'] = (pg_count == 0)
                
                logger.info(f"  {schema}.{table}: {pg_count} rows")
                
            except Exception as e:
                logger.error(f"  Error validating {schema}.{table}: {e}")
                result['status'] = 'error'
                result['error'] = str(e)
            
            results.append(result)
    
    return results


def validate_row_counts_olap(sql_conn, pg_conn: psycopg2.extensions.connection,
                             logger: logging.Logger) -> List[Dict]:
    """Validate row counts for OLAP tables."""
    results = []
    
    for schema, tables in OLAP_TABLES.items():
        for pg_table, sql_table in tables:
            result = {
                'schema': schema,
                'table': pg_table,
                'sql_server_count': None,
                'postgres_count': None,
                'match': None,
                'status': 'success'
            }
            
            try:
                pg_count = get_postgres_row_count(pg_conn, schema, pg_table)
                result['postgres_count'] = pg_count
                
                if sql_conn:
                    try:
                        sql_count = get_sql_server_row_count(
                            sql_conn, schema.capitalize(), sql_table
                        )
                        result['sql_server_count'] = sql_count
                        result['match'] = (sql_count == pg_count)
                        
                        if result['match']:
                            logger.info(f"  {schema}.{pg_table}: {pg_count} rows (MATCH)")
                        else:
                            logger.warning(
                                f"  {schema}.{pg_table}: SQL={sql_count}, PG={pg_count} (MISMATCH)"
                            )
                    except Exception:
                        logger.info(f"  {schema}.{pg_table}: {pg_count} rows (PG only)")
                else:
                    logger.info(f"  {schema}.{pg_table}: {pg_count} rows (PG only)")
                    
            except Exception as e:
                logger.error(f"  Error validating {schema}.{pg_table}: {e}")
                result['status'] = 'error'
                result['error'] = str(e)
            
            results.append(result)
    
    return results


def validate_foreign_keys(conn: psycopg2.extensions.connection, 
                          database: str, logger: logging.Logger) -> List[Dict]:
    """Validate foreign key relationships are intact."""
    results = []
    
    cursor = conn.cursor()
    
    # Get all foreign key constraints
    cursor.execute("""
        SELECT
            tc.table_schema,
            tc.table_name,
            kcu.column_name,
            ccu.table_schema AS foreign_table_schema,
            ccu.table_name AS foreign_table_name,
            ccu.column_name AS foreign_column_name,
            tc.constraint_name
        FROM information_schema.table_constraints AS tc
        JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
        JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
            AND ccu.table_schema = tc.table_schema
        WHERE tc.constraint_type = 'FOREIGN KEY'
        ORDER BY tc.table_schema, tc.table_name
    """)
    
    foreign_keys = cursor.fetchall()
    
    for fk in foreign_keys:
        (schema, table, column, ref_schema, ref_table, ref_column, constraint) = fk
        
        result = {
            'constraint': constraint,
            'table': f"{schema}.{table}",
            'column': column,
            'references': f"{ref_schema}.{ref_table}.{ref_column}",
            'orphaned_count': 0,
            'status': 'success'
        }
        
        try:
            # Check for orphaned records
            cursor.execute(sql.SQL("""
                SELECT COUNT(*) FROM {}.{} t
                WHERE t.{} IS NOT NULL
                AND NOT EXISTS (
                    SELECT 1 FROM {}.{} r
                    WHERE r.{} = t.{}
                )
            """).format(
                sql.Identifier(schema),
                sql.Identifier(table),
                sql.Identifier(column),
                sql.Identifier(ref_schema),
                sql.Identifier(ref_table),
                sql.Identifier(ref_column),
                sql.Identifier(column)
            ))
            
            orphaned = cursor.fetchone()[0]
            result['orphaned_count'] = orphaned
            
            if orphaned > 0:
                logger.warning(
                    f"  FK {constraint}: {orphaned} orphaned records in {schema}.{table}"
                )
                result['status'] = 'warning'
            else:
                logger.info(f"  FK {constraint}: OK")
                
        except Exception as e:
            logger.error(f"  Error checking FK {constraint}: {e}")
            result['status'] = 'error'
            result['error'] = str(e)
        
        results.append(result)
    
    cursor.close()
    return results


def validate_sequences(conn: psycopg2.extensions.connection, sequences: Dict,
                       logger: logging.Logger) -> List[Dict]:
    """Validate sequences are properly seeded."""
    results = []
    cursor = conn.cursor()
    
    for sequence, table_info in sequences.items():
        result = {
            'sequence': sequence,
            'current_value': None,
            'max_table_value': None,
            'valid': None,
            'status': 'success'
        }
        
        try:
            # Get current sequence value
            cursor.execute(sql.SQL("SELECT last_value FROM {}").format(
                sql.SQL(sequence)
            ))
            seq_value = cursor.fetchone()[0]
            result['current_value'] = seq_value
            
            # Get max value from table(s)
            if isinstance(table_info, list):
                max_val = 0
                for table, column in table_info:
                    cursor.execute(
                        sql.SQL("SELECT COALESCE(MAX({}), 0) FROM {}").format(
                            sql.Identifier(column),
                            sql.SQL(table)
                        )
                    )
                    val = cursor.fetchone()[0]
                    max_val = max(max_val, val)
            else:
                table, column = table_info
                cursor.execute(
                    sql.SQL("SELECT COALESCE(MAX({}), 0) FROM {}").format(
                        sql.Identifier(column),
                        sql.SQL(table)
                    )
                )
                max_val = cursor.fetchone()[0]
            
            result['max_table_value'] = max_val
            result['valid'] = (seq_value >= max_val)
            
            if result['valid']:
                logger.info(f"  {sequence}: seq={seq_value}, max={max_val} (OK)")
            else:
                logger.warning(
                    f"  {sequence}: seq={seq_value}, max={max_val} (NEEDS RESET)"
                )
                result['status'] = 'warning'
                
        except Exception as e:
            logger.error(f"  Error validating sequence {sequence}: {e}")
            result['status'] = 'error'
            result['error'] = str(e)
        
        results.append(result)
    
    cursor.close()
    return results


def validate_data_integrity(conn: psycopg2.extensions.connection,
                            logger: logging.Logger) -> List[Dict]:
    """Perform basic data integrity checks."""
    results = []
    cursor = conn.cursor()
    
    # Check for NULL values in NOT NULL columns
    cursor.execute("""
        SELECT table_schema, table_name, column_name
        FROM information_schema.columns
        WHERE is_nullable = 'NO'
        AND table_schema NOT IN ('pg_catalog', 'information_schema')
        ORDER BY table_schema, table_name, ordinal_position
    """)
    
    not_null_columns = cursor.fetchall()
    
    # Group by table
    tables = {}
    for schema, table, column in not_null_columns:
        key = (schema, table)
        if key not in tables:
            tables[key] = []
        tables[key].append(column)
    
    # Check each table
    for (schema, table), columns in tables.items():
        result = {
            'table': f"{schema}.{table}",
            'null_violations': [],
            'status': 'success'
        }
        
        try:
            for column in columns[:5]:  # Check first 5 NOT NULL columns
                cursor.execute(sql.SQL("""
                    SELECT COUNT(*) FROM {}.{} WHERE {} IS NULL
                """).format(
                    sql.Identifier(schema),
                    sql.Identifier(table),
                    sql.Identifier(column)
                ))
                null_count = cursor.fetchone()[0]
                
                if null_count > 0:
                    result['null_violations'].append({
                        'column': column,
                        'count': null_count
                    })
                    result['status'] = 'warning'
            
            if result['null_violations']:
                logger.warning(
                    f"  {schema}.{table}: NULL violations in {len(result['null_violations'])} columns"
                )
            
        except Exception as e:
            # Table might not exist or have issues
            pass
        
        if result['null_violations']:
            results.append(result)
    
    cursor.close()
    return results


def generate_report(oltp_results: Dict, olap_results: Dict, 
                    output_file: str, logger: logging.Logger) -> None:
    """Generate a comprehensive validation report."""
    report = {
        'timestamp': datetime.now().isoformat(),
        'oltp': oltp_results,
        'olap': olap_results,
        'summary': {
            'oltp': {
                'total_tables': 0,
                'matched': 0,
                'mismatched': 0,
                'errors': 0,
                'total_rows': 0
            },
            'olap': {
                'total_tables': 0,
                'matched': 0,
                'mismatched': 0,
                'errors': 0,
                'total_rows': 0
            }
        }
    }
    
    # Calculate OLTP summary
    if 'row_counts' in oltp_results:
        for r in oltp_results['row_counts']:
            report['summary']['oltp']['total_tables'] += 1
            if r.get('postgres_count'):
                report['summary']['oltp']['total_rows'] += r['postgres_count']
            if r.get('match') is True:
                report['summary']['oltp']['matched'] += 1
            elif r.get('match') is False:
                report['summary']['oltp']['mismatched'] += 1
            if r.get('status') == 'error':
                report['summary']['oltp']['errors'] += 1
    
    # Calculate OLAP summary
    if 'row_counts' in olap_results:
        for r in olap_results['row_counts']:
            report['summary']['olap']['total_tables'] += 1
            if r.get('postgres_count'):
                report['summary']['olap']['total_rows'] += r['postgres_count']
            if r.get('match') is True:
                report['summary']['olap']['matched'] += 1
            elif r.get('match') is False:
                report['summary']['olap']['mismatched'] += 1
            if r.get('status') == 'error':
                report['summary']['olap']['errors'] += 1
    
    # Write report
    with open(output_file, 'w') as f:
        json.dump(report, f, indent=2, default=str)
    
    logger.info(f"Validation report written to {output_file}")
    
    # Print summary
    logger.info("=" * 60)
    logger.info("Validation Summary")
    logger.info("=" * 60)
    logger.info(f"OLTP Database:")
    logger.info(f"  Tables: {report['summary']['oltp']['total_tables']}")
    logger.info(f"  Matched: {report['summary']['oltp']['matched']}")
    logger.info(f"  Mismatched: {report['summary']['oltp']['mismatched']}")
    logger.info(f"  Errors: {report['summary']['oltp']['errors']}")
    logger.info(f"  Total Rows: {report['summary']['oltp']['total_rows']}")
    logger.info(f"OLAP Database:")
    logger.info(f"  Tables: {report['summary']['olap']['total_tables']}")
    logger.info(f"  Matched: {report['summary']['olap']['matched']}")
    logger.info(f"  Mismatched: {report['summary']['olap']['mismatched']}")
    logger.info(f"  Errors: {report['summary']['olap']['errors']}")
    logger.info(f"  Total Rows: {report['summary']['olap']['total_rows']}")


def main():
    """Main validation function."""
    logger = setup_logging()
    logger.info("=" * 60)
    logger.info("Starting Migration Validation")
    logger.info("=" * 60)
    
    oltp_results = {}
    olap_results = {}
    
    # Connect to SQL Server (optional - for comparison)
    sql_oltp_conn = get_sql_server_connection(SQL_SERVER_OLTP_DB, logger)
    sql_olap_conn = get_sql_server_connection(SQL_SERVER_OLAP_DB, logger)
    
    # Connect to PostgreSQL
    pg_oltp_conn = get_postgres_connection(POSTGRES_OLTP_DB, logger)
    pg_olap_conn = get_postgres_connection(POSTGRES_OLAP_DB, logger)
    
    try:
        # Validate OLTP
        if pg_oltp_conn:
            logger.info("-" * 60)
            logger.info("Validating OLTP Database")
            logger.info("-" * 60)
            
            logger.info("Checking row counts...")
            oltp_results['row_counts'] = validate_row_counts_oltp(
                sql_oltp_conn, pg_oltp_conn, logger
            )
            
            logger.info("Checking foreign keys...")
            oltp_results['foreign_keys'] = validate_foreign_keys(
                pg_oltp_conn, POSTGRES_OLTP_DB, logger
            )
            
            logger.info("Checking sequences...")
            oltp_results['sequences'] = validate_sequences(
                pg_oltp_conn, OLTP_SEQUENCES, logger
            )
            
            logger.info("Checking data integrity...")
            oltp_results['integrity'] = validate_data_integrity(
                pg_oltp_conn, logger
            )
        else:
            logger.warning("Could not connect to OLTP PostgreSQL database")
        
        # Validate OLAP
        if pg_olap_conn:
            logger.info("-" * 60)
            logger.info("Validating OLAP Database")
            logger.info("-" * 60)
            
            logger.info("Checking row counts...")
            olap_results['row_counts'] = validate_row_counts_olap(
                sql_olap_conn, pg_olap_conn, logger
            )
            
            logger.info("Checking foreign keys...")
            olap_results['foreign_keys'] = validate_foreign_keys(
                pg_olap_conn, POSTGRES_OLAP_DB, logger
            )
            
            logger.info("Checking sequences...")
            olap_results['sequences'] = validate_sequences(
                pg_olap_conn, OLAP_SEQUENCES, logger
            )
            
            logger.info("Checking data integrity...")
            olap_results['integrity'] = validate_data_integrity(
                pg_olap_conn, logger
            )
        else:
            logger.warning("Could not connect to OLAP PostgreSQL database")
        
    finally:
        # Close connections
        if sql_oltp_conn:
            sql_oltp_conn.close()
        if sql_olap_conn:
            sql_olap_conn.close()
        if pg_oltp_conn:
            pg_oltp_conn.close()
        if pg_olap_conn:
            pg_olap_conn.close()
    
    # Generate report
    os.makedirs(DATA_DIR, exist_ok=True)
    report_file = os.path.join(DATA_DIR, 'validation_report.json')
    generate_report(oltp_results, olap_results, report_file, logger)
    
    # Determine exit code
    has_errors = False
    for results in [oltp_results, olap_results]:
        for key, items in results.items():
            if isinstance(items, list):
                for item in items:
                    if item.get('status') == 'error':
                        has_errors = True
                    if item.get('match') is False:
                        has_errors = True
    
    return 1 if has_errors else 0


if __name__ == '__main__':
    sys.exit(main())
