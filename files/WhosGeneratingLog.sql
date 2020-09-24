
-- https://support.microsoft.com/en-us/help/317375/a-transaction-log-grows-unexpectedly-or-becomes-full-in-sql-server
-- see paragraph:
-- How  locate queries that consume a large amount of log space in SQL Server 2005 and later versions
--
-- if you are not in a hurry mode, but try to catch future statements, have a look at xevent directory, xe_db_size_changes.sql for a way to record events with SQL statements
SELECT sesstran.session_id AS [spid]
, DB_NAME(dbtran.database_id) AS [dbname],
QUOTENAME(DB_NAME(sqltxt.dbid)) + N'.' + QUOTENAME(OBJECT_SCHEMA_NAME(sqltxt.objectid, sqltxt.dbid)) + N'.' + QUOTENAME(OBJECT_NAME(sqltxt.objectid, sqltxt.dbid)) AS sql_object
, req.command as [sql_command]
, SUBSTRING(sqltxt.text, ( req.statement_start_offset / 2 ) + 1
, ((CASE req.statement_end_offset 
WHEN -1 THEN DATALENGTH(sqltxt.text) 
ELSE req.statement_end_offset 
END - req.statement_start_offset)/2)+1) AS [sql_command_param]
, dbtran.database_transaction_log_bytes_used / 1048576.0 AS [log_used_mb]
, dbtran.database_transaction_log_bytes_used_system / 1048576.0  AS [logsystem_used_mb]
, dbtran.database_transaction_log_bytes_reserved / 1048576.0 AS  [log_reserved_mb]
, dbtran.database_transaction_log_bytes_reserved_system / 1048576.0 AS [logsystem_reserved_mb]
, dbtran.database_transaction_log_record_count AS [log_records]
FROM sys.dm_tran_database_transactions dbtran 
JOIN sys.dm_tran_session_transactions sesstran ON dbtran.transaction_id = sesstran.transaction_id 
JOIN sys.dm_exec_requests req 
CROSS apply sys.dm_exec_sql_text(req.sql_handle) AS sqltxt
ON sesstran.session_id = req.session_id 
ORDER BY 5 DESC; 
