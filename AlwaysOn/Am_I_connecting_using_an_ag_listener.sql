-- https://learn.microsoft.com/en-us/archive/blogs/sql_pfe_blog/finding-what-availability-group-listeners-applications-are-using-to-connect
-- DJ: Add the 3rd case of shared menory when on the machine
-- add fields use_ag_listener, use_tcpip
SELECT es.login_name
,es.program_name
,ec.client_net_address
,ec.client_tcp_port
,agl.dns_name
,aglip.ip_address
,agl.port
,1 as use_ag_listener
,1 as use_tcpip
FROM sys.availability_group_listeners agl
INNER JOIN sys.availability_group_listener_ip_addresses aglip
ON agl.listener_id = aglip.listener_id
INNER JOIN sys.dm_exec_connections ec
ON ec.local_net_address = aglip.ip_address
INNER JOIN sys.dm_exec_sessions es
ON ec.session_id = es.session_id AND ec.session_id=@@SPID
UNION ALL
SELECT es.login_name
,es.program_name
,ec.client_net_address
,ec.client_tcp_port
,@@SERVERNAME AS [dns_name]
,sr.value_data AS [ip_Address]
,ec.local_tcp_port AS [port]
,0 as use_ag_listener
,1 as use_tcpip
FROM sys.dm_server_registry sr
INNER JOIN sys.dm_exec_connections ec
ON sr.value_name = 'IpAddress'
AND ec.local_net_address = sr.value_data
INNER JOIN sys.dm_exec_sessions es
ON ec.session_id = es.session_id AND ec.session_id=@@SPID
UNION ALL
SELECT es.login_name
,es.program_name
,ec.client_net_address
,0 as client_tcp_port
,'localhost' AS [dns_name]
,'0.0.0.0' AS [ip_Address]
,0 AS [port]
,0 as use_ag_listener
,0 as use_tcpip
FROM sys.dm_server_registry sr
INNER JOIN sys.dm_exec_connections ec
ON sr.value_name = 'IpAddress'
AND ec.local_net_address IS NULL AND sr.value_data = '127.0.0.1'
INNER JOIN sys.dm_exec_sessions es
ON ec.session_id = es.session_id AND ec.session_id=@@SPID
