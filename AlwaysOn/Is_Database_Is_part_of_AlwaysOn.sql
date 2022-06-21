-- Get for a each database a row with:
-- name, AGType, AGName
-- name: name of the database
-- AGType: NOT REPLICATED/PRIMARY/SECONDARY
-- AGName: N/A if NOT REPLICATED, otherwise name of the AG Group the database is part of
 
select DISTINCT @@SERVERNAME as InstanceName, sd.name, 
(
case 
 when
  hdrs.is_primary_replica IS NULL then  'NOT REPLICATED'
 when exists ( select * from sys.dm_hadr_database_replica_states as irs where sd.database_id = irs.database_id and is_primary_replica = 1 ) then
	'PRIMARY'
 else
    'SECONDARY'
 end
) as  AGType,
COALESCE(grp.ag_name,'N/A') as AGName
 from sys.databases as sd
 left outer join sys.dm_hadr_database_replica_states  as hdrs on hdrs.database_id = sd.database_id
 left outer join sys.dm_hadr_name_id_map as grp on grp.ag_id = hdrs.group_id
