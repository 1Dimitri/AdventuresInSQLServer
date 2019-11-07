-- Retrieve xml data from Integration Services packages created by built-in wizards
-- Tested on SQL Server 2016 SP2, 2019 CTP 3.2
SELECT  
	isp.name AS pname
	,isp.description
	,ispf.foldername as folder
	,CASE isp.packagetype
		WHEN 0 THEN 'Default client'
		WHEN 1 THEN 'I/O Wizard'
		WHEN 2 THEN 'DTS Designer'
		WHEN 3 THEN 'Replication'
		WHEN 5 THEN 'SSIS Designer'
		WHEN 6 THEN 'Maintenance Plan'
	ELSE 'Unknown'
	END AS package_type
	,isp.createdate AS created_on 
	,CAST(CAST([packagedata] as varbinary(max)) as xml) XmlData
FROM msdb.dbo.sysssispackages AS isp 
INNER JOIN msdb.dbo.sysssispackagefolders AS ispf
	ON isp.folderid = ispf.folderid
ORDER BY isp.name
