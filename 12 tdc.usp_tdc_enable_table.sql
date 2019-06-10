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
-- this is the main entry point where do all of the function creation etc.
CREATE PROCEDURE [tdc].[Usp_tdc_enable_table](@source_schema SYSNAME,
                                              @source_name   SYSNAME,
                                              @debug         BIT =0)
AS
  BEGIN
      SET NOCOUNT ON

      DECLARE @stmt                        NVARCHAR(MAX),
              @stmtNet                     NVARCHAR(MAX),
              @stmtAll                     NVARCHAR(MAX),
              @dropStmt                    NVARCHAR(MAX),
              @column_list_with_datatypes  NVARCHAR(MAX) = N'',
              @column_list                 NVARCHAR(MAX) = N'',
              @column_list_with_alias      NVARCHAR(MAX) = N'',
              @source_table                SYSNAME,
              @primary_key_list            NVARCHAR(MAX) = N'',
              @primary_key_list_with_alias NVARCHAR(MAX) = N'',
              @join_list                   NVARCHAR(MAX) =N''

      SET @source_schema = Rtrim(@source_schema)
      SET @source_name = Rtrim(@source_name)

      SELECT @source_table = Quotename(@source_schema) + N'.'
                             + Quotename(@source_name)

      EXEC tdc.Usp_getcolumninfo
        @source_schema,
        @source_name,
        @column_list_with_datatypes output,
        @column_list OUTPUT,
        @column_list_with_alias OUTPUT

      -- let's examine the columns to see if there are any unsupported datatypes. Column set is not support for temporal
      -- and spatial is not supported by UNION which we use in our get changes functions.
      IF ( Patindex('%geometry%', @column_list_with_datatypes) > 0
            OR Patindex('%geography%', @column_list_with_datatypes) > 0
            OR Patindex('%COLUMN_SET%', @column_list_with_datatypes) > 0
            OR Patindex('%xml%', @column_list_with_datatypes) > 0 )
        BEGIN
            RAISERROR ('Unsupported datatype detected. Spatial datatypes (geography and geometry), xml and column sets are not supported with TDC.',16,-1);

            RETURN 1
        END

      IF ( Patindex('%SPARSE%', @column_list_with_datatypes) > 0 )
        BEGIN
            RAISERROR ('Warning: The use of SPARSE columns will prevent PAGE compression of the history table.',16,1);
        END

      EXEC tdc.Usp_getjoininfo
        @source_schema,
        @source_name,
        @primary_key_list output,
        @join_list OUTPUT,
        @primary_key_list_with_alias OUTPUT

      SET @column_list_with_datatypes = @column_list_with_datatypes + Char(13)
                                        + Char(9) + N'[Status] nvarchar(10) NOT NULL'

      DECLARE @history_table SYSNAME = REPLACE(DB_NAME(),'-','_') + N'_tdc_history.' + @source_name

      EXEC tdc.Usp_tdc_enable_table_internal
        @source_schema,
        @source_name,
        @primary_key_list

      SET @dropStmt = N'drop function if exists [tdc].['
                      + @source_name + '_AllChanges];'

      EXEC (@dropStmt)

      SET @dropStmt = N'drop function if exists [tdc].['
                      + @source_name + '_NetChanges];'

      EXEC (@dropStmt)

      -- both netchanges and allchanges are very similar, so we just capture the differences
      SET @stmtNet = N'CREATE FUNCTION [tdc].[' + @source_name
                     + '_NetChanges](@Period datetime2)'
      SET @stmtAll = N'CREATE FUNCTION [tdc].[' + @source_name
                     + '_AllChanges](@Period datetime2)'
      SET @stmt = Char(13)
                  + N'RETURNS @changes TABLE 
	(
		-- columns returned by the function'
      SET @stmt= @stmt + @column_list_with_datatypes
      SET @stmt= @stmt + Char(13) + N')
		WITH SCHEMABINDING
		AS
		-- body of the function
		BEGIN
		DECLARE @Now datetime2 = sysutcdatetime();
		-- must examine current and history table to get net changes
		;with CurrentPeriod ('
      SET @stmt = @stmt + @primary_key_list
      SET @stmt = @stmt + Char(13) + Char(9) + N'SysStartTime,'
                  + Char(13) + Char(9) + N'SysEndTime,' + Char(13)
                  + Char(9) + N'IsCurrent)
		AS
		(
			SELECT '
      SET @stmt = @stmt + @primary_key_list
      SET @stmt = @stmt + N'SysStartTime ' + Char(13) + Char(9)
                  + N',SysEndTime ' + Char(13) + Char(9) + N',IIF (YEAR(SysEndTime) = 9999, 1, 0) AS IsCurrent
		from '
                  + @source_table
                  + '
		FOR SYSTEM_TIME BETWEEN @Period AND ''9999-12-31'')'
                  + Char(13)
      SET @stmt = @stmt + N',AsOfNow('
      SET @stmt = @stmt + @primary_key_list + Char(13) + Char(9)
      SET @stmt = @stmt + N'StartTime, ' + Char(13) + Char(9)
                  + N'EndTime, ' + Char(13) + Char(9) + N'Status, '
                  + Char(13) + Char(9) + N'IsCurrent) 
		AS 
		(
			select '
      SET @stmt = @stmt + @primary_key_list_with_alias
      SET @stmt = @stmt + Char(13) + Char(9) + N't.SysStartTime, '
                  + N't.SysEndTime ' + Char(13) + Char(9)
                  + '
			,CASE WHEN (t.SysStartTime = a.SysStartTime)  THEN ''INSERT'' ELSE
			CASE WHEN (YEAR(a.SysEndTime) = 9999 and YEAR(t.SysEndTime) != 9999)  THEN ''UDPATE'' ELSE 
			CASE WHEN (a.SysEndTime IS NULL and YEAR(t.SysEndTime) != 9999)  THEN ''DELETE'' 
				END 
			END
		END AS status
		,IsCurrent
		FROM CurrentPeriod AS t
		left outer join '
      SET @stmt = @stmt + @source_table
      SET @stmt = @stmt
                  + N' FOR SYSTEM_TIME AS OF @now AS a ON '
      SET @stmt = @stmt + @join_list
      SET @stmt = @stmt + N')' + Char(13)
      SET @stmt = @stmt + N'insert @changes
			select '
      SET @stmt = @stmt + @column_list_with_alias
      SET @stmt = @stmt + N' a.Status FROM '
      SET @stmt = @stmt + @source_table
      SET @stmt = @stmt + N' t JOIN AsOfNow a ON '
      SET @stmt = @stmt + @join_list
      SET @stmt = @stmt
                  + N' WHERE (t.SysStartTime >= @Period AND IsCurrent =1)'
                  + Char(13) + 'UNION' + Char(13) + 'SELECT '
      SET @stmt = @stmt + @column_list_with_alias
      SET @stmt = @stmt + N' a.Status from '
      SET @stmt = @stmt + @History_table
      SET @stmt = @stmt + N' t join AsOfNow a on '
      SET @stmt = @stmt + @join_list
      SET @stmt = @stmt
                  + N' AND t.SysStartTime = a.StartTime '
      SET @stmtNet += @stmt + 'AND a.Status = ''DELETE'' '
      SET @stmtAll += @stmt
      -- NOTE: Had issues with using column name from UNION. Would not work reliably
      SET @stmtNet += Char(13) + N'order by 1 desc; RETURN
		END'
      -- NOTE: Had issues with using column name from UNION. Would not work reliably
      SET @stmtAll += Char(13) + N'order by 1 desc; RETURN
		END'

      IF( @debug = 1 )
        BEGIN
            PRINT @stmtNet

            PRINT @stmtAll
        END
      ELSE
        BEGIN
            EXEC (@stmtNet)

            EXEC (@stmtAll)
        END

      SET @stmt = N'GRANT SELECT ON ' + N'[tdc].['
                  + @source_name + '_NetChanges] TO [public]'

      EXEC (@stmt)

      SET @stmt = N'GRANT SELECT ON ' + N'[tdc].['
                  + @source_name + '_AllChanges] TO [public]'

      EXEC (@stmt)
  END 
