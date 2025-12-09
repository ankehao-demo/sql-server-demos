#!/usr/bin/env python3
"""
Phase 6: Data Migration and Validation
Performance Testing Script

Tests query performance on the migrated PostgreSQL database and
provides optimization recommendations.
"""

import os
import sys
import logging
import json
import time
from datetime import datetime
from typing import Optional, Dict, List

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
    POSTGRES_OLTP_DB,
    POSTGRES_OLAP_DB,
    DATA_DIR,
    LOGS_DIR,
)


def setup_logging() -> logging.Logger:
    """Set up logging configuration."""
    os.makedirs(LOGS_DIR, exist_ok=True)
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    log_file = os.path.join(LOGS_DIR, f'performance_{timestamp}.log')
    
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(log_file),
            logging.StreamHandler()
        ]
    )
    return logging.getLogger(__name__)


def get_connection(database: str, logger: logging.Logger) -> Optional[psycopg2.extensions.connection]:
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


# OLTP Performance Test Queries
OLTP_TEST_QUERIES = [
    {
        'name': 'Simple SELECT - People',
        'query': "SELECT * FROM application.people WHERE personid = 1",
        'description': 'Single row lookup by primary key'
    },
    {
        'name': 'JOIN - Customers with Categories',
        'query': """
            SELECT c.customername, cc.customercategoryname
            FROM sales.customers c
            JOIN sales.customercategories cc ON c.customercategoryid = cc.customercategoryid
            LIMIT 100
        """,
        'description': 'Two-table join with limit'
    },
    {
        'name': 'Aggregate - Order Totals by Customer',
        'query': """
            SELECT c.customername, COUNT(o.orderid) as order_count
            FROM sales.customers c
            LEFT JOIN sales.orders o ON c.customerid = o.customerid
            GROUP BY c.customerid, c.customername
            ORDER BY order_count DESC
            LIMIT 20
        """,
        'description': 'Aggregation with GROUP BY and ORDER BY'
    },
    {
        'name': 'Complex JOIN - Invoice Details',
        'query': """
            SELECT 
                i.invoiceid,
                c.customername,
                si.stockitemname,
                il.quantity,
                il.unitprice,
                il.extendedprice
            FROM sales.invoices i
            JOIN sales.customers c ON i.customerid = c.customerid
            JOIN sales.invoicelines il ON i.invoiceid = il.invoiceid
            JOIN warehouse.stockitems si ON il.stockitemid = si.stockitemid
            WHERE i.invoicedate >= '2016-01-01'
            LIMIT 100
        """,
        'description': 'Multi-table join with date filter'
    },
    {
        'name': 'Temporal Query - Historical Data',
        'query': """
            SELECT *
            FROM application.people_archive
            WHERE validto < '9999-12-31'
            ORDER BY validfrom DESC
            LIMIT 50
        """,
        'description': 'Query against archive/history table'
    },
    {
        'name': 'Full Text Search - Stock Items',
        'query': """
            SELECT stockitemid, stockitemname, searchdetails
            FROM warehouse.stockitems
            WHERE searchdetails ILIKE '%chocolate%'
            LIMIT 20
        """,
        'description': 'Text search using ILIKE'
    },
    {
        'name': 'Subquery - Customers with Recent Orders',
        'query': """
            SELECT c.customerid, c.customername
            FROM sales.customers c
            WHERE EXISTS (
                SELECT 1 FROM sales.orders o
                WHERE o.customerid = c.customerid
                AND o.orderdate >= '2016-01-01'
            )
            LIMIT 50
        """,
        'description': 'Correlated subquery with EXISTS'
    },
]

