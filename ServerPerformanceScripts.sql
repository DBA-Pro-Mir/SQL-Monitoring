USE [msdb]
GO

/****** Object:  Job [Server Performance Monitoring]    Script Date: 1/6/2025 11:36:31 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 1/6/2025 11:36:31 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Server Performance Monitoring', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Analyze server performance and capture metrics in JobStepMetrics table.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [CPU Utilization and Wait Stats]    Script Date: 1/6/2025 11:36:31 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'CPU Utilization and Wait Stats', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
USE Blitz;

INSERT INTO JobStepMetrics (JobName, StepName, MetricName, MetricValue, DatabaseName, AdditionalInfo)
SELECT 
    ''Server Performance Monitoring'' AS JobName,
    ''CPU Utilization and Wait Stats'' AS StepName,
    ''CPU_Time_ms'' AS MetricName,
    r.cpu_time AS MetricValue,
    DB_NAME() AS DatabaseName,
    st.text AS AdditionalInfo
FROM 
    sys.dm_exec_requests r
CROSS APPLY 
    sys.dm_exec_sql_text(r.sql_handle) AS st
WHERE 
    r.status IN (''running'', ''runnable'')
ORDER BY 
    r.cpu_time DESC;
', 
		@database_name=N'Blitz', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Wait Statistics Overview]    Script Date: 1/6/2025 11:36:31 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Wait Statistics Overview', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE Blitz;

INSERT INTO JobStepMetrics (JobName, StepName, MetricName, MetricValue, DatabaseName, AdditionalInfo)
SELECT 
    ''Server Performance Monitoring'' AS JobName,
    ''Wait Statistics Overview'' AS StepName,
    ''Wait_Time_sec'' AS MetricName,
    wait_time_ms / 1000.0 AS MetricValue,
    NULL AS DatabaseName,  -- No database context for wait stats
    wait_type AS AdditionalInfo
FROM 
    sys.dm_os_wait_stats
WHERE 
    wait_type NOT IN (
        ''SLEEP_TASK'', ''SQLTRACE_INCREMENTAL_FLUSH_SLEEP'', 
        ''BROKER_TASK_STOP'', ''CLR_AUTO_EVENT'', ''BROKER_TO_FLUSH'',
        ''BROKER_EVENTHANDLER'', ''XE_TIMER_EVENT'', ''LAZYWRITER_SLEEP'',
        ''DIRTY_PAGE_POLL'', ''CLR_MANUAL_EVENT'', ''SLEEP_SYSTEMTASK'', 
        ''SLEEP_BPOOL_FLUSH'', ''CHECKPOINT_QUEUE'', ''REQUEST_FOR_DEADLOCK_SEARCH'',
        ''XE_DISPATCHER_WAIT'', ''XE_DISPATCHER_JOIN'', ''SQLTRACE_WAIT_ENTRIES''
    )
ORDER BY 
    wait_time_ms DESC;
', 
		@database_name=N'Blitz', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [I/O Statistics]    Script Date: 1/6/2025 11:36:31 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'I/O Statistics', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
USE Blitz;

INSERT INTO JobStepMetrics (JobName, StepName, MetricName, MetricValue, DatabaseName, AdditionalInfo)
SELECT 
    ''Server Performance Monitoring'' AS JobName,
    ''I/O Statistics'' AS StepName,
    ''Read_Stall_MS'' AS MetricName,
    fs.io_stall_read_ms AS MetricValue,
    DB_NAME(fs.database_id) AS DatabaseName,
    mf.physical_name AS AdditionalInfo
FROM 
    sys.dm_io_virtual_file_stats(NULL, NULL) AS fs
JOIN 
    sys.master_files AS mf ON fs.database_id = mf.database_id AND fs.file_id = mf.file_id
ORDER BY 
    fs.io_stall_read_ms DESC;
', 
		@database_name=N'Blitz', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Disk Usage]    Script Date: 1/6/2025 11:36:31 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Disk Usage', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
USE Blitz;

INSERT INTO JobStepMetrics (JobName, StepName, MetricName, MetricValue, DatabaseName, AdditionalInfo)
SELECT 
    ''Server Performance Monitoring'' AS JobName,
    ''Disk Usage'' AS StepName,
    ''Total_Space_MB'' AS MetricName,
    total_bytes / 1048576 AS MetricValue,
    NULL AS DatabaseName,
    volume_mount_point AS AdditionalInfo
FROM 
    sys.dm_os_volume_stats(NULL, NULL);
', 
		@database_name=N'Blitz', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Memory Usage]    Script Date: 1/6/2025 11:36:31 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Memory Usage', 
		@step_id=5, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
USE Blitz;

INSERT INTO JobStepMetrics (JobName, StepName, MetricName, MetricValue, DatabaseName, AdditionalInfo)
SELECT 
    ''Server Performance Monitoring'' AS JobName,
    ''Memory Usage'' AS StepName,
    ''SQLServerMemoryUsageMB'' AS MetricName,
    physical_memory_in_use_kb / 1024 AS MetricValue,
    NULL AS DatabaseName,
    NULL AS AdditionalInfo
FROM 
    sys.dm_os_process_memory;
', 
		@database_name=N'Blitz', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Most Expensive Queries]    Script Date: 1/6/2025 11:36:31 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Most Expensive Queries', 
		@step_id=6, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
USE Blitz;

INSERT INTO JobStepMetrics (JobName, StepName, MetricName, MetricValue, DatabaseName, AdditionalInfo)
SELECT 
    ''Server Performance Monitoring'' AS JobName,
    ''Most Expensive Queries'' AS StepName,
    ''Total_CPU_Time_ms'' AS MetricName,
    qs.total_worker_time / 1000 AS MetricValue,
    DB_NAME(qp.dbid) AS DatabaseName,
    SUBSTRING(qt.text, (qs.statement_start_offset / 2) + 1,
              ((CASE qs.statement_end_offset
                WHEN -1 THEN DATALENGTH(qt.text)
                ELSE qs.statement_end_offset END
              - qs.statement_start_offset) / 2) + 1) AS AdditionalInfo
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
OUTER APPLY sys.dm_exec_text_query_plan(qs.plan_handle, qs.statement_start_offset, qs.statement_end_offset) qp
ORDER BY qs.total_worker_time DESC;
', 
		@database_name=N'Blitz', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Identify Worst Queries]    Script Date: 1/6/2025 11:36:32 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Identify Worst Queries', 
		@step_id=7, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
USE Blitz;

-- Insert the 10 worst queries of the current month
INSERT INTO MonthlyWorstQueries (
    MonthYear, DatabaseName, QueryText, TotalCPUTime_ms, ExecutionCount, 
    AvgCPUTime_ms
)
SELECT 
    FORMAT(GETDATE(), ''yyyy-MM'') AS MonthYear,
    DatabaseName,
    AdditionalInfo AS QueryText,
    MAX(CAST(MetricValue AS FLOAT)) AS TotalCPUTime_ms,
    COUNT(*) AS ExecutionCount,
    MAX(CAST(MetricValue AS FLOAT)) / COUNT(*) AS AvgCPUTime_ms
FROM JobStepMetrics
WHERE StepName = ''Most Expensive Queries''
  AND ExecutionTime >= DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)  -- Start of current month
  AND ExecutionTime < DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) + 1, 0)  -- Start of next month
GROUP BY DatabaseName, AdditionalInfo
ORDER BY TotalCPUTime_ms DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
', 
		@database_name=N'Blitz', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Summarize Monthly Metrics]    Script Date: 1/6/2025 11:36:32 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Summarize Monthly Metrics', 
		@step_id=8, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
USE Blitz;

-- Summarize metrics for the current month
INSERT INTO MonthlyJobMetrics (StepName, MetricName, MonthYear, TotalValue, AvgValue, MaxValue, MinValue, RecordCount)
SELECT 
    StepName,
    MetricName,
    CONVERT(VARCHAR(7), ExecutionTime, 120) AS MonthYear, -- "yyyy-MM" format
    SUM(CAST(MetricValue AS FLOAT)) AS TotalValue,
    AVG(CAST(MetricValue AS FLOAT)) AS AvgValue,
    MAX(CAST(MetricValue AS FLOAT)) AS MaxValue,
    MIN(CAST(MetricValue AS FLOAT)) AS MinValue,
    COUNT(*) AS RecordCount
FROM JobStepMetrics
WHERE ExecutionTime >= DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)  -- Start of current month
  AND ExecutionTime < DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) + 1, 0)  -- Start of next month
GROUP BY StepName, MetricName, CONVERT(VARCHAR(7), ExecutionTime, 120); -- "yyyy-MM" format
', 
		@database_name=N'Blitz', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Prune Old Data]    Script Date: 1/6/2025 11:36:32 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Prune Old Data', 
		@step_id=9, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
USE Blitz;

DELETE FROM JobStepMetrics
WHERE ExecutionTime < DATEADD(MONTH, -1, GETDATE());
', 
		@database_name=N'Blitz', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Server Performance Monitoring Schedule', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20250102, 
		@active_end_date=99991231, 
		@active_start_time=80000, 
		@active_end_time=235959, 
		@schedule_uid=N'95f17d1a-f058-485d-9137-8610f2b1b004'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


