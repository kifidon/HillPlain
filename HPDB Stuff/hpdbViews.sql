-- Time Sheety Qurary 
-- DROP VIEW MonthlyBillable;
 
CREATE VIEW MonthlyBillable as (

    SELECT  
        Null as [Number],
        FORMAT(ROW_NUMBER() OVER ( PARTITION BY pj.code ORDER BY pj.code) - 1, '000') AS [Row],
        eu.name as [Name], 
        NULL AS [Supplier],
        CAST(SUM(en.duration) AS DECIMAL(10, 2)) AS QTY,
        'hr' AS Unit,
        --en.rate 
        10.10 AS [Unit Cost],
        CAST(
             SUM(en.duration) * 10.10 AS DECIMAL(10, 2)  -- * en.rate
        )AS Amount,
        ts.start_time,
        ts.end_time,
        en.project_id
    FROM TimeSheet ts 
        INNER JOIN EmployeeUser eu on eu.id = ts.emp_id
        INNER JOIN Entry en ON en.time_sheet_id = ts.id
        LEFT JOIN Project pj on pj.id = en.project_id
        LEFT JOIN Client cl on cl.id = pj.client_id
        GROUP BY
            pj.code, 
            eu.name,
            ts.start_time, 
            ts.end_time,
            en.project_id 

    UNION ALL

    SELECT 
        pj.code as [Number],
        NULL AS [Row],
        pj.name AS [Name],
        cl.name AS [Supplier],
        1 AS QTY,
        'ls' AS Unit,
        CAST(
            SUM(en.duration * 10.10) AS DECIMAL(10, 2) -- * en.rate)
        ) AS UnitCost,
        NULL AS Amount,
        ts.start_time,
        ts.end_time,
        en.project_id     
    FROM TimeSheet ts 
        INNER JOIN EmployeeUser eu on eu.id = ts.emp_id
        INNER JOIN Entry en ON en.time_sheet_id = ts.id
        LEFT JOIN Project pj on pj.id = en.project_id
        LEFT JOIN Client cl on cl.id = pj.client_id
        GROUP BY 
            pj.code,
            pj.name, 
            eu.name,
            cl.name,
            ts.start_time, 
            ts.end_time,
            en.project_id 
  
        
)
GO 
                    DECLARE @ProjID VARCHAR(100)= '65c249bfedeea53ae19d7dad';
                    SELECT 
                        [Number],
                        [Row],
                        [Name],
                        [Supplier],
                        [QTY],
                        [Unit],
                        [Unit Cost],
                        Amount
                    FROM MonthlyBillable mb
                    WHERE 
                        mb.start_time between GETDATE() - 10 AND GETDATE() AND
                        mb.project_id = @ProjID
                    ORDER BY [Number] DESC;
