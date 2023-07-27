USE MSDB;
GO

DECLARE @job_id uniqueidentifier

DECLARE job_cursor CURSOR READ_ONLY FOR  
SELECT SJ.job_id
FROM msdb.dbo.sysjobs SJ
-- INNER JOIN msdb.dbo.syscategories SC on SJ.category_id = SC.category_id
WHERE SJ.enabled = 1
  -- by job category
--  AND SC.[name] = N'Database Maintenance'

OPEN job_cursor   
FETCH NEXT FROM job_cursor INTO @job_id  

WHILE @@FETCH_STATUS = 0
BEGIN
   EXEC msdb.dbo.sp_update_job @job_id = @job_id, @enabled = 0
   FETCH NEXT FROM job_cursor INTO @job_id  
END

CLOSE job_cursor   
DEALLOCATE job_cursor
