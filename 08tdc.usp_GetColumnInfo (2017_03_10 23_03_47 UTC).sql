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
-- this procedure will create the column lists needed by [tdc].[create_netchanges_function] and [tdc].[create_allchanges_function] 
-- since this is heavy - i.e. uses cursors we call once and get all of our lists back for use in the create functions
CREATE PROCEDURE [tdc].[Usp_getcolumninfo] (@source_schema              SYSNAME,
                                            @source_name                SYSNAME,
                                            @column_list_with_datatypes NVARCHAR(max) OUTPUT,
                                            @column_list                NVARCHAR(max) OUTPUT,
                                            @column_list_with_alias     NVARCHAR(max) OUTPUT)
AS
  BEGIN
      DECLARE @source_object_id INT,
              @column_count     INT,
              @is_sparse        BIT,
              @masking_function NVARCHAR(4000) -- need to support masking functions so we dont open any security holes
              ,
              @column_name      SYSNAME,
              @column_id        INT,
              @collation_name   SYSNAME
      DECLARE @source_table SYSNAME

      SELECT @source_table = Quotename(@source_schema) + N.
                             + Quotename(@source_name)

      SET @source_object_id = Object_id(@source_table)

      -- save the columns so we can easily iterate over them
      CREATE TABLE #captured_columns
        (
           column_name      SYSNAME NULL,
           column_type      SYSNAME NULL,
           is_computed      BIT NULL,
           masking_function NVARCHAR(4000) COLLATE Latin1_General_CI_AS_KS_WS NULL
        )

      BEGIN
          -- Insert all of the table columns into #captured_columns
          INSERT INTO #captured_columns
          SELECT c.NAME,
                 Isnull(Type_name(c.system_type_id), Type_name(c.user_type_id)),
                 c.is_computed,
                 m.masking_function
          FROM   [sys].[columns] c
                 LEFT JOIN [sys].[masked_columns] m
                        ON c.object_id = m.object_id
                           AND c.column_id = m.column_id
          WHERE  c.object_id = @source_object_id
          ORDER  BY c.column_id
      END

      DECLARE #hcolumns CURSOR LOCAL FAST_FORWARD FOR
        SELECT c.NAME,
               c.column_id,
               c.collation_name,
               c.is_sparse,
               i.masking_function
        FROM   [sys].[columns] c
               INNER JOIN #captured_columns i
                       ON c.NAME COLLATE database_default = i.column_name COLLATE database_default
        WHERE  c.object_id = @source_object_id
        ORDER  BY column_id

      OPEN #hcolumns

      FETCH #hcolumns INTO @column_name,
                           @column_id,
                           @collation_name,
                           @is_sparse,
                           @masking_function

      SET @column_count = 0

      WHILE ( @@FETCH_STATUS <> -1 )
        BEGIN
            SET @column_count = @column_count + 1
            SET @column_list_with_datatypes = @column_list_with_datatypes + Char(13)
                                              + Char(9) + Quotename(@column_name) + N 
                                              + tdc.Ufn_columntype( @source_schema, @source_name, @column_id)
                                              + CASE ( Isnull(@collation_name, ) )
                                                  WHEN N THEN N
                                                  ELSE N COLLATE  + @collation_name
                                                END

            IF( @is_sparse = 1 )
              BEGIN
                  SET @column_list_with_datatypes = @column_list_with_datatypes + N SPARSE 
              END

            -- while we are here lets build the column list
            SET @column_list += @column_name
            -- and the aliased version too
            SET @column_list_with_alias += t. + @column_name

            -- we want to preserve masking if it is present so we dont open any security vunerabilities
            IF ( @masking_function IS NOT NULL )
              BEGIN
                  SET @column_list_with_datatypes = @column_list_with_datatypes
                                                    + N MASKED WITH (FUNCTION = 
                                                    + @masking_function + N)
              END

            SET @column_list_with_datatypes +=N, 
            SET @column_list += N, 
            SET @column_list_with_alias += N, 

            FETCH #hcolumns INTO @column_name,
                                 @column_id,
                                 @collation_name,
                                 @is_sparse,
                                 @masking_function
        END

      CLOSE #hcolumns

      DEALLOCATE #hcolumns
  END 
