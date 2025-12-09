-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- File: 001-foreign-keys.sql
-- Description: Create foreign key constraints for all tables

-- Application schema foreign keys

-- Application.People foreign keys
ALTER TABLE application.people
    ADD CONSTRAINT fk_application_people_lasteditedby_application_people
    FOREIGN KEY (lasteditedby) REFERENCES application.people(personid);

-- Application.Countries foreign keys
ALTER TABLE application.countries
    ADD CONSTRAINT fk_application_countries_lasteditedby_application_people
    FOREIGN KEY (lasteditedby) REFERENCES application.people(personid);

-- Application.StateProvinces foreign keys
ALTER TABLE application.stateprovinces
    ADD CONSTRAINT fk_application_stateprovinces_countryid_application_countries
    FOREIGN KEY (countryid) REFERENCES application.countries(countryid);

ALTER TABLE application.stateprovinces
    ADD CONSTRAINT fk_application_stateprovinces_lasteditedby_application_people
    FOREIGN KEY (lasteditedby) REFERENCES application.people(personid);

-- Application.Cities foreign keys
ALTER TABLE application.cities
    ADD CONSTRAINT fk_application_cities_stateprovinceid_application_stateprovinces
    FOREIGN KEY (stateprovinceid) REFERENCES application.stateprovinces(stateprovinceid);

ALTER TABLE application.cities
    ADD CONSTRAINT fk_application_cities_lasteditedby_application_people
    FOREIGN KEY (lasteditedby) REFERENCES application.people(personid);

-- Application.DeliveryMethods foreign keys
ALTER TABLE application.deliverymethods
    ADD CONSTRAINT fk_application_deliverymethods_lasteditedby_application_people
    FOREIGN KEY (lasteditedby) REFERENCES application.people(personid);

-- Application.PaymentMethods foreign keys
ALTER TABLE application.paymentmethods
    ADD CONSTRAINT fk_application_paymentmethods_lasteditedby_application_people
    FOREIGN KEY (lasteditedby) REFERENCES application.people(personid);

-- Application.TransactionTypes foreign keys
ALTER TABLE application.transactiontypes
    ADD CONSTRAINT fk_application_transactiontypes_lasteditedby_application_people
    FOREIGN KEY (lasteditedby) REFERENCES application.people(personid);

-- Application.SystemParameters foreign keys
ALTER TABLE application.systemparameters
    ADD CONSTRAINT fk_application_systemparameters_deliverycityid_application_cities
    FOREIGN KEY (deliverycityid) REFERENCES application.cities(cityid);

ALTER TABLE application.systemparameters
    ADD CONSTRAINT fk_application_systemparameters_postalcityid_application_cities
    FOREIGN KEY (postalcityid) REFERENCES application.cities(cityid);

ALTER TABLE application.systemparameters
    ADD CONSTRAINT fk_application_systemparameters_lasteditedby_application_people
    FOREIGN KEY (lasteditedby) REFERENCES application.people(personid);

-- Warehouse schema foreign keys

-- Warehouse.Colors foreign keys
ALTER TABLE warehouse.colors
    ADD CONSTRAINT fk_warehouse_colors_lasteditedby_application_people
    FOREIGN KEY (lasteditedby) REFERENCES application.people(personid);

-- Warehouse.PackageTypes foreign keys
ALTER TABLE warehouse.packagetypes
    ADD CONSTRAINT fk_warehouse_packagetypes_lasteditedby_application_people
    FOREIGN KEY (lasteditedby) REFERENCES application.people(personid);

-- Warehouse.StockGroups foreign keys
ALTER TABLE warehouse.stockgroups
    ADD CONSTRAINT fk_warehouse_stockgroups_lasteditedby_application_people
    FOREIGN KEY (lasteditedby) REFERENCES application.people(personid);

-- Warehouse.StockItems foreign keys
ALTER TABLE warehouse.stockitems
    ADD CONSTRAINT fk_warehouse_stockitems_supplierid_purchasing_suppliers
    FOREIGN KEY (supplierid) REFERENCES purchasing.suppliers(supplierid);

