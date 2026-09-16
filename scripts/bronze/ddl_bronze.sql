

use DataWarehouse


/* 
============================================================================
DDL Script: Create Bronze Tables
===========================================================



Script Purpose:
This script creates tables in the 'bronze' schema, dropping existing tables
if they already exist.
Run this script to re-define the DDL structure of 'bronze' Tables  

===========================================================================

*/




IF OBJECT_ID ('bronze.crm_cst_info', 'U') IS not null   

-- Check if the table already exists and delete it before recreating it.


drop  table bronze.crm_cst_info ;

CREATE TABLE bronze.crm_cst_info (
    cst_id              INT, 
    cst_key             NVARCHAR(50),
    cst_firstname       NVARCHAR(50),
    cst_lastname        NVARCHAR(50),
    cst_marital_status  NVARCHAR(50),
    cst_gndr            NVARCHAR(50),
    cst_create_date     DATE
) ;
go


IF OBJECT_ID ('bronze.crm_prd_info', 'U') IS not null 
drop  table bronze.crm_prd_info;

-- Check if the table already exists and delete it before recreating it.
CREATE TABLE bronze.crm_prd_info ( 
    prd_id        INT,
    prd_key       NVARCHAR(50),
    prd_nm        NVARCHAR(50),
    prd_cost      int,
    prd_line      NVARCHAR(50),
    prd_start_dt  DATETIME,
    prd_end_dt    DATETIME
);
go

IF OBJECT_ID ('bronze.crm_sales_details', 'U') IS not null 
drop  table bronze.crm_sales_details ;

-- Check if the table already exists and delete it before recreating it.
CREATE TABLE bronze.crm_sales_details (
    sls_ord_num    NVARCHAR(50),
    sls_prd_key    NVARCHAR(50),
    sls_cust_id    INT,
    sls_order_dt   INT,
    sls_ship_dt    INT,
    sls_due_dt     INT,
    sls_sales      INT,
    sls_quantity   INT,
    sls_price      INT 
);
go


/*****************************************************/

IF OBJECT_ID ('bronze.erp_cust_az12', 'U') IS not null 
drop  table bronze.erp_cust_az12 ;
-- Check if the table already exists and delete it before recreating it.

CREATE TABLE bronze.erp_cust_az12 (
    CID  VARCHAR(50),
    BDATE DATE,
    GEN  VARCHAR(50)
);
go

IF OBJECT_ID ('bronze.erp_loc_a101', 'U') IS not null 
drop  table bronze.erp_loc_a101 ;

-- Check if the table already exists and delete it before recreating it.

CREATE TABLE bronze.erp_loc_a101 (
    CID   NVARCHAR(50),
    CNTRY NVARCHAR(100)
);


go 

IF OBJECT_ID ('bronze.erp_px_cat_g1v2', 'U') IS not null 
drop  table bronze.erp_px_cat_g1v2 ;
-- Check if the table already exists and delete it before recreating it.


CREATE TABLE bronze.erp_px_cat_g1v2 (
    ID          NVARCHAR(50),
    CAT         NVARCHAR(50),
    SUBCAT      NVARCHAR(50),
    MAINTENANCE NVARCHAR(50)
); 