# OLAP Performance Test Queries
OLAP_TEST_QUERIES = [
    {
        'name': 'Dimension Lookup - City',
        'query': "SELECT * FROM dimension.city WHERE city_key = 1",
        'description': 'Single row lookup by surrogate key'
    },
    {
        'name': 'Fact Table Scan - Sales Summary',
        'query': """
            SELECT 
                invoice_date_key,
                SUM(quantity) as total_quantity,
                SUM(total_including_tax) as total_revenue
            FROM fact.sale
            WHERE invoice_date_key >= '2016-01-01'
            GROUP BY invoice_date_key
            ORDER BY invoice_date_key
            LIMIT 100
        """,
        'description': 'Fact table aggregation with date filter'
    },
    {
        'name': 'Star Schema Query - Sales by Customer',
        'query': """
            SELECT 
                c.customer,
                c.category,
                SUM(s.quantity) as total_quantity,
                SUM(s.total_including_tax) as total_revenue
            FROM fact.sale s
            JOIN dimension.customer c ON s.customer_key = c.customer_key
            WHERE s.invoice_date_key >= '2016-01-01'
            GROUP BY c.customer_key, c.customer, c.category
            ORDER BY total_revenue DESC
            LIMIT 20
        """,
        'description': 'Fact-dimension join with aggregation'
    },
    {
        'name': 'Multi-Dimension Query - Sales Analysis',
        'query': """
            SELECT 
                d.calendar_year,
                d.calendar_month_label,
                c.city,
                c.sales_territory,
                SUM(s.total_including_tax) as revenue
            FROM fact.sale s
            JOIN dimension.date d ON s.invoice_date_key = d.date
            JOIN dimension.city c ON s.city_key = c.city_key
            WHERE d.calendar_year >= 2016
            GROUP BY d.calendar_year, d.calendar_month_label, 
                     d.calendar_month_number, c.city, c.sales_territory
            ORDER BY d.calendar_year, d.calendar_month_number
            LIMIT 100
        """,
        'description': 'Multiple dimension joins with time-based analysis'
    },
    {
        'name': 'Movement Analysis',
        'query': """
            SELECT 
                si.stock_item,
                tt.transaction_type,
                SUM(m.quantity) as total_movement
            FROM fact.movement m
            JOIN dimension.stock_item si ON m.stock_item_key = si.stock_item_key
            JOIN dimension.transaction_type tt ON m.transaction_type_key = tt.transaction_type_key
            WHERE m.date_key >= '2016-01-01'
            GROUP BY si.stock_item_key, si.stock_item, tt.transaction_type
            ORDER BY ABS(total_movement) DESC
            LIMIT 20
        """,
        'description': 'Inventory movement analysis'
    },
]


def run_query_test(conn: psycopg2.extensions.connection, query_info: Dict,
                   iterations: int, logger: logging.Logger) -> Dict:
    """Run a single query test multiple times and collect metrics."""
    result = {
        'name': query_info['name'],
        'description': query_info['description'],
        'iterations': iterations,
        'times_ms': [],
        'avg_ms': 0,
        'min_ms': 0,
        'max_ms': 0,
        'rows_returned': 0,
        'status': 'success',
        'error': None,
        'explain_plan': None
    }
    
    cursor = conn.cursor()
    
    try:
        # Get EXPLAIN ANALYZE for the first run
        cursor.execute(f"EXPLAIN ANALYZE {query_info['query']}")
        explain_rows = cursor.fetchall()
        result['explain_plan'] = '\n'.join([row[0] for row in explain_rows])
        
        # Run the query multiple times
        for i in range(iterations):
            start_time = time.time()
            cursor.execute(query_info['query'])
            rows = cursor.fetchall()
            end_time = time.time()
            
            elapsed_ms = (end_time - start_time) * 1000
            result['times_ms'].append(elapsed_ms)
            
            if i == 0:
                result['rows_returned'] = len(rows)
        
        # Calculate statistics
        result['avg_ms'] = sum(result['times_ms']) / len(result['times_ms'])
        result['min_ms'] = min(result['times_ms'])
        result['max_ms'] = max(result['times_ms'])
        
        logger.info(
            f"  {query_info['name']}: avg={result['avg_ms']:.2f}ms, "
            f"min={result['min_ms']:.2f}ms, max={result['max_ms']:.2f}ms, "
            f"rows={result['rows_returned']}"
        )
        
    except Exception as e:
        logger.error(f"  Error running {query_info['name']}: {e}")
        result['status'] = 'error'
        result['error'] = str(e)
    
    cursor.close()
    return result


