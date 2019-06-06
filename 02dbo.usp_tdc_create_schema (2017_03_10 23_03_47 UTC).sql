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
-- Name: [dbo].[usp_tdc_create_schema]
-- Description:
--	Create the change tracking objects in the current database context.  
-- Parameters: 
--	none
-- Returns: 0 - success
--          1 - Otherwise
CREATE PROCEDURE [dbo].[Usp_tdc_create_schema] @db_name SYSNAME
AS
  BEGIN
      DECLARE @stmt    NVARCHAR(max),
              @retcode INT

      SET NOCOUNT ON

      BEGIN TRY
          -- Create the temporal change data capture schema
          -- will be used for our other objects
          SET @stmt =Ncreate schema [tdc] authorization [tdc]

          EXEC (@stmt)

          -- also create the History schema for the history tables
          SET @stmt =Ncreate schema [ + @db_name
                     + _tdc_history] authorization [tdc]

          EXEC (@stmt)

          RETURN 0
      END TRY
      BEGIN CATCH
          RETURN 1
      END CATCH
  END 
