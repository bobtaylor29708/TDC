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
-- Name: [dbo].[usp_tdc_enable_db]
-- Description:
-- Enable change tracking for the current database.  
-- Parameters: 
--	@on_prem bit determines if we are on premise. If so, then we add messages to sys.messages
-- Returns: 0 - success
--          1 - Otherwise
CREATE PROCEDURE [dbo].[Usp_tdc_enable_db]
AS
  BEGIN
      DECLARE @retcode INT,
              @stmt    NVARCHAR(1000),
              @db_name SYSNAME,
              @action  NVARCHAR(1000),
              @db_id   INT,
              @msg     NVARCHAR(2048)

      SET @db_id = Db_id()
      SET nocount ON
      SET @db_name = REPLACE(DB_NAME(),'-','_')

      IF( @db_name = N'model'
           OR @db_name = N'msdb'
           OR @db_name = N'master'
           OR @db_name = N'tempdb' )
        BEGIN
            RAISERROR ( N'Could not enable TDC for database %s. TDC capture is not supported on system databases, or on a distribution database.',16,-1,@db_name)

            RETURN 1
        END

      -- Verify database is not already enabled for temporal data capture
      IF ( dbo.[Ufn_is_db_tdc_enabled]() = 1 )
        BEGIN
            -- Raise an informational error only  
            RAISERROR(N'Database %s is already enabled for TDC. Ensure that the correct database context is set.',16,1,@db_name)

            RETURN 0
        END

      -- Verify that the reserved 'tdc' database user and login do not already exist.
      IF ( dbo.[Ufn_tdc_objects_exist]() != 0 )
        BEGIN
            -- If the database has since become enabled, only raise informational error
            IF ( dbo.[Ufn_is_db_tdc_enabled]() = 1 )
              BEGIN
                  -- Raise an informational error only    
                  RAISERROR (N'Database %s is already enabled for TDC. Ensure that the correct database context is set.',16,1,@db_name)

                  RETURN 0
              END

            RAISERROR (N'The database %s cannot be enabled for TDC because a database user named ''tdc'' or a schema named ''tdc'' already exists in the current database. These objects are required exclusively by TDC. Drop or rename the user or schema and retry the operation.',16,1,@db_name)

            RETURN 1
        END

      -- create a user that will be tied to our tdc schema
      CREATE USER [tdc] WITHOUT LOGIN WITH DEFAULT_SCHEMA = [tdc];

      -- now create the schema tdc for our objects and for the _AllChanges _NetChanges functions will we create when they enable a table
      EXEC dbo.[Usp_tdc_create_schema]
        @db_name

      -- Make 'tdc' user member of 'db_owner' for database
      EXEC Sp_addrolemember
        'db_owner',
        'tdc'

      -- record the version. This wizard will examine this to see if the components need to be updated.
      CREATE TABLE [tdc].[Version]
        (
           tdc_version NVARCHAR(15) NOT NULL,
           notes       NVARCHAR(4000)
        );

      INSERT INTO [tdc].[Version]
                  (tdc_version,
                   notes)
      VALUES      ('1.0.0.0',
                   'Initial Code Release');

      RETURN 0
  END 
