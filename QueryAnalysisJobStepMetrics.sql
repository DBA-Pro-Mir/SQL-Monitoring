--Top Resource Intensive Databases
--- Identify the databases with the highest total CPU and I/O wait times over the last 7 days.

SELECT 
    DatabaseName,
    MetricName,
    SUM(CAST(MetricValue AS FLOAT)) AS TotalMetricValue,
    AVG(CAST(MetricValue AS FLOAT)) AS AvgMetricValue
FROM JobStepMetrics
WHERE MetricName IN ('Total_IO_Wait_Sec', 'Total_CPU_Time_ms') -- Focus on I/O and CPU
  AND ExecutionTime >= DATEADD(DAY, -7, GETDATE()) -- Last 7 days
  AND DatabaseName NOT IN ('master', 'model', 'msdb', 'tempdb') -- Exclude system databases
GROUP BY DatabaseName, MetricName
ORDER BY TotalMetricValue DESC;

-- Query Wait Statistics Overview
--

SELECT 
    MetricName AS WaitType,
    SUM(CAST(MetricValue AS FLOAT)) AS TotalWaitTimeSec,
    AVG(CAST(MetricValue AS FLOAT)) AS AvgWaitTimeSec
FROM JobStepMetrics
WHERE MetricName = 'Wait_Time_sec' -- Focus on wait time statistics
  AND ExecutionTime >= DATEADD(DAY, -7, GETDATE()) -- Last 7 days
GROUP BY MetricName
ORDER BY TotalWaitTimeSec DESC;


-- Disk IO Latency Analysis

SELECT 
    DatabaseName,
    MetricName,
    SUM(CAST(MetricValue AS FLOAT)) AS TotalReadStallMS,
    AVG(CAST(MetricValue AS FLOAT)) AS AvgReadStallMS
FROM JobStepMetrics
WHERE MetricName = 'Read_Stall_MS' -- Focus on disk read stalls
  AND ExecutionTime >= DATEADD(DAY, -7, GETDATE()) -- Last 7 days
  AND DatabaseName NOT IN ('master', 'model', 'msdb', 'tempdb') -- Exclude system databases
GROUP BY DatabaseName, MetricName
ORDER BY TotalReadStallMS DESC;


-- Cpu Isage Trends

SELECT 
    CAST(ExecutionTime AS DATE) AS SnapshotDate,
    DatabaseName,
    SUM(CAST(MetricValue AS FLOAT)) AS TotalCPUTime_ms,
    AVG(CAST(MetricValue AS FLOAT)) AS AvgCPUTime_ms
FROM JobStepMetrics
WHERE MetricName = 'Total_CPU_Time_ms' -- Focus on total CPU time
  AND ExecutionTime >= DATEADD(MONTH, -1, GETDATE()) -- Last 30 days
  AND DatabaseName NOT IN ('master', 'model', 'msdb', 'tempdb') -- Exclude system databases
GROUP BY CAST(ExecutionTime AS DATE), DatabaseName
ORDER BY SnapshotDate DESC, TotalCPUTime_ms DESC;


-- Query Memory Usage Analysis

SELECT 
    CAST(ExecutionTime AS DATE) AS SnapshotDate,
    MetricName,
    AVG(CAST(MetricValue AS FLOAT)) AS AvgMemoryUsageMB
FROM JobStepMetrics
WHERE MetricName = 'SQLServerMemoryUsageMB' -- Focus on memory usage
  AND ExecutionTime >= DATEADD(MONTH, -1, GETDATE()) -- Last 30 days
GROUP BY CAST(ExecutionTime AS DATE), MetricName
ORDER BY SnapshotDate DESC;

-- Detect performance Spikes


WITH MetricDailyAverages AS (
    SELECT 
        CAST(ExecutionTime AS DATE) AS ExecutionDate,
        MetricName,
        AVG(CAST(MetricValue AS FLOAT)) AS DailyAvg
    FROM JobStepMetrics
    WHERE MetricName IN ('Total_IO_Wait_Sec', 'Total_CPU_Time_ms', 'Wait_Time_sec') -- Focus on key metrics
      AND ExecutionTime >= DATEADD(MONTH, -1, GETDATE()) -- Last 30 days
    GROUP BY CAST(ExecutionTime AS DATE), MetricName
),
LongTermAverages AS (
    SELECT 
        MetricName,
        AVG(CAST(MetricValue AS FLOAT)) AS LongTermAvg
    FROM JobStepMetrics
    WHERE MetricName IN ('Total_IO_Wait_Sec', 'Total_CPU_Time_ms', 'Wait_Time_sec') -- Focus on key metrics
      AND ExecutionTime >= DATEADD(MONTH, -1, GETDATE()) -- Last 30 days
    GROUP BY MetricName
)
SELECT 
    da.ExecutionDate,
    da.MetricName,
    da.DailyAvg,
    lta.LongTermAvg,
    (da.DailyAvg - lta.LongTermAvg) AS Deviation
FROM MetricDailyAverages da
JOIN LongTermAverages lta
    ON da.MetricName = lta.MetricName
WHERE (da.DailyAvg - lta.LongTermAvg) > 1.5 * lta.LongTermAvg -- Significant deviation
ORDER BY Deviation DESC;

