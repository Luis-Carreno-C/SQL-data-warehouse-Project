/* 
silver.crm_cust_info LOAD
*/

PRINT '>> Truncating Table: silver.crm_cust_info'
TRUNCATE TABLE silver.crm_cust_info;
PRINT '>> Inserting Data Into: silver.crm_cust_info'
INSERT INTO silver.crm_cust_info (
	cst_id,
	cst_key,
	cst_firstname,
	cst_lastname,
	cst_marital_status,
	cst_gndr,
	cst_create_date)

SELECT 
cst_id,
cst_key,
TRIM (cst_firstname) AS cst_firstname,
TRIM (cst_lastname) AS cst_lastname,
CASE WHEN UPPER(TRIM(cst_material_status)) = 'M' THEN 'Married' -- Trimming para remover espacios al inicio o final
	 WHEN UPPER(TRIM(cst_material_status)) = 'S' THEN 'Single' -- Upper fuerza a una lectura de letras mayusculas
	 ELSE 'Unknown'											-- Al tener 3 valores es posible utilizar case par normalizar
END AS cst_marital_status,
CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'  -- Usamos Female para valores mas "user friendly" 
	 WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male' 
	 ELSE 'Unknown'									-- Eliminamos los nulos agregando un valor por default
END AS cst_gndr,
cst_create_date -- Se confirma que es formato DATE no es necesario ningun cambio
FROM (

	/*
	Este Script identifica los duplicados de clientes, debido a distintas versiones en la fuente original
	Se utiliza la funcion de ventana ROW_NUMBER para identificar las distintas "versiones" del mismo cliente
	*/

	SELECT *,
	ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS versions
	FROM bronze.crm_cust_info
	WHERE cst_id IS NOT NULL
) AS t
WHERE versions = 1


-- PRODUCT TABLE
PRINT '>> Truncating Table: silver.crm_prd_info'  
TRUNCATE TABLE silver.crm_prd_info;
PRINT '>> Inserting Data Into: silver.crm_prd_info'
INSERT INTO silver.crm_prd_info(
	prd_id,
	cat_id, 
	prd_key, 
	prd_nm,
	prd_cost,
	prd_line,  
	prd_start_dt,
	prd_end_dt
)

SELECT 
prd_id,
REPLACE(SUBSTRING(prd_key,1,5), '-', '_') AS cat_id, -- Reemplazamos el - por _, para utilizar tabla de categorias (CRM)
SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key, -- Al ser largo variable, utilizamos LEN(), para fijar el final en SUBSTRING
prd_nm,
ISNULL(prd_cost, 0) AS prd_cost,
CASE WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
	 WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
	 WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
	 WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
	 ELSE 'n/a'
END AS prd_line,  -- Se complementa con valores descriptivos
CAST(prd_start_dt AS DATE) AS prd_start_dt,
CAST( LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) -1 AS DATE
	) AS prd_end_dt -- Calculate end date as one day before the next start date
FROM bronze.crm_prd_info



-- SALES TABLE
PRINT '>> Truncating Table: silver.crm_sales_details'  
TRUNCATE TABLE silver.crm_sales_details;
PRINT '>> Inserting Data Into: silver.crm_sales_details'
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
/*
Las fechas estan creadas como INT, por lo que se debe:
primero cambiar a VARCHAR
luego de VACHAR cambiar a DATE
Tambien se comprueba que mantengan formato de cantidad de datos con LEN
*/
CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) !=8 THEN NULL
	 ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)	
END AS sls_order_dt,
CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) !=8 THEN NULL
	 ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)	
END AS sls_ship_dt,
CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) !=8 THEN NULL
	 ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)	
END AS sls_due_dt,
/* Reglas para calculo sls_sales = sls_quantity * sls_price
1. Si la venta es negativa, cero o null, se calcula con precio y qty
2. Si el precio es cero o nulo, se calcula usando venta y qty
3. Si el precio es negativo, se cambia a positivo */
CASE WHEN sls_sales <=0 OR sls_sales IS NULL OR sls_sales != sls_quantity * ABS(sls_price)
	 THEN sls_quantity * ABS(sls_price)
	 ELSE sls_sales
END AS sls_sales,
sls_quantity,
CASE WHEN sls_price <= 0 OR sls_price IS NULL
	 THEN sls_sales/ NULLIF(sls_quantity,0)
	 ELSE sls_price
END AS sls_price
FROM bronze.crm_sales_details;


/*
=======================
Carga de tablas de CRM
=======================
*/

PRINT '>> Truncating Table: silver.crm_cust_info'  
TRUNCATE TABLE silver.crm_cust_info;
PRINT '>> Inserting Data Into: silver.erp_cust_az12'
INSERT INTO silver.erp_cust_az12(
	cid,
	bdate,
	gen
)

SELECT
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) -- Se normaliza la id key, para conectar con erp
	 ELSE cid
END AS cid,
CASE WHEN bdate > GETDATE() THEN NULL -- Fechas de nacimiento mayor a hoy son consideradas nulas
	 ELSE bdate
END AS bdate,
CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female' -- Se normaliza los generos presentes en gen
	 WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
	 ELSE 'n/a'
END AS gen
FROM bronze.erp_cust_az12


PRINT '>> Truncating Table: silver.erp_loc_a101'  
TRUNCATE TABLE silver.erp_loc_a101;
PRINT '>> Inserting Data Into: silver.erp_loc_a101'
INSERT INTO silver.erp_loc_a101 (cid, cntry)

SELECT
REPLACE(cid, '-', '') AS cid,
CASE WHEN UPPER(TRIM(cntry)) IN ('DE', 'GERMANY') THEN 'Germany'
	 WHEN UPPER(TRIM(cntry)) IN ('US', 'USA', 'UNITED STATES') THEN 'United States'
	 WHEN UPPER(TRIM(cntry)) IN ('UK', 'UNITED KINGDOM') THEN 'United Kingdom'
	 WHEN UPPER(TRIM(cntry)) IN ('AU', 'AUSTRALIA') THEN 'Australia'
	 WHEN UPPER(TRIM(cntry)) IN ('FR', 'FRANCE') THEN 'France'
	 WHEN UPPER(TRIM(cntry)) IN ('CA', 'CANADA') THEN 'Canada'
	 ELSE 'n/a'
END AS cntry
FROM bronze.erp_loc_a101

PRINT '>> Truncating Table: silver.erp_px_cat_g1v2'  
TRUNCATE TABLE silver.erp_px_cat_g1v2
PRINT '>> Inserting Data Into: silver.erp_px_cat_g1v2'
INSERT INTO silver.erp_px_cat_g1v2
(id, cat, subcat, maintenance )

SELECT
id,
cat,
subcat,
maintenance
FROM bronze.erp_px_cat_g1v2
