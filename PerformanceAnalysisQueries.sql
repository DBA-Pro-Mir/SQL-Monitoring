USE Blitz; -- Change this if using a different database

-- 1. Monthly Summary of Metrics by Step
PRINT '--- Monthly Summary of Metrics by Step ---';
SELECT 
    StepName,
    MetricName,
    SUM(TotalValue) AS TotalValue,
    AVG(AvgValue) AS AvgValue,
    MAX(MaxValue) AS MaxValue,
    MIN(MinValue) AS MinValue,
    SUM(RecordCount) AS TotalRecords
FROM MonthlyJobMetrics
WHERE MonthYear = FORMAT(GETDATE(), 'yyyy-MM') -- Current month
GROUP BY StepName, MetricName
ORDER BY StepName, MetricName;

-- 2. Monthly Top 10 Worst Queries
PRINT '--- Monthly Top 10 Worst Queries ---';
SELECT TOP 10
    DatabaseName,
    QueryText, -- Replaced QueryText with AdditionalInfo
    TotalCPUTime_ms,
    ExecutionCount,
    AvgCPUTime_ms
FROM MonthlyWorstQueries
WHERE MonthYear = FORMAT(GETDATE(), 'yyyy-MM') -- Current month
ORDER BY TotalCPUTime_ms DESC;

-- 3. Daily Metrics Trend
PRINT '--- Daily Metrics Trend ---';
SELECT 
    CAST(ExecutionTime AS DATE) AS ExecutionDate,
    StepName,
    MetricName,
    SUM(CAST(MetricValue AS FLOAT)) AS TotalValue,
    AVG(CAST(MetricValue AS FLOAT)) AS AvgValue
FROM JobStepMetrics
WHERE ExecutionTime >= DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0) -- Start of current month
  AND ExecutionTime < DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) + 1, 0) -- Start of next month
GROUP BY CAST(ExecutionTime AS DATE), StepName, MetricName
ORDER BY ExecutionDate, StepName, MetricName;

-- 4. Identify Metrics with Maximum Values
PRINT '--- Identify Metrics with Maximum Values ---';
SELECT 
    StepName,
    MetricName,
    MAX(CAST(MetricValue AS FLOAT)) AS MaxValue,
    ExecutionTime
FROM JobStepMetrics
WHERE ExecutionTime >= DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0) -- Start of current month
  AND ExecutionTime < DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) + 1, 0) -- Start of next month
GROUP BY StepName, MetricName, ExecutionTime
ORDER BY MaxValue DESC;

-- 5. Database-Specific Analysis
PRINT '--- Database-Specific Analysis ---';
SELECT 
    DatabaseName,
    StepName,
    MetricName,
    SUM(CAST(MetricValue AS FLOAT)) AS TotalValue,
    AVG(CAST(MetricValue AS FLOAT)) AS AvgValue,
    MAX(CAST(MetricValue AS FLOAT)) AS MaxValue,
    MIN(CAST(MetricValue AS FLOAT)) AS MinValue
FROM JobStepMetrics
WHERE ExecutionTime >= DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0) -- Start of current month
  AND ExecutionTime < DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) + 1, 0) -- Start of next month
GROUP BY DatabaseName, StepName, MetricName
ORDER BY DatabaseName, StepName, MetricName;

-- 6. Query Usage Distribution
PRINT '--- Query Usage Distribution ---';
SELECT 
    DatabaseName,
    AdditionalInfo AS QueryText, -- Replaced QueryText with AdditionalInfo
    COUNT(*) AS ExecutionCount,
    AVG(CAST(MetricValue AS FLOAT)) AS AvgMetricValue,
    MAX(CAST(MetricValue AS FLOAT)) AS MaxMetricValue
FROM JobStepMetrics
WHERE StepName = 'CPU Utilization and Wait Stats'
  AND ExecutionTime >= DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0) -- Start of current month
  AND ExecutionTime < DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) + 1, 0) -- Start of next month
GROUP BY DatabaseName, AdditionalInfo
ORDER BY ExecutionCount DESC;

-- 7. Compare Metrics Across Months
PRINT '--- Compare Metrics Across Months ---';
SELECT 
    StepName,
    MetricName,
    MonthYear,
    SUM(TotalValue) AS TotalValue
FROM MonthlyJobMetrics
WHERE MonthYear IN (
    FORMAT(DATEADD(MONTH, -2, GETDATE()), 'yyyy-MM'),
    FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy-MM'),
    FORMAT(GETDATE(), 'yyyy-MM')
)
GROUP BY StepName, MetricName, MonthYear
ORDER BY StepName, MetricName, MonthYear;

-- 8. Detect Performance Spikes
PRINT '--- Detect Performance Spikes ---';
WITH MetricDailyTotals AS (
    SELECT 
        StepName,
        MetricName,
        CAST(ExecutionTime AS DATE) AS ExecutionDate,
        SUM(CAST(MetricValue AS FLOAT)) AS DailyTotal,
        AVG(SUM(CAST(MetricValue AS FLOAT))) OVER (PARTITION BY StepName, MetricName) AS AvgTotal
    FROM JobStepMetrics
    WHERE ExecutionTime >= DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0) -- Start of current month
      AND ExecutionTime < DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) + 1, 0) -- Start of next month
    GROUP BY StepName, MetricName, CAST(ExecutionTime AS DATE)
)
SELECT 
    StepName,
    MetricName,
    ExecutionDate,
    DailyTotal,
    AvgTotal
FROM MetricDailyTotals
WHERE DailyTotal > 1.5 * AvgTotal
ORDER BY ExecutionDate, StepName, MetricName;
