--Overall Trends Across Metrics

SELECT 
    MonthYear,
    StepName,
    MetricName,
    SUM(TotalValue) AS TotalValue,
    AVG(AvgValue) AS AvgValue,
    MAX(MaxValue) AS MaxValue,
    MIN(MinValue) AS MinValue
FROM MonthlyJobMetrics
WHERE MonthYear IN (
    FORMAT(DATEADD(MONTH, -2, GETDATE()), 'yyyy-MM'),
    FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy-MM'),
    FORMAT(GETDATE(), 'yyyy-MM')
)
GROUP BY MonthYear, StepName, MetricName
ORDER BY MonthYear, StepName, MetricName;

-- Metrics Significative Increase

WITH MonthlyTrends AS (
    SELECT 
        StepName,
        MetricName,
        MonthYear,
        SUM(TotalValue) AS TotalValue
    FROM MonthlyJobMetrics
    WHERE MonthYear IN (
        FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy-MM'),
        FORMAT(GETDATE(), 'yyyy-MM')
    )
    GROUP BY StepName, MetricName, MonthYear
)
SELECT 
    mt1.StepName,
    mt1.MetricName,
    mt1.MonthYear AS CurrentMonth,
    mt1.TotalValue AS CurrentValue,
    mt2.TotalValue AS PreviousValue,
    (mt1.TotalValue - mt2.TotalValue) AS Difference
FROM MonthlyTrends mt1
JOIN MonthlyTrends mt2
    ON mt1.StepName = mt2.StepName
    AND mt1.MetricName = mt2.MetricName
    AND FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy-MM') = mt2.MonthYear
WHERE mt1.MonthYear = FORMAT(GETDATE(), 'yyyy-MM') -- Current month
  AND (mt1.TotalValue - mt2.TotalValue) > 0 -- Detect increases
ORDER BY Difference DESC;

-- Under performance steps

SELECT 
    StepName,
    MetricName,
    AVG(AvgValue) AS AvgMetricValue,
    MIN(MinValue) AS MinMetricValue
FROM MonthlyJobMetrics
WHERE MonthYear = FORMAT(GETDATE(), 'yyyy-MM') -- Current month
GROUP BY StepName, MetricName
HAVING AVG(AvgValue) < 100 -- Example threshold, adjust based on environment
ORDER BY AvgMetricValue ASC;


-- Monthly Worst Queries

SELECT TOP 10
    DatabaseName,
    QueryText,
    TotalCPUTime_ms,
    ExecutionCount,
    AvgCPUTime_ms
FROM MonthlyWorstQueries
WHERE MonthYear = FORMAT(GETDATE(), 'yyyy-MM') -- Current month
ORDER BY TotalCPUTime_ms DESC;

-- Query performance month over month

WITH WorstQueries AS (
    SELECT 
        MonthYear,
        DatabaseName,
        QueryText,
        SUM(TotalCPUTime_ms) AS TotalCPUTime_ms
    FROM MonthlyWorstQueries
    WHERE MonthYear IN (
        FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy-MM'),
        FORMAT(GETDATE(), 'yyyy-MM')
    )
    GROUP BY MonthYear, DatabaseName, QueryText
)
SELECT 
    wq1.DatabaseName,
    wq1.QueryText,
    wq1.TotalCPUTime_ms AS CurrentCPUTime,
    wq2.TotalCPUTime_ms AS PreviousCPUTime,
    (wq1.TotalCPUTime_ms - wq2.TotalCPUTime_ms) AS CPUTimeDifference
FROM WorstQueries wq1
JOIN WorstQueries wq2
    ON wq1.QueryText = wq2.QueryText
    AND wq1.DatabaseName = wq2.DatabaseName
    AND FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy-MM') = wq2.MonthYear
WHERE wq1.MonthYear = FORMAT(GETDATE(), 'yyyy-MM') -- Current month
  AND (wq1.TotalCPUTime_ms - wq2.TotalCPUTime_ms) > 0 -- Detect increases
ORDER BY CPUTimeDifference DESC;


--- Query distribution across databases- Worst Queries

SELECT 
    DatabaseName,
    COUNT(*) AS QueryCount,
    SUM(TotalCPUTime_ms) AS TotalCPUTime_ms,
    AVG(AvgCPUTime_ms) AS AvgCPUTime_ms
FROM MonthlyWorstQueries
WHERE MonthYear = FORMAT(GETDATE(), 'yyyy-MM') -- Current month
GROUP BY DatabaseName
ORDER BY QueryCount DESC;
