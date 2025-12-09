-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- File: 001-indexes.sql
-- Description: Create indexes for performance optimization

-- Application schema indexes

-- Application.People indexes
CREATE INDEX ix_application_people_fullname ON application.people (fullname);
CREATE INDEX ix_application_people_issalesperson ON application.people (issalesperson);
CREATE INDEX ix_application_people_isemployee ON application.people (isemployee);
CREATE INDEX ix_application_people_perf_20160301_logonname ON application.people (ispermittedtologon, personid) WHERE ispermittedtologon = true;

-- Application.Countries indexes
CREATE INDEX ix_application_countries_countryname ON application.countries (countryname);

-- Application.StateProvinces indexes
CREATE INDEX ix_application_stateprovinces_countryid ON application.stateprovinces (countryid);
CREATE INDEX ix_application_stateprovinces_salesterritory ON application.stateprovinces (salesterritory);
CREATE INDEX ix_application_stateprovinces_stateprovincename ON application.stateprovinces (stateprovincename);

-- Application.Cities indexes
CREATE INDEX ix_application_cities_stateprovinceid ON application.cities (stateprovinceid);
CREATE INDEX ix_application_cities_cityname ON application.cities (cityname);

-- Application.SystemParameters indexes
CREATE INDEX ix_application_systemparameters_deliverycityid ON application.systemparameters (deliverycityid);
CREATE INDEX ix_application_systemparameters_postalcityid ON application.systemparameters (postalcityid);

-- Warehouse schema indexes

-- Warehouse.Colors indexes
CREATE INDEX ix_warehouse_colors_colorname ON warehouse.colors (colorname);

-- Warehouse.PackageTypes indexes
CREATE INDEX ix_warehouse_packagetypes_packagetypename ON warehouse.packagetypes (packagetypename);

-- Warehouse.StockGroups indexes
CREATE INDEX ix_warehouse_stockgroups_stockgroupname ON warehouse.stockgroups (stockgroupname);

-- Warehouse.StockItems indexes
CREATE INDEX ix_warehouse_stockitems_stockitemname ON warehouse.stockitems (stockitemname);
CREATE INDEX ix_warehouse_stockitems_supplierid ON warehouse.stockitems (supplierid);
CREATE INDEX ix_warehouse_stockitems_colorid ON warehouse.stockitems (colorid);
CREATE INDEX ix_warehouse_stockitems_unitpackageid ON warehouse.stockitems (unitpackageid);
CREATE INDEX ix_warehouse_stockitems_outerpackageid ON warehouse.stockitems (outerpackageid);

-- Warehouse.StockItemHoldings indexes
CREATE INDEX ix_warehouse_stockitemholdings_stockitemid ON warehouse.stockitemholdings (stockitemid);

-- Warehouse.StockItemStockGroups indexes
CREATE INDEX ix_warehouse_stockitemstockgroups_stockitemid ON warehouse.stockitemstockgroups (stockitemid);
CREATE INDEX ix_warehouse_stockitemstockgroups_stockgroupid ON warehouse.stockitemstockgroups (stockgroupid);

-- Warehouse.StockItemTransactions indexes
CREATE INDEX ix_warehouse_stockitemtransactions_stockitemid ON warehouse.stockitemtransactions (stockitemid);
CREATE INDEX ix_warehouse_stockitemtransactions_customerid ON warehouse.stockitemtransactions (customerid);
CREATE INDEX ix_warehouse_stockitemtransactions_invoiceid ON warehouse.stockitemtransactions (invoiceid);
CREATE INDEX ix_warehouse_stockitemtransactions_supplierid ON warehouse.stockitemtransactions (supplierid);
CREATE INDEX ix_warehouse_stockitemtransactions_transactiontypeid ON warehouse.stockitemtransactions (transactiontypeid);
CREATE INDEX ix_warehouse_stockitemtransactions_purchaseorderid ON warehouse.stockitemtransactions (purchaseorderid);
CREATE INDEX ix_warehouse_stockitemtransactions_transactionoccurredwhen ON warehouse.stockitemtransactions (transactionoccurredwhen);

-- Warehouse.ColdRoomTemperatures indexes
CREATE INDEX ix_warehouse_coldroomtemperatures_coldroomsensornumber ON warehouse.coldroomtemperatures (coldroomsensornumber);
CREATE INDEX ix_warehouse_coldroomtemperatures_recordedwhen ON warehouse.coldroomtemperatures (recordedwhen);

