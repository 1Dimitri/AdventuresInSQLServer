ALTER EVENT SESSION [TimeOuts] ON SERVER STATE = STOP
GO
DROP EVENT SESSION [TimeOuts] ON SERVER 
GO
CREATE EVENT SESSION [TimeOuts] ON SERVER 
ADD EVENT sqlserver.rpc_completed(SET collect_output_parameters=(1)
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.is_system,sqlserver.nt_username,sqlserver.plan_handle,sqlserver.session_id)
    WHERE ([result]=(2)))
ADD TARGET package0.event_file(SET filename=N'TimeOuts',max_file_size=(250),max_rollover_files=(3))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=ON,STARTUP_STATE=ON)
GO
ALTER EVENT SESSION [TimeOuts] ON SERVER STATE = START
GO
