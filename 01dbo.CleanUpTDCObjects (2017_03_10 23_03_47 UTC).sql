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

-- This script will install all of the objects necessary for Temporal Data Capture (TDC)
-- Since there is no msdb in which to create the objects, the script must be run in each 
-- database in which TDC will be used

-- Two schemas are created - tdc (used for TDC code) and history (where the temporal portion of tables will reside)
-- Additionally I create a tdc user and set them as the owner of the tdc schema

-- Once the database has been enabled for TDC (excuting this script also performs that action) you must also
-- enable the individual tables by executing exec [tdc].[tdc_enable_table] <schema>, <table>, 0 the 0 indicates SQL Database.

-- this can also be deployed on premise by passing a 1. This installs three messages in sys.messages for use by TDC.
-- one benifit this could bring would be to use TDC on premise but stretch the history table to Azure.
DROP PROCEDURE IF EXISTS [dbo].[usp_tdc_enable_db];
DROP PROCEDURE IF EXISTS [dbo].[usp_tdc_create_schema];
DROP FUNCTION IF EXISTS [dbo].[ufn_is_db_tdc_enabled];
DROP FUNCTION IF EXISTS [dbo].[ufn_tdc_objects_exist];
DROP PROCEDURE IF EXISTS [tdc].[usp_tdc_enable_table];
DROP PROCEDURE IF EXISTS [tdc].[usp_tdc_disable_table];
DROP PROCEDURE IF EXISTS [tdc].[usp_CanTableBeTDC_Enabled] ;
DROP PROCEDURE IF EXISTS [tdc].[usp_GetColumnInfo];
DROP PROCEDURE IF EXISTS [tdc].[usp_GetJoinInfo];
DROP PROCEDURE IF EXISTS [tdc].[usp_tdc_enable_table_internal];
DROP FUNCTION IF EXISTS [tdc].[ufn_ColumnType];
DROP TABLE IF EXISTS [tdc].[Version];
DROP SCHEMA

IF EXISTS [tdc];
DECLARE @schemaName SYSNAME = REPLACE(DB_NAME(),'-','_') + _tdc_history
DECLARE @dropstmt NVARCHAR(255) = NDROP SCHEMA IF EXISTS  + @schemaName

EXEC (@dropstmt)

DROP USER IF EXISTS [tdc];
DROP PROCEDURE IF EXISTS [dbo].[usp_tdc_disable_db];
