-- taken from SQL Server's 2016 instmsdb.sql in  <Instance Folder>\MSSQL\Install
-- sp_enable_component enable setting like 'xp_cmdshell' after storing its current state
-- sp_restore_component_state restores the recorded state
-- Example:
-- EXECUTE #sp_enable_component 'xp_cmdshell', @advopt_old_value out, @comp_old_value out
-- EXEC master.dbo.xp_cmdshell N''DEL *.old'
-- EXECUTE #sp_restore_component_state 'xp_cmdshell', @advopt_old_value, @comp_old_value
	
CREATE PROCEDURE sp_enable_component     
   @comp_name     sysname, 
   @advopt_old_value    INT OUT, 
   @comp_old_value   INT OUT 
AS
   BEGIN
   SELECT @advopt_old_value=cast(value_in_use as int) from sys.configurations where name = 'show advanced options';
   SELECT @comp_old_value=cast(value_in_use as int) from sys.configurations where name = @comp_name; 
   EXEC sp_configure 'show advanced options',1;
   RECONFIGURE WITH OVERRIDE;
   EXEC sp_configure @comp_name, 1; 
   RECONFIGURE WITH OVERRIDE;
   END
go


CREATE PROCEDURE sp_restore_component_state 
   @comp_name     sysname, 
   @advopt_old_value    INT, 
   @comp_old_value   INT 
AS
   BEGIN
   EXEC sp_configure @comp_name, @comp_old_value; 
   RECONFIGURE WITH OVERRIDE;
   EXEC sp_configure 'show advanced options',@advopt_old_value;
   RECONFIGURE WITH OVERRIDE;
   END
go
