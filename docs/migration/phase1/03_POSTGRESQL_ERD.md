# Wide World Importers - PostgreSQL Entity Relationship Diagram

This document presents the Entity Relationship Diagram (ERD) design for the PostgreSQL version of the Wide World Importers database, leveraging PostgreSQL-specific features including JSONB, native full-text search, PostGIS for spatial data, and Row-Level Security.

## Executive Summary

The PostgreSQL ERD maintains the logical structure of the original SQL Server database while adapting to PostgreSQL's strengths. Key design decisions include using JSONB for flexible schema data, PostGIS for spatial operations, native full-text search with tsvector, and PostgreSQL's built-in Row-Level Security for multi-tenant access control.

## Schema Organization

The PostgreSQL database maintains the same schema organization as SQL Server:

```
wideworldimporters
├── application      (Core reference data)
├── sales            (Customer orders and invoices)
├── purchasing       (Supplier orders)
├── warehouse        (Stock items and inventory)
├── sequences        (ID generation)
├── webapi           (API views)
└── website          (Web application support)
```

## ERD Diagram (Text Representation)

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                    APPLICATION SCHEMA                                     │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                           │
│  ┌─────────────────────┐         ┌─────────────────────┐         ┌─────────────────────┐ │
│  │     countries       │         │   state_provinces   │         │       cities        │ │
│  ├─────────────────────┤         ├─────────────────────┤         ├─────────────────────┤ │
│  │ PK country_id       │◄────────┤ FK country_id       │◄────────┤ FK state_province_id│ │
│  │    country_name     │         │ PK state_province_id│         │ PK city_id          │ │
│  │    formal_name      │         │    state_prov_code  │         │    city_name        │ │
│  │    iso_alpha3_code  │         │    state_prov_name  │         │    location (POINT) │ │
│  │    border (POLYGON) │         │    sales_territory  │         │    population       │ │
│  │    population       │         │    border (POLYGON) │         └─────────────────────┘ │
│  └─────────────────────┘         └─────────────────────┘                   │             │
│                                                                             │             │
│  ┌─────────────────────┐         ┌─────────────────────┐                   │             │
│  │      people         │         │  delivery_methods   │                   │             │
│  ├─────────────────────┤         ├─────────────────────┤                   │             │
│  │ PK person_id        │         │ PK delivery_method_id│                  │             │
│  │    full_name        │         │    delivery_method   │                  │             │
│  │    preferred_name   │         └─────────────────────┘                   │             │
│  │    search_name (GEN)│                                                   │             │
│  │    user_prefs (JSONB)│        ┌─────────────────────┐                   │             │
│  │    custom_fields(JSONB)│      │  payment_methods    │                   │             │
│  │    photo (BYTEA)    │         ├─────────────────────┤                   │             │
│  │    search_vector(TSV)│        │ PK payment_method_id│                   │             │
│  └─────────────────────┘         │    payment_method   │                   │             │
│           │                      └─────────────────────┘                   │             │
│           │                                                                │             │
│           │                      ┌─────────────────────┐                   │             │
│           │                      │  transaction_types  │                   │             │
│           │                      ├─────────────────────┤                   │             │
│           │                      │ PK transaction_type_id│                 │             │
│           │                      │    transaction_type  │                  │             │
│           │                      └─────────────────────┘                   │             │
└───────────┼────────────────────────────────────────────────────────────────┼─────────────┘
            │                                                                │
            ▼                                                                ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                      SALES SCHEMA                                        │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                           │
