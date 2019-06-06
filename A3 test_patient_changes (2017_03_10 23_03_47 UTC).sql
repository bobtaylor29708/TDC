USE TemporalTest;
GO
EXEC [tdc].[usp_tdc_enable_table]
  'dbo',
  'Patient';
GO

DECLARE @counter INT = 0;

WHILE @counter < 10
  BEGIN
      INSERT INTO Patient
                  (LastName,
                   FirstName)
      VALUES      (Newid(),
                   Newid())

      INSERT INTO Patient
                  (LastName,
                   FirstName)
      VALUES      (Newid(),
                   Newid())

      INSERT INTO Patient
                  (LastName,
                   FirstName)
      VALUES      (Newid(),
                   Newid())

      INSERT INTO Patient
                  (LastName,
                   FirstName)
      VALUES      (Newid(),
                   Newid())

      INSERT INTO Patient
                  (LastName,
                   FirstName)
      VALUES      (Newid(),
                   Newid())

      WAITFOR delay '00:00:02';

      SET @counter +=1;
  END;


DECLARE @counter1 INT = 0;
DECLARE @pid1 INT = 0;

WHILE @counter1 < 10
  BEGIN
      SET @pid1 = Abs(Checksum(Newid()) % 59)

      UPDATE Patient
      SET
        FirstName = Newid()
      WHERE  PatientID = @pid1;

      WAITFOR delay '00:00:02';

      SET @counter1 +=1;
  END;

DECLARE @counter2 INT = 0;
DECLARE @pid2 INT = 0;

WHILE @counter2 < 5
  BEGIN
      SET @pid2 = Abs(Checksum(Newid()) % 59)

      DELETE FROM Patient
      WHERE  PatientID = @pid2;

      WAITFOR delay '00:00:02';

      SET @counter2 +=1;
  END; 
  GO

SELECT PatientID,
       LastName,
       FirstName,
       SysStartTime,
       SysEndTime
FROM   dbo.Patient;

SELECT PatientID,
       LastName,
       FirstName,
       SysStartTime,
       SysEndTime
FROM   TemporalTest_tdc_history.Patient;


DECLARE @Period DATETIME2 = Dateadd (minute, -15, Sysutcdatetime())

--SELECT *
--FROM   [tdc].[Patient_allchanges](@Period)

SELECT *
FROM   [tdc].[Patient_netchanges](@Period)




