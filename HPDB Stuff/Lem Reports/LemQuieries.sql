-- Lem table 
DECLARE @LemID VARCHAR(50) = 'LEm900234';
DECLARE @DateVariable DATE = '2024-01-12';
DECLARE @ProjNum VARCHAR(50) = 'A24-000-0000';
WITH recentRatesCTE AS (
    SELECT 
        wu.ID,
        wu.CATEGORY,
        COALESCE(er.CALENDAR_DAY_START, lr.CALENDAR_DAY_START) AS DATE,
        COALESCE(er.REG_RATE, lr.REG_RATE) AS REG_RATE,
        COALESCE(lr.REG_RATE, 0) AS OT_RATE,
        ROW_NUMBER() OVER ( PARTITION BY wu.ID ORDER BY COALESCE(er.CALENDAR_DAY_START, lr.CALENDAR_DAY_START) DESC) AS ROWNUM
    FROM
        workingUnit wu
    LEFT JOIN equipmentRates er ON wu.ID = er.ID AND er.CALENDAR_DAY_START <= @DateVariable
    LEFT JOIN liveRatesView lr ON wu.ID = lr.ID AND lr.CALENDAR_DAY_START <= @DateVariable
     WHERE COALESCE(er.CALENDAR_DAY_START, lr.CALENDAR_DAY_START) IS NOT NULL
),
PayoutCTE AS (
    SELECT
        wo.ID,
        rrc.REG_RATE AS REG_RATE,
        rrc.OT_RATE AS OT_RATE,
        wo.REG_HRS,
        wo.OT_HRS,
        wo.LEM_ID
    FROM
        worked_on wo 
    INNER JOIN recentRatesCTE rrc ON wo.ID = rrc.ID and rrc.ROWNUM = 1
    INNER JOIN lemFor wks ON wo.LEM_ID = wks.LEM_ID 
    WHERE wks.PROJ_NUM = @ProjNum AND wo.CALENDAR_DAY = @DateVariable AND wks.LEM_ID = @LemID
)
SELECT wd.LEM_ID, 
    wd.DESCRIPTION, 
    wu.CATEGORY,
    p.ID, 
    CASE 
        WHEN wu.CATEGORY = 'Equipment' THEN eq.TYPE
        WHEN wu.CATEGORY = 'People' THEN pe.ROLE
        WHEN wu.CATEGORY = 'ThirdParty' THEN tp.CLASS
    END AS TITLE,
    wu.NAME,
    p.REG_HRS, p.REG_RATE,
    p.OT_HRS, p.OT_RATE,
    p.REG_HRS + p.OT_HRS AS TotalHrs,
    p.REG_HRS * p.REG_RATE + p.OT_HRS * p.OT_RATE AS TotalPay
FROM 
    PayoutCTE p
JOIN workDone wd on wd.LEM_ID = p.LEM_ID
INNER JOIN workingUnit wu ON wu.ID = p.ID
LEFT JOIN Equipment eq on eq.ID = wu.ID
LEFT JOIN People pe on pe.ID = wu.ID
LEFT JOIN ThirdParty tp ON tp.ID = wu.ID
GROUP BY 
    wu.CATEGORY, 
    eq.TYPE,
    pe.ROLE,
    tp.CLASS,
    wd.LEM_ID,
    wu.NAME, 
    wd.DESCRIPTION, 
    p.ID, 
    p.REG_HRS, 
    p.REG_RATE,
    p.OT_HRS, 
    p.OT_RATE;


-- CalendarDaySummary
DECLARE @Start DATE = '2023-01-01';
DECLARE @End DATE = '2024-12-31';
SELECT
    wd.CALENDAR_DAY AS Day,
    wu.CATEGORY,
    CASE 
        WHEN wu.CATEGORY = 'Equipment' THEN eq.TYPE
        WHEN wu.CATEGORY = 'People' THEN pe.ROLE
        WHEN wu.CATEGORY = 'ThirdParty' THEN tp.CLASS
    END AS ROLE,
    SUM(wo.REG_HRS + wo.OT_HRS) AS TotalHrsPerDay
