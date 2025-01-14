SELECT 
    DatabaseName,
    StepName,
    MetricName,
    AVG(CAST(MetricValue AS float)) AS AvgMetricValue,
    MAX(CAST(MetricValue AS float)) AS MaxMetricValue
FROM JobStepMetrics
GROUP BY DatabaseName, StepName, MetricName
ORDER BY DatabaseName, MaxMetricValue DESC;