│  ┌─────────────────────┐         ┌─────────────────────┐         ┌─────────────────────┐ │
│  │ customer_categories │         │   buying_groups     │         │     customers       │ │
│  ├─────────────────────┤         ├─────────────────────┤         ├─────────────────────┤ │
│  │ PK customer_cat_id  │◄────────┤ PK buying_group_id  │◄────────┤ FK customer_cat_id  │ │
│  │    category_name    │         │    buying_group_name│         │ FK buying_group_id  │ │
│  └─────────────────────┘         └─────────────────────┘         │ FK delivery_city_id │ │
│                                                                   │ FK postal_city_id   │ │
│                                                                   │ PK customer_id      │ │
│                                                                   │    customer_name    │ │
│                                                                   │    delivery_loc(PT) │ │
│                                                                   │    search_vector    │ │
│                                                                   │    [RLS ENABLED]    │ │
│                                                                   └─────────────────────┘ │
│                                                                             │             │
│                                                                             │             │
│  ┌─────────────────────┐         ┌─────────────────────┐                   │             │
│  │      orders         │◄────────┤     order_lines     │                   │             │
│  ├─────────────────────┤         ├─────────────────────┤                   │             │
│  │ PK order_id         │         │ PK order_line_id    │                   │             │
│  │ FK customer_id      │◄────────┤ FK order_id         │                   │             │
│  │ FK salesperson_id   │         │ FK stock_item_id    │                   │             │
│  │    order_date       │         │    quantity         │                   │             │
│  │    comments (TEXT)  │         │    unit_price       │                   │             │
│  └─────────────────────┘         └─────────────────────┘                   │             │
│                                                                             │             │
│  ┌─────────────────────┐         ┌─────────────────────┐                   │             │
│  │     invoices        │◄────────┤   invoice_lines     │                   │             │
│  ├─────────────────────┤         ├─────────────────────┤                   │             │
│  │ PK invoice_id       │         │ PK invoice_line_id  │                   │             │
│  │ FK customer_id      │◄────────┤ FK invoice_id       │                   │             │
│  │ FK order_id         │         │ FK stock_item_id    │                   │             │
│  │    delivery_data(JSONB)│      │    quantity         │                   │             │
│  │    confirmed_time(GEN)│       │    line_profit      │                   │             │
│  └─────────────────────┘         └─────────────────────┘                   │             │
│                                                                             │             │
│  ┌─────────────────────┐         ┌─────────────────────┐                   │             │
│  │ customer_transactions│        │   special_deals     │                   │             │
│  ├─────────────────────┤         ├─────────────────────┤                   │             │
│  │ PK cust_trans_id    │         │ PK special_deal_id  │                   │             │
│  │ FK customer_id      │◄────────┤ FK customer_id      │                   │             │
│  │ FK invoice_id       │         │ FK stock_item_id    │                   │             │
│  │    transaction_amt  │         │    discount_pct     │                   │             │
│  └─────────────────────┘         └─────────────────────┘                   │             │
└─────────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                   PURCHASING SCHEMA                                      │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                           │
│  ┌─────────────────────┐         ┌─────────────────────┐                                │
│  │ supplier_categories │         │     suppliers       │                                │
│  ├─────────────────────┤         ├─────────────────────┤                                │
│  │ PK supplier_cat_id  │◄────────┤ FK supplier_cat_id  │                                │
│  │    category_name    │         │ PK supplier_id      │                                │
│  └─────────────────────┘         │    supplier_name    │                                │
│                                  │    delivery_loc(PT) │                                │
│                                  │    bank_acct_* [MASKED]│                             │
│                                  │    search_vector    │                                │
│                                  └─────────────────────┘                                │
│                                            │                                             │
│                                            │                                             │
│  ┌─────────────────────┐         ┌─────────────────────┐                                │
│  │  purchase_orders    │◄────────┤ purchase_order_lines│                                │
│  ├─────────────────────┤         ├─────────────────────┤                                │
│  │ PK purchase_order_id│         │ PK po_line_id       │                                │
│  │ FK supplier_id      │◄────────┤ FK purchase_order_id│                                │
│  │    order_date       │         │ FK stock_item_id    │                                │
│  │    is_finalized     │         │    ordered_outers   │                                │
│  └─────────────────────┘         └─────────────────────┘                                │
│                                                                                           │
│  ┌─────────────────────┐                                                                │
│  │supplier_transactions│                                                                │
│  ├─────────────────────┤                                                                │
│  │ PK supp_trans_id    │                                                                │
│  │ FK supplier_id      │                                                                │
│  │ FK purchase_order_id│                                                                │
│  │    transaction_amt  │                                                                │
│  └─────────────────────┘                                                                │
└─────────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                   WAREHOUSE SCHEMA                                       │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                           │
│  ┌─────────────────────┐         ┌─────────────────────┐         ┌─────────────────────┐ │
│  │      colors         │         │   package_types     │         │    stock_groups     │ │
│  ├─────────────────────┤         ├─────────────────────┤         ├─────────────────────┤ │
│  │ PK color_id         │         │ PK package_type_id  │         │ PK stock_group_id   │ │
│  │    color_name       │         │    package_type_name│         │    stock_group_name │ │
│  └─────────────────────┘         └─────────────────────┘         └─────────────────────┘ │
│           │                               │                               │             │
│           │                               │                               │             │
│           ▼                               ▼                               ▼             │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                                  stock_items                                         │ │
│  ├─────────────────────────────────────────────────────────────────────────────────────┤ │
│  │ PK stock_item_id                                                                     │ │
│  │ FK supplier_id, FK color_id, FK unit_package_id, FK outer_package_id                │ │
│  │    stock_item_name, brand, size, barcode                                            │ │
│  │    custom_fields (JSONB), tags (GENERATED from JSONB)                               │ │
│  │    photo (BYTEA), marketing_comments (TEXT)                                         │ │
│  │    search_vector (TSVECTOR), search_details (GENERATED)                             │ │
│  └─────────────────────────────────────────────────────────────────────────────────────┘ │
│                    │                                                                     │
│                    │                                                                     │
│  ┌─────────────────┼───────────────────────────────────────────────────────────────────┐ │
│  │                 ▼                                                                    │ │
│  │  ┌─────────────────────┐    ┌─────────────────────┐    ┌─────────────────────┐     │ │
│  │  │ stock_item_holdings │    │stock_item_transactions│   │stock_item_stock_grps│     │ │
│  │  ├─────────────────────┤    ├─────────────────────┤    ├─────────────────────┤     │ │
│  │  │ PK stock_item_id    │    │ PK stock_item_trans_id│   │ PK stock_item_stk_grp│    │ │
│  │  │    quantity_on_hand │    │ FK stock_item_id    │    │ FK stock_item_id    │     │ │
│  │  │    bin_location     │    │ FK customer_id      │    │ FK stock_group_id   │     │ │
│  │  │    reorder_level    │    │    quantity         │    └─────────────────────┘     │ │
│  │  └─────────────────────┘    └─────────────────────┘                                │ │
│  └─────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                           │
│  ┌─────────────────────┐         ┌─────────────────────┐                                │
│  │cold_room_temperatures│        │ vehicle_temperatures│                                │
│  ├─────────────────────┤         ├─────────────────────┤                                │
│  │ PK cold_room_temp_id│         │ PK vehicle_temp_id  │                                │
│  │    sensor_number    │         │    vehicle_reg      │                                │
│  │    recorded_when    │         │    sensor_number    │                                │
│  │    temperature      │         │    temperature      │                                │
│  │    [PARTITIONED]    │         │    sensor_data(JSONB)│                               │
│  └─────────────────────┘         └─────────────────────┘                                │
└─────────────────────────────────────────────────────────────────────────────────────────┘

