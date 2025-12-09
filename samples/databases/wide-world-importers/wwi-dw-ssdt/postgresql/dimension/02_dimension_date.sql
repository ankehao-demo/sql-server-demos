-- Wide World Importers Data Warehouse - PostgreSQL Schema Migration
-- Phase 4: OLAP Schema Migration
-- Dimension: Date
-- Note: Date dimension uses the actual date as the primary key (not a surrogate key)

CREATE TABLE dimension.date (
    date                                DATE NOT NULL,
    date_key                            INTEGER NOT NULL,
    day_number                          INTEGER NOT NULL,
    day                                 VARCHAR(10) NOT NULL,
    day_of_year                         VARCHAR(5) NOT NULL,
    day_of_year_number                  INTEGER NOT NULL,
    day_of_week                         VARCHAR(20) NOT NULL,
    day_of_week_number                  INTEGER NOT NULL,
    week_of_year                        VARCHAR(5) NOT NULL,
    month                               VARCHAR(10) NOT NULL,
    short_month                         VARCHAR(3) NOT NULL,
    quarter                             VARCHAR(2) NOT NULL,
    half_of_year                        VARCHAR(3) NOT NULL,
    beginning_of_month                  DATE NOT NULL,
    beginning_of_quarter                DATE NOT NULL,
    beginning_of_half_year              DATE NOT NULL,
    beginning_of_year                   DATE NOT NULL,
    beginning_of_month_label            VARCHAR(40) NOT NULL,
    beginning_of_month_label_short      VARCHAR(40) NOT NULL,
    beginning_of_quarter_label          VARCHAR(40) NOT NULL,
    beginning_of_quarter_label_short    VARCHAR(40) NOT NULL,
    beginning_of_half_year_label        VARCHAR(40) NOT NULL,
    beginning_of_half_year_label_short  VARCHAR(40) NOT NULL,
    beginning_of_year_label             VARCHAR(40) NOT NULL,
    beginning_of_year_label_short       VARCHAR(40) NOT NULL,
    calendar_day_label                  VARCHAR(20) NOT NULL,
    calendar_day_label_short            VARCHAR(20) NOT NULL,
    calendar_week_number                INTEGER NOT NULL,
    calendar_week_label                 VARCHAR(20) NOT NULL,
    calendar_month_number               INTEGER NOT NULL,
    calendar_month_label                VARCHAR(20) NOT NULL,
    calendar_month_year_label           VARCHAR(20) NOT NULL,
    calendar_quarter_number             INTEGER NOT NULL,
    calendar_quarter_label              VARCHAR(20) NOT NULL,
    calendar_quarter_year_label         VARCHAR(20) NOT NULL,
    calendar_half_of_year_number        INTEGER NOT NULL,
    calendar_half_of_year_label         VARCHAR(20) NOT NULL,
    calendar_year_half_of_year_label    VARCHAR(20) NOT NULL,
    calendar_year                       INTEGER NOT NULL,
    calendar_year_label                 VARCHAR(10) NOT NULL,
    fiscal_month_number                 INTEGER NOT NULL,
    fiscal_month_label                  VARCHAR(20) NOT NULL,
    fiscal_quarter_number               INTEGER NOT NULL,
    fiscal_quarter_label                VARCHAR(20) NOT NULL,
    fiscal_half_of_year_number          INTEGER NOT NULL,
    fiscal_half_of_year_label           VARCHAR(20) NOT NULL,
    fiscal_year                         INTEGER NOT NULL,
    fiscal_year_label                   VARCHAR(10) NOT NULL,
    date_key_alt                        INTEGER NOT NULL,
    year_week_key                       INTEGER NOT NULL,
    year_month_key                      INTEGER NOT NULL,
    year_quarter_key                    INTEGER NOT NULL,
    year_half_of_year_key               INTEGER NOT NULL,
    year_key                            INTEGER NOT NULL,
    beginning_of_month_key              INTEGER NOT NULL,
    beginning_of_quarter_key            INTEGER NOT NULL,
    beginning_of_half_year_key          INTEGER NOT NULL,
    beginning_of_year_key               INTEGER NOT NULL,
    fiscal_year_month_key               INTEGER NOT NULL,
    fiscal_year_quarter_key             INTEGER NOT NULL,
    fiscal_year_half_of_year_key        INTEGER NOT NULL,
    iso_week_number                     INTEGER NOT NULL,

    CONSTRAINT pk_dimension_date PRIMARY KEY (date)
);

-- Add table and column comments
COMMENT ON TABLE dimension.date IS 'Date dimension';
COMMENT ON COLUMN dimension.date.date IS 'DW key for date dimension (actual date is used for key)';
COMMENT ON COLUMN dimension.date.date_key IS 'The date in integer format, can be used as the DW Key if desired';
COMMENT ON COLUMN dimension.date.day_number IS 'Day of the month in integer format (1 to the last day of the month)';
COMMENT ON COLUMN dimension.date.day IS 'Day of the month in string format';
COMMENT ON COLUMN dimension.date.day_of_year IS 'Day number of year (1 to 365) as a string';
COMMENT ON COLUMN dimension.date.day_of_year_number IS 'Day number of year (1 to 365) as an integer';
COMMENT ON COLUMN dimension.date.day_of_week IS 'Day of the week (Monday, Tuesday, etc)';
COMMENT ON COLUMN dimension.date.day_of_week_number IS 'Numeric day of the week (1=Sunday, etc)';
COMMENT ON COLUMN dimension.date.week_of_year IS 'Week number of the year as a string';
COMMENT ON COLUMN dimension.date.month IS 'The full month name (January)';
COMMENT ON COLUMN dimension.date.short_month IS 'The abbreviated current month (Jan)';
COMMENT ON COLUMN dimension.date.quarter IS 'The current quarter as text (Q1, Q2, etc)';
COMMENT ON COLUMN dimension.date.half_of_year IS 'The Half of the year (H1, H2)';
COMMENT ON COLUMN dimension.date.calendar_year IS 'Calendar year';
COMMENT ON COLUMN dimension.date.fiscal_year IS 'Fiscal year';
COMMENT ON COLUMN dimension.date.iso_week_number IS 'ISO week number';
