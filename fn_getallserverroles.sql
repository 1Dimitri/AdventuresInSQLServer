-- fn_getallserverroles
-- 
-- get all server roles
--
-- parameters:
--   none
-- returns:
--  principal_id:		principal_id of the role in sys.server_principals
--  server_role:		name of the server role
--  is_fixed_role:		0/1 fixed role according to sys.server_principals
--                      public is not a fixed role!!
--  is_builtin:         0/1 if role is fixed or public (e.g. no CREATE ROLE)
--  is_empty:			0/1 role does not contain members in sys.server_role_members

-- 1.0 - 07.05.2018 - DJ - Implemented as a inline TVF.


CREATE FUNCTION [dbo].[fn_getallserverroles]()
RETURNS TABLE 
AS
RETURN
select sp.principal_id,sp.name as server_role, sp.is_fixed_role as is_fixed_role, 
CASE WHEN 
  sp.is_fixed_role=1 or sp.name='public' 
  THEN 1
ELSE 
  0
END
as is_builtin,
CASE WHEN 
  exists(select * from sys.server_role_members where role_principal_id = sp.principal_id)
  THEN 0
ELSE
    1
END
as is_empty
from sys.server_principals sp
where sp.type = 'R'

GO


