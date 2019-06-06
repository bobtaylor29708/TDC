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
-- this is a more robust implementation of the ufn_ColumnType
CREATE FUNCTION [tdc].[Ufn_columntype] (@table_schema SYSNAME,
                                        @table_name   SYSNAME,
                                        @column_id    INT)
RETURNS NVARCHAR(255)
AS
  BEGIN
      DECLARE @coltypename   NVARCHAR(258),
              @coltypeschema NVARCHAR(258),
              @coltype       TINYINT,
              @collen        SMALLINT,
              @colprec       TINYINT,
              @colscale      TINYINT,
              @typestring    NVARCHAR(255),
              @table_id      INT

      SELECT @table_id = Object_id(Quotename(Rtrim(@table_schema)) + N.
                                   + Quotename(Rtrim(@table_name)))

      BEGIN
          SELECT @coltypename = typ.NAME,
                 @coltypeschema = Schema_name(typ.schema_id),
                 @coltype = typ.system_type_id,
                 @collen = col.max_length,
                 @colprec = col.PRECISION,
                 @colscale = col.scale
          FROM   sys.columns col
                 JOIN sys.types typ
                   ON typ.user_type_id = col.system_type_id
                       OR
                      --for all UDT types, we just need to get the name of the user type
                      ( typ.system_type_id = 240
                        AND typ.user_type_id = col.user_type_id )
          WHERE  col.object_id = @table_id
                 AND col.column_id = @column_id
      END

      IF @coltypename IN ( Nvarchar, Nnvarchar, Nvarbinary )
         AND ( @collen = -1 )
        BEGIN
            SELECT @typestring = @coltypename + N(max)
        END
      ELSE IF @coltypename IN ( Nchar, Nvarchar, Nbinary, Nvarbinary )
        BEGIN
            SELECT @typestring = @coltypename + N(
                                 + CONVERT(NVARCHAR, @collen) + N)
        END
      ELSE IF @coltypename IN ( Nnchar, Nnvarchar )
        BEGIN
            SELECT @typestring = @coltypename + N(
                                 + CONVERT(NVARCHAR, @collen/2) + N)
        END
      ELSE IF @coltypename IN ( Ndatetime2, Ndatetimeoffset, Ntime )
        BEGIN
            SELECT @typestring = @coltypename

            BEGIN
                SELECT @typestring = @typestring + N(
                                     + CONVERT(NVARCHAR, @colscale) + N)
            END
        END
      ELSE IF @coltypename IN ( Ndate )
        BEGIN
            BEGIN
                SET @typestring = @coltypename
            END
        END
      ELSE IF @coltype = 108
          OR @coltype = 106
        BEGIN
            IF ( @colprec IS NOT NULL )
               AND ( @colprec > 0 )
              BEGIN
                  SELECT @typestring = @coltypename + N(
                                       + CONVERT(NVARCHAR, @colprec)

                  IF ( @colscale IS NOT NULL )
                    BEGIN
                        SELECT @typestring = @typestring + N,
                                             + CONVERT(NVARCHAR, @colscale)
                    END

                  SELECT @typestring = @typestring + N)
              END
        END
      ELSE IF @coltype = 189
        BEGIN
            SELECT @typestring = Nbinary(8)
        END
      ELSE IF @coltype = 240
        BEGIN
            IF @coltypename = Nutcdatetime
              BEGIN
                  SELECT @typestring = @coltypename
              END
            ELSE IF Lower(@coltypename COLLATE SQL_Latin1_General_CP1_CS_AS) = Nhierarchyid
              BEGIN
                  SELECT @typestring = Nhierarchyid
              END
            ELSE IF Lower(@coltypename COLLATE SQL_Latin1_General_CP1_CS_AS) = Ngeometry
              BEGIN
                  SELECT @typestring = Ngeometry
              END
            ELSE IF Lower(@coltypename COLLATE SQL_Latin1_General_CP1_CS_AS) = Ngeography
              BEGIN
                  SELECT @typestring = Ngeography
              END
            ELSE IF @collen = -1
              BEGIN
                  SELECT @typestring = Nvarbinary(max)
              END
        END
      ELSE
        BEGIN
            SELECT @TYPESTRING = @COLTYPENAME
        END

      -- all done
      RETURN @typestring
  END 
