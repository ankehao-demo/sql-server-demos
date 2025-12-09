#!/usr/bin/env python3
"""
Phase 6: Data Migration and Validation
Main Migration Orchestrator

Orchestrates the complete data migration process from SQL Server to PostgreSQL.
Supports running individual steps or the full migration pipeline.
"""

import os
import sys
import argparse
import logging
import subprocess
from datetime import datetime

# Add current directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from config import DATA_DIR, LOGS_DIR


def setup_logging() -> logging.Logger:
    """Set up logging configuration."""
    os.makedirs(LOGS_DIR, exist_ok=True)
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    log_file = os.path.join(LOGS_DIR, f'migration_{timestamp}.log')
    
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(log_file),
            logging.StreamHandler()
        ]
    )
    return logging.getLogger(__name__)


def run_script(script_path: str, logger: logging.Logger) -> int:
    """Run a Python script and return its exit code."""
    logger.info(f"Running: {script_path}")
    
    try:
        result = subprocess.run(
            [sys.executable, script_path],
            cwd=os.path.dirname(os.path.abspath(__file__)),
            capture_output=False
        )
        return result.returncode
    except Exception as e:
        logger.error(f"Failed to run {script_path}: {e}")
        return 1


def run_extraction(oltp: bool, olap: bool, logger: logging.Logger) -> int:
    """Run data extraction scripts."""
    exit_code = 0
    
    if oltp:
        logger.info("=" * 60)
        logger.info("Extracting OLTP Data")
        logger.info("=" * 60)
        script = os.path.join(
            os.path.dirname(__file__), '01-extract', 'extract_oltp.py'
        )
        code = run_script(script, logger)
        if code != 0:
            logger.error("OLTP extraction failed")
            exit_code = 1
    
    if olap:
        logger.info("=" * 60)
        logger.info("Extracting OLAP Data")
        logger.info("=" * 60)
        script = os.path.join(
            os.path.dirname(__file__), '01-extract', 'extract_olap.py'
        )
        code = run_script(script, logger)
        if code != 0:
            logger.error("OLAP extraction failed")
            exit_code = 1
    
    return exit_code


def run_transformation(logger: logging.Logger) -> int:
    """Run data transformation script."""
    logger.info("=" * 60)
    logger.info("Transforming Data")
    logger.info("=" * 60)
    
    script = os.path.join(
        os.path.dirname(__file__), '02-transform', 'transform_data.py'
    )
    return run_script(script, logger)


def run_loading(oltp: bool, olap: bool, logger: logging.Logger) -> int:
    """Run data loading scripts."""
    exit_code = 0
    
    if oltp:
        logger.info("=" * 60)
        logger.info("Loading OLTP Data")
        logger.info("=" * 60)
        script = os.path.join(
            os.path.dirname(__file__), '03-load', 'load_oltp.py'
        )
        code = run_script(script, logger)
        if code != 0:
            logger.error("OLTP loading failed")
            exit_code = 1
    
    if olap:
        logger.info("=" * 60)
        logger.info("Loading OLAP Data")
        logger.info("=" * 60)
        script = os.path.join(
            os.path.dirname(__file__), '03-load', 'load_olap.py'
        )
        code = run_script(script, logger)
        if code != 0:
            logger.error("OLAP loading failed")
            exit_code = 1
    
    return exit_code


def run_validation(logger: logging.Logger) -> int:
    """Run validation script."""
    logger.info("=" * 60)
    logger.info("Validating Migration")
    logger.info("=" * 60)
    
    script = os.path.join(
        os.path.dirname(__file__), '04-validate', 'validate_migration.py'
    )
    return run_script(script, logger)


