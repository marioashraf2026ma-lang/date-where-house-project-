

  
create or alter procedure silver.load_bronze as   /* like an function to easy to creat*/ 

 declare @starte_time datetime , @end_time datetime ,  -- declare variables for save
 @batch_start_time datetime ,  @batch_end_time datetime  ; --   Calculate the Duration of Loading  total Bronze Layer Whole Batch

begin 

 begin try   -- find the erros 

 set @batch_start_time = getdate() ;  

 ----------------------------------------------------------------

 set @starte_time = getdate ()  ;   --  time of start operation 

-- ============================================================



print ' ==========================================  '
print '****************************'
print ' loading sliver layer '
print '****************************'



print '--------------------------------------------------- '
print '                                            '
print '>>> truncating table silver 1  . crm_cust _info'
print '                                            '
print '>>>-  inserting data into 1 : silver. crm_cust _info'

-- Loading Silver Layer table 1  - Customer Information
-- Source: bronze.crm_cst_info
-- Target: silver.crm_cst_info
--
-- Purpose:
--   1. Recreate the Silver customer table
--   2. Clean customer names
--   3. Standardize marital status and gender
--   4. Remove duplicate customer records
--   5. Load the cleaned data into the Silver layer
-- ============================================================


-- ============================================================
-- Step 1: Drop the Silver table if it already exists
-- ============================================================

IF OBJECT_ID('silver.crm_cst_info', 'U') IS NOT NULL   

    -- Check whether the Silver table already exists.
    -- If it exists, drop it so that the table can be
    -- recreated with the required structure.

    DROP TABLE silver.crm_cst_info;


-- ============================================================
-- Step 2: Create the Silver table
-- ============================================================

CREATE TABLE silver.crm_cst_info (

    cst_id              INT,           -- Unique Customer ID
    cst_key             NVARCHAR(50), -- Customer Business Key
    cst_firstname       NVARCHAR(50), -- Customer first name
    cst_lastname        NVARCHAR(50), -- Customer last name
    cst_marital_status  NVARCHAR(50), -- Standardized marital status
    cst_gndr            NVARCHAR(50), -- Standardized gender
    cst_create_date     DATE           -- Customer creation date

);


-- ============================================================
-- Step 3: Clear the Silver table
-- ============================================================

TRUNCATE TABLE silver.crm_cst_info; 

-- Remove all existing records before loading fresh data.
--
-- NOTE:
-- Since the table was just dropped and recreated above,
-- it is already empty at this point.
--
-- Therefore, TRUNCATE is technically redundant here.
-- It would be useful if the table were kept and reused
-- without DROP + CREATE.


-- ============================================================
-- Step 4: Insert cleaned data into Silver
-- ============================================================

INSERT INTO silver.crm_cst_info (

    cst_id,
    cst_key, 
    cst_firstname,
    cst_lastname,
    cst_marital_status,
    cst_gndr, 
    cst_create_date  

)


-- ============================================================
-- Step 5: Select and transform the Bronze data
-- ============================================================

SELECT 

    -- Keep the original Customer ID.
    cst_id,


    -- Keep the original Customer Business Key.
    cst_key,


    -- ========================================================
    -- Clean First Name
    -- ========================================================

    -- TRIM() removes unwanted spaces from the beginning
    -- and end of the customer's first name.

    TRIM(cst_firstname) AS cst_firstname,


    -- ========================================================
    -- Clean Last Name
    -- ========================================================

    -- Remove unwanted leading and trailing spaces.

    TRIM(cst_lastname) AS cst_lastname,


    -- ========================================================
    -- Standardize Marital Status
    -- ========================================================

    CASE

        -- Convert values such as:
        -- 'S', 's', ' S '
        -- into a standardized value.

        WHEN UPPER(TRIM(cst_marital_status)) = 'S'
            THEN 'single'


        -- Convert:
        -- 'M', 'm', ' M '
        -- into a standardized value.

        WHEN UPPER(TRIM(cst_marital_status)) = 'M'
            THEN 'married'


        -- Any unexpected or unknown value
        -- is assigned a standard placeholder.

        ELSE 'n/a'

    END AS cst_marital_status,


    -- ========================================================
    -- Standardize Gender
    -- ========================================================

    CASE

        -- Convert F / f / ' F ' into Female.

        WHEN UPPER(TRIM(cst_gndr)) = 'F'
            THEN 'Female'


        -- Convert M / m / ' M ' into Male.

        WHEN UPPER(TRIM(cst_gndr)) = 'M'
            THEN 'Male'


        -- Unknown or unexpected values
        -- are assigned n/a.

        ELSE 'n/a'

    END AS cst_gndr,


    -- Keep the customer creation date.
    cst_create_date


