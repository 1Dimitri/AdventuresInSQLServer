CREATE EVENT SESSION [XES_SSMS_Profiler_TSQL] ON SERVER 
ADD EVENT sqlserver.existing_connection(
    ACTION(package0.event_sequence,sqlserver.client_hostname,sqlserver.session_id)),
ADD EVENT sqlserver.login(SET collect_options_text=(1)
    ACTION(package0.event_sequence,sqlserver.client_hostname,sqlserver.session_id)),
ADD EVENT sqlserver.logout(
    ACTION(package0.event_sequence,sqlserver.session_id)),
ADD EVENT sqlserver.rpc_starting(
    ACTION(package0.event_sequence,sqlserver.database_name,sqlserver.session_id)
    WHERE ([package0].[equal_boolean]([sqlserver].[is_system],(0)))),
ADD EVENT sqlserver.sql_batch_starting(
    ACTION(package0.event_sequence,sqlserver.database_name,sqlserver.session_id)
    WHERE ([package0].[equal_boolean]([sqlserver].[is_system],(0))))
ADD TARGET package0.event_file(SET filename=N'XES_SSMS_Profiler_TSQL',max_file_size=(100),max_rollover_files=(10))
WITH (MAX_MEMORY=8192 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=5 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=PER_CPU,TRACK_CAUSALITY=ON,STARTUP_STATE=OFF)
GO


