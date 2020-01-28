-- All server properties for SQL Server 2016 and higher
-- based on
-- https://docs.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver15

DECLARE @props TABLE (propertyname sysname PRIMARY KEY)
INSERT INTO @props(propertyname)
SELECT 'BuildClrVersion'
UNION
SELECT 'Collation'
UNION
SELECT 'CollationID'
UNION
SELECT 'ComparisonStyle'
UNION
SELECT 'ComputerNamePhysicalNetBIOS'
UNION
SELECT 'Edition'
UNION
SELECT 'EditionID'
UNION
SELECT 'EngineEdition'
UNION
SELECT 'HadrManagerStatus'
UNION
SELECT 'InstanceDefaultDataPath'
UNION
SELECT 'InstanceDefaultLogPath'
UNION
SELECT 'InstanceName'
UNION
SELECT 'IsAdvancedAnalyticsInstalled'
UNION
SELECT 'IsClustered'
UNION
SELECT 'IsFullTextInstalled'
UNION
SELECT 'IsHadrEnabled'
UNION
SELECT 'IsIntegratedSecurityOnly'
UNION
SELECT 'IsLocalDB'
UNION
SELECT 'IsPolybaseInstalled'
UNION
SELECT 'IsSingleUser'
UNION
SELECT 'IsXTPInstalled'
UNION
SELECT 'LCID'
UNION
SELECT 'LicenseType'
UNION
SELECT 'MachineName'
UNION
SELECT 'NumLicenses'
UNION
SELECT 'ProcessID'
UNION
SELECT 'ProductBuild'
UNION
SELECT 'ProductBuildType'
UNION
SELECT 'ProductVersion'
UNION
SELECT 'ProductLevel'
UNION
SELECT 'ProductMajorVersion'
UNION
SELECT 'ProductMinorVersion'
UNION
SELECT 'ProductUpdateLevel'
UNION
SELECT 'ProductUpdateReference'
UNION
SELECT 'ProductVersion'
UNION
SELECT 'ResourceLastUpdateDateTime'
UNION
SELECT 'ResourceVersion'
UNION
SELECT 'ServerName'
UNION
SELECT 'SqlCharSet'
UNION
SELECT 'SqlCharSetName'
UNION
SELECT 'SqlSortOrder'
UNION
SELECT 'SqlSortOrderName'
UNION
SELECT 'FilestreamShareName'
UNION
SELECT 'FilestreamConfiguredLevel'
UNION
SELECT 'FilestreamEffectiveLevel'
 
SELECT propertyname, SERVERPROPERTY(propertyname) AS PropertyValue FROM @props
