CREATE PROCEDURE [dbo].[sp_createsql_databasepermissions] 

AS
BEGIN
	SET NOCOUNT ON;

	
	select '-- permissions' as sql_statement
	UNION ALL
	select distinct sql_permission+' '+sql_statement+COALESCE(' ON '+objectname,'')+' TO '+QUOTENAME(databaseuser_name ,'[') collate database_default
	from fn_getdetaileddatabasepermissions()
	where databaseuser_id <> 1 -- cannot grant to dbo

END
GO
