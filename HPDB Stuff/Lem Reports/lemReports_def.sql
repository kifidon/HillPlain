/*-- Drop tables
DROP TABLE IF EXISTS Rates;
DROP TABLE IF EXISTS subContractorsLem;
DROP TABLE IF EXISTS matOnLem;
DROP TABLE IF EXISTS EquipLem;
DROP TABLE IF EXISTS worked_onLem;
DROP TABLE IF EXISTS Rates;
DROP TABLE IF EXISTS worked_on;
DROP TABLE IF EXISTS Equipment;
DROP TABLE IF EXISTS Materials;
DROP TABLE IF EXISTS Equipment;
DROP TABLE IF EXISTS Employee;
DROP TABLE IF EXISTS workingUnit;
DROP TABLE IF EXISTS Category;
DROP TABLE IF EXISTS LemForDay;
DROP TABLE IF EXISTS projCode;
DROP TABLE IF EXISTS representative;
DROP TABLE IF EXISTS client;
DROP TABLE IF EXISTS calendarDay;


-- Drop triggers
DROP TRIGGER IF EXISTS InsertIntoSubTable;
DROP TRIGGER IF EXISTS createNewRate;
DROP TRIGGER IF EXISTS trg_LemForDay_Insert;

-- Drop views
DROP VIEW IF EXISTS EmployeeRates;
DROP VIEW IF EXISTS MostRecentRates;
DROP VIEW IF EXISTS EmployeeUnit;
DROP VIEW IF EXISTS MosteRecentEmployeeRates;


*/

-- Create the calendarDay tablE
CREATE TABLE calendarDay (
    CALENDAR_DAY DATE PRIMARY KEY
);

-- Create the client table
CREATE TABLE client (
    BILLING VARCHAR(MAX),
    NAME VARCHAR(50) PRIMARY KEY,
    LOCATION VARCHAR(MAX)
);
-- Create the representative table
CREATE TABLE representative (
    EMAIL  VARCHAR(50) PRIMARY KEY,
    REP_NAME VARCHAR(MAX) NOT NULL,
    PHONE_NUM  VARCHAR(50) UNIQUE,
    NAME  VARCHAR(50) NOT NULL,
    FOREIGN KEY (NAME) REFERENCES client(NAME)
);

-- Create the projCode table
CREATE TABLE projCode (
    PROJ_NUM  VARCHAR(50) PRIMARY KEY,
    PROJ_NAME VARCHAR(MAX) NOT NULL,
    EMAIL  VARCHAR(50) NOT NULL,
    FOREIGN KEY (EMAIL) REFERENCES representative(EMAIL)
    ON DELETE CASCADE ON UPDATE CASCADE 
);


-- Create the LemForDay table
CREATE TABLE LemForDay (
    LID INT IDENTITY(1,1) PRIMARY KEY,
    PROJ_NUM VARCHAR(50),
    LemNumber INT,
    UNIQUE (PROJ_NUM, LemNumber),
    -- Computed column for LEM_ID
    LEM_ID AS (CONCAT(PROJ_NUM, '-', RIGHT('000' + CAST(LemNumber AS VARCHAR(3)), 3))),
    DESCRIPTION VARCHAR(MAX),
    CALENDAR_DAY DATE NOT NULL,
    FOREIGN KEY (CALENDAR_DAY) REFERENCES calendarDay(CALENDAR_DAY),
    FOREIGN KEY (PROJ_NUM) REFERENCES projCode(PROJ_NUM),
);

-----------------------------------------------------------------------------------------------
GO
-- AUTO FILLS AND INCREMENTS LEM NUMBER 
CREATE TRIGGER trg_LemForDay_Insert
ON LemForDay
AFTER INSERT
AS
BEGIN
    UPDATE wu
    SET LemNumber = ISNULL((SELECT MAX(wu_inner.LemNumber) FROM LemForDay wu_inner
                            WHERE wu_inner.PROJ_NUM = wu.PROJ_NUM),-1) + 1
    FROM LemForDay wu
    JOIN inserted i ON wu.LID = i.LID;
END;
GO
-----------------------------------------------------------------------------------------------
CREATE TABLE Category(
    CATEGORY VARCHAR(50) PRIMARY KEY,
    CHECK( 
        CATEGORY IN ('Equipment', 'Materials', 'SubContractor', 'Employee')
    )
)

-- Create the workingUnit table with CATEGORY column
CREATE TABLE workingUnit (
    WID VARCHAR(50) PRIMARY KEY,
    NAME  VARCHAR(50) NOT NULL UNIQUE,
    CATEGORY VARCHAR(50),
    FOREIGN KEY (CATEGORY) REFERENCES Category(CATEGORY)
);

