USE [master]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE OR ALTER       procedure [dbo].[RecreateLogin](
        @login sysname,
		@ADIntegrated bit
)

as

declare @cleancmd nvarchar(4000)
SET @cleancmd='
IF  EXISTS 
    (SELECT name  
     FROM master.sys.server_principals
     WHERE name = '''+ @Login + ''')
BEGIN
   DROP LOGIN  '+QUOTENAME(@Login)+'
END '

exec sp_executesql @cleancmd


declare @sqlcmd nvarchar(4000)
IF @ADIntegrated=0
BEGIN
set @sqlcmd = 'use [master];' +
           'create login ' + QUOTENAME(@login) + 
               ' with password = ''Abcd1234!''; ' 

END
ELSE
BEGIN
set @sqlcmd = 'use [master];' +
           'create login ' + QUOTENAME(@login) + 
               'FROM WINDOWS; ' 
END

exec sp_executesql @sqlcmd

GO

