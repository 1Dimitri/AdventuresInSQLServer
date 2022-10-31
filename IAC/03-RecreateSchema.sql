USE [master]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE       procedure [dbo].[RecreateSchema](
        @Schema sysname,
		@DBName sysname
	
)

as

declare @cleancmd nvarchar(4000)
SET @cleancmd='USE '+QUOTENAME(@DBName)+';
IF EXISTS (SELECT * FROM sys.schemas WHERE Name=''' + @Schema + ''')

BEGIN
   DROP SCHEMA '+QUOTENAME(@Schema)+'
END '

exec sp_executesql @cleancmd


declare @innersqlcmd nvarchar(400)
declare @outersqlcmd nvarchar(800)

set @innersqlcmd = 'CREATE SCHEMA ' +  QUOTENAME(@Schema) 
set @outersqlcmd = 'exec '+QUOTENAME(@DBName)+'.sys.sp_executesql N'''+ @innersqlcmd + ''''

exec (@outersqlcmd)

GO

