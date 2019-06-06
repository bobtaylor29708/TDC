USE [TemporalTest];

GO

/****** Object:  Table [dbo].[Patient]    Script Date: 9/13/2016 9:58:35 AM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER ON;

GO

CREATE TABLE [dbo].[Patient]
  (
     [PatientID] [INT] IDENTITY(1, 1) NOT NULL,
     [LastName]  [NCHAR](50) NOT NULL,
     [FirstName] [NCHAR](50) NOT NULL
     PRIMARY KEY CLUSTERED ( [PatientID] ASC )
  )

GO 
