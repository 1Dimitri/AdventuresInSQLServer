DECLARE @name NVARCHAR(100)

declare @table table (IsOff int, ServerName varchar(100), TheError varchar(4000))


DECLARE getid CURSOR FOR
SELECT  name FROM sys.servers where is_linked = 1


OPEN getid

FETCH NEXT FROM getid INTO @name
WHILE @@FETCH_STATUS = 0

BEGIN

    begin try
        exec sys.sp_testlinkedserver @name
    end try

    begin catch
        insert into @table
        values
        (1,@name,ERROR_MESSAGE())
    end catch

FETCH NEXT FROM getid INTO @name

END

CLOSE getid
DEALLOCATE getid

select ServerName, TheError from @table where IsOff = 1
