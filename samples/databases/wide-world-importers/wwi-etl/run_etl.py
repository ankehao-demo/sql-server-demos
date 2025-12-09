#!/usr/bin/env python3
"""
Wide World Importers Daily ETL Runner
PostgreSQL-compatible ETL solution replacing SQL Server SSIS packages

This script runs the daily ETL process that migrates data from the OLTP
database (WideWorldImporters) to the OLAP data warehouse (WideWorldImportersDW).

Usage:
    python run_etl.py [--config CONFIG_FILE] [--log-level LEVEL]
    
Environment Variables:
    OLTP_DB_HOST: OLTP database host (default: localhost)
    OLTP_DB_PORT: OLTP database port (default: 5432)
    OLTP_DB_NAME: OLTP database name (default: wideworldimporters)
    OLTP_DB_USER: OLTP database user (default: webapi)
    OLTP_DB_PASSWORD: OLTP database password
    OLAP_DB_HOST: OLAP database host (default: localhost)
    OLAP_DB_PORT: OLAP database port (default: 5432)
    OLAP_DB_NAME: OLAP database name (default: wideworldimportersdw)
    OLAP_DB_USER: OLAP database user (default: webapi)
    OLAP_DB_PASSWORD: OLAP database password
    ETL_BATCH_SIZE: Batch size for bulk inserts (default: 10000)
    ETL_LOG_LEVEL: Logging level (default: INFO)
"""

import argparse
import json
import logging
import sys
from datetime import datetime

from config import ETLConfig
from etl_engine import ETLEngine


def setup_logging(log_level: str) -> None:
    """Configure logging for the ETL process."""
    logging.basicConfig(
        level=getattr(logging, log_level.upper()),
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[
            logging.StreamHandler(sys.stdout),
        ]
    )


def print_results(results: dict) -> None:
    """Print ETL results in a formatted manner."""
    print("\n" + "=" * 60)
    print("ETL RESULTS SUMMARY")
    print("=" * 60)
    print(f"Start Time: {results['start_time']}")
    print(f"End Time: {results['end_time']}")
    print(f"Duration: {results['duration']:.2f} seconds")
    print(f"Overall Success: {results['success']}")
    print(f"Total Rows Processed: {results['total_rows']}")
    print()
    
    print("Tables Processed:")
    print("-" * 40)
    for table_name, table_results in results['tables_processed'].items():
        status = "OK" if table_results['success'] else "FAILED"
        print(f"  {table_name}: {table_results['rows']} rows [{status}]")
    
    if results['errors']:
        print()
        print("Errors:")
        print("-" * 40)
        for error in results['errors']:
            print(f"  - {error}")
    
    print("=" * 60)


def main():
    """Main entry point for the ETL runner."""
    parser = argparse.ArgumentParser(
        description='Wide World Importers Daily ETL Runner',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    parser.add_argument(
        '--log-level',
        default='INFO',
        choices=['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL'],
        help='Logging level (default: INFO)'
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Perform a dry run without making changes'
    )
    parser.add_argument(
        '--output-json',
        type=str,
        help='Output results to JSON file'
    )
    
    args = parser.parse_args()
    
    setup_logging(args.log_level)
    logger = logging.getLogger(__name__)
    
    logger.info("Wide World Importers Daily ETL")
    logger.info("PostgreSQL-compatible ETL replacing SSIS DailyETLMain package")
    logger.info("-" * 60)
    
    try:
        config = ETLConfig.from_env()
        logger.info("OLTP Database: %s@%s:%d/%s",
                   config.oltp_db.user, config.oltp_db.host,
                   config.oltp_db.port, config.oltp_db.database)
        logger.info("OLAP Database: %s@%s:%d/%s",
                   config.olap_db.user, config.olap_db.host,
                   config.olap_db.port, config.olap_db.database)
        
        if args.dry_run:
            logger.info("DRY RUN MODE - No changes will be made")
            return 0
            
        with ETLEngine(config) as engine:
            results = engine.run_daily_etl()
            
        print_results(results)
        
        if args.output_json:
            results_serializable = {
                'start_time': results['start_time'].isoformat(),
                'end_time': results['end_time'].isoformat(),
                'duration': results['duration'],
                'success': results['success'],
                'total_rows': results['total_rows'],
                'tables_processed': results['tables_processed'],
                'errors': results['errors'],
            }
            with open(args.output_json, 'w') as f:
                json.dump(results_serializable, f, indent=2)
            logger.info("Results written to %s", args.output_json)
            
        return 0 if results['success'] else 1
        
    except Exception as e:
        logger.error("ETL failed with error: %s", str(e))
        return 1


if __name__ == '__main__':
    sys.exit(main())