FROM
    workDone wd
JOIN worked_on wo ON wd.LEM_ID = wo.LEM_ID
JOIN workingUnit wu ON wo.ID = wu.ID
LEFT JOIN Equipment eq ON wu.ID = eq.ID
LEFT JOIN People pe ON wu.ID = pe.ID
LEFT JOIN ThirdParty tp ON wu.ID = tp.ID
WHERE
    wd.CALENDAR_DAY BETWEEN @Start AND @End 
GROUP BY
    wd.CALENDAR_DAY,
    wu.CATEGORY,
    eq.TYPE,
    pe.ROLE,
    tp.CLASS;


-------------------InsertWorkDone TO BUILD A LEM TABLE 
DECLARE @DESCRIPTION VARCHAR(MAX) = 'This is a test';
DECLARE @CALENDAR_DAY DATE = '2023-01-22';
DECLARE @PROJ_NUM VARCHAR(50) = 'A23-000-0000';

-- Check if the row exists in the workDone table
INSERT INTO LemForDay ( DESCRIPTION, CALENDAR_DAY, PROJ_NUM)
    VALUES ( @DESCRIPTION, @CALENDAR_DAY, @PROJ_NUM);
    -- Record exists, so update the existing record
   

--ASSIGN A LEM TO A PROJECT
INSERT INTO worked_onLem (WID, LEM_ID, PROJ_NUM)
VALUES ('WID_EMP001', @LEM_ID, @PROJ_NUM);


---------aSSIGN Employee TO LEM ------
DECLARE @WID VARCHAR(50) = '';
DECLARE @PROJ_NUM VARCHAR(50) = '';
DECLARE @LemNumber INT = 0; 
DECLARE @REG_HRS REAL = 12; 
DECLARE @OT_HRS REAL = 12; 

-- Insert data into the worked_on table
INSERT INTO worked_onLem (WID, PROJ_NUM, LemNumber, REG_HRS, OT_HRS)
VALUES (@WID, @PROJ_NUM, @LemNumber, @REG_HRS, @OT_HRS);

--------------- Insert Equip
DECLARE @UNIT_NO VARCHAR(50) = '';
DECLARE @PROJ_NUM VARCHAR(50) = '';
DECLARE @LemNumber INT = 0; 
DECLARE @REG_HRS REAL = 12; 

-- Insert data into the worked_on table
INSERT INTO EquipLem (UNIT_NO, PROJ_NUM, LemNumber, HRS)
VALUES (@UNIT_NO, @PROJ_NUM, @LemNumber, @REG_HRS);

-------------------InsertSubCon
DECLARE @WID VARCHAR(50) = 'YourWID';
DECLARE @PROJ_NUM VARCHAR(50) = 'YourProjNum';
DECLARE @LemNumber INT = 123; -- Your LemNumber
DECLARE @REF_NUM VARCHAR(15) = 'YourRefNum';
DECLARE @DESCRIPTION VARCHAR(50) = 'YourDescription';
DECLARE @QTY REAL = 10.5; -- Your QTY
DECLARE @UNIT_PRICE REAL = 20.75; -- Your UNIT_PRICE

INSERT INTO subContractorsLem (WID, PROJ_NUM, LemNumber, REF_NUM, DESCRIPTION, QTY, UNIT_PRICE)
VALUES (@WID, @PROJ_NUM, @LemNumber, @REF_NUM, @DESCRIPTION, @QTY, @UNIT_PRICE);





-- Add any necessary JOIN conditions based on your schema



----------------ASSIGN LEM TO A PROJECT 
-- DECLARE @LEM_ID VARCHAR(50) = '@{outputs('LemIDC')}';
-- DECLARE @DESCRIPTION VARCHAR(MAX) = '@{outputs('Description')}';
-- DECLARE @CALENDAR_DAY DATE = '@{outputs('Compose_2')}';
-- DECLARE @PROJ_NUM VARCHAR(50) = '@{outputs('PN')}';

