-- size of index in KB by table

USE [mydatabase]
GO
SELECT
@@SERVERNAME as InstanceName,
DB_NAME(DB_ID()) as DatabaseName,
OBJECT_SCHEMA_NAME(i.OBJECT_ID) AS SchemaName,
OBJECT_NAME(i.OBJECT_ID) AS TableName,
i.name AS IndexName,
i.index_id AS IndexID,
8 * SUM(a.used_pages) AS 'Indexsize(KB)'
FROM sys.indexes AS i
JOIN sys.partitions AS p ON p.OBJECT_ID = i.OBJECT_ID AND p.index_id = i.index_id
JOIN sys.allocation_units AS a ON a.container_id = p.partition_id
-- get it with QueryStore, etc
-- where OBJECT_SCHEMA_NAME(i.OBJECT_ID)<> 'sys'
GROUP BY i.OBJECT_ID,i.index_id,i.name
ORDER BY OBJECT_NAME(i.OBJECT_ID),i.index_id
