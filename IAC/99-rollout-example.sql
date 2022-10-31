use [MASTER]

GO



exec master.dbo.CreateDB @DBName='db'
GO


exec master.dbo.ReCreateLogin @Login='SQL-DBA-XXX',@ADIntegrated=0
ALTER SERVER ROLE [sysadmin] ADD MEMBER [SQL-DBA-XXX]


exec master.dbo.RecreateLogin @Login='api',@ADIntegrated=0
exec master.dbo.RecreateLogin @Login='etl',@ADIntegrated=0


exec master.dbo.RecreateSchema @DBName='db',@Schema='data'

exec master.dbo.RecreateUserFromLogin  @Login='api',@DBName='cfcd_connect_db'

exec master.dbo.RecreateUserFromLogin  @Login='etl',@DBName='cfcd_connect_db'



USE [db]
-- CREATE ROLE ur_dbo_noaccess

exec master.dbo.RecreateRole @Role='ur_dbo_noaccess',@DBName='db'

DENY CONTROL ON SCHEMA::dbo TO [ur_dbo_noaccess]
DENY ALTER ON SCHEMA::dbo TO [ur_dbo_noaccess]

-- CREATE ROLE [ur_data_fullcontrol]
exec master.dbo.RecreateRole @Role='ur_data_fullcontrol',@DBName='db'
GRANT CONTROL ON SCHEMA::[_data] TO [ur_data_fullcontrol]
GRANT ALTER ON SCHEMA::[data] TO [ur_data_fullcontrol]

-- CREATE ROLE [ur_data_read]
exec master.dbo.RecreateRole @Role='ur_data_read',@DBName='db'
GRANT SELECT ON SCHEMA::[data] TO [ur_data_read]

--CREATE ROLE [ur_data_readwrite]
exec master.dbo.RecreateRole @Role='ur_data_readwrite',@DBName='db'
GRANT SELECT ON SCHEMA::[data] TO [ur_data_readwrite]
GRANT INSERT ON SCHEMA::[data] TO [ur_data_readwrite]
GRANT UPDATE ON SCHEMA::[data] TO [ur_data_readwrite]
GRANT DELETE ON SCHEMA::[data] TO [ur_data_readwrite]
-- GRANT CREATE SYNONYM ON SCHEMA::[data] TO [ur_data_readwrite]

-- CREATE ROLE [ur_dbo_readwrite]
exec master.dbo.RecreateRole @Role='ur_dbo_readwrite',@DBName='db'
GRANT SELECT ON SCHEMA::[dbo] TO [ur_dbo_readwrite]
GRANT INSERT ON SCHEMA::[dbo] TO [ur_dbo_readwrite]
GRANT UPDATE ON SCHEMA::[dbo] TO [ur_dbo_readwrite]
GRANT DELETE ON SCHEMA::[dbo] TO [ur_dbo_readwrite]

exec master.dbo.RecreateRole @Role='ur_anyschema_alter',@DBName='db'
-- CREATE ROLE [ur_anyschema_alter]
-- GRANT CONTROL ANY SCHEMA TO [ur_anyschema_alter]
GRANT ALTER ANY SCHEMA TO [ur_anyschema_alter]

ALTER ROLE [ur_dbo_noaccess] ADD MEMBER [etl]
ALTER ROLE [ur_anyschema_alter] ADD MEMBER [etl]

ALTER  ROLE [ur_dbo_readwrite] ADD MEMBER [api]
ALTER  ROLE [ur_data_read] ADD MEMBER [api]

