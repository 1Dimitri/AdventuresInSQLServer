USE [mydatabase]
GO

-- fn_getdetaileddatabasepermissions
-- 
-- get all permissions set on the server object adding human friendly columns
--
-- parameters:
--   none
-- returns:
--  userdatabase_id:		principal_id of the user/role in sys.database_principals to grant/deny permission to
--  userdatabase_name:     name matching userlogin_id
--  userdatabase_type:		type of principal (SQL Login, Role...)
--  is_builtin_user:    0/1 if user/role is well-known or public (e.g. no CREATE ROLE)
--  permission_type:	G For GRANT, D for DENY
--  sql_permission:     permission as human-readable (GRANT, DENY)
--  permission_code:    4 letter abbreviation of the permission to apply
--  sql_statement:      T-SQL for the permission_code
--  object_type:        object type being secured as number (COLUMN, ...)
--  sql_object:         object type being secured as human readable text (COLUMN, ...)
--  objectname:         name of the object (name of the column, ...)
--  grantedby_id:       principal_id of the grantor of such permission
--  grantedby_name:     name of the grantor of such permission

-- 1.0 - 13.05.2019 - DJ - Implemented as a inline TVF.
CREATE FUNCTION [dbo].[fn_getdetaileddatabasepermissions]()
RETURNS TABLE 
AS
RETURN

select sp.grantee_principal_id as databaseuser_id,
sid1.name  as databaseuser_name , 
sid1.type as databaseuser_type,
CASE WHEN 
  sid1.is_fixed_role=1 or sid1.principal_id < 5
  THEN 1
ELSE 
  0
END
as is_builtin_user,
sp.state as permission_type, 
sp.state_desc as sql_permission,
sp.type as permission_code,
sp.permission_name as sql_statement,
sp.class as object_type,
sp.class_desc as sql_object,
QUOTENAME(sch.name,'[') +'.'+QUOTENAME(objs.name,'[') as objectname,
sp.grantor_principal_id as grantedby_id,
sid2.name as grantedby_name

from sys.database_permissions sp
join sys.database_principals  as sid1 on sid1.principal_id=sp.grantee_principal_id 
join sys.database_principals  as sid2 on sid2.principal_id=sp.grantor_principal_id 
left join sys.objects as objs on sp.major_id = objs.object_id
left join sys.schemas as sch on sch.schema_id = objs.schema_id
  
GO


