CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $$
	DECLARE 
		start_time TIMESTAMP;
		end_time TIMESTAMP;
		batch_start_time TIMESTAMP;
		batch_end_time TIMESTAMP;
	BEGIN
		batch_start_time := NOW();
		RAISE NOTICE '+++++++++++++++++++++++++++++++++++++++';
		RAISE NOTICE 'LOADING SILVER LAYER';
		RAISE NOTICE '+++++++++++++++++++++++++++++++++++++++';
		start_time := NOW();
		RAISE NOTICE '>> Truncating Table: silver.crm_cust_info';
		TRUNCATE TABLE silver.crm_cust_info;
		RAISE NOTICE '>> Inserting Data into: silver.crm_cust_info';
		INSERT INTO silver.crm_cust_info (cst_id,cst_key,cst_firstname,cst_lastname,cst_marital_status,cst_gndr,cst_create_date)
		SELECT 
			t.cst_id as cst_id,
			t.cst_key as cst_key,
			TRIM(t.cst_firstname) as cst_firstname,
			TRIM(t.cst_lastname) as cst_lastname,
			CASE 
				WHEN UPPER(TRIM(t.cst_marital_status)) = 'S' THEN 'Single'
				WHEN UPPER(TRIM(t.cst_marital_status)) = 'M' THEN 'Married'
				ELSE 'Unknown'
			END as cst_marital_status,
			CASE 
				WHEN UPPER(TRIM(t.cst_gndr)) = 'M' THEN 'Male' 
				WHEN UPPER(TRIM(t.cst_gndr)) = 'F' THEN 'Female'
				ELSE 'Unknown' 
			END as cst_gndr,
			t.cst_create_date as create_date
		FROM (SELECT 
			*,ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY crm_cust_info.cst_create_date DESC) as flag_last
		FROM bronze.crm_cust_info 
		WHERE cst_id IS NOT NULL) t WHERE flag_last = 1;
		end_time := NOW();
		RAISE NOTICE 'Load Duration : % SECONDS', EXTRACT(EPOCH FROM (end_time - start_time));
		RAISE NOTICE '---------------------------------------------';
		start_time := NOW();
		RAISE NOTICE '>> Truncating Table: silver.crm_prd_info';
		TRUNCATE TABLE silver.crm_prd_info;
		RAISE NOTICE '>> Inserting Data into: silver.crm_prd_info';
		INSERT INTO silver.crm_prd_info(
			prd_id,
			cat_key,
			prd_key,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt
		)
		SELECT 
			prd_id,
			REPLACE(SUBSTRING(prd_key,1,5),'-','_') as cat_key,
			SUBSTRING(prd_key,7,LENGTH(prd_key)) as prd_key,
			prd_nm,
			COALESCE(prd_cost,0) as prd_cost,
			CASE 
				UPPER(TRIM(prd_line)) 
					WHEN 'S' THEN 'Other Sales'
					WHEN 'R' THEN 'Road'
					WHEN 'T' THEN 'Train'
					WHEN 'M' THEN 'Mountain'
				ELSE 'Unknown'
			END as prd_line,
			CAST(prd_start_dt as DATE),
			CAST(LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt) - INTERVAL '1 day' as DATE) as prd_end_dt
		FROM bronze.crm_prd_info ;
		end_time := NOW();
		RAISE NOTICE 'Load Duration : % SECONDS', EXTRACT(EPOCH FROM (end_time - start_time));
		RAISE NOTICE '---------------------------------------------';
		start_time := NOW();
		RAISE NOTICE '>> Truncating Table: silver.crm_sales_details';
		TRUNCATE TABLE silver.crm_sales_details;
		RAISE NOTICE '>> Inserting Data into: silver.crm_sales_details';
		INSERT INTO silver.crm_sales_details(
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales,
			sls_quantity,
			sls_price
		)	
		SELECT 
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			CASE 
				WHEN 
					sls_order_dt <= 0 
					OR LENGTH(sls_order_dt :: TEXT) <> 8
					OR sls_order_dt > 20500101
					OR sls_order_dt < 19000101
				THEN NULL
				ELSE sls_order_dt :: TEXT :: DATE 
			END as sls_order_dt,
			CASE 
				WHEN 
					sls_ship_dt <= 0 
					OR LENGTH(sls_ship_dt :: TEXT) <> 8
					OR sls_ship_dt > 20500101
					OR sls_ship_dt < 19000101
				THEN NULL
				ELSE sls_ship_dt :: TEXT :: DATE 
			END as sls_ship_dt,
			CASE 
				WHEN 
					sls_due_dt <= 0 
					OR LENGTH(sls_due_dt :: TEXT) <> 8
					OR sls_due_dt > 20500101
					OR sls_due_dt < 19000101
				THEN NULL
				ELSE sls_due_dt :: TEXT :: DATE 
			END as sls_due_dt,
			CASE
				WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales <> sls_quantity * ABS(sls_price)
				THEN sls_quantity * ABS(sls_price)
				ELSE sls_sales 
			END as sls_sales,
			sls_quantity,
			CAST(CASE
					WHEN sls_price IS NULL OR sls_price <= 0 
					THEN sls_sales / NULLIF(sls_quantity,0) 
					ELSE sls_price 
				END as INTEGER) as sls_price 
		FROM bronze.crm_sales_details;
		end_time := NOW();
		RAISE NOTICE 'Load Duration : % SECONDS', EXTRACT(EPOCH FROM (end_time - start_time));
		RAISE NOTICE '---------------------------------------------';
		start_time := NOW();
		RAISE NOTICE '>> Truncating Table: silver.erp_cust_az12';
		TRUNCATE TABLE silver.erp_cust_az12;
		RAISE NOTICE '>> Inserting Data into: silver.erp_cust_az12';
		INSERT INTO silver.erp_cust_az12(
			cid,
			bdate,
			gen
		)
		SELECT 
			CASE 
				WHEN cid LIKE 'NAS%'
				THEN SUBSTRING(cid,4,LENGTH(cid))
				ELSE cid
			END as cid,
			CASE
				WHEN bdate > CURRENT_DATE
				THEN NULL
				ELSE bdate
			END as bdate,
			CASE 
				WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') 
				THEN 'Female'
				WHEN UPPER(TRIM(gen)) IN ('M','MALE') 
				THEN 'Male'
				ELSE 'Unknown'
			END as gen 
		FROM bronze.erp_cust_az12;
		end_time := NOW();
		RAISE NOTICE 'Load Duration : % SECONDS', EXTRACT(EPOCH FROM (end_time - start_time));
		RAISE NOTICE '---------------------------------------------';
		start_time := NOW();
		RAISE NOTICE '>> Truncating Table: silver.erp_loc_a101';
		TRUNCATE TABLE silver.erp_loc_a101;
		RAISE NOTICE '>> Inserting Data into: silver.erp_loc_a101';
		INSERT INTO silver.erp_loc_a101(
			cid,
			cntry
		)
		SELECT 
			REPLACE(cid,'-','') as cid,
			CASE 
				WHEN TRIM(cntry) = 'DE' THEN 'Germany'
				WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
				WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'Unknown'
				ELSE TRIM(cntry)
			END as cntry
		FROM bronze.erp_loc_a101;
		end_time := NOW();
		RAISE NOTICE 'Load Duration : % SECONDS', EXTRACT(EPOCH FROM (end_time - start_time));
		RAISE NOTICE '---------------------------------------------';
		start_time := NOW();
		RAISE NOTICE '>> Truncating Table: silver.erp_px_cat_g1v2';
		TRUNCATE TABLE silver.erp_px_cat_g1v2;
		RAISE NOTICE '>> Inserting Data into: silver.erp_px_cat_g1v2';
		INSERT INTO silver.erp_px_cat_g1v2(
			id,
			cat,
			subcat,
			maintenance
		)
		SELECT 
			id,
			cat,
			subcat,
			maintenance
		FROM bronze.erp_px_cat_g1v2;
		end_time := NOW();
		RAISE NOTICE 'Load Duration : % SECONDS', EXTRACT(EPOCH FROM (end_time - start_time));
		batch_end_time := NOW();
		RAISE NOTICE 'Batch Load Duration : % SECONDS', EXTRACT(EPOCH FROM (batch_end_time - batch_start_time));
	EXCEPTION
	    WHEN OTHERS THEN
	        RAISE NOTICE 'Error Message: %', SQLERRM;
	        RAISE NOTICE 'Error Code: %', SQLSTATE; 
END $$;

CALL silver.load_silver()
