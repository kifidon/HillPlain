--TimeTracker_def
/*
DROP TABLE IF EXISTS TimeOffRequests
DROP TABLE IF EXISTS TimeOffPolicies
DROP TABLE IF EXISTS TimeOffAccrual
DROP TABLE IF EXISTS Expense;
DROP TABLE IF EXISTS ExpenseCategory;
DROP TABLE IF EXISTS Rates;
DROP TABLE IF EXISTS Entry;
DROP TABLE IF EXISTS Task;
DROP TABLE IF EXISTS Project;
DROP TABLE IF EXISTS TimeSheet;
DROP TABLE IF EXISTS EmployeeUser;
DROP TABLE IF EXISTS Client;
DROP TABLE IF EXISTS Workspace;

SELECT * FROM Workspace;
SELECT * FROM EmployeeUser;
SELECT * FROM Project;
SELECT * FROM Client;
SELECT * FROM TimeOffPolicies;
SELECT * FROM TimeSheet;
SELECT * FROM Entry;
SELECT * FROM Expense;
SELECT * FROM Rates;
SELECT * FROM TimeOffRequests;

SELECT * FROM TimeSheet ts
INNER JOIN EmployeeUser emp ON ts.emp_id = emp.id
WHERE emp.name = 'Timmy Ifidon';

*/
-- Workspace Table
CREATE TABLE Workspace (
    id VARCHAR(50) PRIMARY KEY,
    [name] varchar(50)
    -- Add other workspace-related columns as needed
);
-- Client Table
CREATE TABLE Client (
    id VARCHAR(50) PRIMARY KEY,
    email VARCHAR(50),
    [address] VARCHAR(100),
    [name] VARCHAR(255)
    -- Add other client-related columns as needed
);

-- User Table
CREATE TABLE EmployeeUser (
    id VARCHAR(50) PRIMARY KEY,
    email VARCHAR(255),
    [name] VARCHAR(255)
    -- may include some information about memberships
);
-- TimeSheet Table
CREATE TABLE TimeSheet (
    id VARCHAR(50) PRIMARY KEY,
    emp_id VARCHAR(50),
    start_time DATETIME,
    end_time DATETIME,
    approved_time REAL,
    billable_time REAL,
    billable_amount DECIMAL(10, 2),
    cost_amount DECIMAL(10, 2),
    expense_total DECIMAL(10, 2),
    workspace_id VARCHAR(50),
    FOREIGN KEY (emp_id) REFERENCES EmployeeUser(id),
    FOREIGN KEY (workspace_id) REFERENCES Workspace(id)
    ON DELETE NO ACTION 
);

-- Project Table
CREATE TABLE Project (
    id VARCHAR(50) PRIMARY KEY,
    [name] VARCHAR(100),
    code VARCHAR(50),
    client_id VARCHAR(50),
    FOREIGN KEY (client_id) REFERENCES Client(id)
    -- include info a bout project Representative
    ON DELETE NO ACTION 
);

-- Task Table
CREATE TABLE Task (
    id VARCHAR(50) PRIMARY KEY,
    [name] VARCHAR(255)
    -- Add other task-related columns as needed
);

-- Entry Table
CREATE TABLE Entry (
    id VARCHAR(50) PRIMARY KEY,
    time_sheet_id VARCHAR(50),
    duration REAL,
    [description] TEXT,
    billable BIT,
    project_id VARCHAR(50), -- used this as the WorkedOn relation 
    task_id VARCHAR(50),
    [type] VARCHAR(20),
    rate DECIMAL (10,2), -- rates for billing 
    start_time DATETIME,
    end_time DATETIME
    -- Add other entry-related columns as needed
    FOREIGN KEY (time_sheet_id) REFERENCES TimeSheet(id),
    FOREIGN KEY (project_id) REFERENCES Project(id),
    FOREIGN KEY (task_id) REFERENCES Task(id)
    ON DELETE CASCADE 
);

-- Rates for payroll 
CREATE TABLE Rates(
    id VARCHAR(50) PRIMARY KEY ,
    hourly BIT,
    rate_cost DECIMAL(10,2)
    FOREIGN KEY (id) REFERENCES EmployeeUser(id)
    ON DELETE CASCADE 
)

-- ExpenseCategory Table
CREATE TABLE ExpenseCategory (
    id VARCHAR(50) PRIMARY KEY,
    [name] VARCHAR(255),
    unit VARCHAR(50),
    priceInCents DECIMAL(10, 2),
    billable BIT,
    workspaceId VARCHAR(50),
    FOREIGN KEY (workspaceId) REFERENCES Workspace(id)
    ON DELETE CASCADE 
    -- Add other category-related columns as needed
);


-- Expense Table
CREATE TABLE Expense (
    id VARCHAR(50) PRIMARY KEY,
    billable BIT,
    timesheet_id VARCHAR(50),
    category_id VARCHAR(50),
    [date] DATE,
    notes TEXT,
    project_id VARCHAR(50),
    quantity INT,
    total DECIMAL(10, 2),
    -- Add other expense-related columns as needed
    FOREIGN KEY (project_id) REFERENCES Project(id),
    FOREIGN KEY (timesheet_id) REFERENCES TimeSheet(id),
    FOREIGN KEY (category_id) REFERENCES ExpenseCategory(id)
    ON DELETE CASCADE 
);

CREATE TABLE TimeOffAccrual (
    id VARCHAR(50)  PRIMARY KEY,
    balance  INT,
    FOREIGN KEY (id) REFERENCES EmployeeUser(id)
    ON DELETE CASCADE 
)

CREATE TABLE TimeOffPolicies(
    id VARCHAR(50) PRIMARY KEY, -- TIME OFF POLICY ID 
    policy_name VARCHAR(50),
    accrual_amount INT,
    accrual_period VARCHAR(15),
    time_unit VARCHAR(14),
    wID VARCHAR(50), 
    FOREIGN KEY (wID) REFERENCES Workspace(id)
    ON DELETE CASCADE 
)

CREATE TABLE TimeOffRequests(
    id VARCHAR(50) PRIMARY KEY,
    eID VARCHAR(50),
    pID VARCHAR(50), 
    startDate DATETIME,
    end_date DATETIME,
    duration INT, --IN DAYS
    FOREIGN KEY (eID) REFERENCES EmployeeUser(id),
    FOREIGN KEY (pID) REFERENCES TimeOffPolicies(id)
    ON DELETE CASCADE  
    
)
-- Add indexes or constraints as necessary
