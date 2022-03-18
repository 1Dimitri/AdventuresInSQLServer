USE master;  
GO  
CREATE ENDPOINT [DedicatedConnection]  
STATE = STARTED  
AS TCP  
   (LISTENER_PORT = 60000, LISTENER_IP =ALL)  
FOR TSQL() ;  
GO

GRANT CONNECT ON ENDPOINT::[TSQL Default TCP] to [public]


GRANT CONNECT ON ENDPOINT::[DedicatedConnection] to [public]
-- do not forget to add it to the IPAll list in the SQL Server Connection Manager
