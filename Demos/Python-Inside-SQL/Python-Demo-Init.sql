-- Add support for running R / Python

exec sp_configure 'external scripts enabled', 1;
go
RECONFIGURE

-- check Python is fine
-- first run will need a warm up and thus takes longer

EXECUTE sp_execute_external_script @language = N'Python'
    , @script = N'import sys; print(f"Hello from Python {sys.version}")'

-- Python 3.7 so it is likely you get f strings support

