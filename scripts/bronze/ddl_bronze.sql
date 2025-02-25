/*
============================================================================
DDL Script: Create Bronze Tables 
============================================================================
Script Purpose:
  This script creates tables in the bronze schema dropping existing tables
  if they already exists.
 Run thsi script to re-define the DDL structure of bronze Tables
============================================================================
*/

DROP TABLE IF EXISTS bronze.crm_cust_info;
CREATE TABLE bronze.crm_cust_info(
	cst_id INTEGER,
	cst_key VARCHAR(50),
	cst_firstname VARCHAR(50),
	cst_lastname VARCHAR(50),
	cst_marital_status VARCHAR(1),
	cst_gndr VARCHAR(50),
	cst_create_data DATE
);

DROP TABLE IF EXISTS bronze.crm_prd_info;
CREATE TABLE bronze.crm_prd_info(
	prd_id INTEGER,
	prd_key VARCHAR(50),
	prd_nm VARCHAR(50),
	prd_cost DECIMAL,
	prd_line VARCHAR(1),
	prd_start_dt DATE,
	prd_end_dt DATE
);

DROP TABLE IF EXISTS bronze.crm_sales_details;
CREATE TABLE bronze.crm_sales_details(
	sls_ord_num VARCHAR(50),
	sls_prd_key VARCHAR(50),
	sls_cust_id INTEGER,
	sls_order_dt INTEGER,
	sls_ship_dt INTEGER,
	sls_due_dt INTEGER,
	sls_sales DECIMAL,
	sls_quantity INTEGER,
	sls_price DECIMAL
);

DROP TABLE IF EXISTS bronze.erp_cust_az12;
CREATE TABLE bronze.erp_cust_az12(
	cid VARCHAR(50),
	bdate DATE,
	gen VARCHAR(50)
);

DROP TABLE IF EXISTS bronze.erp_loc_a101;
CREATE TABLE bronze.erp_loc_a101(
	cid VARCHAR(50),
	cntry VARCHAR(50)
);

DROP TABLE IF EXISTS bronze.erp_px_cat_g1v2;
CREATE TABLE bronze.erp_px_cat_g1v2(
	id VARCHAR(20),
	cat VARCHAR(20),
	subcat VARCHAR(50),
	maintenance VARCHAR(10)
);
