-- startup parameters
-- IP addresses
-- MachineID for SQM (Telemetry)

select * from sys.dm_server_registry

-- services
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-server-services-transact-sql?view=sql-server-ver15

select * from sys.dm_server_services