-- Check if the row exists in the worksDone table
IF NOT EXISTS (SELECT 1 FROM workDone WHERE LEM_ID = @LEM_ID)
BEGIN
    -- Record doesn't exist, so insert a new record
    INSERT INTO workDone (LEM_ID, DESCRIPTION, CALENDAR_DAY)
    VALUES (@LEM_ID, @DESCRIPTION, @CALENDAR_DAY);
END
ELSE
BEGIN
    -- Record exists, so update the existing record
    UPDATE workDone
    SET DESCRIPTION = @DESCRIPTION,
        CALENDAR_DAY = @CALENDAR_DAY
    WHERE LEM_ID = @LEM_ID;
END

-----ASSIGN A LEM TO A PROJECT 
INSERT INTO lemFor (LEM_ID, PROJ_NUM)
VALUES( @LEM_ID, @PROJ_NUM);

-------------All Dates with lems for a given project 
GO
DECLARE @Proj_N VARCHAR(50) = 'A24-000-0000';

SELECT DISTINCT CONVERT(VARCHAR(10), wd.CALENDAR_DAY, 10) AS DATE FROM workDone wd
INNER JOIN lemFor lf ON lf.LEM_ID = wd.LEM_ID
WHERE lf.PROJ_NUM = @Proj_N;

----------------AutoPullLemms  BASED ON DATE AND PROJ NUM
GO

DECLARE @Proj_N VARCHAR(50) = '  ';
DECLARE @DATE DATE = ' ';

SELECT lf.LEM_ID FROM lemFor lf
INNER JOIN workDone wd ON wd.LEM_ID = lf.LEM_ID
WHERE wd.CALENDAR_DAY = @DATE AND lf.PROJ_NUM = @Proj_N;


--------Date filter per person 

DECLARE @StartDate DATE = '2023-01-01';  -- Replace with your start date
DECLARE @EndDate DATE = '2025-02-24';    -- Replace with your end date
WITH CombinedRatesCTE AS (
    SELECT
        COALESCE(lrv.ID, er.ID) AS ID,
        COALESCE(lrv.CALENDAR_DAY_START, er.CALENDAR_DAY_START) AS CALENDAR_DAY_START,
        COALESCE(
            COALESCE(lrv.CALENDAR_DAY_END, er.CALENDAR_DAY_END), GETDATE()
        ) AS CALENDAR_DAY_END,
        COALESCE(lrv.REG_RATE, er.REG_RATE) AS REG_RATE,
        COALESCE(lrv.OT_RATE, 0) AS OT_RATE,
        COALESCE(lrv.RATE_COST, er.RATE_COST) AS RATE_COST,
        COALESCE(lrv.HOURLY, er.HOURLY) AS HOURLY
    FROM
        liveRatesView lrv
    FULL JOIN
        equipmentRates er ON lrv.ID = er.ID
),
CalendarRange AS (
    Select 
        cd.CALENDAR_DAY
    FROM 
        calendarDay cd
    WHERE 
        cd.CALENDAR_DAY BETWEEN @StartDate AND @EndDate
),
WorkedHoursCTE AS (
    SELECT
        wu.ID AS ID,
        crg.CALENDAR_DAY,
        wo.REG_HRS,
        wo.OT_HRS,
        CASE
            WHEN wu.CATEGORY = 'Equipment' THEN eq.TYPE
            WHEN wu.CATEGORY = 'People' THEN pe.ROLE
            WHEN wu.CATEGORY = 'ThirdParty' THEN tp.CLASS
        END AS Title,
        CASE
            WHEN wo.CALENDAR_DAY BETWEEN cr.CALENDAR_DAY_START AND cr.CALENDAR_DAY_END AND wo.ID =cr.ID THEN cr.REG_RATE
                
        END AS REG_Rate,
        CASE 
            WHEN wo.CALENDAR_DAY BETWEEN cr.CALENDAR_DAY_START AND cr.CALENDAR_DAY_END AND wo.ID =cr.ID THEN cr.OT_RATE
        END AS OT_Rate
    FROM
        CalendarRange crg
    JOIN
        worked_on wo ON crg.CALENDAR_DAY = wo.CALENDAR_DAY 
    JOIN 
        workingUnit wu ON wu.ID = wo.ID
    JOIN
        CombinedRatesCTE cr ON cr.ID = wu.ID
    LEFT JOIN
        Equipment eq ON eq.ID = wu.ID AND wu.CATEGORY = 'Equipment'
    LEFT JOIN
        People pe ON pe.ID = wu.ID AND wu.CATEGORY = 'People'
    LEFT JOIN
        ThirdParty tp ON tp.ID = wu.ID AND wu.CATEGORY = 'ThirdParty'
    WHERE  wo.CALENDAR_DAY BETWEEN cr.CALENDAR_DAY_START AND cr.CALENDAR_DAY_END 
    --ORDER BY crg.CALENDAR_DAY ASC
)
SELECT
    ID,
    Title,
    SUM(REG_HRS) AS TotalRegularHours,
    SUM(OT_HRS) AS TotalOvertimeHours,
    SUM(REG_HRS * REG_RATE) + SUM(OT_HRS * OT_RATE * 1.5) AS TotalAmountPaid
