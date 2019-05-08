-- fn_getdetailedserverpermissions
-- 
-- get all permissions set on the server object adding human friendly columns
--  for objects of type ROLE only
-- parameters:
--   none
-- returns:
--  userlogin_id:		principal_id of the user/role in sys.server_principals to grant/deny permission to
--  userlogin_name:     name matching userlogin_id
--  userlogin_type:		type of principal (SQL Login, Role...)
--  is_builtin_user:    0/1 if user/role is well-known or public (e.g. no CREATE ROLE)
--  permission_type:	G For GRANT, D for DENY
--  sql_permission:     permission as human-readable (GRANT, DENY)
--  permission_code:    4 letter abbreviation of the permission to apply
--  sql_statement:      T-SQL for the permission_code
--  grantedby_id:       principal_id of the grantor of such permission
--  grantedby_name:     name of the grantor of such permission


-- 1.0 - 08.05.2018 - DJ - Implemented as a inline TVF.
CREATE FUNCTION [dbo].[fn_getdetailedserverrolepermissions]()
RETURNS TABLE 
AS
RETURN

select sp.grantee_principal_id as userlogin_id,
sid1.name as userlogin_name , 
sid1.type as userlogin_type,
CASE WHEN 
  sid1.is_fixed_role=1 or sid1.principal_id < 257 
  THEN 1
ELSE 
  0
END
as is_builtin,
sp.state as permission_type, 
sp.state_desc as sql_permission,
sp.type as permission_code,
sp.permission_name as sql_statement,
sp.grantor_principal_id as grantedby_id,
sid2.name as grantedby_name

from sys.server_permissions sp
join sys.server_principals  as sid1 on sid1.principal_id=sp.grantee_principal_id
join sys.server_principals  as sid2 on sid2.principal_id=sp.grantor_principal_id
where sp.class = 100 -- SERVER only, not ENDPOINT
and sid1.type='R'  -- Role only
GO


