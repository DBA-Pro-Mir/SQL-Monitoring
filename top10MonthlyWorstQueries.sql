-- 2. Monthly Top 10 Worst Queries
PRINT '--- Monthly Top 10 Worst Queries ---';
SELECT TOP 20
    DatabaseName,
    QueryText, -- Updated to use the QueryText column
    TotalCPUTime_ms,
    ExecutionCount,
    AvgCPUTime_ms
FROM MonthlyWorstQueries
WHERE MonthYear = FORMAT(GETDATE(), 'yyyy-MM') -- Current month
ORDER BY TotalCPUTime_ms DESC;