ALTER TABLE warehouse.stockitems
    ADD CONSTRAINT fk_warehouse_stockitems_colorid_warehouse_colors
    FOREIGN KEY (colorid) REFERENCES warehouse.colors(colorid);

ALTER TABLE warehouse.stockitems
    ADD CONSTRAINT fk_warehouse_stockitems_unitpackageid_warehouse_packagetypes
    FOREIGN KEY (unitpackageid) REFERENCES warehouse.packagetypes(packagetypeid);

ALTER TABLE warehouse.stockitems
    ADD CONSTRAINT fk_warehouse_stockitems_outerpackageid_warehouse_packagetypes
    FOREIGN KEY (outerpackageid) REFERENCES warehouse.packagetypes(packagetypeid);

ALTER TABLE warehouse.stockitems
    ADD CONSTRAINT fk_warehouse_stockitems_lasteditedby_application_people
    FOREIGN KEY (lasteditedby) REFERENCES application.people(personid);

-- Warehouse.StockItemHoldings foreign keys
ALTER TABLE warehouse.stockitemholdings
    ADD CONSTRAINT fk_warehouse_stockitemholdings_stockitemid_warehouse_stockitems
    FOREIGN KEY (stockitemid) REFERENCES warehouse.stockitems(stockitemid);

ALTER TABLE warehouse.stockitemholdings
    ADD CONSTRAINT fk_warehouse_stockitemholdings_lasteditedby_application_people
    FOREIGN KEY (lasteditedby) REFERENCES application.people(personid);

-- Warehouse.StockItemStockGroups foreign keys
ALTER TABLE warehouse.stockitemstockgroups
    ADD CONSTRAINT fk_warehouse_stockitemstockgroups_stockitemid_warehouse_stockitems
    FOREIGN KEY (stockitemid) REFERENCES warehouse.stockitems(stockitemid);

ALTER TABLE warehouse.stockitemstockgroups
    ADD CONSTRAINT fk_warehouse_stockitemstockgroups_stockgroupid_warehouse_stockgroups
    FOREIGN KEY (stockgroupid) REFERENCES warehouse.stockgroups(stockgroupid);

ALTER TABLE warehouse.stockitemstockgroups
    ADD CONSTRAINT fk_warehouse_stockitemstockgroups_lasteditedby_application_people
    FOREIGN KEY (lasteditedby) REFERENCES application.people(personid);

-- Warehouse.StockItemTransactions foreign keys
ALTER TABLE warehouse.stockitemtransactions
    ADD CONSTRAINT fk_warehouse_stockitemtransactions_stockitemid_warehouse_stockitems
    FOREIGN KEY (stockitemid) REFERENCES warehouse.stockitems(stockitemid);

ALTER TABLE warehouse.stockitemtransactions
    ADD CONSTRAINT fk_warehouse_stockitemtransactions_customerid_sales_customers
    FOREIGN KEY (customerid) REFERENCES sales.customers(customerid);

ALTER TABLE warehouse.stockitemtransactions
    ADD CONSTRAINT fk_warehouse_stockitemtransactions_invoiceid_sales_invoices
    FOREIGN KEY (invoiceid) REFERENCES sales.invoices(invoiceid);

ALTER TABLE warehouse.stockitemtransactions
    ADD CONSTRAINT fk_warehouse_stockitemtransactions_supplierid_purchasing_suppliers
    FOREIGN KEY (supplierid) REFERENCES purchasing.suppliers(supplierid);

ALTER TABLE warehouse.stockitemtransactions
    ADD CONSTRAINT fk_warehouse_stockitemtransactions_transactiontypeid_application_transactiontypes
    FOREIGN KEY (transactiontypeid) REFERENCES application.transactiontypes(transactiontypeid);

ALTER TABLE warehouse.stockitemtransactions
    ADD CONSTRAINT fk_warehouse_stockitemtransactions_purchaseorderid_purchasing_purchaseorders
    FOREIGN KEY (purchaseorderid) REFERENCES purchasing.purchaseorders(purchaseorderid);

