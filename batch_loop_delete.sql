-- delete & other DML statements whose execution on a huge number of rows may lead to table lock
-- and fill in log even in SIMPLE model

DECLARE @more INT
DECLARE @rowprocessed INT
 
SET @more = 1
 
WHILE @more = 1
BEGIN
    SET ROWCOUNT 4000
    BEGIN TRANSACTION
    DELETE FROM some_big_table WHERE -- statement to be repeated
    SET @rowprocessed = @@rowcount 
    COMMIT
    PRINT "4000 rows processed"
    IF @rowcount = 0
    BEGIN
        SET @more = 0
    END
END 