-- ============================================================
-- Step 6: Read data from Bronze and remove duplicates
-- ============================================================

FROM
(
    
    SELECT

        -- Select all columns from the Bronze customer table.
        *


        -- ====================================================
        -- Deduplication
        -- ====================================================

        ,
        
        -- ROW_NUMBER() assigns a sequential number to each
        -- record for the same customer.
        --
        -- PARTITION BY cst_id:
        --     Creates a separate group for every customer.
        --
        -- ORDER BY cst_create_date:
        --     Sorts records by creation date.
        --
        -- Example:
        --
        -- cst_id | cst_create_date | flag_last
        -- -------|-----------------|----------
        -- 1001   | 2020-01-01      | 1
        -- 1001   | 2021-01-01      | 2
        -- 1001   | 2022-01-01      | 3
        --
        -- flag_last = 1 therefore represents
        -- the earliest record.

        ROW_NUMBER() OVER (
            PARTITION BY cst_id
            ORDER BY cst_create_date
        ) AS flag_last


    -- Bronze source table.
    FROM bronze.crm_cst_info


    -- ========================================================
    -- Data Quality Check
    -- ========================================================

    -- Customer ID is required to identify the customer
    -- and perform the deduplication correctly.

    WHERE cst_id IS NOT NULL

) t


-- ============================================================
-- Step 7: Keep only one record per customer
-- ============================================================

WHERE flag_last = 1;


-- The subquery is given the alias "t".
--
-- flag_last = 1 keeps only one record for each customer.
--
-- IMPORTANT:
-- Because the ORDER BY uses ASC by default,
-- this keeps the EARLIEST record.
--
-- If you want the LATEST record instead, use:
--
-- ROW_NUMBER() OVER (
--     PARTITION BY cst_id
--     ORDER BY cst_create_date DESC
-- )


-- ============================================================
-- Optional Data Quality Check
-- ============================================================

-- This query can be used to inspect the original values
-- before deciding how they should be standardized.
--
-- SELECT DISTINCT
--     cst_gndr,
--     cst_marital_status
-- FROM bronze.crm_cst_info;


-- ============================================================
-- Silver Layer Flow
--
-- Bronze CRM Customer Data
--          |
--          v
-- Remove NULL Customer IDs
--          |
--          v
-- Identify duplicate customers
--          |
--          v
-- Keep one record per customer
--          |
--          v
-- TRIM customer names
--          |
--          v
-- Standardize marital status
--          |
--          v
-- Standardize gender
--          |
--          v
-- Silver CRM Customer Data
-- ============================================================

--***************************************************---***************************************************************************************************************************

--***************************************************---***************************************************************************************************************************

--***************************************************---***************************************************************************************************************************
--***************************************************---***************************************************************************************************************************
--***************************************************---***************************************************************************************************************************
--***************************************************---***************************************************************************************************************************
--***************************************************---***************************************************************************************************************************
--***************************************************---***************************************************************************************************************************
--***************************************************---***************************************************************************************************************************

 set @end_time = getdate ()  ;   --  time of the end operation  

  print '========================================================================='

 
 print '>>>>>>>>>>>> 1 load durtion :  ' + cast (datediff (second , @starte_time ,@end_time  ) as nvarchar ) + 'seconds'
  print '=========================================================================='





