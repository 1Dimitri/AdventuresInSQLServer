-- sys.master_files: basically gives one line per file for all databases,
-- whereas sys.database_files is a per database view
-- !!! Sizes are in 8KB page units



-- one line by file for every db 
-- rounded size in MB

select DB_NAME(database_id) as databasename, type_desc ,physical_name, cast (size*8.0/1024 as int ) as SizeMB from sys.master_files
order by database_id

-- sum by database
select DB_NAME(database_id) as databasename, cast(sum(size)*8.0/1024 as int ) as TotalSizeMB from sys.master_files
group by database_id
order by database_id

-- sum by file type
-- being lazy using type_desc friendly description instead of numeric type
select type_desc, cast(sum(size)*8.0/1024 as int ) as TotalSizeMB from sys.master_files
group by type_desc
order by type_desc