ALTER TABLE warehouse.stockitemtransactions
    ADD CONSTRAINT fk_warehouse_stockitemtransactions_lasteditedby_application_people
    FOREIGN KEY (lasteditedby) REFERENCES application.people(personid);

-- Sales schema foreign keys

-- Sales.BuyingGroups foreign keys
ALTER TABLE sales.buyinggroups
    ADD CONSTRAINT fk_sales_buyinggroups_lasteditedby_application_people
    FOREIGN KEY (lasteditedby) REFERENCES application.people(personid);

-- Sales.CustomerCategories foreign keys
ALTER TABLE sales.customercategories
    ADD CONSTRAINT fk_sales_customercategories_lasteditedby_application_people
    FOREIGN KEY (lasteditedby) REFERENCES application.people(personid);

-- Sales.Customers foreign keys
ALTER TABLE sales.customers
    ADD CONSTRAINT fk_sales_customers_billtocustomerid_sales_customers
    FOREIGN KEY (billtocustomerid) REFERENCES sales.customers(customerid);

ALTER TABLE sales.customers
    ADD CONSTRAINT fk_sales_customers_customercategoryid_sales_customercategories
    FOREIGN KEY (customercategoryid) REFERENCES sales.customercategories(customercategoryid);

ALTER TABLE sales.customers
    ADD CONSTRAINT fk_sales_customers_buyinggroupid_sales_buyinggroups
    FOREIGN KEY (buyinggroupid) REFERENCES sales.buyinggroups(buyinggroupid);

ALTER TABLE sales.customers
    ADD CONSTRAINT fk_sales_customers_primarycontactpersonid_application_people
    FOREIGN KEY (primarycontactpersonid) REFERENCES application.people(personid);

ALTER TABLE sales.customers
    ADD CONSTRAINT fk_sales_customers_alternatecontactpersonid_application_people
    FOREIGN KEY (alternatecontactpersonid) REFERENCES application.people(personid);

ALTER TABLE sales.customers
    ADD CONSTRAINT fk_sales_customers_deliverymethodid_application_deliverymethods
    FOREIGN KEY (deliverymethodid) REFERENCES application.deliverymethods(deliverymethodid);

ALTER TABLE sales.customers
    ADD CONSTRAINT fk_sales_customers_deliverycityid_application_cities
    FOREIGN KEY (deliverycityid) REFERENCES application.cities(cityid);

ALTER TABLE sales.customers
    ADD CONSTRAINT fk_sales_customers_postalcityid_application_cities
    FOREIGN KEY (postalcityid) REFERENCES application.cities(cityid);

ALTER TABLE sales.customers
    ADD CONSTRAINT fk_sales_customers_lasteditedby_application_people
    FOREIGN KEY (lasteditedby) REFERENCES application.people(personid);

-- Sales.Orders foreign keys
ALTER TABLE sales.orders
    ADD CONSTRAINT fk_sales_orders_customerid_sales_customers
    FOREIGN KEY (customerid) REFERENCES sales.customers(customerid);

ALTER TABLE sales.orders
    ADD CONSTRAINT fk_sales_orders_salespersonpersonid_application_people
    FOREIGN KEY (salespersonpersonid) REFERENCES application.people(personid);

ALTER TABLE sales.orders
    ADD CONSTRAINT fk_sales_orders_pickedbypersonid_application_people
    FOREIGN KEY (pickedbypersonid) REFERENCES application.people(personid);

ALTER TABLE sales.orders
    ADD CONSTRAINT fk_sales_orders_contactpersonid_application_people
    FOREIGN KEY (contactpersonid) REFERENCES application.people(personid);

ALTER TABLE sales.orders
    ADD CONSTRAINT fk_sales_orders_backorderorderid_sales_orders
    FOREIGN KEY (backorderorderid) REFERENCES sales.orders(orderid);

ALTER TABLE sales.orders
    ADD CONSTRAINT fk_sales_orders_lasteditedby_application_people
    FOREIGN KEY (lasteditedby) REFERENCES application.people(personid);

