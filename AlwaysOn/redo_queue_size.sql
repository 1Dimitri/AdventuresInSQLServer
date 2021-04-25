SELECT ag.name AS [availability_group_name]
, d.name AS [database_name]
, ar.replica_server_name AS [replica_instance_name]
, drs.truncation_lsn , drs.log_send_queue_size
, drs.redo_queue_size
FROM sys.availability_groups ag
INNER JOIN sys.availability_replicas ar
    ON ar.group_id = ag.group_id
INNER JOIN sys.dm_hadr_database_replica_states drs
    ON drs.replica_id = ar.replica_id
INNER JOIN sys.databases d
    ON d.database_id = drs.database_id
WHERE drs.is_local=0
ORDER BY ag.name ASC, d.name ASC, drs.truncation_lsn ASC, ar.replica_server_name ASC
