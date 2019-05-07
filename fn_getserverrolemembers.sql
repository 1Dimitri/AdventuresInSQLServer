-- fn_getserverrolemembers
-- 
-- get server role members
--
-- parameters:
--   none
-- returns:
--  role_principal_id:	principal_id of the role in sys.server_principals
--  server_role:		name of the server role
--  member_principal_id:principal_id of the member in sys.server_principals
--  member_type:		type of member
--						S: SQL Login
--				        U: Windows Login
--                      G: Windows group
--                      R: Role (nested role)
--
-- 1.0 - 07.05.2018 - DJ - Implemented as a inline TVF.
CREATE FUNCTION [dbo].[fn_getserverrolemembers]()
RETURNS TABLE 
AS
RETURN

WITH ServerRoleMembers (member_principal_id, role_principal_id) 
AS 
(
  SELECT 
   rm1.member_principal_id, 
   rm1.role_principal_id
  FROM sys.server_role_members rm1 (NOLOCK)
   UNION ALL
  SELECT 
   d.member_principal_id, 
   rm.role_principal_id
  FROM sys.server_role_members rm (NOLOCK)
   INNER JOIN ServerRoleMembers AS d 
   ON rm.member_principal_id = d.role_principal_id
)

select distinct rp.principal_id as role_principal_id, rp.name as server_role, mp.principal_id as member_principal_id, mp.name as server_userlogin, mp.type as member_type
from ServerRoleMembers drm
  join sys.server_principals rp on (drm.role_principal_id = rp.principal_id)
  join sys.server_principals mp on (drm.member_principal_id = mp.principal_id)
-- order by rp.name

GO




