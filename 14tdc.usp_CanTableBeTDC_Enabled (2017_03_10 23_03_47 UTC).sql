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
-- this procedure is used by the TDC Wizard UI
CREATE PROCEDURE [tdc].[Usp_cantablebetdc_enabled] (@table_schema SYSNAME,
                                                    @table_name   SYSNAME,
                                                    @is_eligible  BIT OUTPUT,
                                                    @msg          NVARCHAR(4000) OUTPUT)
AS
  BEGIN
      -- Has Primary Key
      DECLARE @index_name       SYSNAME,
              @source_table     NVARCHAR(4000),
              @source_object_id INT,
              @column_name      SYSNAME,
              @column_count     INT =0,
              @column_number    INT = 0,
              @error_count      INT = 0

      SET @table_name = Rtrim(@table_name)
      SET @table_schema = Rtrim(@table_schema)

      SELECT @source_table = Quotename(@table_schema) + N.
                             + Quotename(@table_name)

      SELECT @source_object_id = Object_id(@source_table)

      SELECT @index_name = i.NAME
      FROM   [sys].[indexes] i
      WHERE  i.object_id = @source_object_id
             AND i.is_primary_key = 1

      SET @msg = NThe following errors were found which will prevent enabling 
                 + @source_table +  for TDC.

      SELECT @is_eligible = 1

      IF ( @index_name IS NULL )
        BEGIN
            SET @is_eligible = 0
            SET @error_count += 1
            SET @msg += Cast(@error_count AS NVARCHAR(2)) + . 
            SET @msg += TDC requires the table to have a primary key defined. Table 
                        + @source_table
                        +  does not have a primary key.
            SET @msg += Please define a primary key and retry the operation.
        END

      -- No ineligible datatypes
      IF( EXISTS (SELECT 1
                  FROM   INFORMATION_SCHEMA.COLUMNS c
                  WHERE  c.TABLE_SCHEMA = @table_schema
                         AND c.TABLE_NAME = @table_name
                         AND c.DATA_TYPE IN ( xml, geography, geometry )) )
        BEGIN
            SET @is_eligible = 0
            SET @error_count += 1
            SET @msg += Cast(@error_count AS NVARCHAR(2)) + . 
            SET @msg += TDC does not support the xml, geometry, or geography data types. Perhaps you can try vertically partitioning the table to remove those columns.
        END
  -- not already a temporal table??? maybe this is ok would skip that processing
  -- and just create the two functions
  END 