-- Sales.OrderLines foreign keys
ALTER TABLE sales.orderlines
    ADD CONSTRAINT fk_sales_orderlines_orderid_sales_orders
    FOREIGN KEY (orderid) REFERENCES sales.orders(orderid);

ALTER TABLE sales.orderlines
    ADD CONSTRAINT fk_sales_orderlines_stockitemid_warehouse_stockitems
    FOREIGN KEY (stockitemid) REFERENCES warehouse.stockitems(stockitemid);

ALTER TABLE sales.orderlines
    ADD CONSTRAINT fk_sales_orderlines_packagetypeid_warehouse_packagetypes
    FOREIGN KEY (packagetypeid) REFERENCES warehouse.packagetypes(packagetypeid);

ALTER TABLE sales.orderlines
    ADD CONSTRAINT fk_sales_orderlines_lasteditedby_application_people
    FOREIGN KEY (lasteditedby) REFERENCES application.people(personid);

-- Sales.Invoices foreign keys
ALTER TABLE sales.invoices
    ADD CONSTRAINT fk_sales_invoices_customerid_sales_customers
    FOREIGN KEY (customerid) REFERENCES sales.customers(customerid);

ALTER TABLE sales.invoices
    ADD CONSTRAINT fk_sales_invoices_billtocustomerid_sales_customers
    FOREIGN KEY (billtocustomerid) REFERENCES sales.customers(customerid);

ALTER TABLE sales.invoices
    ADD CONSTRAINT fk_sales_invoices_orderid_sales_orders
    FOREIGN KEY (orderid) REFERENCES sales.orders(orderid);

ALTER TABLE sales.invoices
    ADD CONSTRAINT fk_sales_invoices_deliverymethodid_application_deliverymethods
    FOREIGN KEY (deliverymethodid) REFERENCES application.deliverymethods(deliverymethodid);

ALTER TABLE sales.invoices
    ADD CONSTRAINT fk_sales_invoices_contactpersonid_application_people
    FOREIGN KEY (contactpersonid) REFERENCES application.people(personid);

ALTER TABLE sales.invoices
    ADD CONSTRAINT fk_sales_invoices_accountspersonid_application_people
    FOREIGN KEY (accountspersonid) REFERENCES application.people(personid);

ALTER TABLE sales.invoices
    ADD CONSTRAINT fk_sales_invoices_salespersonpersonid_application_people
    FOREIGN KEY (salespersonpersonid) REFERENCES application.people(personid);

ALTER TABLE sales.invoices
    ADD CONSTRAINT fk_sales_invoices_packedbypersonid_application_people
    FOREIGN KEY (packedbypersonid) REFERENCES application.people(personid);

ALTER TABLE sales.invoices
    ADD CONSTRAINT fk_sales_invoices_lasteditedby_application_people
    FOREIGN KEY (lasteditedby) REFERENCES application.people(personid);

-- Sales.InvoiceLines foreign keys
ALTER TABLE sales.invoicelines
    ADD CONSTRAINT fk_sales_invoicelines_invoiceid_sales_invoices
    FOREIGN KEY (invoiceid) REFERENCES sales.invoices(invoiceid);

ALTER TABLE sales.invoicelines
    ADD CONSTRAINT fk_sales_invoicelines_stockitemid_warehouse_stockitems
    FOREIGN KEY (stockitemid) REFERENCES warehouse.stockitems(stockitemid);

ALTER TABLE sales.invoicelines
    ADD CONSTRAINT fk_sales_invoicelines_packagetypeid_warehouse_packagetypes
    FOREIGN KEY (packagetypeid) REFERENCES warehouse.packagetypes(packagetypeid);

ALTER TABLE sales.invoicelines
    ADD CONSTRAINT fk_sales_invoicelines_lasteditedby_application_people
    FOREIGN KEY (lasteditedby) REFERENCES application.people(personid);

-- Sales.SpecialDeals foreign keys
ALTER TABLE sales.specialdeals
    ADD CONSTRAINT fk_sales_specialdeals_stockitemid_warehouse_stockitems
    FOREIGN KEY (stockitemid) REFERENCES warehouse.stockitems(stockitemid);