-- Warehouse.VehicleTemperatures indexes
CREATE INDEX ix_warehouse_vehicletemperatures_vehicleregistration ON warehouse.vehicletemperatures (vehicleregistration);
CREATE INDEX ix_warehouse_vehicletemperatures_recordedwhen ON warehouse.vehicletemperatures (recordedwhen);

-- Sales schema indexes

-- Sales.BuyingGroups indexes
CREATE INDEX ix_sales_buyinggroups_buyinggroupname ON sales.buyinggroups (buyinggroupname);

-- Sales.CustomerCategories indexes
CREATE INDEX ix_sales_customercategories_customercategoryname ON sales.customercategories (customercategoryname);

-- Sales.Customers indexes
CREATE INDEX ix_sales_customers_customername ON sales.customers (customername);
CREATE INDEX ix_sales_customers_customercategoryid ON sales.customers (customercategoryid);
CREATE INDEX ix_sales_customers_buyinggroupid ON sales.customers (buyinggroupid);
CREATE INDEX ix_sales_customers_primarycontactpersonid ON sales.customers (primarycontactpersonid);
CREATE INDEX ix_sales_customers_alternatecontactpersonid ON sales.customers (alternatecontactpersonid);
CREATE INDEX ix_sales_customers_deliverymethodid ON sales.customers (deliverymethodid);
CREATE INDEX ix_sales_customers_deliverycityid ON sales.customers (deliverycityid);
CREATE INDEX ix_sales_customers_postalcityid ON sales.customers (postalcityid);
CREATE INDEX ix_sales_customers_billtocustomerid ON sales.customers (billtocustomerid);
CREATE INDEX ix_sales_customers_perf_20160301_isoncredithold ON sales.customers (isoncredithold, customerid, billtocustomerid) WHERE isoncredithold = true;

-- Sales.Orders indexes
CREATE INDEX ix_sales_orders_customerid ON sales.orders (customerid);
CREATE INDEX ix_sales_orders_salespersonpersonid ON sales.orders (salespersonpersonid);
CREATE INDEX ix_sales_orders_contactpersonid ON sales.orders (contactpersonid);
CREATE INDEX ix_sales_orders_orderdate ON sales.orders (orderdate);
CREATE INDEX ix_sales_orders_expecteddeliverydate ON sales.orders (expecteddeliverydate);
CREATE INDEX ix_sales_orders_backorderorderid ON sales.orders (backorderorderid);
CREATE INDEX ix_sales_orders_pickedbypersonid ON sales.orders (pickedbypersonid);

-- Sales.OrderLines indexes
CREATE INDEX ix_sales_orderlines_orderid ON sales.orderlines (orderid);
CREATE INDEX ix_sales_orderlines_stockitemid ON sales.orderlines (stockitemid);
CREATE INDEX ix_sales_orderlines_packagetypeid ON sales.orderlines (packagetypeid);
CREATE INDEX ix_sales_orderlines_perf_20160301_pickingcompletedwhen ON sales.orderlines (pickingcompletedwhen, orderid, orderlineid) WHERE pickingcompletedwhen IS NOT NULL;

-- Sales.Invoices indexes
CREATE INDEX ix_sales_invoices_customerid ON sales.invoices (customerid);
CREATE INDEX ix_sales_invoices_billtocustomerid ON sales.invoices (billtocustomerid);
CREATE INDEX ix_sales_invoices_orderid ON sales.invoices (orderid);
CREATE INDEX ix_sales_invoices_deliverymethodid ON sales.invoices (deliverymethodid);
CREATE INDEX ix_sales_invoices_contactpersonid ON sales.invoices (contactpersonid);
CREATE INDEX ix_sales_invoices_accountspersonid ON sales.invoices (accountspersonid);
CREATE INDEX ix_sales_invoices_salespersonpersonid ON sales.invoices (salespersonpersonid);
CREATE INDEX ix_sales_invoices_packedbypersonid ON sales.invoices (packedbypersonid);
CREATE INDEX ix_sales_invoices_invoicedate ON sales.invoices (invoicedate);
CREATE INDEX ix_sales_invoices_confirmeddeliverytime ON sales.invoices (confirmeddeliverytime);
CREATE INDEX ix_sales_invoices_perf_20160301_confirmeddeliverytime ON sales.invoices (confirmeddeliverytime) INCLUDE (confirmedreceivedby) WHERE confirmeddeliverytime IS NOT NULL;

-- Sales.InvoiceLines indexes
CREATE INDEX ix_sales_invoicelines_invoiceid ON sales.invoicelines (invoiceid);
CREATE INDEX ix_sales_invoicelines_stockitemid ON sales.invoicelines (stockitemid);
CREATE INDEX ix_sales_invoicelines_packagetypeid ON sales.invoicelines (packagetypeid);

