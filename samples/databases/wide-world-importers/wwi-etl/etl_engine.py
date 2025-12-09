"""
Wide World Importers ETL Engine
PostgreSQL-compatible ETL solution replacing SQL Server SSIS packages

This module provides the core ETL functionality for extracting data from the
OLTP database (WideWorldImporters) and loading it into the OLAP data warehouse
(WideWorldImportersDW).
"""

import logging
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional, Tuple

import psycopg2
from psycopg2 import sql
from psycopg2.extras import RealDictCursor, execute_batch

from config import (
    DIMENSION_CONFIGS,
    ETL_EXECUTION_ORDER,
    FACT_CONFIGS,
    ETLConfig,
)

logger = logging.getLogger(__name__)


class ETLEngine:
    """
    ETL Engine for Wide World Importers data warehouse.
    
    This engine orchestrates the ETL process from the OLTP database to the
    OLAP data warehouse, following the same pattern as the original SSIS package:
    1. Calculate ETL cutoff time
    2. Populate date dimension for current year
    3. Load dimensions (City, Customer, Employee, etc.)
    4. Load facts (Sale, Order, Purchase, Movement, Transaction, Stock Holding)
    """
    
    def __init__(self, config: ETLConfig):
        self.config = config
        self.oltp_conn = None
        self.olap_conn = None
        
    def connect(self) -> None:
        """Establish connections to both OLTP and OLAP databases."""
        logger.info("Connecting to OLTP database: %s", self.config.oltp_db.database)
        self.oltp_conn = psycopg2.connect(self.config.oltp_db.connection_string)
        
        logger.info("Connecting to OLAP database: %s", self.config.olap_db.database)
        self.olap_conn = psycopg2.connect(self.config.olap_db.connection_string)
        
    def disconnect(self) -> None:
        """Close database connections."""
        if self.oltp_conn:
            self.oltp_conn.close()
            self.oltp_conn = None
        if self.olap_conn:
            self.olap_conn.close()
            self.olap_conn = None
            
    def __enter__(self):
        self.connect()
        return self
        
    def __exit__(self, exc_type, exc_val, exc_tb):
        self.disconnect()
        return False
        
    def calculate_etl_cutoff_time(self) -> datetime:
        """
        Calculate the ETL cutoff time.
        
        This is the current time minus 5 minutes to ensure data consistency,
        matching the original SSIS package behavior.
        """
        cutoff_time = datetime.utcnow() - timedelta(minutes=5)
        cutoff_time = cutoff_time.replace(microsecond=0)
        logger.info("ETL cutoff time: %s", cutoff_time)
        return cutoff_time
        
    def get_last_etl_cutoff_time(self, table_name: str) -> datetime:
        """Get the last ETL cutoff time for a given table."""
        with self.olap_conn.cursor() as cur:
            cur.execute(
                "SELECT integration.get_last_etl_cutoff_time(%s)",
                (table_name,)
            )
            result = cur.fetchone()
            return result[0] if result else datetime(2012, 12, 31, 23, 59, 59)
            
    def get_lineage_key(self, table_name: str, new_cutoff_time: datetime) -> int:
        """Create a new lineage record and return the lineage key."""
        with self.olap_conn.cursor() as cur:
            cur.execute(
                "SELECT integration.get_lineage_key(%s, %s)",
                (table_name, new_cutoff_time)
            )
            result = cur.fetchone()
            self.olap_conn.commit()
            return result[0]
            
    def populate_date_dimension(self, year: int) -> None:
        """Populate the date dimension for a given year."""
        logger.info("Populating date dimension for year %d", year)
        with self.olap_conn.cursor() as cur:
            cur.execute("CALL integration.populate_date_dimension_for_year(%s)", (year,))
            self.olap_conn.commit()
        logger.info("Date dimension populated for year %d", year)
        
    def truncate_staging_table(self, staging_table: str) -> None:
        """Truncate a staging table before loading new data."""
        with self.olap_conn.cursor() as cur:
            cur.execute(sql.SQL("TRUNCATE TABLE {}").format(
                sql.Identifier(*staging_table.split('.'))
            ))
            self.olap_conn.commit()
            
    def extract_data(
        self,
        procedure_name: str,
        last_cutoff: datetime,
        new_cutoff: datetime
    ) -> List[Dict[str, Any]]:
        """
        Extract data from OLTP database using the specified procedure.
        
        Args:
            procedure_name: Name of the extraction procedure
            last_cutoff: Last ETL cutoff time
            new_cutoff: New ETL cutoff time
            
        Returns:
            List of dictionaries containing the extracted data
        """
        logger.info("Extracting data using %s", procedure_name)
        logger.debug("Last cutoff: %s, New cutoff: %s", last_cutoff, new_cutoff)
        
        with self.oltp_conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(
                f"CALL {procedure_name}(%s, %s, %s)",
                (last_cutoff, new_cutoff, None)
            )
            
            cur.execute("FETCH ALL FROM p_results")
            results = cur.fetchall()
            
            cur.execute("CLOSE p_results")
            self.oltp_conn.rollback()
            
        logger.info("Extracted %d rows", len(results))
        return [dict(row) for row in results]
        
    def load_staging_data(
        self,
        staging_table: str,
        columns: List[str],
        data: List[Dict[str, Any]]
    ) -> int:
        """
        Load data into a staging table.
        
        Args:
            staging_table: Name of the staging table
            columns: List of column names
            data: List of dictionaries containing the data
            
        Returns:
            Number of rows loaded
        """
        if not data:
            logger.info("No data to load into %s", staging_table)
            return 0
            
        logger.info("Loading %d rows into %s", len(data), staging_table)
        
        self.truncate_staging_table(staging_table)
        
        column_map = self._create_column_map(columns)
        
        insert_sql = sql.SQL("INSERT INTO {} ({}) VALUES ({})").format(
            sql.Identifier(*staging_table.split('.')),
            sql.SQL(', ').join(map(sql.Identifier, columns)),
            sql.SQL(', ').join(sql.Placeholder() * len(columns))
        )
        
        with self.olap_conn.cursor() as cur:
            rows = []
            for row in data:
                values = []
                for col in columns:
                    source_col = column_map.get(col, col)
                    value = row.get(source_col)
                    values.append(value)
                rows.append(tuple(values))
                
            execute_batch(cur, insert_sql.as_string(self.olap_conn), rows, 
                         page_size=self.config.batch_size)
            self.olap_conn.commit()
            
        logger.info("Loaded %d rows into %s", len(data), staging_table)
        return len(data)
        
    def _create_column_map(self, columns: List[str]) -> Dict[str, str]:
        """
        Create a mapping from staging column names to source column names.
        
        The source procedures return columns with spaces (e.g., "WWI City ID")
        while staging tables use underscores (e.g., "wwi_city_id").
        """
        column_map = {}
        for col in columns:
            source_col = col.replace('_', ' ').title()
            if source_col.startswith('Wwi '):
                source_col = 'WWI ' + source_col[4:]
            column_map[col] = source_col
        return column_map
        
    def migrate_staged_data(self, migrate_procedure: str) -> None:
        """Execute the migration procedure to move data from staging to final tables."""
        logger.info("Executing migration procedure: %s", migrate_procedure)
        with self.olap_conn.cursor() as cur:
            cur.execute(f"CALL {migrate_procedure}()")
            self.olap_conn.commit()
        logger.info("Migration procedure completed: %s", migrate_procedure)
        
    def process_dimension(
        self,
        table_name: str,
        config: Dict[str, Any],
        new_cutoff: datetime
    ) -> Tuple[int, bool]:
        """
        Process a single dimension ETL.
        
        Args:
            table_name: Name of the dimension table
            config: ETL configuration for this dimension
            new_cutoff: New ETL cutoff time
            
        Returns:
            Tuple of (rows_processed, success)
        """
        logger.info("Processing dimension: %s", table_name)
        
        try:
            last_cutoff = self.get_last_etl_cutoff_time(table_name)
            
            lineage_key = self.get_lineage_key(table_name, new_cutoff)
            logger.debug("Lineage key: %d", lineage_key)
            
            data = self.extract_data(
                config["extract_procedure"],
                last_cutoff,
                new_cutoff
            )
            
            if data:
                self.load_staging_data(
                    config["staging_table"],
                    config["staging_columns"],
                    data
                )
                
                self.migrate_staged_data(config["migrate_procedure"])
            else:
                with self.olap_conn.cursor() as cur:
                    cur.execute("""
                        UPDATE integration.lineage
                        SET data_load_completed = CURRENT_TIMESTAMP,
                            was_successful = true
                        WHERE lineage_key = %s
                    """, (lineage_key,))
                    self.olap_conn.commit()
                    
            logger.info("Dimension %s processed successfully: %d rows", 
                       table_name, len(data))
            return len(data), True
            
        except Exception as e:
            logger.error("Error processing dimension %s: %s", table_name, str(e))
            self.olap_conn.rollback()
            return 0, False
            
    def process_fact(
        self,
        table_name: str,
        config: Dict[str, Any],
        new_cutoff: datetime
    ) -> Tuple[int, bool]:
        """
        Process a single fact ETL.
        
        Args:
            table_name: Name of the fact table
            config: ETL configuration for this fact
            new_cutoff: New ETL cutoff time
            
        Returns:
            Tuple of (rows_processed, success)
        """
        logger.info("Processing fact: %s", table_name)
        
        try:
            last_cutoff = self.get_last_etl_cutoff_time(table_name)
            
            lineage_key = self.get_lineage_key(table_name, new_cutoff)
            logger.debug("Lineage key: %d", lineage_key)
            
            data = self.extract_data(
                config["extract_procedure"],
                last_cutoff,
                new_cutoff
            )
            
            if data:
                self.load_staging_data(
                    config["staging_table"],
                    config["staging_columns"],
                    data
                )
                
                self.migrate_staged_data(config["migrate_procedure"])
            else:
                with self.olap_conn.cursor() as cur:
                    cur.execute("""
                        UPDATE integration.lineage
                        SET data_load_completed = CURRENT_TIMESTAMP,
                            was_successful = true
                        WHERE lineage_key = %s
                    """, (lineage_key,))
                    self.olap_conn.commit()
                    
            logger.info("Fact %s processed successfully: %d rows", 
                       table_name, len(data))
            return len(data), True
            
        except Exception as e:
            logger.error("Error processing fact %s: %s", table_name, str(e))
            self.olap_conn.rollback()
            return 0, False
            
    def run_daily_etl(self) -> Dict[str, Any]:
        """
        Run the complete daily ETL process.
        
        This follows the same workflow as the original SSIS DailyETLMain package:
        1. Calculate ETL cutoff time
        2. Populate date dimension for current year
        3. Load all dimensions
        4. Load all facts
        
        Returns:
            Dictionary containing ETL results and statistics
        """
        logger.info("Starting Daily ETL process")
        start_time = datetime.now()
        
        results = {
            "start_time": start_time,
            "end_time": None,
            "success": True,
            "tables_processed": {},
            "total_rows": 0,
            "errors": [],
        }
        
        try:
            new_cutoff = self.calculate_etl_cutoff_time()
            
            current_year = datetime.utcnow().year
            self.populate_date_dimension(current_year)
            
            for table_name in ETL_EXECUTION_ORDER:
                if table_name in DIMENSION_CONFIGS:
                    config = DIMENSION_CONFIGS[table_name]
                    rows, success = self.process_dimension(table_name, config, new_cutoff)
                else:
                    config = FACT_CONFIGS[table_name]
                    rows, success = self.process_fact(table_name, config, new_cutoff)
                    
                results["tables_processed"][table_name] = {
                    "rows": rows,
                    "success": success,
                }
                results["total_rows"] += rows
                
                if not success:
                    results["success"] = False
                    results["errors"].append(f"Failed to process {table_name}")
                    
        except Exception as e:
            logger.error("ETL process failed: %s", str(e))
            results["success"] = False
            results["errors"].append(str(e))
            
        results["end_time"] = datetime.now()
        results["duration"] = (results["end_time"] - results["start_time"]).total_seconds()
        
        logger.info("Daily ETL completed in %.2f seconds", results["duration"])
        logger.info("Total rows processed: %d", results["total_rows"])
        
        return results