ALTER TABLE sales.specialdeals
    ADD CONSTRAINT fk_sales_specialdeals_customerid_sales_customers
    FOREIGN KEY (customerid) REFERENCES sales.customers(customerid);

ALTER TABLE sales.specialdeals
    ADD CONSTRAINT fk_sales_specialdeals_buyinggroupid_sales_buyinggroups
    FOREIGN KEY (buyinggroupid) REFERENCES sales.buyinggroups(buyinggroupid);

ALTER TABLE sales.specialdeals
    ADD CONSTRAINT fk_sales_specialdeals_customercategoryid_sales_customercategories
    FOREIGN KEY (customercategoryid) REFERENCES sales.customercategories(customercategoryid);

ALTER TABLE sales.specialdeals
    ADD CONSTRAINT fk_sales_specialdeals_stockgroupid_warehouse_stockgroups
    FOREIGN KEY (stockgroupid) REFERENCES warehouse.stockgroups(stockgroupid);

ALTER TABLE sales.specialdeals
    ADD CONSTRAINT fk_sales_specialdeals_lasteditedby_application_people
    FOREIGN KEY (lasteditedby) REFERENCES application.people(personid);

-- Sales.CustomerTransactions foreign keys
ALTER TABLE sales.customertransactions
    ADD CONSTRAINT fk_sales_customertransactions_customerid_sales_customers
    FOREIGN KEY (customerid) REFERENCES sales.customers(customerid);

ALTER TABLE sales.customertransactions
    ADD CONSTRAINT fk_sales_customertransactions_transactiontypeid_application_transactiontypes
    FOREIGN KEY (transactiontypeid) REFERENCES application.transactiontypes(transactiontypeid);

ALTER TABLE sales.customertransactions
    ADD CONSTRAINT fk_sales_customertransactions_invoiceid_sales_invoices
    FOREIGN KEY (invoiceid) REFERENCES sales.invoices(invoiceid);

ALTER TABLE sales.customertransactions
    ADD CONSTRAINT fk_sales_customertransactions_paymentmethodid_application_paymentmethods
    FOREIGN KEY (paymentmethodid) REFERENCES application.paymentmethods(paymentmethodid);

ALTER TABLE sales.customertransactions
    ADD CONSTRAINT fk_sales_customertransactions_lasteditedby_application_people
    FOREIGN KEY (lasteditedby) REFERENCES application.people(personid);

-- Purchasing schema foreign keys

-- Purchasing.SupplierCategories foreign keys
ALTER TABLE purchasing.suppliercategories
    ADD CONSTRAINT fk_purchasing_suppliercategories_lasteditedby_application_people
    FOREIGN KEY (lasteditedby) REFERENCES application.people(personid);

-- Purchasing.Suppliers foreign keys
ALTER TABLE purchasing.suppliers
    ADD CONSTRAINT fk_purchasing_suppliers_suppliercategoryid_purchasing_suppliercategories
    FOREIGN KEY (suppliercategoryid) REFERENCES purchasing.suppliercategories(suppliercategoryid);

ALTER TABLE purchasing.suppliers
    ADD CONSTRAINT fk_purchasing_suppliers_primarycontactpersonid_application_people
    FOREIGN KEY (primarycontactpersonid) REFERENCES application.people(personid);

ALTER TABLE purchasing.suppliers
    ADD CONSTRAINT fk_purchasing_suppliers_alternatecontactpersonid_application_people
    FOREIGN KEY (alternatecontactpersonid) REFERENCES application.people(personid);

ALTER TABLE purchasing.suppliers
    ADD CONSTRAINT fk_purchasing_suppliers_deliverymethodid_application_deliverymethods
    FOREIGN KEY (deliverymethodid) REFERENCES application.deliverymethods(deliverymethodid);

ALTER TABLE purchasing.suppliers
    ADD CONSTRAINT fk_purchasing_suppliers_deliverycityid_application_cities
    FOREIGN KEY (deliverycityid) REFERENCES application.cities(cityid);

