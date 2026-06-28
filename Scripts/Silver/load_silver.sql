/* 
silver.crm_cust_info LOAD
*/

TRUNCATE TABLE silver.crm_cust_info;
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
  
TRUNCATE TABLE silver.crm_prd_info;
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
