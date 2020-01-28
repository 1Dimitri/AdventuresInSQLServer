-- get command, text and ETA for every command but this one


SELECT session_id as SPID,
      command, a.text AS Query,
      start_time, percent_complete,
      dateadd(second,estimated_completion_time/1000, getdate()) as estimated_completion_time
FROM sys.dm_exec_requests r CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) a 
WHERE session_id <> @@SPID
