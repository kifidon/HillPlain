---Test.sql

DECLARE @StartDate DATE = '2023-01-01';
DECLARE @EndDate DATE = '2024-12-31';

-- Loop through each day and insert into the calendarDay table
WHILE @StartDate <= @EndDate
BEGIN
    INSERT INTO calendarDay (CALENDAR_DAY)
    VALUES (@StartDate);

    -- Increment to the next day
    SET @StartDate = DATEADD(DAY, 1, @StartDate);
END;

-- Insert data into client table
INSERT INTO client (BILLING, NAME, LOCATION)
VALUES ('Billing Info A', 'Client A', 'Location A');

-- Insert data into representative table
INSERT INTO representative (EMAIL, REP_NAME, PHONE_NUM, NAME)
VALUES ('email1@example.com', 'Representative 1', '123-456-7890', 'Client A');

-- Example entries for projCode table
INSERT INTO projCode (PROJ_NUM, PROJ_NAME, EMAIL) 
VALUES ('A23-000-0000', 'Project A23', 'email1@example.com');

INSERT INTO projCode (PROJ_NUM, PROJ_NAME, EMAIL) 
VALUES ('A24-000-0000', 'Project A24', 'email1@example.com');

-- Example entries for LemForDay table
INSERT INTO LemForDay (PROJ_NUM, DESCRIPTION, CALENDAR_DAY)
VALUES ('A23-000-0000', 'LemForDay description 1', GETDATE());

INSERT INTO LemForDay (PROJ_NUM, DESCRIPTION, CALENDAR_DAY)
VALUES ('A23-000-0000',  'LemForDay description 2', GETDATE());

INSERT INTO LemForDay (PROJ_NUM,  DESCRIPTION, CALENDAR_DAY)
VALUES ('A24-000-0000',  'LemForDay description 3', GETDATE());

INSERT INTO LemForDay (PROJ_NUM,  DESCRIPTION, CALENDAR_DAY)
VALUES ('A24-000-0000', 'LemForDay description 4', GETDATE());

INSERT INTO LemForDay (PROJ_NUM, DESCRIPTION, CALENDAR_DAY)
VALUES ('A24-000-0000', 'LemForDay description 5', GETDATE());

INSERT INTO LemForDay (PROJ_NUM, DESCRIPTION, CALENDAR_DAY)
VALUES ('A24-000-0000', 'LemForDay description 6', GETDATE());


INSERT INTO Category (CATEGORY)
VALUES ('Equipment'), ('Materials'), ('SubContractor'), ('Employee');

-- Sample entities for each category
-- Equipment
INSERT INTO workingUnit (WID, NAME, CATEGORY) VALUES ('WID_EMP001', 'Employee 1', 'Employee');
UPDATE Employee SET ROLE = 'Developer' WHERE WID = 'WID_EMP001';

-- Materials
INSERT INTO workingUnit (WID, NAME, CATEGORY) VALUES ('WID_M001', 'Materials 1', 'Materials');
UPDATE Materials SET VENDOR = 'Vendor A' WHERE UNIT_ID = 'WID_M001';
-- SubContractor
INSERT INTO workingUnit (WID, NAME, CATEGORY) VALUES ('WID_S001', 'SubContractor 1', 'SubContractor');

-- Employee
INSERT INTO workingUnit (WID, NAME, CATEGORY) VALUES ('WID_E001', 'Equipment 1', 'Equipment');
UPDATE Equipment SET DESCRIPTION = 'Excavator' WHERE UNIT_NO = 'WID_E001';

-- Other related entities
INSERT INTO worked_onLem (WID, PROJ_NUM, LemNumber, REG_HRS, OT_HRS)
VALUES ('WID_EMP001', 'A23-000-0000', 1, 8, 2);

INSERT INTO EquipLem (UNIT_NO, PROJ_NUM, LemNumber, HRS)
VALUES ('WID_E001', 'A24-000-0000', 2, 5);

INSERT INTO matOnLem (UNIT_ID, PROJ_NUM, LemNumber, QTY)
VALUES ('WID_M001', 'A23-000-0000', 1, 100);

INSERT INTO subContractorsLem (WID, PROJ_NUM, LemNumber, REF_NUM, QTY, UNIT_PRICE)
VALUES ('WID_S001', 'A24-000-0000', 2, 'REF001', 3, 150);

INSERT INTO Rates (WID, CALENDAR_DAY_START, CALENDAR_DAY_END, REG_RATE)
VALUES ('WID_EMP001', '2024-02-02', NULL, 20);
INSERT INTO Rates (WID, CALENDAR_DAY_START, CALENDAR_DAY_END, REG_RATE)
VALUES ('WID_E001', '2024-02-02', NULL, 20);

UPDATE Rates
SET CALENDAR_DAY_START = '2024-03-01',
    REG_RATE = 25
WHERE WID = 'WID_EMP001' AND CALENDAR_DAY_START = '2024-02-02' ;

UPDATE Rates
SET CALENDAR_DAY_START = '2024-03-01',
    REG_RATE = 30
WHERE WID = 'WID_EMP001' AND CALENDAR_DAY_START = '2024-01-01';

select * from LemForDay ORDER BY LEM_ID;
select * from workingUnit;
SELECT * FROM Rates;
SELECT * FROM Employee;
SELECT * FROM EmployeeRates;
SELECT * FROM MostRecentRates;



/*
SELECT * FROM liveRates;
SELECT * FROM worked_onLem;
SELECT * FROM Equipment;
SELECT * FROM equipmentRates;
SELECT * FROM MostRecentLiveRates;
SELECT * FROM PeopleUnit;
SELECT * FROM People;
SELECT * FROM LemForDay;

*/

-- DECLARE @Sql NVARCHAR(MAX) = '';

-- SELECT @Sql += 'DROP INDEX ' + t.name + '.' + i.name + ';' + CHAR(13) + CHAR(10)
-- FROM sys.indexes i
-- JOIN sys.tables t ON i.object_id = t.object_id
-- WHERE i.type_desc = 'CLUSTERED';

-- PRINT @Sql; -- Review the generated SQL

-- -- Uncomment the line below to execute the generated SQL
-- -- EXEC sp_executesql @Sql;
-- SELECT
--     FK.name AS ForeignKeyName,
--     TP.name AS TableName,
--     CP.name AS ColumnName,
--     REF.name AS ReferencedTableName,
--     RC.name AS ReferencedColumnName
-- FROM
--     sys.foreign_keys FK
-- INNER JOIN
--     sys.tables TP ON FK.parent_object_id = TP.object_id
-- INNER JOIN
--     sys.tables REF ON FK.referenced_object_id = REF.object_id
-- INNER JOIN
--     sys.foreign_key_columns FKC ON FKC.constraint_object_id = FK.object_id
-- INNER JOIN
--     sys.columns CP ON FKC.parent_column_id = CP.column_id AND FKC.parent_object_id = CP.object_id
-- INNER JOIN
--     sys.columns RC ON FKC.referenced_column_id = RC.column_id AND FKC.referenced_object_id = RC.object_id;