----- MAY ADD INHERITANCE FOR THIRDPARTY AND EQUIPMENT 
CREATE TABLE Employee (
    WID VARCHAR(50) PRIMARY KEY,
    ROLE VARCHAR(50),
    FOREIGN KEY (WID) REFERENCES workingUnit(WID)
    ON DELETE CASCADE 
)

CREATE TABLE Equipment (
    UNIT_NO VARCHAR(50) PRIMARY KEY,
    DESCRIPTION VARCHAR(50),
    FOREIGN KEY (UNIT_NO) REFERENCES workingUnit (WID)
    ON DELETE CASCADE
)
CREATE TABLE Materials (
    UNIT_ID VARCHAR (50) PRIMARY KEY,
    VENDOR VARCHAR(50),
    FOREIGN KEY (UNIT_ID) REFERENCES workingUnit(WID)
    ON DELETE CASCADE
)

-- RELATE TO LEMMS 
CREATE TABLE worked_onLem ( -- FURTHER ABSTRACTION FOR TIME TRACKING. EITHER A VIEW OR EXPAND THE TABLE 
    WID VARCHAR(50),
    PROJ_NUM VARCHAR(50),
    LemNumber INT,
    REG_HRS REAL,
    OT_HRS REAL,
    PRIMARY KEY (WID, PROJ_NUM, LemNumber),
    FOREIGN KEY (WID) REFERENCES Employee(WID),
    FOREIGN KEY (PROJ_NUM, LemNumber) REFERENCES LemForDay(PROJ_NUM, LemNumber)
);
CREATE TABLE EquipLem(
    UNIT_NO VARCHAR(50),
    PROJ_NUM VARCHAR(50),
    LemNumber INT, 
    HRS REAL,
    PRIMARY KEY (UNIT_NO, PROJ_NUM, LemNumber),
    FOREIGN KEY (UNIT_NO) REFERENCES Equipment(UNIT_NO),
    FOREIGN KEY (PROJ_NUM, lemNumber) REFERENCES LemForDay(PROJ_NUM, LemNumber)
    ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE matOnLem(
    UNIT_ID VARCHAR(50),
    PROJ_NUM VARCHAR(50),
    LemNumber INT,
    QTY REAL,
    PRIMARY KEY (UNIT_ID, PROJ_NUM, LemNumber),
    FOREIGN KEY (UNIT_ID) REFERENCES Materials(UNIT_ID),
    FOREIGN KEY (PROJ_NUM, LemNumber) REFERENCES LemForDay(PROJ_NUM, LemNumber)
    ON DELETE CASCADE 

)
CREATE TABLE subContractorsLem ( 
    WID VARCHAR(50) ,
    PROJ_NUM VARCHAR(50),
    LemNumber INT,
    REF_NUM VARCHAR(15),
    DESCRIPTION VARCHAR(50),
    QTY REAL,
    UNIT_PRICE REAL,
    AMOUNT AS QTY * UNIT_PRICE,
    PRIMARY KEY ( WID, PROJ_NUM, LemNumber),
    FOREIGN KEY (WID) REFERENCES workingUnit(WID),
    FOREIGN KEY (PROJ_NUM, LemNumber) REFERENCES LemForDay(PROJ_NUM, LemNumber) 
    ON DELETE CASCADE 
);

-- Create the rates table
CREATE TABLE Rates (
    WID VARCHAR(50),
    CALENDAR_DAY_START DATE,
    CALENDAR_DAY_END DATE,
    REG_RATE REAL,
    PRIMARY KEY (WID, CALENDAR_DAY_START),
    FOREIGN KEY (CALENDAR_DAY_START) REFERENCES calendarDay(CALENDAR_DAY)
    ON DELETE CASCADE
);

GO
--------------------------------------TRIGGERS------------------------------------------------------
-- Create the createNewRateA trigger
CREATE TRIGGER createNewRate
ON Rates
INSTEAD OF UPDATE
AS
BEGIN
    -- Debugging: Print messages
    PRINT 'Trigger Executing';

    -- Check if the specified columns were updated
    IF UPDATE(CALENDAR_DAY_START) OR UPDATE(REG_RATE)
    BEGIN
        -- Debugging: Print messages
        PRINT 'Update condition met';

        DECLARE @CurrentDay DATE;

        -- Get the current date
        SET @CurrentDay = GETDATE();

        -- Debugging: Print messages
        PRINT 'Setting CALENDAR_DAY_END to ' + CONVERT(VARCHAR(10), @CurrentDay);

        -- Update the CALENDAR_DAY_END of the existing row
        UPDATE Rates
        SET CALENDAR_DAY_END = @CurrentDay
        WHERE WID IN (SELECT WID FROM INSERTED) -- change to max 
    
          AND CALENDAR_DAY_END IS NULL;

        -- Debugging: Print messages
        PRINT 'Inserting new row';

        -- Insert a new row with updated values
        INSERT INTO Rates (WID, CALENDAR_DAY_START, REG_RATE)
        SELECT 
            i.WID,
            i.CALENDAR_DAY_START,
            i.REG_RATE
        FROM INSERTED i;
    END
END;
GO
--- UPDATE END DATE FOR RATE PRIOD 



-- -- Updated createNewRate trigger for equipmentRates
-- CREATE TRIGGER createNewEquipmentRate
-- ON equipmentRates
-- INSTEAD OF UPDATE
-- AS
-- IF UPDATE(CALENDAR_DAY_START) OR UPDATE (REG_RATE) OR UPDATE (RATE_COST)  OR UPDATE (FUEL_BURN) OR UPDATE (EQP_TIME)
-- BEGIN
--     DECLARE @CurrentDay DATE;

--     -- Get the current date
--     SET @CurrentDay = GETDATE();

--     -- Update the CALENDAR_DAY_END of the existing row
--     UPDATE equipmentRates
--     SET CALENDAR_DAY_END = @CurrentDay
--     WHERE ID IN (SELECT ID FROM INSERTED)
--       AND CALENDAR_DAY_END IS NULL
-- END;
-- BEGIN
--     -- Chec k if the specified columns were updated
--     IF UPDATE(CALENDAR_DAY_START) OR UPDATE (REG_RATE) OR UPDATE (RATE_COST)  OR UPDATE (FUEL_BURN) OR UPDATE (EQP_TIME)
--     BEGIN
--         INSERT INTO equipmentRates (ID, CALENDAR_DAY_START, REG_RATE, RATE_COST, FUEL_BURN, EQP_TIME)
--         SELECT 
--             i.ID,
--             GETDATE() AS CALENDAR_DAY_START,
--             i.REG_RATE,
--             i.RATE_COST,
--             i.FUEL_BURN,
--             i.EQP_TIME
--         FROM INSERTED i;
--     END
-- END
-- GO


-- Create the InsertEmployee trigger
CREATE TRIGGER InsertIntoSubTable
ON workingUnit
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Insert into the Employee table for rows with CATEGORY = 'Employee'
    INSERT INTO Employee (WID)
    SELECT WID
    FROM INSERTED
    WHERE CATEGORY = 'Employee';

    -- Insert into the Equipment table for rows with CATEGORY = 'Equipment'
    INSERT INTO Equipment (UNIT_NO)
    SELECT WID
    FROM INSERTED
    WHERE CATEGORY = 'Equipment';

    -- Insert into the ThirdParty table for rows with CATEGORY = 'ThirdParty'
    INSERT INTO Materials (UNIT_ID)
    SELECT WID
    FROM INSERTED
    WHERE CATEGORY = 'Materials';
END;

-------------------------------------------------------VIEWS ------------------------------------------------------

GO 
CREATE VIEW EmployeeRates AS (
SELECT
    r.WID ,
    r.CALENDAR_DAY_START ,
    r.CALENDAR_DAY_END ,
    r.REG_RATE ,
    r.REG_RATE *1.5 AS OT_RATE,
    r.REG_RATE * 2 AS X2_RATE
FROM 
    Rates r 
INNER JOIN Employee emp ON emp.WID = r.WID
)

GO 
-- CREATE VIEW Role AS (
-- SELECT p.ROLE, 
--     lr.REG_RATE, 
--     lr.OT_RATE, 
--     wu.SHIFT, 
--     wu.HOURLY
-- FROM Employee P 
--     JOIN workingUnit wu ON wu.ID = p.ID 
--     JOIN EmployeeRatesView lr on lr.ID = p.ID
-- WHERE
--     lr.CALENDAR_DAY_START IN (
--         SELECT MAX(CALENDAR_DAY_START) FROM EmployeeRatesView
--         WHERE CALENDAR_DAY_START <= GETDATE()
--     )

-- );

GO
CREATE VIEW MostRecentRates AS
SELECT
    WID,
    CALENDAR_DAY_START AS MostRecentStartDate,
    CALENDAR_DAY_END AS MostRecentEndDate,
    REG_RATE AS MostRecentRegRate,
    ROW_NUMBER() OVER ( PARTITION BY WID ORDER BY CALENDAR_DAY_START DESC) AS ROWNUM
FROM
    Rates
WHERE
    CALENDAR_DAY_END IS NULL


GO

-- CREATE VIEW EquipUnit AS (
--     SELECT 
--         w.ID,
--         w.NAME,
--         w.SHIFT,
--         eq.TYPE,
--         w.HOURLY,
--         mrer.MostRecentStartDate,
--         CASE 
--             WHEN mrer.MostRecentEndDate IS NULL THEN GETDATE()
--             ELSE mrer.MostRecentEndDate
--         END AS MostRecentEndDate,
--         CASE
--             WHEN mrer.MostRecentRegRate IS NULL THEN 0
--             ELSE mrer.MostRecentRegRate
--         END AS MostRecentRegRate,
--         CASE
--             WHEN mrer.MostRecentRateCost IS NULL THEN 0
--             ELSE mrer.MostRecentRateCost
--         END AS MostRecentRateCost,
--         CASE
--             WHEN mrer.MostRecentFuelBurn IS NULL THEN 0
--             ELSE mrer.MostRecentFuelBurn
--         END AS MostRecentFuelBurn,
--         CASE
--             WHEN mrer.MostRecentEqpTime IS NULL THEN 0
--             ELSE mrer.MostRecentEqpTime
--         END AS MostRecentEqpTime
--         --any other relavant columns 
--     FROM
--         workingUnit w
--     INNER JOIN Equipment eq on eq.ID = w.ID
--     INNER JOIN MostRecentEquipmentRates mrer on mrer.ID = w.ID AND mrer.ROWNUM = 1

-- );

GO 
CREATE VIEW MosteRecentEmployeeRates AS
SELECT
    WID,
    CALENDAR_DAY_START AS MostRecentStartDate,
    CALENDAR_DAY_END AS MostRecentEndDate,
    REG_RATE AS MostRecentRegRate,
    OT_RATE AS MostRecentOTRate,
    X2_RATE AS MostRecentx2Rate,
    ROW_NUMBER() OVER ( PARTITION BY WID ORDER BY CALENDAR_DAY_START DESC) AS ROWNUM
FROM
    EmployeeRates
WHERE
   CALENDAR_DAY_END IS NULL


GO

CREATE VIEW EmployeeUnit AS (
    SELECT 
        wu.WID,
        wu.NAME,
        emp.ROLE, 
        mrlrv.MostRecentStartDate,
        COALESCE(mrlrv.MostRecentEndDate, GETDATE()) AS MostRecentEndDate,
        COALESCE(mrlrv.MostRecentRegRate, 0) AS MostRecentRegRate,
        COALESCE(mrlrv.MostRecentOTRate, 0) AS MostRecentOTRate,
        COALESCE(mrlrv.MostRecentx2Rate, 0) AS MostRecentx2Rate
        -- Add any other relevant columns from the tables
    FROM
        workingUnit wu
    INNER JOIN
        Employee emp ON emp.WID = wu.WID AND wu.CATEGORY = 'Employee'
    LEFT JOIN
        MosteRecentEmployeeRates mrlrv ON mrlrv.WID = emp.WID and mrlrv.ROWNUM = 1
);
GO

-- CREATE VIEW ThirdPartyUnit AS (
--     SELECT 
--         wu.ID,
--         wu.NAME,
--         wu.SHIFT,
--         tp.CLASS, 
--         tp.TICKET,
--         wu.HOURLY,
--         mrlrv.MostRecentStartDate,
--         COALESCE(mrlrv.MostRecentEndDate, GETDATE()) AS MostRecentEndDate,
--         COALESCE(mrlrv.MostRecentRegRate, 0) AS MostRecentRegRate,
--         COALESCE(mrlrv.MostRecentOTRate, 0) AS MostRecentOTRate,
--         COALESCE(mrlrv.MostRecentx2Rate, 0) AS MostRecentx2Rate,
--         COALESCE(mrlrv.MostRecentRateCost, 0) AS MostRecentRateCost
--         -- Add any other relevant columns from the tables
--     FROM
--         workingUnit wu
--     INNER JOIN
--         ThirdParty tp ON tp.ID = wu.ID AND wu.CATEGORY = 'ThirdParty'
--     LEFT JOIN
--         MostRecentLiveRates mrlrv ON mrlrv.ID = wu.ID and mrlrv.ROWNUM = 1
-- );
-- GO


-----------------------------Relevant days View 
-- CREATE VIEW RelevantDays AS (
--     SELECT CALENDAR_DAY FROM calendarDay
--     Where CALENDAR_DAY IN (
--         SELECT CALENDAR_DAY FROM LemForDay
--     )
-- );

--------------------------------- LEM Table
CREATE VIEW EmpLemTable AS (
    SELECT lm.LEM_ID, 
        e.WID, 
        wu.NAME, 
        e.ROLE, 
        wko.REG_HRS, 
        er.MostRecentRegRate, 
        wko.OT_HRS, 
        er.MostRecentOtRate, 
        wko.REG_hrs + wko.OT_HRS AS TotalHrs, 
        (wko.REG_hrs * er.MostRecentRegRate) + (wko.OT_HRS * er.MostRecentOtRate) AS TotalPay
        FROM 
            LemForDay lm
        INNER JOIN 
            worked_onLem wko ON lm.LEM_ID = (CONCAT(wko.PROJ_NUM, '-', RIGHT('000' + CAST(wko.LemNumber AS VARCHAR(3)), 3)))
        INNER JOIN
            Employee e ON e.WID = wko.WID
        INNER JOIN 
            workingUnit wu ON wu.WID = e.WID
        INNER JOIN 
            MosteRecentEmployeeRates er ON e.WID = er.WID    
            
    -- Union with the subtotal row
    UNION ALL

    SELECT
        lm.LEM_ID,
        '----' AS WID,  -- Assuming NULL for aggregated rows
        '----' AS NAME, 
        'Total Regular Hrs' AS ROLE, 
        SUM(wko.REG_HRS) AS REG_HRS, 
        0 AS REG_RATE,  -- If you want NULL for aggregated rows
        SUM(wko.OT_HRS) AS OT_HRS, 
        0 AS OT_RATE,  -- If you want NULL for aggregated rows
        SUM(wko.REG_hrs + wko.OT_HRS) AS TotalHrs, 
        SUM((wko.REG_hrs * er.MostRecentRegRate) + (wko.OT_HRS * er.MostRecentOtRate)) AS TotalPay
    FROM 
        LemForDay lm
    INNER JOIN 
        worked_onLem wko ON lm.LEM_ID = (CONCAT(wko.PROJ_NUM, '-', RIGHT('000' + CAST(wko.LemNumber AS VARCHAR(3)), 3)))
    INNER JOIN
        Employee e ON e.WID = wko.WID
    INNER JOIN 
        MosteRecentEmployeeRates er ON e.WID = er.WID
    GROUP BY lm.LEM_ID
);
GO
---------------------------------EQP LEM Table
CREATE VIEW EqpLemTable AS (
    SELECT lm.LEM_ID, 
        eq.UNIT_NO, 
        wu.NAME, 
        eq.DESCRIPTION, 
        el.HRS, 
        mr.MostRecentRegRate,   
        (el.HRS * mr.MostRecentRegRate) AS TotalPay
        FROM 
            LemForDay lm
        INNER JOIN 
            EquipLem el ON lm.LEM_ID = (CONCAT(el.PROJ_NUM, '-', RIGHT('000' + CAST(el.LemNumber AS VARCHAR(3)), 3)))
        INNER JOIN
            Equipment eq ON eq.UNIT_NO = el.UNIT_NO
        INNER JOIN 
            workingUnit wu ON wu.WID = eq.UNIT_NO
        INNER JOIN 
            MostRecentRates mr ON eq.UNIT_NO = mr.WID    
            
    -- Union with the subtotal row
    UNION ALL

    SELECT
        lm.LEM_ID,
        '----' AS UNIT_NO,  -- Assuming NULL for aggregated rows
        '----' AS NAME, 
        'Total Regular Hrs' AS DESCRIPTION, 
        SUM(el.HRS) AS HRS, 
        0 AS REG_RATE,  -- If you want NULL for aggregated rows
        SUM((el.HRS * er.MostRecentRegRate)) AS TotalPay
    FROM 
        LemForDay lm
    INNER JOIN 
        EquipLem el ON lm.LEM_ID = (CONCAT(el.PROJ_NUM, '-', RIGHT('000' + CAST(el.LemNumber AS VARCHAR(3)), 3)))
    INNER JOIN
        Equipment eq ON eq.UNIT_NO = el.UNIT_NO
    INNER JOIN 
        MostRecentRates er ON eq.UNIT_NO = er.WID
    GROUP BY lm.LEM_ID
);