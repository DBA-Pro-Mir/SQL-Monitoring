SELECT 
    CAST(ExecutionTime AS DATE) AS SnapshotDate,
    DatabaseName,
    AdditionalInfo AS FilePath,
    MetricName,
    SUM(CAST(MetricValue AS FLOAT)) AS TotalMetricValue
FROM JobStepMetrics
WHERE StepName = 'Disk Usage'
  AND ISNUMERIC(MetricValue) = 1 -- Ensure MetricValue is numeric
  AND ExecutionTime >= DATEADD(DAY, -7, GETDATE()) -- Last 7 days
  AND DatabaseName NOT IN ('master', 'model', 'msdb', 'tempdb') -- Exclude system databases
GROUP BY CAST(ExecutionTime AS DATE), DatabaseName, AdditionalInfo, MetricName
HAVING SUM(CAST(MetricValue AS FLOAT)) > 600
ORDER BY SnapshotDate DESC, DatabaseName, MetricName;
