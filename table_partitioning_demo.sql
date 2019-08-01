-- an exampole of a table storing messages with a timestamp
-- you want to get rid of older messages

-- CREATE DB
CREATE DATABASE [db_partdemo]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'db_partdemo', FILENAME = N'D:\DBE.SQLDBFiles\db_partdemo.mdf' , SIZE = 8192KB , FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'db_partdemo_log', FILENAME = N'D:\DBE.SQLLog\db_partdemo_log.ldf' , SIZE = 8192KB , FILEGROWTH = 65536KB )
GO

IF NOT EXISTS (SELECT name FROM sys.filegroups WHERE is_default=1 AND name = N'PRIMARY') ALTER DATABASE [db_partdemo] MODIFY FILEGROUP [PRIMARY] DEFAULT
GO

---- CREATE Filegroups & files
USE [master]
GO
ALTER DATABASE [db_partdemo] ADD FILEGROUP [fg_week0]
GO
ALTER DATABASE [db_partdemo] ADD FILE ( NAME = N'file_week0', FILENAME = N'D:\DBE.SQLDBFiles\file_week0.ndf' , SIZE = 8192KB , FILEGROWTH = 65536KB ) TO FILEGROUP [fg_week0]
GO
ALTER DATABASE [db_partdemo] ADD FILEGROUP [fg_week1]
GO
ALTER DATABASE [db_partdemo] ADD FILE ( NAME = N'file_week1', FILENAME = N'D:\DBE.SQLDBFiles\file_week1.ndf' , SIZE = 8192KB , FILEGROWTH = 65536KB ) TO FILEGROUP [fg_week1]
GO
ALTER DATABASE [db_partdemo] ADD FILEGROUP [fg_week2]
GO
ALTER DATABASE [db_partdemo] ADD FILE ( NAME = N'file_week2', FILENAME = N'D:\DBE.SQLDBFiles\file_week2.ndf' , SIZE = 8192KB , FILEGROWTH = 65536KB ) TO FILEGROUP [fg_week2]
GO

USE [db_partdemo]
GO

-- Helper function to count rows by partition and display the criteria for a row being in a partition
CREATE PROCEDURE usp_getpartitiondetails AS 
  SELECT
  QUOTENAME(OBJECT_SCHEMA_NAME(pstats.object_id),'[') +'.'+QUOTENAME(OBJECT_NAME(pstats.object_id),'[') as objectname
,ds.name AS Filegroup
,ps.name AS PartitionScheme
,pf.name AS PartitionFunctionName
,CASE pf.boundary_value_on_right WHEN 0 THEN 'Left' ELSE 'Right' END AS RangeType
,CASE pf.boundary_value_on_right WHEN 0 THEN 'Upper' ELSE 'Lower' END AS Boundary
,prv.value AS PartitionBoundaryValue
,c.name AS Field
,CASE 
WHEN pf.boundary_value_on_right = 0 
THEN c.name + ' > ' + CAST(ISNULL(LAG(prv.value) OVER(PARTITION BY pstats.object_id ORDER BY pstats.object_id, pstats.partition_number), '(No Limit)') AS VARCHAR(100)) + ' and ' + c.name + ' <= ' + CAST(ISNULL(prv.value, '(No Limit)') AS VARCHAR(100)) 
ELSE c.name + ' >= ' + CAST(ISNULL(prv.value, '(No Limit)') AS VARCHAR(100)) + ' and ' + c.name + ' < ' + CAST(ISNULL(LEAD(prv.value) OVER(PARTITION BY pstats.object_id ORDER BY pstats.object_id, pstats.partition_number), '(No Limit)') AS VARCHAR(100))
END AS PartitionRange
,pstats.partition_number AS PartitionNumber
,pstats.row_count AS RowsInPartition
FROM sys.dm_db_partition_stats AS pstats
INNER JOIN sys.partitions AS p ON pstats.partition_id = p.partition_id
INNER JOIN sys.destination_data_spaces AS dds ON pstats.partition_number = dds.destination_id
INNER JOIN sys.data_spaces AS ds ON dds.data_space_id = ds.data_space_id
INNER JOIN sys.partition_schemes AS ps ON dds.partition_scheme_id = ps.data_space_id
INNER JOIN sys.partition_functions AS pf ON ps.function_id = pf.function_id
INNER JOIN sys.indexes AS i ON pstats.object_id = i.object_id AND pstats.index_id = i.index_id AND dds.partition_scheme_id = i.data_space_id AND i.type <= 1 /* Heap or Clustered Index */
INNER JOIN sys.index_columns AS ic ON i.index_id = ic.index_id AND i.object_id = ic.object_id AND ic.partition_ordinal > 0
INNER JOIN sys.columns AS c ON pstats.object_id = c.object_id AND ic.column_id = c.column_id
LEFT JOIN sys.partition_range_values AS prv ON pf.function_id = prv.function_id AND pstats.partition_number = (CASE pf.boundary_value_on_right WHEN 0 THEN prv.boundary_id ELSE (prv.boundary_id+1) END)
ORDER BY ObjectName, PartitionNumber;

GO

-- Start the real work ---

--- Create Partition function
CREATE PARTITION FUNCTION pf_3weeks(Datetime2(3)) 
AS RANGE LEFT FOR VALUES ('2019-07-20', '2019-07-27'); 
GO

--- Create Partition Scheme
CREATE PARTITION SCHEME ps_3filegroups
AS PARTITION pf_3weeks
TO (fg_week0,fg_week1,fg_week2);
GO


-- Demo table
CREATE TABLE tbl_msgs (
CreatedAt DATETIME2(3) NOT NULL,
MsgSequenceNumber INT NOT NULL DEFAULT 1,
MsgText nvarchar(50)
);

