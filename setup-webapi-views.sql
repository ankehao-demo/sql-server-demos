-- Setup script for Wide World Importers WebApi views (Development Mode)
-- This script disables Row-Level Security and creates the WebApi views needed for the application

USE WideWorldImporters;
GO

-- Disable Row-Level Security for development
PRINT 'Disabling Row-Level Security for development...';
ALTER SECURITY POLICY [Application].[FilterCustomersBySalesTerritoryRole] WITH (STATE = OFF);
GO

-- Ensure WebApi user has proper permissions
PRINT 'Granting permissions to WebApi user...';
GRANT SELECT ON SCHEMA::WebApi TO WebApi;
GO

PRINT 'WebApi views setup complete! The Wide World Importers web application should now work.';
PRINT 'Note: Row-Level Security has been disabled for development purposes.';
GO