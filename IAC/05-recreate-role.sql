USE [master]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE OR ALTER           procedure [dbo].[RecreateRole](
        @Role sysname,
		@DBName sysname
	
)

as

declare @cleancmd nvarchar(4000)
SET @cleancmd='USE '+QUOTENAME(@DBName)+';
IF EXISTS (SELECT * FROM sys.database_principals WHERE Name=''' + @Role + ''' AND type=''R'')

BEGIN
   DROP ROLE '+QUOTENAME(@Role)+'
END '


exec sp_executesql @cleancmd


declare @innersqlcmd nvarchar(400)
declare @outersqlcmd nvarchar(800)

set @innersqlcmd = 'CREATE ROLE ' +  QUOTENAME(@Role) 
set @outersqlcmd = 'exec '+QUOTENAME(@DBName)+'.sys.sp_executesql N'''+ @innersqlcmd + ''''


exec sp_executesql @outersqlcmd


GO


