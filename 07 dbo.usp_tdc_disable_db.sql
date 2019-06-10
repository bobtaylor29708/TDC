/*
This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.  
THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  
We grant You a nonexclusive, royalty-free right to use and modify the 
Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; 
(ii) to include a valid copyright notice on Your software product in which the Sample Code is 
embedded; and 
(iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
Please note: None of the conditions outlined in the disclaimer above will supercede the terms and conditions contained within the Premier Customer Services Description.
*/
-- clean up TDC completely
CREATE PROCEDURE [dbo].[usp_tdc_disable_db]
AS
BEGIN
	IF(EXISTS (SELECT 1 FROM sys.objects WHERE type = 'TF' AND PATINDEX('%_AllChanges%',name) > 0))
	BEGIN
		SELECT SUBSTRING(name,1,PATINDEX('%_AllChanges%',name)-1) as table_name
			INTO #table_names
		FROM sys.objects 
		WHERE type = 'TF' AND PATINDEX('%_AllChanges%',name) > 0
		DECLARE @stmt nvarchar(4000) = 
			N'There are still tables that have TDC enabled. Please disable TDC for each of the following tables '
		SELECT @stmt += table_name +', '
			FROM #table_names 
		SET @stmt = SUBSTRING(@stmt,1,LEN(@stmt)-1)+ '.' + CHAR(13)
		SET @stmt += CHAR(13) + CHAR(9)
		SET @stmt += N'Usage: EXEC tdc.usp_tdc_disable_table <schema>,<tablename>,1'
		RAISERROR (@stmt,16,-1)
		RETURN
	END
	ELSE
	BEGIN
		DROP PROCEDURE IF EXISTS [dbo].[usp_tdc_enable_db];
		DROP PROCEDURE IF EXISTS [dbo].[usp_tdc_create_schema];
		DROP FUNCTION  IF EXISTS [dbo].[ufn_is_db_tdc_enabled];
		DROP FUNCTION  IF EXISTS [dbo].[ufn_tdc_objects_exist];
		DROP PROCEDURE IF EXISTS [tdc].[usp_tdc_enable_table];
		DROP PROCEDURE IF EXISTS [tdc].[usp_tdc_disable_table];
		DROP PROCEDURE IF EXISTS [tdc].[usp_CanTableBeTDC_Enabled] ;
		DROP PROCEDURE IF EXISTS [tdc].[usp_GetColumnInfo];
		DROP PROCEDURE IF EXISTS [tdc].[usp_GetJoinInfo];
		DROP PROCEDURE IF EXISTS [tdc].[usp_tdc_enable_table_internal];
		DROP FUNCTION  IF EXISTS [tdc].[ufn_ColumnType];
		DROP TABLE IF EXISTS [tdc].[Version];
		DROP SCHEMA IF EXISTS [tdc];
		DECLARE @schemaName sysname = REPLACE(DB_NAME(),'-','_')+'_tdc_history'
		DECLARE @dropstmt nvarchar(255) = N'DROP SCHEMA IF EXISTS '+@schemaName
		EXEC (@dropstmt)
		DROP USER IF EXISTS [tdc];
		DROP PROCEDURE IF EXISTS [dbo].[usp_tdc_disable_db];	
	END
END



