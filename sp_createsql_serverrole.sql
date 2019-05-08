-- sp_createsql_serverrole
--
-- generate statements to recreate ROLE memberships and permissions
--
-- parameters:
--   none
-- returns:
--      sql_statement: one T-SQL statement
--      the rowset allows to recreate server roles, add their members and assign permissions to these server roles

-- require:
--  ITVF fn_getserverrolemembers()
--  ITVF fn_getdetailedserverrolepermissions()
 
CREATE PROCEDURE [dbo].[sp_createsql_serverrole] 

AS
BEGIN
	SET NOCOUNT ON;

	select '-- non built-in server roles creation' as sql_statement
	UNION ALL
	select 'CREATE SERVER ROLE '+QUOTENAME(server_role,'[')  from fn_getallserverroles()
	where is_builtin=0 
	UNION ALL
	select ' -- Memberships'
	UNION ALL
	select 'ALTER SERVER ROLE '+QUOTENAME(server_role,'[')+' ADD MEMBER '+QUOTENAME(server_userlogin,'[')  from fn_getserverrolemembers()
	where member_principal_id != 1  --sa: Cannot use the special principal 'sa'.
	UNION ALL 
	select '-- permissions'
	UNION ALL
	select sql_permission+' '+sql_statement+' TO '+QUOTENAME(userlogin_name ,'[') collate database_default 	from fn_getdetailedserverrolepermissions()


END
GO