FROM
    WorkedHoursCTE
WHERE
    ID IS NOT NULL
GROUP BY
    ID, Title

UNION ALL  -- Use UNION ALL to include duplicates

-- Final row with sums for all working units
SELECT
    '----' AS ID, -- there is a problem
    -- when passing null so save as this for now 
    'TOTAL AMOUNT' AS Title,
    SUM(TotalRegularHours) AS TotalRegularHours,
    SUM(TotalOvertimeHours) AS TotalOvertimeHours,
    SUM(TotalAmountPaid) AS TotalAmountPaid
FROM (
    -- Subquery to calculate sums for each working unit
    SELECT
        ID,
        Title,
        SUM(REG_HRS) AS TotalRegularHours,
        SUM(OT_HRS) AS TotalOvertimeHours,
        SUM(REG_HRS * REG_Rate) + SUM(OT_HRS * OT_Rate * 1.5) AS TotalAmountPaid
    FROM
        WorkedHoursCTE
    WHERE
        ID IS NOT NULL
    GROUP BY
        ID, Title
) AS SubqueryAlias
ORDER BY Title;
-------------------------------------Delete equip 
DECLARE @ID VARCHAR(10) = ' ';
DELETE FROM workingUnit
WHERE ID = @ID
  AND NOT EXISTS (
    SELECT 1
    FROM equipment
    WHERE ID = @ID
);
----------------------------------------Insert equip rates 
DECLARE @ID VARCHAR(50) = 'YourID';  -- Replace with your actual ID
DECLARE @RegRate REAL = 20.0;  -- Replace with your actual RegRate
DECLARE @RateCost REAL = 150.0;  -- Replace with your actual RateCost
DECLARE @FuelBurn REAL = 5.0;  -- Replace with your actual FuelBurn
DECLARE @EquipmentTime REAL = 8.0;  -- Replace with your actual EquipmentTime

INSERT INTO equipmentRates (ID, CALENDAR_DAY_START, REG_RATE, RATE_COST, FUEL_BURN, EQP_TIME)
VALUES (@ID, GETDATE(), @RegRate, @RateCost, @FuelBurn, @EquipmentTime);