print '--------------------------------------------------- '
print '                                                    '
print '>>> truncating table silver 2  . silver.crm_prd_info'
print '                                                    '
print '>>>-  inserting data into 2 : silver.crm_prd_info   '


-- ============================================================

set @starte_time = getdate ()  ;   --  time of start operation 


--Loading Silver Layer - Table 2
-- Source: Bronze CRM Product Information
--
-- Purpose:
--   1. Remove the existing Silver table if it exists
--   2. Create a clean and standardized Product table
--   3. Clean product keys and categories
--   4. Handle missing product costs
--   5. Standardize product line values
--   6. Generate product end dates using LEAD()
-- ============================================================


-- ============================================================
-- Step 1: Drop the existing Silver table
-- ============================================================

IF OBJECT_ID('silver.crm_prd_info', 'U') IS NOT NULL 
    DROP TABLE silver.crm_prd_info;

-- Check whether the Silver table already exists.
-- If it exists, drop it so the ETL script can be executed again
-- without getting a "table already exists" error.


-- ============================================================
-- Step 2: Create the Silver Product table
-- ============================================================

CREATE TABLE silver.crm_prd_info ( 
    
    prd_id        INT,           -- Product ID
    cat_id        NVARCHAR(50),  -- Category ID
    prd_key       NVARCHAR(50),  -- Product key
    prd_nm        NVARCHAR(50),  -- Product name
    prd_cost      INT,           -- Product cost
    prd_line      NVARCHAR(50),  -- Product line/category
    prd_start_dt  DATE,          -- Product validity start date
    prd_end_dt    DATE           -- Product validity end date
   
);


-- ============================================================
-- Step 3: Load cleaned data from Bronze → Silver
-- ============================================================

