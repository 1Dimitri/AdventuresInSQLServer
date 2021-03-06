-- simple cursor example
--
-- iterates through a list of databases
--
-- DJ -- 1.0 -- 17.05.2019

DECLARE @DBName as sysname;
DECLARE @db_id as int;
DECLARE @DBListCursor as CURSOR;

SET @DBListCursor = CURSOR FORWARD_ONLY FOR
SELECT Name, database_id
  FROM sys.databases
  -- no system databases
-- WHERE database_id > 4
 -- no system databases and not this database I'm in
--  WHERE database_id > 4 AND database_id<>DB_ID()
 
 
OPEN @DBListCursor;
FETCH NEXT FROM @DBListCursor INTO @DBName, @db_id
 WHILE @@FETCH_STATUS = 0
BEGIN
	PRINT CONVERT(nvarchar,@db_id)+' '+@DBName
	 FETCH NEXT FROM @DBListCursor INTO @DBName,@DB_id;
END
CLOSE @DBListCursor;
DEALLOCATE @DBListCursor;
