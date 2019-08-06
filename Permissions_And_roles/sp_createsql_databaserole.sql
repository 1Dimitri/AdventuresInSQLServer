use [mydatabase]
go

-- sp_createsql_databaserole
--
-- generate statements to recreate ROLE memberships and permissions
--
-- parameters:
--   none
-- returns:
--      sql_statement: one T-SQL statement
--      the rowset allows to recreate server roles, add their members and assign permissions to these server roles

-- require:
--  ITVF fn_getdatabaserolemembers()
--  ITVF fn_getdetaileddatabaserolepermissions()
--
-- 1.0 - DJ - 13.05.2019
CREATE PROCEDURE [dbo].[dsp_createsql_databaserole] 

AS
BEGIN
	SET NOCOUNT ON;

	select '-- non databases roles creation' as sql_statement
	UNION ALL
	select 'CREATE ROLE '+QUOTENAME(database_role,'[')  from fn_getalldatabaseroles()
	where is_builtin=0 
	UNION ALL
	select ' -- Memberships'
	UNION ALL
	select 'ALTER ROLE '+QUOTENAME(database_role,'[')+' ADD MEMBER '+QUOTENAME(database_user,'[')  from fn_getdatabaserolemembers()
	where member_principal_id != 1  --sa: Cannot use the special principal 'sa'.
	UNION ALL 
	select '-- permissions'
	UNION ALL
	select distinct sql_permission+' '+sql_statement+COALESCE(' ON '+objectname,'')+' TO '+QUOTENAME(databaseuser_name ,'[') collate database_default 	from fn_getdetaileddatabaserolepermissions()


END
GO