--------------------------------------------Update equip Rates
DECLARE @ID vARcHAR(10) = ' ';
DECLARE @reg REAL = ' ';
DECLARE @COST REAL = ' ';
DECLARE @FuelBurn REAL = 5.0;  -- Replace with your actual 
DECLARE @EquipmentTime REAL = 8.0;
UPDATE liveRates
SET REG_RATE = @reg,
    RATE_COST = @COST,
    FUEL_BURN = @FuelBurn,
    EQP_TIME = @EquipmentTime
      -- Replace with the new REG_RATE value
WHERE ID = @ID
  AND CALENDAR_DAY_START IN (SELECT MostRecentStartDate FROM MostRecentEquipmentRates WHERE ID = @ID);

--------------------------------------DeleteEquip rates 
DECLARE @EquipmentID VARCHAR(50) = 'YourEquipmentID'; -- Replace with the actual EquipmentID

DELETE FROM equipmentRates
WHERE ID = @EquipmentID;

--------------------------------------------Insert PEople 
GO 
-- Declare variables
DECLARE @ID VARCHAR(50) = '';
DECLARE @Name VARCHAR(50) = '';
DECLARE @Cat VARCHAR(50) = 'People';
DECLARE @Shift VARCHAR(50) = '';
DECLARE @Hourly VARCHAR(50) = '';
DECLARE @Type VARCHAR(50) = ''; --role 

-- Insert into workingUnit
INSERT INTO workingUnit (ID, NAME, SHIFT, CATEGORY)
VALUES (@ID, @Name, @Shift, @Cat);

UPDATE People
SET ROLE = @Type
WHERE ID = @ID;

---------------------------------------------------- Delete Peopele 
DECLARE @ID VARCHAR(10) = '';
DELETE FROM workingUnit
WHERE ID = @ID
  AND EXISTS (
    SELECT 1
    FROM People
    WHERE ID = @ID
);

---------------------------------------------insert live rates 
DECLARE @ID VARCHAR(50) = 'YourID';  -- Replace with your actual ID
DECLARE @RegRate REAL = 20.0;  -- Replace with your actual RegRate
DECLARE @RateCost REAL = 150.0;

INSERT INTO liveRates (ID, CALENDAR_DAY_START,  REG_RATE, RATE_COST)
VALUES ( @ID, GETDATE(), @RegRate, @RateCost);

------------------------------------------------- DElete peopela rates 
DECLARE @ID VARCHAR(50) = 'YourEquipmentID'; -- Replace with the actual EquipmentID

DELETE FROM liveRates
WHERE ID = @ID;

------------------------------------------------------Update rates 
DECLARE @ID vARcHAR(10) = ' ';
DECLARE @reg REAL = ' ';
DECLARE @COST REAL = ' ';
UPDATE liveRates
SET REG_RATE = @reg,
    RATE_COST = @COST
      -- Replace with the new REG_RATE value
WHERE ID = @ID
  AND CALENDAR_DAY_START IN (SELECT MostRecentStartDate FROM MostRecentLiveRates WHERE ID = @ID);


--------------------------------------------------------Insert ThirdParty 
DECLARE @ID VARCHAR(50) = '';
DECLARE @Name VARCHAR(50) = '';
DECLARE @Cat VARCHAR(50) = 'ThirdParty';
DECLARE @Shift VARCHAR(50) = '';
DECLARE @Hourly VARCHAR(50) = '';
DECLARE @Type VARCHAR(50) = ''; --class
DECLARE @TICKET VARCHAR(50) = '' -- ticket  

INSERT INTO workingUnit (ID, NAME, SHIFT, CATEGORY, HOURLY)
VALUES (@ID, @Name, @Shift, @Cat, @Hourly);

UPDATE ThirdParty
SET CLASS = @Type,
    TICKET = @Ticket
WHERE ID = @ID;

---------------------------------------------------------------Delete third party 
DECLARE @ID VARCHAR(10) = '';
DELETE FROM workingUnit
WHERE ID = @ID
  AND EXISTS (
    SELECT 1
    FROM ThirdParty
    WHERE ID = @ID
);


*/