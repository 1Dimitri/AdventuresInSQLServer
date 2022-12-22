
-- db is accessible if
-- 1. online
-- 2. if online and part of always on:
--     a. on the prinary
--    b. or on secondarz and readable


select db.name,
-- drs.is_primary_replica,
-- drs.replica_id,
 COALESCE(drs.ReplicaName,@@SERVERNAME) AS InstanceName,
case db.state
when 0 THEN 

 CASE 
  when drs.is_primary_replica = 1 THEN 1
  when drs.is_primary_replica IS NULL then 1
  else
    drs.secondary_role_allow_connections
	END
ELSE
 0

end
as is_accessible
from sys.databases as db
left join (select ar.replica_server_name as ReplicaName, rs.replica_id, is_primary_replica, rs.database_id, ar.secondary_role_allow_connections from sys.dm_hadr_database_replica_states rs join sys.availability_replicas as ar on rs.replica_id= ar.replica_id where ar.replica_server_name = @@SERVERNAME )  as  drs 
on db.database_id = drs.database_id 