ALTER TABLE purchasing.suppliers
    ADD CONSTRAINT fk_purchasing_suppliers_postalcityid_application_cities
    FOREIGN KEY (postalcityid) REFERENCES application.cities(cityid);

ALTER TABLE purchasing.suppliers
    ADD CONSTRAINT fk_purchasing_suppliers_lasteditedby_application_people
    FOREIGN KEY (lasteditedby) REFERENCES application.people(personid);

-- Purchasing.PurchaseOrders foreign keys
ALTER TABLE purchasing.purchaseorders
    ADD CONSTRAINT fk_purchasing_purchaseorders_supplierid_purchasing_suppliers
    FOREIGN KEY (supplierid) REFERENCES purchasing.suppliers(supplierid);

ALTER TABLE purchasing.purchaseorders
    ADD CONSTRAINT fk_purchasing_purchaseorders_deliverymethodid_application_deliverymethods
    FOREIGN KEY (deliverymethodid) REFERENCES application.deliverymethods(deliverymethodid);

ALTER TABLE purchasing.purchaseorders
    ADD CONSTRAINT fk_purchasing_purchaseorders_contactpersonid_application_people
    FOREIGN KEY (contactpersonid) REFERENCES application.people(personid);

ALTER TABLE purchasing.purchaseorders
    ADD CONSTRAINT fk_purchasing_purchaseorders_lasteditedby_application_people
    FOREIGN KEY (lasteditedby) REFERENCES application.people(personid);

-- Purchasing.PurchaseOrderLines foreign keys
ALTER TABLE purchasing.purchaseorderlines
    ADD CONSTRAINT fk_purchasing_purchaseorderlines_purchaseorderid_purchasing_purchaseorders
    FOREIGN KEY (purchaseorderid) REFERENCES purchasing.purchaseorders(purchaseorderid);

ALTER TABLE purchasing.purchaseorderlines
    ADD CONSTRAINT fk_purchasing_purchaseorderlines_stockitemid_warehouse_stockitems
    FOREIGN KEY (stockitemid) REFERENCES warehouse.stockitems(stockitemid);

ALTER TABLE purchasing.purchaseorderlines
    ADD CONSTRAINT fk_purchasing_purchaseorderlines_packagetypeid_warehouse_packagetypes
    FOREIGN KEY (packagetypeid) REFERENCES warehouse.packagetypes(packagetypeid);

ALTER TABLE purchasing.purchaseorderlines
    ADD CONSTRAINT fk_purchasing_purchaseorderlines_lasteditedby_application_people
    FOREIGN KEY (lasteditedby) REFERENCES application.people(personid);

-- Purchasing.SupplierTransactions foreign keys
ALTER TABLE purchasing.suppliertransactions
    ADD CONSTRAINT fk_purchasing_suppliertransactions_supplierid_purchasing_suppliers
    FOREIGN KEY (supplierid) REFERENCES purchasing.suppliers(supplierid);

ALTER TABLE purchasing.suppliertransactions
    ADD CONSTRAINT fk_purchasing_suppliertransactions_transactiontypeid_application_transactiontypes
    FOREIGN KEY (transactiontypeid) REFERENCES application.transactiontypes(transactiontypeid);

ALTER TABLE purchasing.suppliertransactions
    ADD CONSTRAINT fk_purchasing_suppliertransactions_purchaseorderid_purchasing_purchaseorders
    FOREIGN KEY (purchaseorderid) REFERENCES purchasing.purchaseorders(purchaseorderid);

ALTER TABLE purchasing.suppliertransactions
    ADD CONSTRAINT fk_purchasing_suppliertransactions_paymentmethodid_application_paymentmethods
    FOREIGN KEY (paymentmethodid) REFERENCES application.paymentmethods(paymentmethodid);

ALTER TABLE purchasing.suppliertransactions
    ADD CONSTRAINT fk_purchasing_suppliertransactions_lasteditedby_application_people
    FOREIGN KEY (lasteditedby) REFERENCES application.people(personid);
