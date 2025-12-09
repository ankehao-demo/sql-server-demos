# Wide World Importers ETL for PostgreSQL

This is a PostgreSQL-compatible ETL solution that replaces the SQL Server Integration Services (SSIS) packages for migrating data from the WideWorldImporters OLTP database to the WideWorldImportersDW OLAP data warehouse.

## Overview

The original SQL Server solution uses SSIS packages (located in `wwi-ssis/`) to perform ETL operations. This PostgreSQL implementation provides equivalent functionality using Python scripts and PostgreSQL stored procedures.

### ETL Workflow

The ETL process follows the same pattern as the original SSIS DailyETLMain package:

1. **Calculate ETL Cutoff Time**: Determines the time boundary for data extraction (current time minus 5 minutes for consistency)
2. **Populate Date Dimension**: Ensures all dates for the current year exist in the Date dimension
3. **Load Dimensions**: Extracts and loads dimension data in order:
   - City
   - Customer
   - Employee
   - Payment Method
   - Stock Item
   - Supplier
   - Transaction Type
4. **Load Facts**: Extracts and loads fact data in order:
   - Sale
   - Order
   - Purchase
   - Movement
   - Transaction
   - Stock Holding

### Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         ETL Process Flow                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐ │
│  │   OLTP Database  │     │   Python ETL     │     │   OLAP Database  │ │
│  │ WideWorldImporters│     │     Engine       │     │WideWorldImportersDW│
│  └────────┬─────────┘     └────────┬─────────┘     └────────┬─────────┘ │
│           │                        │                        │           │
│           │  1. Extract via        │                        │           │
│           │     stored procedures  │                        │           │
│           │ ◄──────────────────────┤                        │           │
│           │                        │                        │           │
│           │  2. Return data        │                        │           │
│           ├───────────────────────►│                        │           │
│           │                        │                        │           │
│           │                        │  3. Load to staging    │           │
│           │                        ├───────────────────────►│           │
│           │                        │                        │           │
│           │                        │  4. Migrate to final   │           │
│           │                        ├───────────────────────►│           │
│           │                        │     tables             │           │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Prerequisites

- Python 3.8 or higher
- PostgreSQL 12 or higher with PostGIS extension
- Both OLTP (WideWorldImporters) and OLAP (WideWorldImportersDW) databases migrated to PostgreSQL

## Installation

1. Install Python dependencies:

```bash
pip install -r requirements.txt
```

2. Install the ETL procedures in the OLAP database:

```bash
psql -h localhost -U webapi -d wideworldimportersdw -f ../postgres-migration-dw/10-etl-procedures/001-helper-procedures.sql
psql -h localhost -U webapi -d wideworldimportersdw -f ../postgres-migration-dw/10-etl-procedures/002-dimension-migration-procedures.sql
psql -h localhost -U webapi -d wideworldimportersdw -f ../postgres-migration-dw/10-etl-procedures/003-fact-migration-procedures.sql
```

## Configuration

The ETL process is configured via environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `OLTP_DB_HOST` | OLTP database host | localhost |
| `OLTP_DB_PORT` | OLTP database port | 5432 |
| `OLTP_DB_NAME` | OLTP database name | wideworldimporters |
| `OLTP_DB_USER` | OLTP database user | webapi |
| `OLTP_DB_PASSWORD` | OLTP database password | (required) |
| `OLAP_DB_HOST` | OLAP database host | localhost |
| `OLAP_DB_PORT` | OLAP database port | 5432 |
| `OLAP_DB_NAME` | OLAP database name | wideworldimportersdw |
| `OLAP_DB_USER` | OLAP database user | webapi |
| `OLAP_DB_PASSWORD` | OLAP database password | (required) |
| `ETL_BATCH_SIZE` | Batch size for bulk inserts | 10000 |
| `ETL_LOG_LEVEL` | Logging level | INFO |

## Usage

### Running the Daily ETL

```bash
# Set environment variables
export OLTP_DB_PASSWORD='your_password'
export OLAP_DB_PASSWORD='your_password'

# Run the ETL
python run_etl.py
```

