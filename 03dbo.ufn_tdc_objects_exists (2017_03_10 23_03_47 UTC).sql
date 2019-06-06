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
-- Name: [dbo].[ufn_tdc_objects_exist]
-- Description:
--	checks to see if our tdc objects exist in the current database context.  
-- Parameters: 
--	none
-- Returns: 0 - success
--          1 - error
CREATE FUNCTION [dbo].[Ufn_tdc_objects_exist]()
RETURNS BIT
AS
  BEGIN
      DECLARE @schema_name SYSNAME,
              @db_user     SYSNAME

      -- Check if the schema already exists
      SELECT @schema_name = NAME
      FROM   [sys].[schemas]
      WHERE  NAME = Ntdc

      IF ( @schema_name IS NOT NULL )
        BEGIN
            RETURN 1
        END

      -- Check if a user of the same name already exists
      SELECT @db_user = NAME
      FROM   [sys].[database_principals]
      WHERE  type_desc = NSQL_USER
             AND NAME = Ntdc

      IF ( @db_user IS NOT NULL )
        BEGIN
            RETURN 1
        END

      RETURN 0
  END 
