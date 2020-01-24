
-- Where to record
-- database: my_database
-- schema: my_schema
-- table: table_name

--What to record
-- original_table eg.  master.sys.databases

-- create table
IF NOT EXISTS (SELECT * FROM [my_database].[sys].[tables] WHERE name='table_name')
	select @@SERVERNAME as instance,*, GETUTCDATE() as recorded_at_utc
	into [my_database].[my_schema].[table_name]
	from original_table
ELSE
-- or update table
	insert [my_database].[my_schema].[table_name]
	select  @@SERVERNAME as instance, *, GETUTCDATE() as recorded_at_utc
	from @table


