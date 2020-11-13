CREATE EVENT SESSION CaptureErrors

ON SERVER
   ADD EVENT sqlserver.error_reported
   (ACTION (sqlserver.sql_text,sqlserver.database_id,sqlserver.client_hostname
   ,sqlserver.username,sqlserver.nt_username,sqlserver.tsql_stack)
     WHERE severity>=10 and severity<20
     /*anything over20 is captured by System Health Event*/
     )
   ADD TARGET package0.asynchronous_file_target
  (SET FILENAME = N'CaptureErrors.xel'
  , METADATAFILE = N'CaptureErrors.xem')
       WITH (max_dispatch_latency = 1 seconds);
GO
ALTER EVENT SESSION CaptureErrors ON SERVER

STATE = START
GO