-- Sales.SpecialDeals indexes
CREATE INDEX ix_sales_specialdeals_stockitemid ON sales.specialdeals (stockitemid);
CREATE INDEX ix_sales_specialdeals_customerid ON sales.specialdeals (customerid);
CREATE INDEX ix_sales_specialdeals_buyinggroupid ON sales.specialdeals (buyinggroupid);
CREATE INDEX ix_sales_specialdeals_customercategoryid ON sales.specialdeals (customercategoryid);
CREATE INDEX ix_sales_specialdeals_stockgroupid ON sales.specialdeals (stockgroupid);

-- Sales.CustomerTransactions indexes
CREATE INDEX ix_sales_customertransactions_customerid ON sales.customertransactions (customerid);
CREATE INDEX ix_sales_customertransactions_transactiontypeid ON sales.customertransactions (transactiontypeid);
CREATE INDEX ix_sales_customertransactions_invoiceid ON sales.customertransactions (invoiceid);
CREATE INDEX ix_sales_customertransactions_paymentmethodid ON sales.customertransactions (paymentmethodid);
CREATE INDEX ix_sales_customertransactions_transactiondate ON sales.customertransactions (transactiondate);
CREATE INDEX ix_sales_customertransactions_isfinalized ON sales.customertransactions (isfinalized);

-- Purchasing schema indexes

-- Purchasing.SupplierCategories indexes
CREATE INDEX ix_purchasing_suppliercategories_suppliercategoryname ON purchasing.suppliercategories (suppliercategoryname);

-- Purchasing.Suppliers indexes
CREATE INDEX ix_purchasing_suppliers_suppliername ON purchasing.suppliers (suppliername);
CREATE INDEX ix_purchasing_suppliers_suppliercategoryid ON purchasing.suppliers (suppliercategoryid);
CREATE INDEX ix_purchasing_suppliers_primarycontactpersonid ON purchasing.suppliers (primarycontactpersonid);
CREATE INDEX ix_purchasing_suppliers_alternatecontactpersonid ON purchasing.suppliers (alternatecontactpersonid);
CREATE INDEX ix_purchasing_suppliers_deliverymethodid ON purchasing.suppliers (deliverymethodid);
CREATE INDEX ix_purchasing_suppliers_deliverycityid ON purchasing.suppliers (deliverycityid);
CREATE INDEX ix_purchasing_suppliers_postalcityid ON purchasing.suppliers (postalcityid);

-- Purchasing.PurchaseOrders indexes
CREATE INDEX ix_purchasing_purchaseorders_supplierid ON purchasing.purchaseorders (supplierid);
CREATE INDEX ix_purchasing_purchaseorders_deliverymethodid ON purchasing.purchaseorders (deliverymethodid);
CREATE INDEX ix_purchasing_purchaseorders_contactpersonid ON purchasing.purchaseorders (contactpersonid);
CREATE INDEX ix_purchasing_purchaseorders_orderdate ON purchasing.purchaseorders (orderdate);
CREATE INDEX ix_purchasing_purchaseorders_expecteddeliverydate ON purchasing.purchaseorders (expecteddeliverydate);

-- Purchasing.PurchaseOrderLines indexes
CREATE INDEX ix_purchasing_purchaseorderlines_purchaseorderid ON purchasing.purchaseorderlines (purchaseorderid);
CREATE INDEX ix_purchasing_purchaseorderlines_stockitemid ON purchasing.purchaseorderlines (stockitemid);
CREATE INDEX ix_purchasing_purchaseorderlines_packagetypeid ON purchasing.purchaseorderlines (packagetypeid);
CREATE INDEX ix_purchasing_purchaseorderlines_isorderlinefinalized ON purchasing.purchaseorderlines (isorderlinefinalized);

-- Purchasing.SupplierTransactions indexes
CREATE INDEX ix_purchasing_suppliertransactions_supplierid ON purchasing.suppliertransactions (supplierid);
CREATE INDEX ix_purchasing_suppliertransactions_transactiontypeid ON purchasing.suppliertransactions (transactiontypeid);
CREATE INDEX ix_purchasing_suppliertransactions_purchaseorderid ON purchasing.suppliertransactions (purchaseorderid);
CREATE INDEX ix_purchasing_suppliertransactions_paymentmethodid ON purchasing.suppliertransactions (paymentmethodid);
CREATE INDEX ix_purchasing_suppliertransactions_transactiondate ON purchasing.suppliertransactions (transactiondate);
CREATE INDEX ix_purchasing_suppliertransactions_isfinalized ON purchasing.suppliertransactions (isfinalized);