LEGEND:
  PK = Primary Key
  FK = Foreign Key
  (JSONB) = PostgreSQL JSONB column
  (POINT/POLYGON) = PostGIS geometry
  (TSVECTOR/TSV) = Full-text search vector
  (GEN/GENERATED) = Generated column
  [RLS ENABLED] = Row-Level Security enabled
  [MASKED] = Data masking via views
  [PARTITIONED] = Table partitioning enabled
```

## Detailed Table Definitions

### Application Schema

#### application.people

```sql
CREATE TABLE application.people (
    person_id INTEGER PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
    full_name VARCHAR(50) NOT NULL,
    preferred_name VARCHAR(50) NOT NULL,
    search_name VARCHAR(101) GENERATED ALWAYS AS (preferred_name || ' ' || full_name) STORED,
    is_permitted_to_logon BOOLEAN NOT NULL DEFAULT FALSE,
    logon_name VARCHAR(256),
    is_external_logon_provider BOOLEAN NOT NULL DEFAULT FALSE,
    hashed_password BYTEA,
    is_system_user BOOLEAN NOT NULL DEFAULT FALSE,
    is_employee BOOLEAN NOT NULL DEFAULT FALSE,
    is_salesperson BOOLEAN NOT NULL DEFAULT FALSE,
    user_preferences JSONB,
    phone_number VARCHAR(20),
    fax_number VARCHAR(20),
    email_address VARCHAR(256),
    photo BYTEA,
    custom_fields JSONB,
    other_languages JSONB GENERATED ALWAYS AS (custom_fields -> 'OtherLanguages') STORED,
    last_edited_by INTEGER NOT NULL REFERENCES application.people(person_id),
    valid_from TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP(6) NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    search_vector TSVECTOR GENERATED ALWAYS AS (
        setweight(to_tsvector('english', coalesce(full_name, '')), 'A') ||
        setweight(to_tsvector('english', coalesce(preferred_name, '')), 'B')
    ) STORED
);

-- Indexes
CREATE INDEX idx_people_is_employee ON application.people(is_employee);
CREATE INDEX idx_people_is_salesperson ON application.people(is_salesperson);
CREATE INDEX idx_people_full_name ON application.people(full_name);
CREATE INDEX idx_people_search ON application.people USING GIN(search_vector);
CREATE INDEX idx_people_custom_fields ON application.people USING GIN(custom_fields);

-- History table for temporal data
CREATE TABLE application.people_history (LIKE application.people);
```

#### application.countries

```sql
CREATE TABLE application.countries (
    country_id INTEGER PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
    country_name VARCHAR(60) NOT NULL UNIQUE,
    formal_name VARCHAR(60) NOT NULL UNIQUE,
    iso_alpha3_code CHAR(3),
    iso_numeric_code INTEGER,
    country_type VARCHAR(20),
    latest_recorded_population BIGINT,
    continent VARCHAR(30) NOT NULL,
    region VARCHAR(30) NOT NULL,
    subregion VARCHAR(30) NOT NULL,
    border GEOMETRY(MultiPolygon, 4326),
    last_edited_by INTEGER NOT NULL REFERENCES application.people(person_id),
    valid_from TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP(6) NOT NULL DEFAULT '9999-12-31 23:59:59.999999'
);

-- Spatial index
CREATE INDEX idx_countries_border ON application.countries USING GIST(border);

-- History table
CREATE TABLE application.countries_history (LIKE application.countries);
```

#### application.state_provinces

```sql
CREATE TABLE application.state_provinces (
    state_province_id INTEGER PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
    state_province_code VARCHAR(5) NOT NULL,
    state_province_name VARCHAR(50) NOT NULL UNIQUE,
    country_id INTEGER NOT NULL REFERENCES application.countries(country_id),
    sales_territory VARCHAR(50) NOT NULL,
    border GEOMETRY(MultiPolygon, 4326),
    latest_recorded_population BIGINT,
    last_edited_by INTEGER NOT NULL REFERENCES application.people(person_id),
    valid_from TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP(6) NOT NULL DEFAULT '9999-12-31 23:59:59.999999'
);

