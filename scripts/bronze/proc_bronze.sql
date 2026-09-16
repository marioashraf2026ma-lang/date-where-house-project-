
use DataWarehouse ;


/*
Stored Procedure: Load Bronze Layer (Source -> Bronze)

Script Purpose:
This stored procedure loads data into the 'bronze' schema from external CSV files.
It performs the following actions:
- Truncates the bronze tables before loading data.
- Uses the 'BULK INSERT' command to load data from csv Files to bronze tables.

Parameters:
None.
This stored procedure does not accept any parameters or return any values.

Usage Example:
EXEC bronze. load_bronze;



*/



go 

create or alter procedure bronze.load_bronze  /* like an function to easy to creat*/ 
as 
 
 declare @starte_time datetime , @end_time datetime ,  -- declare variables for save
 @batch_start_time datetime ,  @batch_end_time datetime  ; --   Calculate the Duration of Loading  total Bronze Layer Whole Batch

begin 

 begin try   -- find the erros 

 set @batch_start_time = getdate() ;  


print ' ==========================================  '
print '****************************'
print ' loading bronze layer '
print '****************************'


print '======================================='
print 'loading crm tables '
print '======================================='


print '>> truncating table bronze.crm_cst_info  '

set @starte_time = getdate ()  ;   --  time of start operation 


truncate table   bronze.crm_cst_info ;
-- make the table empty 

print '>> inserting data into :bronze.crm_cst_info  '

bulk insert bronze.crm_cst_info 
from 'C:\Users\Mario\Downloads\sql-data-warehouse-project-main\sql-data-warehouse-project-main\datasets\source_crm\cust_info.csv'

with (  firstrow = 2,    /* the row number */
fieldterminator = ',' ,
tablock  /*lock the table */
); 
 
 set @end_time = getdate ()  ;   --  time of the end operation

 print '========================================================================='

  print '=========================================================================='
  
/******************************************************************************************************************/


set @starte_time = getdate ()  ;   --  time of start operation 


print '>> inserting data into :bronze.crm_prd_info  '
truncate table   bronze.crm_prd_info ; /*make the table empty*/  
print '>> inserting data into :bronze.crm_prd_info  '
bulk insert bronze.crm_prd_info 
from 'C:\Users\Mario\Downloads\sql-data-warehouse-project-main\sql-data-warehouse-project-main\datasets\source_crm\prd_info.csv'
with (  firstrow = 2 ,    /* the row number */
fieldterminator = ',' ,
tablock  /*lock the table */
); 

 set @end_time = getdate ()  ;   --  time of the end operation

 print '========================================================================='

 print '>>>>>>>>>>>>  2 load durtion :  ' + cast (datediff (second , @starte_time ,@end_time  ) as nvarchar ) + 'seconds'
 print '=========================================================================='

/******************************************************************************************************************/
 

 set @starte_time = getdate ()  ;   --  time of start operation 


 print '>> truncating table  bronze.crm_sales_details  '

truncate table  bronze.crm_sales_details ; /*make the table empty*/  
print '>> inserting data into :bronze.crm_sales_details  '

bulk insert bronze.crm_sales_details 
from 'C:\Users\Mario\Downloads\sql-data-warehouse-project-main\sql-data-warehouse-project-main\datasets\source_crm\sales_details.csv'
with (  firstrow = 2 ,    /* the row number */
fieldterminator = ',' ,
tablock  /*lock the table */
); 

 set @end_time = getdate ()  ;   --  time of the end operation

 print '========================================================================='

 print '>>>>>>>>>>>> 3 load durtion :  ' + cast (datediff (second , @starte_time ,@end_time  ) as nvarchar ) + 'seconds' ;
 print '=========================================================================='



/******************************************************************************************************************/

print '------------------------------------------'

print 'loading erp tables '

print '------------------------------------------'


set @starte_time = getdate ()  ;   --  time of start operation 



print '>> truncating table bronze.erp_cust_az12  '

truncate table  bronze.erp_cust_az12  ; /*make the table empty*/  

print '>> inserting data into :bronze.erp_cust_az12  '

bulk insert bronze.erp_cust_az12 
from 'C:\Users\Mario\Desktop\sql-data-warehouse-project-main\datasets\source_erp\CUST_AZ12.csv'
with (  firstrow = 2 ,    /* the row number */
fieldterminator = ',' ,
tablock  /*lock the table */
); 



 set @end_time = getdate ()  ;   --  time of the end operation

 print '========================================================================='

 print '>>>>>>>>>>>>  4 load durtion :  ' + cast (datediff (second , @starte_time ,@end_time  ) as nvarchar ) + 'seconds'
 print '=========================================================================='

/******************************************************************************************************************/

set @starte_time = getdate ()  ;   --  time of start operation 


print '>> truncating table bronze.erp_loc_a101 '

truncate table bronze.erp_loc_a101 ; /*make the table empty*/  

print '>> inserting data into :bronze.erp_loc_a101   '

bulk insert bronze.erp_loc_a101  
from 'C:\Users\Mario\Desktop\sql-data-warehouse-project-main\datasets\source_erp\LOC_A101.csv'
with (  firstrow = 2 ,    /* the row number */
fieldterminator = ',' ,
tablock  /*lock the table */
); 



 set @end_time = getdate ()  ;   --  time of the end operation

 print '========================================================================='

 print '>>>>>>>>>>>> 5 load durtion :  ' + cast (datediff (second , @starte_time ,@end_time  ) as nvarchar ) + 'seconds'
 print '=========================================================================='
/******************************************************************************************************************/



set @starte_time = getdate ()  ;   --  time of start operation 


print '>> truncating table bronze.erp_px_cat_g1v2  '  

truncate table bronze.erp_px_cat_g1v2 ; /*make the table empty*/  

print '>> inserting data into :bronze.erp_px_cat_g1v2 '


bulk insert bronze.erp_px_cat_g1v2
from 'C:\Users\Mario\Desktop\sql-data-warehouse-project-main\datasets\source_erp\PX_CAT_G1V2.csv'
with (  firstrow = 2 ,    /* the row number */
fieldterminator = ',' ,
tablock  /*lock the table */
); 


 set @end_time = getdate ()  ;   --  time of the end operation

 print '========================================================================='

 print '>>>>>>>>>>>> 6 load durtion :  ' + cast (datediff (second , @starte_time ,@end_time  ) as nvarchar ) + 'seconds'
 print '=========================================================================='

  set @batch_end_time = getdate() ; 

  print '========================================================='

  print 'loading Bronze layer is completed ' ;


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













