DELIMITER $$

CREATE PROCEDURE load_silver()
BEGIN
  DECLARE start_time DATETIME;
  DECLARE end_time DATETIME;
  DECLARE batch_start_time DATETIME;
  DECLARE batch_end_time DATETIME;

  SET batch_start_time = NOW();
  SELECT 'PROCEDURE STARTED' AS start_msg;

  -- Load CRM Customer Info
  SET start_time = NOW();
  SELECT '>> Truncating silver.crm_cust_info' AS message;
  TRUNCATE TABLE silver.crm_cust_info;
  SELECT '>> Inserting into silver.crm_cust_info' AS message;
  INSERT INTO silver.crm_cust_info (
    cst_id, 
    cst_key, 
    cst_firstname, 
    cst_lastname, 
    cst_marital_status, 
    cst_gndr,
    cst_create_date
  )
  SELECT 
    cst_id,
    cst_key,
    TRIM(cst_firstname),
    TRIM(cst_lastname),
    CASE 
      WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
      WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
      ELSE 'n/a'
    END,
    CASE 
      WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
      WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
      ELSE 'n/a'
    END,
    cst_create_date
  FROM (
    SELECT *, 
           ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
    FROM bronze.crm_cust_info
    WHERE cst_id IS NOT NULL
  ) AS t
  WHERE flag_last = 1;
  SET end_time = NOW();
  SELECT CONCAT('>> Duration: ', TIMESTAMPDIFF(SECOND, start_time, end_time), ' seconds') AS duration;


  -- Load CRM Product Info

  SET start_time = NOW();
  SELECT '>> Truncating silver.crm_prd_info' AS message;
  TRUNCATE TABLE silver.crm_prd_info;
  SELECT '>> Inserting into silver.crm_prd_info' AS message;
  INSERT INTO silver.crm_prd_info (
    prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt
  )
  SELECT 
    prd_id,
    REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_'),
    SUBSTRING(prd_key, 7),
    prd_nm,
    IFNULL(prd_cost, 0),
    CASE 
      WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
      WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
      WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
      WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
      ELSE 'n/a'
    END,
    prd_start_dt,
    NULL
  FROM bronze.crm_prd_info;
  SET end_time = NOW();
  SELECT CONCAT('>> Duration: ', TIMESTAMPDIFF(SECOND, start_time, end_time), ' seconds') AS duration;

  -- Load CRM Sales Details

  SET start_time = NOW();
  SELECT '>> Truncating silver.crm_sales_details' AS message;
  TRUNCATE TABLE silver.crm_sales_details;
  SELECT '>> Inserting into silver.crm_sales_details' AS message;
  INSERT INTO silver.crm_sales_details (
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
  STR_TO_DATE(sls_order_dt, '%Y%m%d'),
  STR_TO_DATE(sls_ship_dt, '%Y%m%d'),
  STR_TO_DATE(sls_due_dt, '%Y%m%d'),
  CASE 
    WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
      THEN sls_quantity * ABS(sls_price)
    ELSE sls_sales
  END,
  sls_quantity,
  CASE 
    WHEN sls_price IS NULL OR sls_price <= 0 
      THEN sls_sales / NULLIF(sls_quantity, 0)
    ELSE sls_price
  END
FROM (
  SELECT 
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
  FROM bronze.crm_sales_details
  WHERE 
    sls_order_dt REGEXP '^[0-9]{8}$' AND sls_order_dt != '00000000'
    AND sls_ship_dt REGEXP '^[0-9]{8}$' AND sls_ship_dt != '00000000'
    AND sls_due_dt REGEXP '^[0-9]{8}$' AND sls_due_dt != '00000000'
) AS filtered;
SET end_time=NOW();
SELECT CONCAT('>> Duration: ', TIMESTAMPDIFF(SECOND, start_time, end_time), ' seconds') AS duration;


  -- Load ERP Customer

  SET start_time = NOW();
  SELECT '>> Truncating silver.erp_cust_az12' AS message;
  TRUNCATE TABLE silver.erp_cust_az12;
  SELECT '>> Inserting into silver.erp_cust_az12' AS message;
  INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
  SELECT 
    IF(LEFT(cid, 3) = 'NAS', SUBSTRING(cid, 4), cid),
    IF(bdate > NOW(), NULL, bdate),
    CASE 
      WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
      WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
      ELSE 'n/a'
    END
  FROM bronze.erp_cust_az12;
  SET end_time = NOW();
  SELECT CONCAT('>> Duration: ', TIMESTAMPDIFF(SECOND, start_time, end_time), ' seconds') AS duration;

  -- Load ERP Location

  SET start_time = NOW();
  SELECT '>> Truncating silver.erp_loc_a101' AS message;
  TRUNCATE TABLE silver.erp_loc_a101;
  SELECT '>> Inserting into silver.erp_loc_a101' AS message;
  INSERT INTO silver.erp_loc_a101 (cid, cntry)
  SELECT 
    REPLACE(cid, '-', ''),
    CASE 
      WHEN TRIM(cntry) = 'DE' THEN 'Germany'
      WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
      WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
      ELSE TRIM(cntry)
    END
  FROM bronze.erp_loc_a101;
  SET end_time = NOW();
  SELECT CONCAT('>> Duration: ', TIMESTAMPDIFF(SECOND, start_time, end_time), ' seconds') AS duration;

  -- Load ERP Product Categories

  SET start_time = NOW();
  SELECT '>> Truncating silver.erp_px_cat_g1v2' AS message;
  TRUNCATE TABLE silver.erp_px_cat_g1v2;
  SELECT '>> Inserting into silver.erp_px_cat_g1v2' AS message;
  INSERT INTO silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
  SELECT id, cat, subcat, maintenance
  FROM bronze.erp_px_cat_g1v2;
  SET end_time = NOW();
  SELECT CONCAT('>> Duration: ', TIMESTAMPDIFF(SECOND, start_time, end_time), ' seconds') AS duration;

  SET batch_end_time = NOW();
  SELECT 'PROCEDURE ENDED' AS end_msg;
END$$

DELIMITER ;
