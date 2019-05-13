USE [mydatabase]
GO

/****** Object:  UserDefinedFunction [dbo].[fn_getalldatabaseroles]    Script Date: 13/05/2019 10:55:41 ******/
DROP FUNCTION [dbo].[fn_getalldatabaseroles]
GO

/****** Object:  UserDefinedFunction [dbo].[fn_getalldatabaseroles]    Script Date: 13/05/2019 10:55:41 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- fn_getallserverroles
-- 
-- get all server roles
--
-- parameters:
--   none
-- returns:
--  principal_id:		principal_id of the role in sys.database_principals
--  server_role:		name of the server role
--  is_fixed_role:		0/1 fixed role according to sys.database_principals
--                      public is not a fixed role!!
--  is_builtin:         0/1 if role is fixed or public (e.g. no CREATE ROLE)
--  is_empty:			0/1 role does not contain members in sys.database_role_members

-- 1.0 - 13.05.2018 - DJ - Implemented as a inline TVF.
CREATE FUNCTION [dbo].[fn_getalldatabaseroles]()
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
  exists(select * from sys.database_role_members where role_principal_id = sp.principal_id)
  THEN 0
ELSE
    1
END
as is_empty
from sys.database_principals sp
where sp.type = 'R'

GO


