
-- getting statement which create change in database files change

CREATE EVENT SESSION [xe_dbsize_changes] ON SERVER 
ADD EVENT sqlserver.database_file_size_change(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.nt_username,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text,sqlserver.username))
ADD TARGET package0.event_file(SET filename=N'X:\Path\xe_dbsize_changes.xel')
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=ON)

ALTER EVENT SESSION [xe_dbsize_changes] ON SERVER STATE=START