def analyze_table_statistics(conn: psycopg2.extensions.connection,
                             logger: logging.Logger) -> List[Dict]:
    """Analyze table statistics and suggest optimizations."""
    results = []
    cursor = conn.cursor()
    
    # Get table statistics
    cursor.execute("""
        SELECT 
            schemaname,
            relname as tablename,
            n_live_tup as row_count,
            n_dead_tup as dead_rows,
            last_vacuum,
            last_autovacuum,
            last_analyze,
            last_autoanalyze
        FROM pg_stat_user_tables
        ORDER BY n_live_tup DESC
    """)
    
    tables = cursor.fetchall()
    
    for table in tables:
        (schema, tablename, row_count, dead_rows, last_vacuum, 
         last_autovacuum, last_analyze, last_autoanalyze) = table
        
        result = {
            'schema': schema,
            'table': tablename,
            'row_count': row_count,
            'dead_rows': dead_rows,
            'last_vacuum': str(last_vacuum) if last_vacuum else None,
            'last_analyze': str(last_analyze) if last_analyze else None,
            'recommendations': []
        }
        
        # Check for high dead row ratio
        if row_count > 0 and dead_rows > row_count * 0.1:
            result['recommendations'].append(
                f"High dead row ratio ({dead_rows}/{row_count}). Consider running VACUUM."
            )
        
        # Check if ANALYZE is needed
        if last_analyze is None and last_autoanalyze is None:
            result['recommendations'].append(
                "Table has never been analyzed. Run ANALYZE to update statistics."
            )
        
        if result['recommendations']:
            results.append(result)
    
    cursor.close()
    return results


def analyze_index_usage(conn: psycopg2.extensions.connection,
                        logger: logging.Logger) -> List[Dict]:
    """Analyze index usage and suggest optimizations."""
    results = []
    cursor = conn.cursor()
    
    # Get index usage statistics
    cursor.execute("""
        SELECT 
            schemaname,
            relname as tablename,
            indexrelname as indexname,
            idx_scan as index_scans,
            idx_tup_read as tuples_read,
            idx_tup_fetch as tuples_fetched,
            pg_size_pretty(pg_relation_size(indexrelid)) as index_size
        FROM pg_stat_user_indexes
        ORDER BY idx_scan ASC
        LIMIT 50
    """)
    
    indexes = cursor.fetchall()
    
    for idx in indexes:
        (schema, tablename, indexname, scans, reads, fetches, size) = idx
        
        result = {
            'schema': schema,
            'table': tablename,
            'index': indexname,
            'scans': scans,
            'tuples_read': reads,
            'tuples_fetched': fetches,
            'size': size,
            'recommendations': []
        }
        
        # Check for unused indexes
        if scans == 0:
            result['recommendations'].append(
                f"Index '{indexname}' has never been used. Consider dropping if not needed."
            )
        
        if result['recommendations']:
            results.append(result)
    
    cursor.close()
    return results


def generate_optimization_recommendations(query_results: List[Dict],
                                          table_stats: List[Dict],
                                          index_stats: List[Dict],
                                          logger: logging.Logger) -> List[str]:
    """Generate optimization recommendations based on test results."""
    recommendations = []
    
    # Analyze slow queries
    slow_queries = [q for q in query_results if q.get('avg_ms', 0) > 100]
    if slow_queries:
        recommendations.append(
            f"Found {len(slow_queries)} queries with average execution time > 100ms. "
            "Review EXPLAIN plans and consider adding indexes."
        )
    
    # Check for sequential scans in explain plans
    seq_scan_queries = []
    for q in query_results:
        if q.get('explain_plan') and 'Seq Scan' in q['explain_plan']:
            seq_scan_queries.append(q['name'])
    
    if seq_scan_queries:
        recommendations.append(
            f"Sequential scans detected in: {', '.join(seq_scan_queries)}. "
            "Consider adding indexes on frequently filtered columns."
        )
    
    # Table maintenance recommendations
    tables_needing_vacuum = [t for t in table_stats if t.get('recommendations')]
    if tables_needing_vacuum:
        recommendations.append(
            f"{len(tables_needing_vacuum)} tables need maintenance (VACUUM/ANALYZE)."
        )
    
    # Unused index recommendations
    unused_indexes = [i for i in index_stats if i.get('recommendations')]
    if unused_indexes:
        recommendations.append(
            f"{len(unused_indexes)} indexes appear to be unused. "
            "Review and consider dropping to save space and improve write performance."
        )
    
    # General recommendations
    recommendations.extend([
        "Run ANALYZE on all tables after data migration to update statistics.",
        "Consider using BRIN indexes for large fact tables partitioned by date.",
        "Monitor pg_stat_statements for identifying slow queries in production.",
        "Configure work_mem and shared_buffers based on available memory.",
        "Use connection pooling (e.g., PgBouncer) for high-concurrency workloads."
    ])
    
    return recommendations