-- Indexes
CREATE INDEX idx_state_provinces_country ON application.state_provinces(country_id);
CREATE INDEX idx_state_provinces_territory ON application.state_provinces(sales_territory);
CREATE INDEX idx_state_provinces_border ON application.state_provinces USING GIST(border);

-- History table
CREATE TABLE application.state_provinces_history (LIKE application.state_provinces);
```

#### application.cities

```sql
CREATE TABLE application.cities (
    city_id INTEGER PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
    city_name VARCHAR(50) NOT NULL,
    state_province_id INTEGER NOT NULL REFERENCES application.state_provinces(state_province_id),
    location GEOMETRY(Point, 4326),
    latest_recorded_population BIGINT,
    last_edited_by INTEGER NOT NULL REFERENCES application.people(person_id),
    valid_from TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP(6) NOT NULL DEFAULT '9999-12-31 23:59:59.999999'
);

-- Indexes
CREATE INDEX idx_cities_state_province ON application.cities(state_province_id);
CREATE INDEX idx_cities_location ON application.cities USING GIST(location);

-- History table
CREATE TABLE application.cities_history (LIKE application.cities);
```

### Sales Schema

#### sales.customers

```sql
CREATE TABLE sales.customers (
    customer_id INTEGER PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
    customer_name VARCHAR(100) NOT NULL UNIQUE,
    bill_to_customer_id INTEGER NOT NULL REFERENCES sales.customers(customer_id),
    customer_category_id INTEGER NOT NULL REFERENCES sales.customer_categories(customer_category_id),
    buying_group_id INTEGER REFERENCES sales.buying_groups(buying_group_id),
    primary_contact_person_id INTEGER NOT NULL REFERENCES application.people(person_id),
    alternate_contact_person_id INTEGER REFERENCES application.people(person_id),
    delivery_method_id INTEGER NOT NULL REFERENCES application.delivery_methods(delivery_method_id),
    delivery_city_id INTEGER NOT NULL REFERENCES application.cities(city_id),
    postal_city_id INTEGER NOT NULL REFERENCES application.cities(city_id),
    credit_limit NUMERIC(18,2),
    account_opened_date DATE NOT NULL,
    standard_discount_percentage NUMERIC(18,3) NOT NULL,
    is_statement_sent BOOLEAN NOT NULL DEFAULT FALSE,
    is_on_credit_hold BOOLEAN NOT NULL DEFAULT FALSE,
    payment_days INTEGER NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    fax_number VARCHAR(20) NOT NULL,
    delivery_run VARCHAR(5),
    run_position VARCHAR(5),
    website_url VARCHAR(256) NOT NULL,
    delivery_address_line1 VARCHAR(60) NOT NULL,
    delivery_address_line2 VARCHAR(60),
    delivery_postal_code VARCHAR(10) NOT NULL,
    delivery_location GEOMETRY(Point, 4326),
    postal_address_line1 VARCHAR(60) NOT NULL,
    postal_address_line2 VARCHAR(60),
    postal_postal_code VARCHAR(10) NOT NULL,
    last_edited_by INTEGER NOT NULL REFERENCES application.people(person_id),
    valid_from TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP(6) NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    search_vector TSVECTOR GENERATED ALWAYS AS (
        to_tsvector('english', coalesce(customer_name, ''))
    ) STORED
);

-- Indexes
CREATE INDEX idx_customers_category ON sales.customers(customer_category_id);
CREATE INDEX idx_customers_buying_group ON sales.customers(buying_group_id);
CREATE INDEX idx_customers_delivery_city ON sales.customers(delivery_city_id);
CREATE INDEX idx_customers_postal_city ON sales.customers(postal_city_id);
CREATE INDEX idx_customers_delivery_location ON sales.customers USING GIST(delivery_location);
CREATE INDEX idx_customers_search ON sales.customers USING GIN(search_vector);
CREATE INDEX idx_customers_credit_hold ON sales.customers(is_on_credit_hold, customer_id, bill_to_customer_id);

-- Row-Level Security
ALTER TABLE sales.customers ENABLE ROW LEVEL SECURITY;

CREATE POLICY customer_territory_policy ON sales.customers
FOR ALL
USING (
    current_setting('app.is_admin', true)::boolean = true
    OR current_setting('app.sales_territory', true) = 'ALL_TERRITORIES'
    OR EXISTS (
        SELECT 1 FROM application.cities c
        JOIN application.state_provinces sp ON c.state_province_id = sp.state_province_id
        WHERE c.city_id = delivery_city_id
        AND sp.sales_territory = current_setting('app.sales_territory', true)
    )
);

