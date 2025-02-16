USE [Blitz]
GO
/****** Object:  Table [dbo].[JobStepMetrics]    Script Date: 1/6/2025 11:39:36 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[JobStepMetrics](
	[MetricID] [int] IDENTITY(1,1) NOT NULL,
	[JobName] [nvarchar](255) NULL,
	[StepName] [nvarchar](255) NULL,
	[ExecutionTime] [datetime] NULL,
	[MetricName] [nvarchar](255) NULL,
	[MetricValue] [nvarchar](max) NULL,
	[AdditionalInfo] [nvarchar](max) NULL,
	[DatabaseName] [nvarchar](255) NULL,
PRIMARY KEY CLUSTERED 
(
	[MetricID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MonthlyJobMetrics]    Script Date: 1/6/2025 11:39:36 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MonthlyJobMetrics](
	[MetricID] [int] IDENTITY(1,1) NOT NULL,
	[StepName] [nvarchar](255) NULL,
	[MetricName] [nvarchar](255) NULL,
	[MonthYear] [nvarchar](7) NULL,
	[TotalValue] [float] NULL,
	[AvgValue] [float] NULL,
	[MaxValue] [float] NULL,
	[MinValue] [float] NULL,
	[RecordCount] [int] NULL,
	[LastUpdated] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[MetricID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MonthlyWorstQueries]    Script Date: 1/6/2025 11:39:36 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MonthlyWorstQueries](
	[QueryID] [int] IDENTITY(1,1) NOT NULL,
	[MonthYear] [nvarchar](7) NULL,
	[DatabaseName] [nvarchar](255) NULL,
	[QueryText] [nvarchar](max) NULL,
	[TotalCPUTime_ms] [float] NULL,
	[ExecutionCount] [int] NULL,
	[AvgCPUTime_ms] [float] NULL,
	[LoggedDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[QueryID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[JobStepMetrics] ADD  DEFAULT (getdate()) FOR [ExecutionTime]
GO
ALTER TABLE [dbo].[MonthlyJobMetrics] ADD  DEFAULT (getdate()) FOR [LastUpdated]
GO
ALTER TABLE [dbo].[MonthlyWorstQueries] ADD  DEFAULT (getdate()) FOR [LoggedDate]
GO
