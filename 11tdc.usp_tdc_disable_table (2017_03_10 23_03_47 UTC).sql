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
--this procedure does the work of undoing all the work accomplished in tdc_enable_table_internal
CREATE PROCEDURE [tdc].[Usp_tdc_disable_table](@source_schema  SYSNAME,
                                               @source_name    SYSNAME,
                                               @remove_history BIT =0,
                                               @debug          BIT = 0)
AS
  BEGIN
      SET NOCOUNT ON

      DECLARE @stmt         NVARCHAR(MAX),
              @dropStmt     NVARCHAR(MAX),
              @source_table SYSNAME

      SET @source_schema = Rtrim(@source_schema)
      SET @source_name = Rtrim(@source_name)

      SELECT @source_table = Quotename(@source_schema) + N.
                             + Quotename(@source_name)

      IF EXISTS(SELECT Object_id(@source_table)
                FROM   sys.tables
                WHERE  object_id IS NOT NULL
                       AND temporal_type = 2)
        BEGIN
            SET @stmt = NALTER TABLE  + @source_table
                        + N set (system_versioning = off);
		  ALTER TABLE  + @source_table
                        + N DROP PERIOD FOR SYSTEM_TIME;

            IF( @debug = 1 )
              BEGIN
                  PRINT @stmt

                  SET @dropStmt = Ndrop function if exists [tdc].[
                                  + @source_name
                                  + _AllChanges];
			  drop function if exists [tdc].[
                                  + @source_name + _NetChanges];

                  PRINT @dropStmt
              END
            ELSE
              BEGIN
                  EXEC (@stmt)

                  SET @dropStmt = Ndrop function if exists [tdc].[
                                  + @source_name
                                  + _AllChanges];
			  drop function if exists [tdc].[
                                  + @source_name + _NetChanges];

                  EXEC (@dropStmt)
              END

            IF( @remove_history = 1 )
              BEGIN
                  SET @stmt = Ndrop table  + Db_name() + _tdc_history.
                              + @source_name + N;
                  SET @stmt = @stmt + NDROP INDEX tdc_ + @source_name
                              + N ON  + @source_table + N;
			ALTER TABLE 
                              + @source_table
                              +  DROP CONSTRAINT DF_SysStart_
                              + @source_name + ;
			ALTER TABLE 
                              + @source_table
                              +  DROP CONSTRAINT DF_SysEndTime
                              + @source_name + ;
			ALTER TABLE 
                              + @source_table +  DROP COLUMN SysStartTime;
			ALTER TABLE 
                              + @source_table +  DROP COLUMN SysEndTime;
              END

            IF( @debug = 1 )
              BEGIN
                  PRINT @stmt
              END
            ELSE
              BEGIN
                  EXEC (@stmt)
              END
        END
      ELSE
        BEGIN
            RAISERROR ( NCould not disable TDC for table %s, TDC is not enabled for table %s,16,1)
        END
  END 
