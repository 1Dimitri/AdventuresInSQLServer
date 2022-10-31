USE [master]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE OR ALTER     procedure [dbo].[CreateDB](
        @DBName sysname
	
)

as

declare @createcmd nvarchar(4000)
SET @createcmd='
IF  NOT EXISTS (SELECT Name FROM sys.databases WHERE Name=''' + @DBName + ''')

BEGIN
   CREATE DATABASE '+QUOTENAME(@DBName)+'
END '

exec sp_executesql @createcmd




GO


