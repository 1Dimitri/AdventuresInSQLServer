-- Repair Recovery Pending output script


DECLARE @DBName as sysname;
DECLARE @db_id as int;
DECLARE @DBListCursor as CURSOR;

SET @DBListCursor = CURSOR FORWARD_ONLY FOR
SELECT Name, database_id
  FROM sys.databases
WHERE database_id > 4

OPEN @DBListCursor;
FETCH NEXT FROM @DBListCursor INTO @DBName, @db_id
 WHILE @@FETCH_STATUS = 0
BEGIN
	PRINT 'ALTER DATABASE '+QUOTENAME(@DBName)+' SET EMERGENCY'
     PRINT 'ALTER DATABASE '+QUOTENAME(@DBName)+' SET single_user'
PRINT 'DBCC CHECKDB ('+QUOTENAME(@DBName)+', REPAIR_ALLOW_DATA_LOSS) WITH ALL_ERRORMSGS'
PRINT 'ALTER DATABASE '+QUOTENAME(@DBName)+' SET multi_user'


	 FETCH NEXT FROM @DBListCursor INTO @DBName,@DB_id;
END
CLOSE @DBListCursor;
DEALLOCATE @DBListCursor;
