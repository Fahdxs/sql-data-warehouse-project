/*

=================================================================
Create Database and Schemas 
=================================================================
Script Purpose:
  This script creates a new database named 'DataWarehouse' after checking if it already exists.
  If the database exists, it is dropped and recreated. Additionally, the scripts sets up three schemas
  within the database: 'bronze','silver', and 'gold'.

WARNING:
  Running this script will drop the entire 'DataWarehouse' database if it exists.
  All data in the database will be permentantly deleted. Proceed with caution
  and ensure you have proper backups before running this script.

*/

-- Drop and recreate the 'DataWarehouse' database
DO $$ 
BEGIN 
    IF EXISTS (SELECT 1 FROM pg_database WHERE datname = 'datawarehouse') THEN
        PERFORM pg_terminate_backend(pid) 
        FROM pg_stat_activity 
        WHERE datname = 'datawarehouse'; -- Kills active connections
        DROP DATABASE datawarehouse;
    END IF;
END $$;


-- Create the Database 'Datawarehouse'
CREATE DATABASE DataWarehouse;

  
-- Create Schemas  
CREATE SCHEMA bronze;

  
CREATE SCHEMA silver;


CREATE SCHEMA gold;



