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
--this procedure does the bulk of the work. It creates the temporal columns and metadata
-- and then writes the two functions _AllChanges and _NetChanges for the specified table
CREATE PROCEDURE [tdc].[Usp_tdc_enable_table_internal] (@source_schema SYSNAME,
                                                        @source_name   SYSNAME,
                                                        @primary_key   NVARCHAR(255),
                                                        @debug         BIT = 0)
AS
    DECLARE @source_table     SYSNAME,
            @index_name       SYSNAME,
            @source_object_id INT

    SELECT @source_table = Quotename(@source_schema) + N'.'
                           + Quotename(@source_name)

    SELECT @source_object_id = Object_id(@source_table)

    --if the temporal columns are already there, don't add them again
    IF NOT EXISTS(SELECT *
                  FROM   sys.tables t
                         JOIN sys.columns c
                           ON t.object_id = c.object_id
                  WHERE  c.object_id = @source_object_id
                         AND c.generated_always_type IN ( 1, 2 ))
      BEGIN
          -- create an alter table statement that adds the two tracking columns, provides default values for them
          -- and establishes the period for system time
          DECLARE @stmt NVARCHAR(max)

          SET @stmt = N'ALTER TABLE ' + @source_schema + '.'
                      + @source_name + N'   ADD 
			SysStartTime datetime2(0) GENERATED ALWAYS AS ROW START HIDDEN
				CONSTRAINT DF_SysStart_'
                      + @source_name
                      + ' DEFAULT GETDATE()
			  , SysEndTime datetime2(0) GENERATED ALWAYS AS ROW END HIDDEN  
				CONSTRAINT DF_SysEndTime'
                      + @source_name
                      + ' DEFAULT CONVERT(datetime2 (0), ''9999-12-31 23:59:59'')
			  ,PERIOD FOR SYSTEM_TIME (SysStartTime, SysEndTime);';

          IF( @debug = 1 )
            PRINT @stmt
          ELSE
            EXEC (@stmt)
      END

    -- the columns were there, have we started history collection yet?
    IF EXISTS(SELECT *
              FROM   sys.tables t
              WHERE  object_id = @source_object_id
                     AND temporal_type = 0)
      IF @debug = 1
        BEGIN
            SELECT *
            FROM   sys.tables t
            WHERE  object_id = @source_object_id
        END

  BEGIN
      SET @stmt = N'ALTER TABLE ' + @source_schema + '.'
                  + @source_name
                  + ' SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = '
                  + REPLACE(DB_NAME(),'-','_') + '_tdc_history.' + @source_name
                  + '));'

      IF( @debug = 1 )
        PRINT @stmt
      ELSE
        EXEC (@stmt)
  END

    -- let's make sure we index for performance for the change functions
    SET @index_name = 'tdc_' + @source_name

    IF NOT EXISTS(SELECT 1
                  FROM   sys.indexes
                  WHERE  NAME = @index_name)
      BEGIN
          SET @stmt = N'CREATE UNIQUE NONCLUSTERED INDEX tdc_'
                      + @source_name + N' ON ' + + @source_schema + '.'
                      + @source_name + N'(SysStartTime,SysEndTime,'
                      + Substring(@primary_key, 1, Len(@primary_key)-1)
                      + N');'

          IF( @debug = 1 )
            PRINT @stmt
          ELSE
            EXEC (@stmt)
      END 
