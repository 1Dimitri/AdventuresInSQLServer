USE [master]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE OR ALTER       procedure [dbo].[RecreateUserfromLogin](
        @login sysname,
		@DBName sysname
)

as

declare @cleancmd nvarchar(4000)
SET @cleancmd='
USE '+QUOTENAME(@DBName)+';
IF  EXISTS 
    (SELECT name  
     FROM sys.database_principals
     WHERE name = '''+ @Login + ''')
BEGIN
   DROP USER  '+QUOTENAME(@Login)+'
END '

exec sp_executesql @cleancmd


declare @sqlcmd nvarchar(4000)
set @sqlcmd = 'USE '+QUOTENAME(@DBName)+';' + 
           'CREATE USER ' + QUOTENAME(@login) + 
               ' FROM LOGIN '+QUOTENAME(@Login) 


exec sp_executesql @sqlcmd

GO