-- History table
CREATE TABLE sales.customers_history (LIKE sales.customers);
```

#### sales.orders

```sql
CREATE TABLE sales.orders (
    order_id INTEGER PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
    customer_id INTEGER NOT NULL REFERENCES sales.customers(customer_id),
    salesperson_person_id INTEGER NOT NULL REFERENCES application.people(person_id),
    picked_by_person_id INTEGER REFERENCES application.people(person_id),
    contact_person_id INTEGER NOT NULL REFERENCES application.people(person_id),
    backorder_order_id INTEGER REFERENCES sales.orders(order_id),
    order_date DATE NOT NULL,
    expected_delivery_date DATE NOT NULL,
    customer_purchase_order_number VARCHAR(20),
    is_undersupply_backordered BOOLEAN NOT NULL DEFAULT FALSE,
    comments TEXT,
    delivery_instructions TEXT,
    internal_comments TEXT,
    picking_completed_when TIMESTAMP(6),
    last_edited_by INTEGER NOT NULL REFERENCES application.people(person_id),
    last_edited_when TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_orders_customer ON sales.orders(customer_id);
CREATE INDEX idx_orders_salesperson ON sales.orders(salesperson_person_id);
CREATE INDEX idx_orders_picked_by ON sales.orders(picked_by_person_id);
CREATE INDEX idx_orders_contact ON sales.orders(contact_person_id);
CREATE INDEX idx_orders_date ON sales.orders(order_date);
```

#### sales.order_lines

```sql
CREATE TABLE sales.order_lines (
    order_line_id INTEGER PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
    order_id INTEGER NOT NULL REFERENCES sales.orders(order_id),
    stock_item_id INTEGER NOT NULL REFERENCES warehouse.stock_items(stock_item_id),
    description VARCHAR(100) NOT NULL,
    package_type_id INTEGER NOT NULL REFERENCES warehouse.package_types(package_type_id),
    quantity INTEGER NOT NULL,
    unit_price NUMERIC(18,2),
    tax_rate NUMERIC(18,3) NOT NULL,
    picked_quantity INTEGER NOT NULL DEFAULT 0,
    picking_completed_when TIMESTAMP(6),
    last_edited_by INTEGER NOT NULL REFERENCES application.people(person_id),
    last_edited_when TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_order_lines_order ON sales.order_lines(order_id);
CREATE INDEX idx_order_lines_stock_item ON sales.order_lines(stock_item_id);
CREATE INDEX idx_order_lines_package_type ON sales.order_lines(package_type_id);
CREATE INDEX idx_order_lines_picking ON sales.order_lines(picking_completed_when, order_id, order_line_id);

-- BRIN index for analytics (alternative to columnstore)
CREATE INDEX idx_order_lines_brin ON sales.order_lines USING BRIN(order_id, stock_item_id);
```

#### sales.invoices

```sql
CREATE TABLE sales.invoices (
    invoice_id INTEGER PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
    customer_id INTEGER NOT NULL REFERENCES sales.customers(customer_id),
    bill_to_customer_id INTEGER NOT NULL REFERENCES sales.customers(customer_id),
    order_id INTEGER REFERENCES sales.orders(order_id),
    delivery_method_id INTEGER NOT NULL REFERENCES application.delivery_methods(delivery_method_id),
    contact_person_id INTEGER NOT NULL REFERENCES application.people(person_id),
    accounts_person_id INTEGER NOT NULL REFERENCES application.people(person_id),
    salesperson_person_id INTEGER NOT NULL REFERENCES application.people(person_id),
    packed_by_person_id INTEGER NOT NULL REFERENCES application.people(person_id),
    invoice_date DATE NOT NULL,
    customer_purchase_order_number VARCHAR(20),
    is_credit_note BOOLEAN NOT NULL DEFAULT FALSE,
    credit_note_reason TEXT,
    comments TEXT,
    delivery_instructions TEXT,
    internal_comments TEXT,
    total_dry_items INTEGER NOT NULL DEFAULT 0,
    total_chiller_items INTEGER NOT NULL DEFAULT 0,
    delivery_run VARCHAR(5),
    run_position VARCHAR(5),
    returned_delivery_data JSONB,
    confirmed_delivery_time TIMESTAMP(6) GENERATED ALWAYS AS (
        (returned_delivery_data->>'DeliveredWhen')::timestamp
    ) STORED,
    confirmed_received_by VARCHAR(4000) GENERATED ALWAYS AS (
        returned_delivery_data->>'ReceivedBy'
    ) STORED,
    last_edited_by INTEGER NOT NULL REFERENCES application.people(person_id),
    last_edited_when TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_invoices_valid_json CHECK (
        returned_delivery_data IS NULL OR jsonb_typeof(returned_delivery_data) = 'object'
    )
);

-- Indexes
CREATE INDEX idx_invoices_customer ON sales.invoices(customer_id);
CREATE INDEX idx_invoices_bill_to ON sales.invoices(bill_to_customer_id);
CREATE INDEX idx_invoices_order ON sales.invoices(order_id);
CREATE INDEX idx_invoices_delivery_time ON sales.invoices(confirmed_delivery_time);
CREATE INDEX idx_invoices_delivery_data ON sales.invoices USING GIN(returned_delivery_data);
```

#### sales.invoice_lines

```sql
CREATE TABLE sales.invoice_lines (
    invoice_line_id INTEGER PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
    invoice_id INTEGER NOT NULL REFERENCES sales.invoices(invoice_id),
    stock_item_id INTEGER NOT NULL REFERENCES warehouse.stock_items(stock_item_id),
    description VARCHAR(100) NOT NULL,
    package_type_id INTEGER NOT NULL REFERENCES warehouse.package_types(package_type_id),
    quantity INTEGER NOT NULL,
    unit_price NUMERIC(18,2),
    tax_rate NUMERIC(18,3) NOT NULL,
    tax_amount NUMERIC(18,2) NOT NULL,
    line_profit NUMERIC(18,2) NOT NULL,
    extended_price NUMERIC(18,2) NOT NULL,
    last_edited_by INTEGER NOT NULL REFERENCES application.people(person_id),
    last_edited_when TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_invoice_lines_invoice ON sales.invoice_lines(invoice_id);
CREATE INDEX idx_invoice_lines_stock_item ON sales.invoice_lines(stock_item_id);

-- BRIN index for analytics
CREATE INDEX idx_invoice_lines_brin ON sales.invoice_lines USING BRIN(invoice_id, stock_item_id);
```

### Warehouse Schema

#### warehouse.stock_items

```sql
CREATE TABLE warehouse.stock_items (
    stock_item_id INTEGER PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
    stock_item_name VARCHAR(100) NOT NULL UNIQUE,
    supplier_id INTEGER NOT NULL REFERENCES purchasing.suppliers(supplier_id),
    color_id INTEGER REFERENCES warehouse.colors(color_id),
    unit_package_id INTEGER NOT NULL REFERENCES warehouse.package_types(package_type_id),
    outer_package_id INTEGER NOT NULL REFERENCES warehouse.package_types(package_type_id),
    brand VARCHAR(50),
    size VARCHAR(20),
    lead_time_days INTEGER NOT NULL,
    quantity_per_outer INTEGER NOT NULL,
    is_chiller_stock BOOLEAN NOT NULL DEFAULT FALSE,
    barcode VARCHAR(50),
    tax_rate NUMERIC(18,3) NOT NULL,
    unit_price NUMERIC(18,2) NOT NULL,
    recommended_retail_price NUMERIC(18,2),
    typical_weight_per_unit NUMERIC(18,3) NOT NULL,
    marketing_comments TEXT,
    internal_comments TEXT,
    photo BYTEA,
    custom_fields JSONB,
    tags JSONB GENERATED ALWAYS AS (custom_fields -> 'Tags') STORED,
    search_details VARCHAR(201) GENERATED ALWAYS AS (
        stock_item_name || ' ' || coalesce(marketing_comments, '')
    ) STORED,
    last_edited_by INTEGER NOT NULL REFERENCES application.people(person_id),
    valid_from TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP(6) NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    search_vector TSVECTOR GENERATED ALWAYS AS (
        setweight(to_tsvector('english', coalesce(stock_item_name, '')), 'A') ||
        setweight(to_tsvector('english', coalesce(marketing_comments, '')), 'B')
    ) STORED
);

-- Indexes
CREATE INDEX idx_stock_items_supplier ON warehouse.stock_items(supplier_id);
CREATE INDEX idx_stock_items_color ON warehouse.stock_items(color_id);
CREATE INDEX idx_stock_items_search ON warehouse.stock_items USING GIN(search_vector);
CREATE INDEX idx_stock_items_custom_fields ON warehouse.stock_items USING GIN(custom_fields);
CREATE INDEX idx_stock_items_tags ON warehouse.stock_items USING GIN(tags);

-- History table
CREATE TABLE warehouse.stock_items_history (LIKE warehouse.stock_items);
```

#### warehouse.cold_room_temperatures (Partitioned)

```sql
-- Partitioned table for high-volume temperature data
CREATE TABLE warehouse.cold_room_temperatures (
    cold_room_temperature_id BIGSERIAL,
    cold_room_sensor_number INTEGER NOT NULL,
    recorded_when TIMESTAMP(6) NOT NULL,
    temperature NUMERIC(10,2) NOT NULL,
    valid_from TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP(6) NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    PRIMARY KEY (cold_room_temperature_id, recorded_when)
) PARTITION BY RANGE (recorded_when);

-- Create partitions (example for monthly partitions)
CREATE TABLE warehouse.cold_room_temperatures_2024_01 
    PARTITION OF warehouse.cold_room_temperatures
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE warehouse.cold_room_temperatures_2024_02 
    PARTITION OF warehouse.cold_room_temperatures
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

-- Index on sensor number
CREATE INDEX idx_cold_room_temps_sensor ON warehouse.cold_room_temperatures(cold_room_sensor_number);

-- History table
CREATE TABLE warehouse.cold_room_temperatures_history (
    LIKE warehouse.cold_room_temperatures INCLUDING ALL
);
```

### Purchasing Schema

#### purchasing.suppliers

```sql
CREATE TABLE purchasing.suppliers (
    supplier_id INTEGER PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
    supplier_name VARCHAR(100) NOT NULL UNIQUE,
    supplier_category_id INTEGER NOT NULL REFERENCES purchasing.supplier_categories(supplier_category_id),
    primary_contact_person_id INTEGER NOT NULL REFERENCES application.people(person_id),
    alternate_contact_person_id INTEGER NOT NULL REFERENCES application.people(person_id),
    delivery_method_id INTEGER REFERENCES application.delivery_methods(delivery_method_id),
    delivery_city_id INTEGER NOT NULL REFERENCES application.cities(city_id),
    postal_city_id INTEGER NOT NULL REFERENCES application.cities(city_id),
    supplier_reference VARCHAR(20),
    bank_account_name VARCHAR(50),
    bank_account_branch VARCHAR(50),
    bank_account_code VARCHAR(20),
    bank_account_number VARCHAR(20),
    bank_international_code VARCHAR(20),
    payment_days INTEGER NOT NULL,
    internal_comments TEXT,
    phone_number VARCHAR(20) NOT NULL,
    fax_number VARCHAR(20) NOT NULL,
    website_url VARCHAR(256) NOT NULL,
    delivery_address_line1 VARCHAR(60) NOT NULL,
    delivery_address_line2 VARCHAR(60),
    delivery_postal_code VARCHAR(10) NOT NULL,
    delivery_location GEOMETRY(Point, 4326),
    postal_address_line1 VARCHAR(60) NOT NULL,
    postal_address_line2 VARCHAR(60),
    postal_postal_code VARCHAR(10) NOT NULL,
    last_edited_by INTEGER NOT NULL REFERENCES application.people(person_id),
    valid_from TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP(6) NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    search_vector TSVECTOR GENERATED ALWAYS AS (
        to_tsvector('english', coalesce(supplier_name, ''))
    ) STORED
);

-- Indexes
CREATE INDEX idx_suppliers_category ON purchasing.suppliers(supplier_category_id);
CREATE INDEX idx_suppliers_delivery_city ON purchasing.suppliers(delivery_city_id);
CREATE INDEX idx_suppliers_delivery_location ON purchasing.suppliers USING GIST(delivery_location);
CREATE INDEX idx_suppliers_search ON purchasing.suppliers USING GIN(search_vector);

-- History table
CREATE TABLE purchasing.suppliers_history (LIKE purchasing.suppliers);
```

## PostgreSQL-Specific Features Implementation

### 1. JSONB for Flexible Schema Data

The PostgreSQL design uses JSONB for columns that store semi-structured data:

```sql
-- Example: Querying JSONB custom fields
SELECT 
    person_id,
    full_name,
    custom_fields->>'HireDate' AS hire_date,
    custom_fields->'OtherLanguages' AS languages
FROM application.people
WHERE custom_fields @> '{"Department": "Sales"}';

-- Example: Updating JSONB data
UPDATE application.people
SET custom_fields = jsonb_set(custom_fields, '{Title}', '"Senior Manager"')
WHERE person_id = 1;
```

### 2. Native Full-Text Search

PostgreSQL's native full-text search replaces SQL Server's full-text indexes:

```sql
-- Search for people
SELECT person_id, full_name, ts_rank(search_vector, query) AS rank
FROM application.people, plainto_tsquery('english', 'John Smith') query
WHERE search_vector @@ query
ORDER BY rank DESC
LIMIT 10;

-- Search for stock items with weighted ranking
SELECT stock_item_id, stock_item_name, ts_rank(search_vector, query) AS rank
FROM warehouse.stock_items, to_tsquery('english', 'novelty & toy') query
WHERE search_vector @@ query
ORDER BY rank DESC;
```

### 3. PostGIS for Spatial Data

PostGIS provides spatial functionality equivalent to SQL Server's geography type:

```sql
-- Find customers within 50km of a point
SELECT customer_id, customer_name,
       ST_Distance(delivery_location::geography, 
                   ST_SetSRID(ST_MakePoint(-122.4194, 37.7749), 4326)::geography) / 1000 AS distance_km
FROM sales.customers
WHERE ST_DWithin(delivery_location::geography,
                 ST_SetSRID(ST_MakePoint(-122.4194, 37.7749), 4326)::geography,
                 50000)
ORDER BY distance_km;

-- Find all cities in a state using spatial containment
SELECT c.city_name
FROM application.cities c
JOIN application.state_provinces sp ON c.state_province_id = sp.state_province_id
WHERE ST_Contains(sp.border, c.location);
```

### 4. Row-Level Security

PostgreSQL's native RLS provides multi-tenant access control:

```sql
-- Enable RLS on customers table
ALTER TABLE sales.customers ENABLE ROW LEVEL SECURITY;

-- Create policy for sales territory access
CREATE POLICY customer_territory_policy ON sales.customers
FOR ALL
USING (
    -- Admin users see all
    current_setting('app.is_admin', true)::boolean = true
    -- ALL_TERRITORIES setting sees all
    OR current_setting('app.sales_territory', true) = 'ALL_TERRITORIES'
    -- Territory-specific access
    OR EXISTS (
        SELECT 1 FROM application.cities c
        JOIN application.state_provinces sp ON c.state_province_id = sp.state_province_id
        WHERE c.city_id = sales.customers.delivery_city_id
        AND sp.sales_territory = current_setting('app.sales_territory', true)
    )
);

-- Set session context for RLS
SET app.sales_territory = 'Far West';
SET app.is_admin = 'false';
```

### 5. Data Masking via Views

Since PostgreSQL doesn't have native Dynamic Data Masking, we implement it via views:

```sql
-- Create masking function
CREATE OR REPLACE FUNCTION mask_value(val TEXT, visible_chars INTEGER DEFAULT 4)
RETURNS TEXT AS $$
BEGIN
    IF current_setting('app.is_admin', true)::boolean = true THEN
        RETURN val;
    ELSE
        RETURN REPEAT('X', GREATEST(length(val) - visible_chars, 0)) || RIGHT(val, visible_chars);
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create masked view for suppliers
CREATE VIEW purchasing.suppliers_masked AS
SELECT 
    supplier_id,
    supplier_name,
    supplier_category_id,
    primary_contact_person_id,
    alternate_contact_person_id,
    delivery_method_id,
    delivery_city_id,
    postal_city_id,
    supplier_reference,
    mask_value(bank_account_name) AS bank_account_name,
    mask_value(bank_account_branch) AS bank_account_branch,
    mask_value(bank_account_code) AS bank_account_code,
    mask_value(bank_account_number) AS bank_account_number,
    mask_value(bank_international_code) AS bank_international_code,
    payment_days,
    internal_comments,
    phone_number,
    fax_number,
    website_url,
    delivery_address_line1,
    delivery_address_line2,
    delivery_postal_code,
    delivery_location,
    postal_address_line1,
    postal_address_line2,
    postal_postal_code,
    last_edited_by,
    valid_from,
    valid_to
FROM purchasing.suppliers;
```

### 6. Temporal Tables via Triggers

PostgreSQL implements temporal tables using triggers:

```sql
-- Create trigger function for history tracking
CREATE OR REPLACE FUNCTION track_history()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        OLD.valid_to = CURRENT_TIMESTAMP;
        INSERT INTO application.people_history SELECT OLD.*;
        NEW.valid_from = CURRENT_TIMESTAMP;
        NEW.valid_to = '9999-12-31 23:59:59.999999';
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        OLD.valid_to = CURRENT_TIMESTAMP;
        INSERT INTO application.people_history SELECT OLD.*;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to people table
CREATE TRIGGER people_history_trigger
BEFORE UPDATE OR DELETE ON application.people
FOR EACH ROW EXECUTE FUNCTION track_history();
```

### 7. Table Partitioning

PostgreSQL uses declarative partitioning for large tables:

```sql
-- Partition cold_room_temperatures by month
CREATE TABLE warehouse.cold_room_temperatures (
    cold_room_temperature_id BIGSERIAL,
    cold_room_sensor_number INTEGER NOT NULL,
    recorded_when TIMESTAMP(6) NOT NULL,
    temperature NUMERIC(10,2) NOT NULL,
    PRIMARY KEY (cold_room_temperature_id, recorded_when)
) PARTITION BY RANGE (recorded_when);

-- Automatic partition management with pg_partman
SELECT partman.create_parent(
    p_parent_table := 'warehouse.cold_room_temperatures',
    p_control := 'recorded_when',
    p_type := 'native',
    p_interval := 'monthly',
    p_premake := 3
);
```

## Relationship Summary

### Primary Key Generation

All primary keys use PostgreSQL's `GENERATED BY DEFAULT AS IDENTITY` which is equivalent to SQL Server's sequences:

```sql
-- PostgreSQL identity column
column_name INTEGER PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY

-- Equivalent to SQL Server
column_name INT DEFAULT (NEXT VALUE FOR [Sequences].[SequenceName]) NOT NULL
```

### Foreign Key Relationships

The PostgreSQL schema maintains all foreign key relationships from the original SQL Server schema:

| Parent Table | Child Table | Foreign Key Column |
|--------------|-------------|-------------------|
| application.countries | application.state_provinces | country_id |
| application.state_provinces | application.cities | state_province_id |
| application.cities | sales.customers | delivery_city_id, postal_city_id |
| application.cities | purchasing.suppliers | delivery_city_id, postal_city_id |
| application.people | [All tables] | last_edited_by |
| sales.customers | sales.orders | customer_id |
| sales.orders | sales.order_lines | order_id |
| sales.customers | sales.invoices | customer_id, bill_to_customer_id |
| sales.invoices | sales.invoice_lines | invoice_id |
| warehouse.stock_items | sales.order_lines | stock_item_id |
| warehouse.stock_items | sales.invoice_lines | stock_item_id |
| purchasing.suppliers | warehouse.stock_items | supplier_id |
| purchasing.suppliers | purchasing.purchase_orders | supplier_id |

## Index Strategy

### B-tree Indexes (Default)
Used for equality and range queries on scalar columns.

### GIN Indexes
Used for full-text search (tsvector) and JSONB columns.

### GiST Indexes
Used for PostGIS geometry columns.

### BRIN Indexes
Used as an alternative to columnstore indexes for large tables with naturally ordered data.

## Conclusion

The PostgreSQL ERD design maintains full compatibility with the original SQL Server schema while leveraging PostgreSQL-specific features for improved functionality. Key adaptations include JSONB for flexible schema data, PostGIS for spatial operations, native full-text search, Row-Level Security for access control, and table partitioning for high-volume data.
