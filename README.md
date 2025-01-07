Here’s a detailed description for your **SQL-Monitoring** repository:

---

# **SQL-Monitoring**

## **Overview**
The **SQL-Monitoring** repository contains a set of SQL scripts designed to monitor, collect, and analyze SQL Server performance metrics. These scripts help database administrators (DBAs) identify resource bottlenecks, optimize query performance, and maintain a healthy SQL Server environment.

The solution includes:
- **Performance Metrics Collection**: CPU, memory, disk I/O, and query performance.
- **Monthly Summarization**: Aggregates raw data for long-term trend analysis.
- **Query Analysis**: Identifies the most resource-intensive queries.
- **Data Maintenance**: Ensures efficient storage by pruning older records.

---

## **Key Features**
- **Comprehensive Metrics**:
  - Tracks real-time performance for CPU usage, wait statistics, memory, and disk I/O.
  - Captures detailed query performance metrics for advanced analysis.
  
- **Monthly Summarization**:
  - Aggregates data into summarized tables for easier reporting and trend analysis.

- **Top Queries Analysis**:
  - Identifies the 10 most resource-intensive queries each month, including execution count and average CPU usage.

- **Automated Maintenance**:
  - Deletes old records to manage table size and improve query performance.

- **Customizable Database**:
  - By default, uses a database named **Blitz**, but can be adapted for any database.

---

## **Repository Contents**

### 1. **`blitzTablestocreate.sql`**
- **Purpose**: Creates the schema required for monitoring SQL Server performance.
- **Tables Included**:
  - `JobStepMetrics`: Stores raw performance data.
  - `MonthlyJobMetrics`: Stores monthly summaries of performance metrics.
  - `MonthlyWorstQueries`: Tracks the 10 most resource-intensive queries for each month.
  - `JobExecutionHistory` (optional): Logs SQL Agent job execution history.

### 2. **`ServerPerformanceScripts.sql`**
- **Purpose**: Collects, summarizes, and prunes performance metrics.
- **Key Functions**:
  - Collects raw performance data into `JobStepMetrics`.
  - Aggregates data into `MonthlyJobMetrics`.
  - Extracts top 10 queries into `MonthlyWorstQueries`.
  - Prunes data older than one month.

---

## **How to Use**

### **Step 1: Setup**
1. Run `blitzTablestocreate.sql` in the SQL Server Management Studio (SSMS) to create the necessary tables.
2. Use the default **Blitz** database or modify the script to use a different database.

### **Step 2: Create Monitoring Jobs**
1. Use the queries from `ServerPerformanceScripts.sql` to create SQL Server Agent jobs.
2. Schedule jobs to:
   - Collect raw performance metrics (daily).
   - Summarize monthly metrics (end of the month).
   - Prune old data (monthly maintenance).

### **Step 3: Analyze Data**
1. Use the `MonthlyJobMetrics` table for long-term performance trends.
2. Use the `MonthlyWorstQueries` table to identify and optimize high-impact queries.
3. Export summarized data for visualization in tools like Power BI or Excel.

---

## **Benefits**
- Simplifies SQL Server performance monitoring.
- Enables proactive identification of resource bottlenecks.
- Improves database performance with query optimization insights.
- Maintains efficient data storage through automated pruning.

---

## **Customization**
- Modify the database name (`Blitz`) to fit your environment.
- Adjust job schedules based on your organization’s needs.

---

## **License**
This repository is open-source and available for community contributions.

---

Let me know if you'd like further refinements!