### Command Line Options

```bash
python run_etl.py --help

Options:
  --log-level {DEBUG,INFO,WARNING,ERROR,CRITICAL}
                        Logging level (default: INFO)
  --dry-run             Perform a dry run without making changes
  --output-json FILE    Output results to JSON file
```

### Example Output

```
============================================================
ETL RESULTS SUMMARY
============================================================
Start Time: 2024-01-15 10:30:00
End Time: 2024-01-15 10:35:23
Duration: 323.45 seconds
Overall Success: True
Total Rows Processed: 125432

Tables Processed:
----------------------------------------
  City: 1234 rows [OK]
  Customer: 5678 rows [OK]
  Employee: 123 rows [OK]
  Payment Method: 5 rows [OK]
  Stock Item: 456 rows [OK]
  Supplier: 78 rows [OK]
  Transaction Type: 12 rows [OK]
  Sale: 45678 rows [OK]
  Order: 23456 rows [OK]
  Purchase: 12345 rows [OK]
  Movement: 34567 rows [OK]
  Transaction: 1800 rows [OK]
  Stock Holding: 227 rows [OK]
============================================================
```

## Scheduling

### Using cron (Linux/macOS)

Add to crontab to run daily at 2:00 AM:

```bash
0 2 * * * cd /path/to/wwi-etl && /usr/bin/python3 run_etl.py >> /var/log/wwi-etl.log 2>&1
```

### Using pg_cron (PostgreSQL)

If pg_cron is installed, you can schedule the ETL directly in PostgreSQL:

```sql
SELECT cron.schedule('daily-etl', '0 2 * * *', 
    $$SELECT integration.run_daily_etl()$$);
```

### Using systemd timer (Linux)

Create `/etc/systemd/system/wwi-etl.service`:

```ini
[Unit]
Description=Wide World Importers Daily ETL

[Service]
Type=oneshot
WorkingDirectory=/path/to/wwi-etl
ExecStart=/usr/bin/python3 run_etl.py
Environment=OLTP_DB_PASSWORD=your_password
Environment=OLAP_DB_PASSWORD=your_password
```

Create `/etc/systemd/system/wwi-etl.timer`:

```ini
[Unit]
Description=Run WWI ETL daily

[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

Enable and start:

```bash
sudo systemctl enable wwi-etl.timer
sudo systemctl start wwi-etl.timer
```

## Comparison with SSIS

| Feature | SSIS (Original) | PostgreSQL ETL |
|---------|-----------------|----------------|
| Orchestration | SSIS Package | Python Script |
| Scheduling | SQL Server Agent | cron/pg_cron/systemd |
| Data Flow | OLE DB Source/Destination | psycopg2 |
| Bulk Operations | Fast Load | execute_batch |
| Lineage Tracking | Integration.Lineage table | Same |
| Error Handling | SSIS Error Output | Python exceptions |
| Logging | SSIS Logging | Python logging |

## Troubleshooting

### Connection Issues

If you encounter connection errors, verify:
1. PostgreSQL is running and accepting connections
2. Database credentials are correct
3. Network connectivity between ETL host and database servers

### Performance Issues

For large data volumes:
1. Increase `ETL_BATCH_SIZE` for faster bulk inserts
2. Ensure proper indexes exist on staging tables
3. Consider running during off-peak hours

### Data Issues

If data is not being extracted:
1. Check the ETL cutoff times in `integration.etl_cutoff`
2. Verify the extraction procedures are returning data
3. Check the lineage table for failed loads

## Files

- `config.py` - ETL configuration and table definitions
- `etl_engine.py` - Core ETL engine implementation
- `run_etl.py` - Command-line ETL runner
- `requirements.txt` - Python dependencies

## Related Documentation

- [SSIS README](../wwi-ssis/README.md) - Original SSIS package documentation
- [PostgreSQL Migration Guide](../postgres-migration/README.md) - OLTP migration documentation
- [PostgreSQL DW Migration Guide](../postgres-migration-dw/README.md) - OLAP migration documentation
