-- get a list of objects in the database which are signed.

-- USE [mydb]
-- go

SELECT quotename(sch.name)+'.'+quotename(obj.name) AS [database object],  cp.class_desc  as [Object Type], certs.name AS [Certificate], certs.subject as [Certificate Subject], dp.name as [Username], cp.thumbprint
FROM sys.crypt_properties cp
JOIN sys.certificates as certs ON certs.thumbprint = cp.thumbprint
LEFT JOIN sys.database_principals dp ON certs.sid = dp.sid
JOIN sys.objects as obj ON cp.major_id = obj.object_id
JOIN sys.schemas as sch ON obj.schema_id = sch.schema_id