-- Add the index 
-- partitiooned against the datetime2 field
ALTER TABLE tbl_msgs ADD CONSTRAINT PK_Orders PRIMARY KEY Clustered (CreatedAt, MsgSequenceNumber)
ON ps_3filegroups (CreatedAt);
GO

-- Create some bogus data
INSERT INTO tbl_msgs(CreatedAt,MsgSequenceNumber,MsgText)
VALUES(DateAdd(d, ROUND(DateDiff(d, '2019-07-10', '2019-07-26') * RAND(CHECKSUM(NEWID())), 0),DATEADD(second,CHECKSUM(NEWID())%48000, '2019-07-10')),
       ABS(CHECKSUM(NewId())) % 1000,
	   'Something happened you know.' )
GO 2000


exec usp_getpartitiondetails

-- Note the row counts
-- objectname	Filegroup	PartitionScheme	PartitionFunctionName	RangeType	Boundary	PartitionBoundaryValue	Field	PartitionRange	PartitionNumber	RowsInPartition
--[dbo].[tbl_msgs]	fg_week0	ps_3filegroups	pf_3weeks	Left	Upper	2019-07-20 00:00:00.000	CreatedAt	CreatedAt > (No Limit) and CreatedAt <= Jul 20 2019 12:00AM	1	1264
--[dbo].[tbl_msgs]	fg_week1	ps_3filegroups	pf_3weeks	Left	Upper	2019-07-27 00:00:00.000	CreatedAt	CreatedAt > Jul 20 2019 12:00AM and CreatedAt <= Jul 27 2019 12:00AM	2	736
--[dbo].[tbl_msgs]	fg_week2	ps_3filegroups	pf_3weeks	Left	Upper	NULL	CreatedAt	CreatedAt > Jul 27 2019 12:00AM and CreatedAt <= (No Limit)	3	0
-- With SQL Server 2016, truncate a partition to get rid of the old data
-- if you need to store it you would switch a partition to another table

TRUNCATE TABLE tbl_msgs WITH (PARTITIONS(1))
 

 exec usp_getpartitiondetails
 -- partition 1 has now 0 rows
 -- objectname	Filegroup	PartitionScheme	PartitionFunctionName	RangeType	Boundary	PartitionBoundaryValue	Field	PartitionRange	PartitionNumber	RowsInPartition
--[dbo].[tbl_msgs]	fg_week0	ps_3filegroups	pf_3weeks	Left	Upper	2019-07-20 00:00:00.000	CreatedAt	CreatedAt > (No Limit) and CreatedAt <= Jul 20 2019 12:00AM	1	0
--[dbo].[tbl_msgs]	fg_week1	ps_3filegroups	pf_3weeks	Left	Upper	2019-07-27 00:00:00.000	CreatedAt	CreatedAt > Jul 20 2019 12:00AM and CreatedAt <= Jul 27 2019 12:00AM	2	736
--[dbo].[tbl_msgs]	fg_week2	ps_3filegroups	pf_3weeks	Left	Upper	NULL	CreatedAt	CreatedAt > Jul 27 2019 12:00AM and CreatedAt <= (No Limit)	3	0
-
 ALTER PARTITION SCHEME ps_3filegroups NEXT USED fg_week0

  exec usp_getpartitiondetails
 -- still same answer

 ALTER PARTITION FUNCTION pf_3weeks() SPLIT RANGE ('2019-08-04')
  exec usp_getpartitiondetails
 -- a new boundary has appeared fore Aug, 4th
--objectname	Filegroup	PartitionScheme	PartitionFunctionName	RangeType	Boundary	PartitionBoundaryValue	Field	PartitionRange	PartitionNumber	RowsInPartition
--[dbo].[tbl_msgs]	fg_week0	ps_3filegroups	pf_3weeks	Left	Upper	2019-07-20 00:00:00.000	CreatedAt	CreatedAt > (No Limit) and CreatedAt <= Jul 20 2019 12:00AM	1	0
--[dbo].[tbl_msgs]	fg_week1	ps_3filegroups	pf_3weeks	Left	Upper	2019-07-27 00:00:00.000	CreatedAt	CreatedAt > Jul 20 2019 12:00AM and CreatedAt <= Jul 27 2019 12:00AM	2	736
--[dbo].[tbl_msgs]	fg_week0	ps_3filegroups	pf_3weeks	Left	Upper	2019-08-04 00:00:00.000	CreatedAt	CreatedAt > Jul 27 2019 12:00AM and CreatedAt <= Aug  4 2019 12:00AM	3	0
--[dbo].[tbl_msgs]	fg_week2	ps_3filegroups	pf_3weeks	Left	Upper	NULL	CreatedAt	CreatedAt > Aug  4 2019 12:00AM and CreatedAt <= (No Limit)	4	0

 ALTER PARTITION FUNCTION pf_3weeks() MERGE RANGE ('2019-07-20')
  exec usp_getpartitiondetails
  -- We merged the useless partition on fg_week0
--[dbo].[tbl_msgs]	fg_week1	ps_3filegroups	pf_3weeks	Left	Upper	2019-07-27 00:00:00.000	CreatedAt	CreatedAt > (No Limit) and CreatedAt <= Jul 27 2019 12:00AM	1	736
--[dbo].[tbl_msgs]	fg_week0	ps_3filegroups	pf_3weeks	Left	Upper	2019-08-04 00:00:00.000	CreatedAt	CreatedAt > Jul 27 2019 12:00AM and CreatedAt <= Aug  4 2019 12:00AM	2	0
--[dbo].[tbl_msgs]	fg_week2	ps_3filegroups	pf_3weeks	Left	Upper	NULL	CreatedAt	CreatedAt > Aug  4 2019 12:00AM and CreatedAt <= (No Limit)	3	0

-- -- get out of the database
  USE [master]
  GO