def main():
    """Main performance testing function."""
    logger = setup_logging()
    logger.info("=" * 60)
    logger.info("Starting Performance Testing")
    logger.info("=" * 60)
    
    results = {
        'timestamp': datetime.now().isoformat(),
        'oltp': {},
        'olap': {},
        'recommendations': []
    }
    
    iterations = 3  # Number of times to run each query
    
    # Test OLTP database
    logger.info("-" * 60)
    logger.info("Testing OLTP Database Performance")
    logger.info("-" * 60)
    
    oltp_conn = get_connection(POSTGRES_OLTP_DB, logger)
    if oltp_conn:
        try:
            logger.info("Running query tests...")
            results['oltp']['queries'] = []
            for query_info in OLTP_TEST_QUERIES:
                result = run_query_test(oltp_conn, query_info, iterations, logger)
                results['oltp']['queries'].append(result)
            
            logger.info("Analyzing table statistics...")
            results['oltp']['table_stats'] = analyze_table_statistics(oltp_conn, logger)
            
            logger.info("Analyzing index usage...")
            results['oltp']['index_stats'] = analyze_index_usage(oltp_conn, logger)
            
        finally:
            oltp_conn.close()
    else:
        logger.warning("Could not connect to OLTP database")
    
    # Test OLAP database
    logger.info("-" * 60)
    logger.info("Testing OLAP Database Performance")
    logger.info("-" * 60)
    
    olap_conn = get_connection(POSTGRES_OLAP_DB, logger)
    if olap_conn:
        try:
            logger.info("Running query tests...")
            results['olap']['queries'] = []
            for query_info in OLAP_TEST_QUERIES:
                result = run_query_test(olap_conn, query_info, iterations, logger)
                results['olap']['queries'].append(result)
            
            logger.info("Analyzing table statistics...")
            results['olap']['table_stats'] = analyze_table_statistics(olap_conn, logger)
            
            logger.info("Analyzing index usage...")
            results['olap']['index_stats'] = analyze_index_usage(olap_conn, logger)
            
        finally:
            olap_conn.close()
    else:
        logger.warning("Could not connect to OLAP database")
    
    # Generate recommendations
    logger.info("-" * 60)
    logger.info("Generating Optimization Recommendations")
    logger.info("-" * 60)
    
    all_queries = results.get('oltp', {}).get('queries', []) + \
                  results.get('olap', {}).get('queries', [])
    all_table_stats = results.get('oltp', {}).get('table_stats', []) + \
                      results.get('olap', {}).get('table_stats', [])
    all_index_stats = results.get('oltp', {}).get('index_stats', []) + \
                      results.get('olap', {}).get('index_stats', [])
    
    results['recommendations'] = generate_optimization_recommendations(
        all_queries, all_table_stats, all_index_stats, logger
    )
    
    for rec in results['recommendations']:
        logger.info(f"  - {rec}")
    
    # Write results
    os.makedirs(DATA_DIR, exist_ok=True)
    report_file = os.path.join(DATA_DIR, 'performance_report.json')
    with open(report_file, 'w') as f:
        json.dump(results, f, indent=2, default=str)
    logger.info(f"Performance report written to {report_file}")
    
    # Summary
    logger.info("=" * 60)
    logger.info("Performance Testing Summary")
    logger.info("=" * 60)
    
    oltp_queries = results.get('oltp', {}).get('queries', [])
    olap_queries = results.get('olap', {}).get('queries', [])
    
    if oltp_queries:
        avg_oltp = sum(q.get('avg_ms', 0) for q in oltp_queries) / len(oltp_queries)
        logger.info(f"OLTP: {len(oltp_queries)} queries tested, avg={avg_oltp:.2f}ms")
    
    if olap_queries:
        avg_olap = sum(q.get('avg_ms', 0) for q in olap_queries) / len(olap_queries)
        logger.info(f"OLAP: {len(olap_queries)} queries tested, avg={avg_olap:.2f}ms")
    
    return 0


if __name__ == '__main__':
    sys.exit(main())
