SELECT es.login_name, start_time, r.session_id as SPID, command, a.text AS Query, percent_complete, dateadd(second,estimated_completion_time/1000, getdate()) as estimated_completion_time
FROM sys.dm_exec_requests r CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) a
join sys.dm_exec_sessions as es on es.session_id = r.session_id
-- WHERE r.command in ('BACKUP DATABASE','RESTORE DATABASE','BACKUP LOG', 'RESTORE LOG')



