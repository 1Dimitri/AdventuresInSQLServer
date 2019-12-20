SELECT
  es.session_id AS [SESSION ID]
  ,DB_NAME(es.database_id) AS [DB]
  ,HOST_NAME AS [System Name]
 -- ,program_name AS [Program Name]
  ,login_name AS [USER Name]
  ,status
    ,(internal_objects_alloc_page_count * 8) AS [SPACE Allocated FOR Internal Objects (in KB)]
  ,(internal_objects_dealloc_page_count * 8) AS [SPACE Deallocated FOR Internal Objects (in KB)]

  ,cpu_time AS [CPU TIME (in milisec)]
  ,total_scheduled_time AS [Total Scheduled TIME (in milisec)]
  ,total_elapsed_time AS    [Elapsed TIME (in milisec)]
  ,(memory_usage * 8)      AS [Memory USAGE (in KB)]
  ,(user_objects_alloc_page_count * 8) AS [SPACE Allocated FOR USER Objects (in KB)]
  ,(user_objects_dealloc_page_count * 8) AS [SPACE Deallocated FOR USER Objects (in KB)]
  ,CASE is_user_process
             WHEN 1      THEN 'user'
             WHEN 0      THEN 'system'
  END         AS [SESSION Type], row_count AS [ROW COUNT]
FROM 
  sys.dm_db_session_space_usage as ssu
INNER join
  sys.dm_exec_sessions as es
ON  ssu.session_id = es.session_id
ORDER BY [SPACE Allocated FOR Internal Objects (in KB)] DESC,[DB]