INSERT INTO silver.crm_prd_info (
    
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

    -- Keep the original Product ID.
    prd_id,


    -- ========================================================
    -- Clean Category ID
    -- ========================================================

    -- Example:
    -- Original prd_key:
    --     "AC-HE-001"
    --
    -- SUBSTRING(prd_key, 1, 5)
    --     → "AC-HE"
    --
    -- REPLACE('-', '_')
    --     → "AC_HE"
    --
    -- This standardizes the category ID so it matches
    -- the category ID format used in:
    --     silver.erp_px_cat_g1v2
    
    REPLACE(
        SUBSTRING(prd_key, 1, 5),
        '-',
        '_'
    ) AS cat_id,


    -- ========================================================
    -- Clean Product Key
    -- ========================================================

    -- Remove the category prefix from the original product key.
    --
    -- Example:
    --     Original: AC-HE-001
    --     Result:   001
    --
    -- This creates a standardized product key that can be
    -- used to match product information with other tables.
    
    SUBSTRING(
        prd_key,
        7,
        LEN(prd_key)
    ) AS prd_key,


    -- Keep the original product name.
    prd_nm,


    -- ========================================================
    -- Handle Missing Product Cost
    -- ========================================================

    -- If product cost is NULL, replace it with 0.
    --
    -- This prevents NULL values from causing problems
    -- during calculations and reporting.
    
    ISNULL(prd_cost, 0) AS prd_cost,


    -- ========================================================
    -- Standardize Product Line
    -- ========================================================

    -- TRIM() removes unnecessary spaces.
    -- UPPER() converts the value to uppercase.
    --
    -- This makes values consistent even if the source data
    -- contains different casing or extra spaces.
    
    CASE UPPER(TRIM(prd_line))

        -- M = Mountain
        WHEN 'M' THEN 'Mountain'

        -- R = Road
        WHEN 'R' THEN 'Road'

        -- S = Other Sales
        WHEN 'S' THEN 'Other Sales'

        -- T = Touring
        WHEN 'T' THEN 'Touring'

        -- Unknown or invalid values
        ELSE 'N/A'

    END AS prd_line,


    -- ========================================================
    -- Product Start Date
    -- ========================================================

    -- Convert the source value explicitly into DATE
    -- to standardize the data type in the Silver layer.
    
    CAST(prd_start_dt AS DATE) AS prd_start_dt,


    -- ========================================================
    -- Product End Date
    -- ========================================================

    -- LEAD() gets the next start date for the same product.
    --
    -- Example:
    --
    -- Product | Start Date | Next Start Date
    -- --------|------------|----------------
    -- A       | 2020-01-01 | 2021-01-01
    -- A       | 2021-01-01 | 2022-01-01
    -- A       | 2022-01-01 | NULL
    --
    -- Subtracting 1 day gives:
    --
    -- Product | Start Date | End Date
    -- --------|------------|----------
    -- A       | 2020-01-01 | 2020-12-31
    -- A       | 2021-01-01 | 2021-12-31
    -- A       | 2022-01-01 | NULL
    --
    -- This creates a validity period for each version
    -- of the product.
    
    CAST(
        LEAD(prd_start_dt) OVER (
            PARTITION BY prd_key
            ORDER BY prd_start_dt
        ) - 1 AS DATE
    ) AS prd_end_dt


-- ============================================================
-- Source Table
-- ============================================================

FROM bronze.crm_prd_info;


-- ============================================================
-- Silver Layer Result
--
-- Bronze Layer:
--     Raw product data
--
--          ↓
--
-- Cleaning / Transformation:
--     - Standardize Category ID
--     - Extract Product Key
--     - Replace NULL costs with 0
--     - Standardize Product Line
--     - Convert dates to DATE
--     - Generate Product End Dates
--
--          ↓
--
-- Silver Layer:
--     Cleaned and standardized product data
-- ============================================================
 set @end_time = getdate ()  ;   --  time of the end operation

  print '========================================================================='

 
 print '>>>>>>>>>>>> 2 load durtion :  ' + cast (datediff (second , @starte_time ,@end_time  ) as nvarchar ) + 'seconds'
  print '=========================================================================='
--***************************************************---***************************************************************************************************************************

--***************************************************---***************************************************************************************************************************

--***************************************************---***************************************************************************************************************************
--***************************************************---***************************************************************************************************************************
--***************************************************---***************************************************************************************************************************
--***************************************************---***************************************************************************************************************************
--***************************************************---***************************************************************************************************************************
--***************************************************---***************************************************************************************************************************
--***************************************************---***************************************************************************************************************************
print '--------------------------------------------------- '
print '                                                    '
print '>>> truncating table silver 3    silver.crm_sales_details    '
print '                                                    '
print '>>>-  inserting data into 3 :  silver.crm_sales_details '
                                                 
-- ============================================================
set @starte_time = getdate ()  ;   --  time of start operation 


-- Loading Silver Layer - Table 3



-- Source: Bronze CRM Sales Details
-- Purpose:
--   1. Remove the old Silver table if it already exists
--   2. Create a clean Silver table
--   3. Transform and validate raw Bronze data
--   4. Load the cleaned data into the Silver layer
-- ============================================================


-- ============================================================
-- Step 1: Drop the existing Silver table
-- ============================================================

IF OBJECT_ID('silver.crm_sales_details', 'U') IS NOT NULL 
    DROP TABLE silver.crm_sales_details;

-- If the Silver table already exists, delete it first.
-- This allows the script to be re-run without getting
-- a "table already exists" error.


-- ============================================================
-- Step 2: Create the Silver table
-- ============================================================

CREATE TABLE silver.crm_sales_details (
    
    sls_ord_num    NVARCHAR(50),  -- Sales order number
    sls_prd_key    NVARCHAR(50),  -- Product key
    sls_cust_id    INT,           -- Customer ID
    
    sls_order_dt   DATE,          -- Order date
    sls_ship_dt    DATE,          -- Shipping date
    sls_due_dt     DATE,          -- Due date
    
    sls_sales      INT,           -- Total sales amount
    sls_quantity   INT,           -- Quantity sold
    sls_price      INT            -- Price per unit
);


-- ============================================================
-- Step 3: Load cleaned data from Bronze → Silver
-- ============================================================

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

    -- Keep the original order number.
    sls_ord_num,

    -- Keep the original product key.
    sls_prd_key,

    -- Keep the original customer ID.
    sls_cust_id,


    -- ========================================================
    -- Clean Order Date
    -- ========================================================
    
    CASE 
        -- 0 means there is no valid date.
        -- LEN != 8 means the value is not in YYYYMMDD format.
        WHEN sls_order_dt = 0 
             OR LEN(sls_order_dt) != 8 
            THEN NULL

        -- Convert YYYYMMDD integer/string into a SQL DATE.
        ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
    END AS sls_order_dt,


    -- ========================================================
    -- Clean Ship Date
    -- ========================================================

    CASE 
        -- Invalid date → NULL
        WHEN sls_ship_dt = 0 
             OR LEN(sls_ship_dt) != 8 
            THEN NULL

        -- Convert YYYYMMDD → DATE
        ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
    END AS sls_ship_dt,


    -- ========================================================
    -- Clean Due Date
    -- ========================================================

    CASE 
        -- Invalid date → NULL
        WHEN sls_due_dt = 0 
             OR LEN(sls_due_dt) != 8 
            THEN NULL

        -- Convert YYYYMMDD → DATE
        ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
    END AS sls_due_dt,


    -- ========================================================
    -- Validate / Recalculate Sales
    -- ========================================================

    CASE 
        -- If sales is:
        --   1. NULL
        --   2. <= 0
        --   3. Different from Quantity × Price
        -- then recalculate it.
        
        WHEN sls_sales IS NULL 
             OR sls_sales <= 0 
             OR sls_sales != sls_quantity * ABS(sls_price) 
             
            THEN sls_quantity * ABS(sls_price)

        -- Otherwise, keep the original sales value.
        ELSE sls_sales

    END AS sls_sales,


    -- Keep the original quantity.
    sls_quantity,


    -- ========================================================
    -- Validate / Derive Price
    -- ========================================================

    CASE 
    
        -- If price is NULL or <= 0,
        -- calculate price from:
        --
        -- Sales ÷ Quantity
        --
        -- NULLIF prevents division by zero.
        
        WHEN sls_price IS NULL 
             OR sls_price <= 0 
             
            THEN sls_sales / NULLIF(sls_quantity, 0)

        -- Otherwise, keep the original price.
        ELSE sls_price

    END AS sls_price


-- ============================================================
-- Source Table
-- ============================================================

FROM bronze.crm_sales_details;


-- ============================================================
-- Silver Layer Result
--
-- Bronze:
--     Raw / unclean data
--
--        ↓
--
-- Cleaning & Validation:
--     - Invalid dates → NULL
--     - Invalid sales → recalculated
--     - Invalid price → derived
--
--        ↓
--
-- Silver:
--     Cleaned and standardized sales data
-- ============================================================

 set @end_time = getdate ()  ;   --  time of the end operation
  print '========================================================================='

 
 print '>>>>>>>>>>>> 3 load durtion :  ' + cast (datediff (second , @starte_time ,@end_time  ) as nvarchar ) + 'seconds'
  print '=========================================================================='

--***************************************************---***************************************************************************************************************************

--***************************************************---***************************************************************************************************************************

--***************************************************---***************************************************************************************************************************
--***************************************************---***************************************************************************************************************************
--***************************************************---***************************************************************************************************************************
--***************************************************---***************************************************************************************************************************
--***************************************************---***************************************************************************************************************************
--***************************************************---***************************************************************************************************************************
--***************************************************---***************************************************************************************************************************
print '--------------------------------------------------- '
print '                                                    '
print '>>> truncating table silver 4  . silver.erp_cust_az12'
print '                                                      '
print '>>>-  inserting data into 4 : silver.erp_cust_az12  '

-- ============================================================

set @starte_time = getdate ()  ;   --  time of start operation 

-- Loading Silver Layer table  4   - ERP Customer Information
-- Source: bronze.erp_cust_az12
-- Target: silver.erp_cust_az12
--
-- Purpose:
--   1. Recreate the Silver table
--   2. Standardize Customer IDs
--   3. Validate Birth Dates
--   4. Standardize Gender values
--   5. Prepare the data for integration with CRM customer data
-- ============================================================


-- ============================================================
-- Step 1: Drop the existing Silver table
-- ============================================================

IF OBJECT_ID('silver.erp_cust_az12', 'U') IS NOT NULL 
    DROP TABLE silver.erp_cust_az12;

-- Check whether the Silver table already exists.
-- If it exists, drop it so the table can be recreated
-- with the required structure.


-- ============================================================
-- Step 2: Create the Silver table
-- ============================================================

CREATE TABLE silver.erp_cust_az12 (
    
    CID  VARCHAR(50),  -- Customer ID
    BDATE DATE,        -- Customer birth date
    GEN  VARCHAR(50)   -- Customer gender

);


-- ============================================================
-- Step 3: Insert cleaned data into Silver
-- ============================================================

INSERT INTO silver.erp_cust_az12
(
    CID,
    BDATE,
    GEN
)


SELECT 


    -- ========================================================
    -- Clean Customer ID
    -- ========================================================

    CASE 
    
        -- Some Customer IDs contain the prefix "NAS".
        --
        -- Example:
        --     NAS12345
        --
        -- After removing "NAS":
        --     12345
        --
        -- This transformation makes the ERP Customer ID
        -- consistent with the Customer Key used in the CRM
        -- customer table.

        WHEN CID LIKE 'NAS%' 
            THEN SUBSTRING(CID, 4, LEN(CID))

        -- If the ID does not start with NAS,
        -- keep the original value.

        ELSE CID  

    END AS CID,


    -- ========================================================
    -- Validate Birth Date
    -- ========================================================

    CASE  

        -- A birth date cannot logically be in the future.
        --
        -- GETDATE() returns the current date and time
        -- from the SQL Server.
        --
        -- Therefore, if BDATE is greater than the current
        -- date/time, the value is considered invalid
        -- and replaced with NULL.

        WHEN BDATE > GETDATE() 
            THEN NULL

        -- Otherwise, keep the original birth date.

        ELSE BDATE 

    END AS BDATE,


    -- ========================================================
    -- Standardize Gender
    -- ========================================================

    CASE 


        -- UPPER() converts the value to uppercase.
        -- TRIM() removes unnecessary spaces.
        --
        -- This allows different representations such as:
        --
        --   F
        --   f
        --   Female
        --   female
        --   ' Female '
        --
        -- to be treated as the same gender.

        WHEN UPPER(TRIM(GEN)) IN ('F', 'FEMALE')
            THEN 'Female'


        -- Standardize male values.

        WHEN UPPER(TRIM(GEN)) IN ('M', 'MALE')
            THEN 'Male'


        -- Any unknown, unexpected, or invalid value
        -- is standardized as N/A.

        ELSE 'n/a'


    END AS GEN


-- ============================================================
-- Step 4: Read data from Bronze
-- ============================================================

FROM bronze.erp_cust_az12;


-- ============================================================
-- Silver Layer Result
--
-- Bronze ERP Customer Data
--          |
--          v
-- Standardize Customer ID
--          |
--          v
-- Validate Birth Date
--          |
--          v
-- Standardize Gender
--          |
--          v
-- Silver ERP Customer Data
-- ============================================================

 set @end_time = getdate ()  ;   --  time of the end operation
  print '========================================================================='

 
 print '>>>>>>>>>>>> 4 load durtion :  ' + cast (datediff (second , @starte_time ,@end_time  ) as nvarchar ) + 'seconds'
  print '=========================================================================='

--***************************************************---***************************************************************************************************************************

--***************************************************---***************************************************************************************************************************

--***************************************************---***************************************************************************************************************************
--***************************************************---***************************************************************************************************************************
--***************************************************---***************************************************************************************************************************
--***************************************************---***************************************************************************************************************************
--***************************************************---***************************************************************************************************************************
--***************************************************---***************************************************************************************************************************
--***************************************************---***************************************************************************************************************************
print '--------------------------------------------------- '
print '                                                    '
print '>>> truncating table silver 5 . silver.erp_loc_a101  '
print '                                                      '
print '>>>-  inserting data into 5 : silver.erp_loc_a101   '

-- ============================================================

set @starte_time = getdate ()  ;   --  time of start operation 

-- Loading Silver Layer TABLE 5  - ERP Location Information
-- Source: bronze.erp_loc_a101
-- Target: silver.erp_loc_a101
--
-- Purpose:
--   1. Recreate the Silver location table
--   2. Standardize Customer IDs
--   3. Standardize country names
--   4. Handle missing country values
--   5. Validate the number of loaded records
-- ============================================================


-- ============================================================
-- Step 1: Drop the existing Silver table
-- ============================================================

IF OBJECT_ID('silver.erp_loc_a101', 'U') IS NOT NULL 
    DROP TABLE silver.erp_loc_a101;

-- Check whether the Silver table already exists.
-- If it exists, drop it before recreating it.
--
-- This allows the ETL script to be executed repeatedly
-- without getting a "table already exists" error.


-- ============================================================
-- Step 2: Create the Silver table
-- ============================================================

CREATE TABLE silver.erp_loc_a101 (

    CID   NVARCHAR(50),   -- Customer ID
    CNTRY NVARCHAR(100) ,  -- Customer country
        dwh_create_date DATETIME2 DEFAULT GETDATE()  -- Stores the date and time when the record is created in the Data Warehouse.
);


-- ============================================================
-- Step 3: Insert cleaned data into Silver
-- ============================================================

INSERT INTO silver.erp_loc_a101
(
    CID,
    CNTRY
)


SELECT


    -- ========================================================
    -- Clean Customer ID
    -- ========================================================

    -- Remove '-' characters from the Customer ID.
    --
    -- Example:
    --
    --     123-456-789
    --
    -- becomes:
    --
    --     123456789
    --
    -- This creates a standardized ID format that can be
    -- matched with Customer IDs from other ERP/CRM tables.

    REPLACE(CID, '-', '') AS CID,


    -- ========================================================
    -- Standardize Country
    -- ========================================================

    CASE


        -- Convert the country code DE
        -- into the full country name.

        WHEN TRIM(CNTRY) = 'DE'
            THEN 'Germany'


        -- Both US and USA represent the same country.
        -- Standardize them to one consistent value.

        WHEN TRIM(CNTRY) IN ('US', 'USA')
            THEN 'United States'


        -- If the country is empty or NULL,
        -- replace it with a standard missing-value label.

        WHEN TRIM(CNTRY) = ''
             OR CNTRY IS NULL
            THEN 'n/a'


        -- Keep other country values after removing
        -- unnecessary leading/trailing spaces.

        ELSE TRIM(CNTRY)

    END AS CNTRY


-- ============================================================
-- Step 4: Source Table
-- ============================================================

FROM bronze.erp_loc_a101;


-- ============================================================
-- Step 5: Validate the number of loaded records
-- ============================================================

 set @end_time = getdate ()  ;   --  time of the end operation


  print '========================================================================='

 
 print '>>>>>>>>>>>> 5 load durtion :  ' + cast (datediff (second , @starte_time ,@end_time  ) as nvarchar ) + 'seconds'
  print '=========================================================================='

--***************************************************---***************************************************************************************************************************

--***************************************************---***************************************************************************************************************************
--***************************************************---***************************************************************************************************************************
--***************************************************---***************************************************************************************************************************
--***************************************************---***************************************************************************************************************************
--***************************************************---***************************************************************************************************************************
--***************************************************---***************************************************************************************************************************
--***************************************************---***************************************************************************************************************************
print '--------------------------------------------------- '
print '                                                    '
print '>>> truncating table silver 6 .  silver.erp_px_cat_g1v2 '
print '                                                      '
print '>>>-  inserting data into 6 : silver.erp_px_cat_g1v2   '


set @starte_time = getdate ()  ;   --  time of start operation 

-- Loading Silver Layer table 6  - ERP Product Category Information
-- Source: bronze.erp_px_cat_g1v2
-- Target: silver.erp_px_cat_g1v2
--
-- Purpose:
--   1. Recreate the Silver category table
--   2. Load category data from Bronze
--   3. Add a Data Warehouse creation timestamp
-- ============================================================


-- ============================================================
-- Step 1: Drop the existing Silver table
-- ============================================================

IF OBJECT_ID('silver.erp_px_cat_g1v2', 'U') IS NOT NULL 
    DROP TABLE silver.erp_px_cat_g1v2;

-- Check whether the Silver table already exists.
-- If it exists, drop it before recreating it.
--
-- This allows the ETL script to be executed repeatedly
-- without a "table already exists" error.


-- ============================================================
-- Step 2: Create the Silver table
-- ============================================================

CREATE TABLE silver.erp_px_cat_g1v2 (

    ID          NVARCHAR(50),  -- Category/Product ID
    CAT         NVARCHAR(50),  -- Main category
    SUBCAT      NVARCHAR(50),  -- Sub-category
    MAINTENANCE NVARCHAR(50),  -- Maintenance classification


    -- ========================================================
    -- Data Warehouse Audit Column
    -- ========================================================

    -- Stores the date and time when the record is inserted
    -- into the Data Warehouse.
    --
    -- GETDATE() returns the current date and time from SQL Server.
    --
    -- DEFAULT means:
    -- If no value is provided for this column during INSERT,
    -- SQL Server automatically uses GETDATE().

    dwh_create_date DATETIME2 DEFAULT GETDATE()

);


-- ============================================================
-- Step 3: Load data from Bronze → Silver
-- ============================================================

INSERT INTO silver.erp_px_cat_g1v2
(
    ID,
    CAT,
    SUBCAT,
    MAINTENANCE
)


-- Insert the required business columns from the Bronze table.
--
-- Notice that dwh_create_date is NOT included in the INSERT.
--
-- SQL Server will automatically populate it using:
--
--     DEFAULT GETDATE()
--
-- for every inserted record.

SELECT 
    *
FROM bronze.erp_px_cat_g1v2;


-- ============================================================
-- Silver Layer Result
--
-- Bronze ERP Category Data
--          |
--          v
-- Load category information
--          |
--          v
-- Add Data Warehouse creation timestamp
--          |
--          v
-- Silver ERP Category Data
-- ============================================================

 set @end_time = getdate ()  ;   --  time of the end operation
  print '========================================================================='

 
 print '>>>>>>>>>>>> 6 load durtion :  ' + cast (datediff (second , @starte_time ,@end_time  ) as nvarchar ) + 'seconds'
  print '=========================================================================='





  set @batch_end_time = getdate() ; 

  print '========================================================='

  print 'loading sliver layer is completed ' ;


   print 'total load durtion :  ' + cast (datediff (second , @batch_start_time ,@batch_end_time  ) as nvarchar ) + '  seconds' ; 

   
  print '========================================================='



end try 
begin catch -- catch the erros  
print '============================================'
print 'error message ' + Error_message () ; 

print 'error message '+ cast(error_number() as nvarchar) ; 

print 'error message '+ cast(error_state() as nvarchar) ; 
print '============================================'

end catch 

end 
go
exec silver.load_bronze ;

