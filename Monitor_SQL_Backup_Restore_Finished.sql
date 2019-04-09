
-- Works in SQL Server 2014

SELECT session_id as SPID,
command,
a.text AS Query,
start_time,
percent_complete,
dateadd(second,estimated_completion_time/1000, getdate()) as estimated_completion_time
FROM sys.dm_exec_requests r CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) a
WHERE r.command in ('BACKUP DATABASE','RESTORE DATABASE') 

-- remove or change above to monitor other statements than BACKUP/RESTORE