def run_performance_test(logger: logging.Logger) -> int:
    """Run performance testing script."""
    logger.info("=" * 60)
    logger.info("Running Performance Tests")
    logger.info("=" * 60)
    
    script = os.path.join(
        os.path.dirname(__file__), '05-performance', 'performance_test.py'
    )
    return run_script(script, logger)


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description='Wide World Importers Data Migration Tool',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Run full migration (OLTP + OLAP)
  python run_migration.py --full
  
  # Run OLTP migration only
  python run_migration.py --oltp
  
  # Run OLAP migration only
  python run_migration.py --olap
  
  # Run individual steps
  python run_migration.py --extract --oltp
  python run_migration.py --transform
  python run_migration.py --load --oltp
  python run_migration.py --validate
  python run_migration.py --performance
  
  # Skip extraction (use existing CSV files)
  python run_migration.py --full --skip-extract
        """
    )
    
    # Database selection
    db_group = parser.add_argument_group('Database Selection')
    db_group.add_argument('--full', action='store_true',
                          help='Run full migration (OLTP + OLAP)')
    db_group.add_argument('--oltp', action='store_true',
                          help='Include OLTP database')
    db_group.add_argument('--olap', action='store_true',
                          help='Include OLAP database')
    
    # Step selection
    step_group = parser.add_argument_group('Step Selection')
    step_group.add_argument('--extract', action='store_true',
                            help='Run extraction step')
    step_group.add_argument('--transform', action='store_true',
                            help='Run transformation step')
    step_group.add_argument('--load', action='store_true',
                            help='Run loading step')
    step_group.add_argument('--validate', action='store_true',
                            help='Run validation step')
    step_group.add_argument('--performance', action='store_true',
                            help='Run performance testing')
    
    # Options
    opt_group = parser.add_argument_group('Options')
    opt_group.add_argument('--skip-extract', action='store_true',
                           help='Skip extraction (use existing CSV files)')
    opt_group.add_argument('--skip-transform', action='store_true',
                           help='Skip transformation')
    opt_group.add_argument('--skip-validate', action='store_true',
                           help='Skip validation')
    
    args = parser.parse_args()
    
    # Set up logging
    logger = setup_logging()
    
    logger.info("=" * 60)
    logger.info("Wide World Importers Data Migration")
    logger.info("Phase 6: Data Migration and Validation")
    logger.info("=" * 60)
    logger.info(f"Started at: {datetime.now().isoformat()}")
    
    # Determine what to run
    run_oltp = args.oltp or args.full
    run_olap = args.olap or args.full
    
    # If no database specified and no specific step, show help
    if not (run_oltp or run_olap) and not any([
        args.extract, args.transform, args.load, args.validate, args.performance
    ]):
        parser.print_help()
        return 0
    
    # If specific steps are selected, run only those
    run_specific_steps = any([
        args.extract, args.transform, args.load, args.validate, args.performance
    ])
    
    exit_code = 0
    
    if run_specific_steps:
        # Run only selected steps
        if args.extract:
            code = run_extraction(run_oltp or True, run_olap or True, logger)
            if code != 0:
                exit_code = 1
        
        if args.transform:
            code = run_transformation(logger)
            if code != 0:
                exit_code = 1
        
        if args.load:
            code = run_loading(run_oltp or True, run_olap or True, logger)
            if code != 0:
                exit_code = 1
        
        if args.validate:
            code = run_validation(logger)
            if code != 0:
                exit_code = 1
        
        if args.performance:
            code = run_performance_test(logger)
            if code != 0:
                exit_code = 1
    else:
        # Run full pipeline
        if not args.skip_extract:
            code = run_extraction(run_oltp, run_olap, logger)
            if code != 0:
                logger.error("Extraction failed. Stopping migration.")
                return 1
        
        if not args.skip_transform:
            code = run_transformation(logger)
            if code != 0:
                logger.error("Transformation failed. Stopping migration.")
                return 1
        
        code = run_loading(run_oltp, run_olap, logger)
        if code != 0:
            logger.error("Loading failed. Continuing with validation...")
            exit_code = 1
        
        if not args.skip_validate:
            code = run_validation(logger)
            if code != 0:
                logger.warning("Validation found issues.")
                exit_code = 1
        
        # Performance testing is optional
        logger.info("Running performance tests...")
        run_performance_test(logger)
    
    # Summary
    logger.info("=" * 60)
    logger.info("Migration Complete")
    logger.info("=" * 60)
    logger.info(f"Finished at: {datetime.now().isoformat()}")
    
    if exit_code == 0:
        logger.info("Status: SUCCESS")
    else:
        logger.warning("Status: COMPLETED WITH ISSUES")
    
    logger.info(f"Logs directory: {LOGS_DIR}")
    logger.info(f"Data directory: {DATA_DIR}")
    
    return exit_code


if __name__ == '__main__':
    sys.exit(main())
