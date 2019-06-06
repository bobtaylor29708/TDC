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
-- this procedure will get us the join info based on the primary key
-- we do this with several variations for performance sake
CREATE PROCEDURE [tdc].[Usp_getjoininfo] (@source_schema               SYSNAME,
                                          @source_name                 SYSNAME,
                                          @primary_key_list            NVARCHAR(max) OUTPUT,
                                          @join_list                   NVARCHAR(MAX) OUTPUT,
                                          @primary_key_list_with_alias NVARCHAR(max) OUTPUT)
AS
  BEGIN
      SET nocount ON
      SET @join_list = N
      SET @primary_key_list = N

      DECLARE @index_name       SYSNAME,
              @source_table     NVARCHAR(1000),
              @source_object_id INT,
              @column_name      SYSNAME,
              @column_count     INT =0,
              @column_number    INT = 0

      SET @source_name = Rtrim(@source_name)
      SET @source_schema = Rtrim(@source_schema)

      SELECT @source_table = Quotename(@source_schema) + N.
                             + Quotename(@source_name)

      SELECT @source_object_id = Object_id(@source_table)

      -- capture our columns to make the processing easier
      CREATE TABLE #index_columns
        (
           column_name   SYSNAME NULL,
           index_ordinal INT NULL,
           column_id     INT NULL
        )

      -- get info about the indexes - hopefully there is a primary key
      -- TODO: Perhaps report back if no primary key and stop.
      SELECT @index_name = i.NAME
      FROM   [sys].[indexes] i
      WHERE  i.object_id = @source_object_id
             AND i.is_primary_key = 1

      IF ( @index_name IS NOT NULL )
        BEGIN
            INSERT INTO #index_columns
            SELECT c.NAME,
                   ic.key_ordinal,
                   c.column_id
            FROM   [sys].[indexes] i
                   INNER JOIN [sys].[columns] c
                           ON i.object_id = c.object_id
                   INNER JOIN [sys].[index_columns] ic
                           ON i.object_id = ic.object_id
                              AND i.index_id = ic.index_id
                              AND c.column_id = ic.column_id
            WHERE  i.object_id = @source_object_id
                   AND i.NAME = @index_name
        END

      SELECT @column_count = Count(*)
      FROM   #index_columns

      DECLARE #icolumns CURSOR LOCAL FAST_FORWARD FOR
        SELECT column_name
        FROM   #index_columns
        ORDER  BY column_id

      OPEN #icolumns

      FETCH #icolumns INTO @column_name

      WHILE ( @@FETCH_STATUS <> -1 )
        BEGIN
            SET @column_number += 1
            -- build both the primary key list and the aliased version of the list
            SET @primary_key_list = @primary_key_list + Char(13) + Char(9)
                                    + @column_name
            SET @primary_key_list_with_alias = @primary_key_list_with_alias + Nt.
                                               + @column_name
            SET @join_list = @join_list + Nt. + @column_name + = a.
                             + @column_name

            IF( @column_number < @column_count )
              SET @join_list += N AND 

            FETCH #icolumns INTO @column_name

            SET @primary_key_list += ,
            SET @primary_key_list_with_alias += ,
        END

      CLOSE #icolumns

      DEALLOCATE #icolumns

      DROP TABLE #index_columns
  END 
