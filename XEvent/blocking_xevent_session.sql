ALTER EVENT SESSION [Blocking] ON SERVER STATE = STOP
GO
DROP EVENT SESSION [Blocking] ON SERVER 
GO
CREATE EVENT SESSION [Blocking] ON SERVER 
ADD EVENT sqlserver.blocked_process_report 
ADD TARGET package0.event_file(SET filename=N'Blocking',max_file_size=(250),max_rollover_files=(3))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=ON,STARTUP_STATE=ON)
GO
ALTER EVENT SESSION [Blocking] ON SERVER STATE = START
GO
