WITH ag_conn as (SELECT es.login_name
,es.program_name
,ec.client_net_address
,ec.client_tcp_port
,agl.dns_name
,aglip.ip_address
,agl.port
,1 as use_ag_listener
,1 as use_tcpip
FROM sys.availability_group_listeners agl
INNER JOIN sys.availability_group_listener_ip_addresses aglip
ON agl.listener_id = aglip.listener_id
INNER JOIN sys.dm_exec_connections ec
ON ec.local_net_address = aglip.ip_address
INNER JOIN sys.dm_exec_sessions es
ON ec.session_id = es.session_id AND ec.session_id=@@SPID
UNION ALL
SELECT es.login_name
,es.program_name
,ec.client_net_address
,ec.client_tcp_port
,@@SERVERNAME AS [dns_name]
,sr.value_data AS [ip_Address]
,ec.local_tcp_port AS [port]
,0 as use_ag_listener
,1 as use_tcpip
FROM sys.dm_server_registry sr
INNER JOIN sys.dm_exec_connections ec
ON sr.value_name = 'IpAddress'
AND ec.local_net_address = sr.value_data
INNER JOIN sys.dm_exec_sessions es
ON ec.session_id = es.session_id AND ec.session_id=@@SPID
UNION ALL
SELECT es.login_name
,es.program_name
,ec.client_net_address
,0 as client_tcp_port
,'localhost' AS [dns_name]
,'0.0.0.0' AS [ip_Address]
,0 AS [port]
,0 as use_ag_listener
,0 as use_tcpip
FROM sys.dm_server_registry sr
INNER JOIN sys.dm_exec_connections ec
ON sr.value_name = 'IpAddress'
AND ec.local_net_address IS NULL AND sr.value_data = '127.0.0.1'
INNER JOIN sys.dm_exec_sessions es
ON ec.session_id = es.session_id AND ec.session_id=@@SPID
) 
select db.name,
case
 when drs.is_primary_replica = 1  then 1
 when drs.is_primary_replica = 0 then 1
 else 0
end as should_use_ag_listener,
ag_conn.use_ag_listener as  is_using_ag_listener,
ag_conn.dns_name as connected_to_server_name,
 COALESCE(drs.ReplicaName,@@SERVERNAME) AS real_server_name,
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
cross join ag_conn
