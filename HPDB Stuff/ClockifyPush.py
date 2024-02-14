import pyodbc
import ClockifyPull
from datetime import datetime

def pushWorkspaces(conn, cursor):
    """
    Inserts workspace records into the database if they do not already exist.

    Args:
        conn: Connection object for the database.
        cursor: Cursor object for executing SQL queries.

    Returns:
        str: Message indicating the operation status.
    """
    count = 0
    key = ClockifyPull.getApiKey()
    workspaces = ClockifyPull.getWorkspaces(key)
    for key, value in workspaces.items():
        try:
            cursor.execute(
                '''
                INSERT INTO Workspace (id, name)
                SELECT ?, ? 
                WHERE NOT EXISTS (
                        SELECT 1 FROM Workspace WHERE id = ?
                    )
                ''',(
                    (value, key, value)
                )
            )
            conn.commit()
            count += 1
        except pyodbc.IntegrityError as e:
                print(f"IntegrityError: {e}")
        except pyodbc.Error as e: 
                print(f"Error: {e}")
    return(f"Operation Completed. Workspace table has {count} new records")

def pushRates( conn, cursor, user, uID):
    """
    Inserts or updates rate records for a user into the database.

    Args:
        conn: Connection object for the database.
        cursor: Cursor object for executing SQL queries.
        user: Dictionary containing user information.
        uID: User ID.

    Returns:
        None
    """
    unitType = None
    unitCosts = None
    for customFields in user['customFields']:
        if customFields['customFieldName'] == "Unit Type":
            unitType = customFields['value']
        if customFields['customFieldName'] == "Unit Cost":
            unitCosts = customFields['value']
    if unitType != "HOURLY":
        hourly = False
    else: 
        hourly = True
    try: 
        cursor.execute(
            '''
            INSERT INTO Rates (id, hourly, rate_cost)
            VALUES (?, ?, ?)
            ''' ,(uID, hourly, unitCosts)
        )
        conn.commit()
    except pyodbc.IntegrityError:
        # update instead in a later version 
        pass
    except pyodbc.Error as e :
        print(f"Error:  {e}")

    
def pushUsers(wkSpaceID, conn, cursor):
    """
    Inserts or updates user records into the database.

    Args:
        wkSpaceID: Workspace ID.
        conn: Connection object for the database.
        cursor: Cursor object for executing SQL queries.

    Returns:
        str: Message indicating the operation status.
    """
    count = 0
    key = ClockifyPull.getApiKey()
    users = ClockifyPull.getWorkspaceUsers(wkSpaceID, key)
    for user in users:
        uName = user['name']
        uEmail = user['email']
        uid = user['id']
        try:
            cursor.execute(
                '''
                    INSERT INTO EmployeeUser (id, email, name)
                    SELECT ?, ?, ?
                ''', (uid, uEmail, uName)
            )
            print(f"Adding Employee Rate information...")
            pushRates(conn, cursor, user, uid)
            conn.commit()
            count += 1
        except pyodbc.IntegrityError as e:
            pushRates(conn, cursor, user, uid) # set to an update rates flag later 
            continue
        except pyodbc.Error as e: 
            print(f"Error: {e}")
    return(f"Operation Completed. EmployeeUser table has {count} new records")

def pushProjects(wkSpaceID, conn, cursor):
    """
    Inserts project records into the database.

    Args:
        wkSpaceID: Workspace ID.
        conn: Connection object for the database.
        cursor: Cursor object for executing SQL queries.

    Returns:
        str: Message indicating the operation status.
    """
    count = 0
    key = ClockifyPull.getApiKey()
    projects = ClockifyPull.getProjects(wkSpaceID, key)
    for project in projects:
        pID = project['id']
        
        pTitle = project['name']
        proj = pTitle.split(' - ')
        pCode = proj[0]
        pName = ' - '.join(proj[1:])
        
        cID = project['clientId']
        while True: 
            try:
                cursor.execute(
                    '''
                        INSERT INTO Project( id, name, client_id, code)
                        Values ( ?, ?, ?, ?)
                    ''', (pID, pName, cID, pCode)
                )
                conn.commit()
                count += 1
                break
            except pyodbc.Error as e:
                if isinstance(e, pyodbc.IntegrityError):
                    message = str(e)
                    if 'FOREIGN KEY constraint' in message: 
                        print(pushClients(wkSpaceID, conn, cursor) + " Called by Project Function")
                    elif 'PRIMARY KEY constraint' in message:
                        break
                else:
                    print(f"Error: {e}")
    return(f"Operation Completed. Projects table has {count} new records")

def pushClients(wkSpaceID, conn, cursor):
    """
    Inserts client records into the database.

    Args:
        wkSpaceID: Workspace ID.
        conn: Connection object for the database.
        cursor: Cursor object for executing SQL queries.

    Returns:
        str: Message indicating the operation status.
    """
    count = 0
    key = ClockifyPull.getApiKey()
    clients = ClockifyPull.getClients(wkSpaceID, key)
    for client in clients:
        cID = client['id']
        cEmail = client['email']
        cAddress = client['address']
        cName = client ['name']
        try:
            cursor.execute(
                '''
                INSERT INTO Client ( id, email, address, name)
                VALUES (?, ?, ?, ?)
                ''',
                (cID, cEmail, cAddress, cName)
            )
            conn.commit()
            count += 1
        except pyodbc.Error as e: 
            if isinstance(e, pyodbc.IntegrityError):
                continue
            else:
                print(f"Error: {e}")
    return(f"Operation Completed. Clients table has {count} new records")

def timeDuration(duration_str):
    """
    Converts a duration string to hours.

    Args:
        duration_str (str): ISO 8601 duration format. In this format:
                "PT" indicates a period of time.
                "1H" indicates 1 hour.
                "30M" indicates 30 minutes.
            So, "PT1H30M" represents a duration of 1 hour and 30 minutes.

    Returns:
        float: Total duration in hours.
    """
    duration_str = duration_str[2:]
    hours, minutes = 0, 0
    if 'H' in duration_str:
        hours, duration_str = duration_str.split('H')
        hours = int(hours)
    if 'M' in duration_str:
        minutes = int(duration_str.strip('M'))/60
    return( hours + minutes)

def pushEntries(approve, conn, cursor, wkSpaceID):
    count = 0
    entries = approve['entries']
    for entry in entries:
        eID = entry['id']
        timeSheetID = entry['approvalRequestId']
        duration = timeDuration(entry['timeInterval']['duration'])
        description = entry['description']
        billable = entry['billable']
        projectID = entry['project']['id']
        type = entry['type']
        startTime = entry['timeInterval']['start']
        endTime = entry['timeInterval']['end']
        rate = entry['hourlyRate']['amount'] if entry['hourlyRate'] is not None else 0

        try:
            cursor.execute(
                '''
                    INSERT INTO Entry (id, time_sheet_id, duration, description, billable, project_id, type, start_time, end_time, rate)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ''',(
                      eID, 
                      timeSheetID, 
                      duration, 
                      description, 
                      billable,
                      projectID, 
                      type, 
                      startTime,
                      endTime, 
                      rate
                      )
            )
            conn.commit()
            count +=1
        except pyodbc.IntegrityError as e:
            if 'PRIMARY KEY constraint' in str(e):
                continue
            elif 'FOREIGN KEY constraint' in str(e):
                print(pushProjects(wkSpaceID, conn, cursor) + ". Called from Entries Function. \n")
            else:
                print(f"IntegrityError: {e}")
        except pyodbc.Error as e: 
            print(f"Error: {e}")
    return(f"Operation Completed. Entries table has {count} new records")

def pushExpenses(approve, timesheetID, conn, cursor):
    count = 0
    expenses = approve['expenses']
    for expense in expenses:
        eID = expense['id']
        billable = expense['billable']
        date = expense['date']
        notes = expense['notes']
        projectID = expense['project']['id']
        qty = expense['quantity']
        total = expense['total']
        category = expense['category']['id']
        try: 
            cursor.execute(
                '''
                INSERT INTO Expenses(id, billable, date, notes, project_id, quantity, total, timesheet_id, category_id)
                SELECT ?, ?, ?, ?, ?, ?, ?, ?
                WHERE NOT EXISTS(
                    SELECT 1 FROM Expense WHERE id = ?
                )
                ''',
                (eID, billable, date, notes, projectID, qty, total, timesheetID, category, eID)
            )
            conn.commit()
            count += 1
        except pyodbc.IntegrityError as e:
            if 'PRIMARY KEY constraint' in str(e):
                continue
            else:
                print(f"IntegrityError: {e}")
        except pyodbc.Error as e: 
            print(f"Error: {e}")
    return(f"Operation Completed. Expenses table has {count} new records")

def pushApprovedTime(wkSpaceID, conn, cursor):
    count = 0
    key = ClockifyPull.getApiKey()
    approved = ClockifyPull.getApprovedRequests(wkSpaceID, key)
    for approve in approved:
        if (ClockifyPull.is_within(approve['approvalRequest']['dateRange']['start'], 14)): 
            aID = approve['approvalRequest']['id']
            userID = approve['approvalRequest']['creator']['userId']
            
            startString = approve['approvalRequest']['dateRange']['start']
            endString = approve['approvalRequest']['dateRange']['end']

            approvedTime = timeDuration(approve['approvedTime'])
            billableTime = timeDuration(approve['billableTime'])
            billableAmount = approve['billableAmount']
            costAmount = approve['costAmount']
            expenseTotal = approve['expenseTotal']
            while True:
                try: 
                    cursor.execute(
                        '''
                        INSERT INTO TimeSheet (
                            id, 
                            emp_id,
                            start_time, 
                            end_time, 
                            approved_time, 
                            billable_time, 
                            billable_amount, 
                            cost_amount, 
                            expense_total)
                        VALUES (?, ?, ? , ?, ?, ?, ?, ?, ?)
                        '''
                        ,(
                            aID, 
                            userID, 
                            startString, 
                            endString,
                            approvedTime, 
                            billableTime, 
                            billableAmount, 
                            costAmount, 
                            expenseTotal, 
                            )
                    )
                    pushEntries(approve, conn, cursor, wkSpaceID)
                    pushExpenses(approve, aID, conn, cursor)
                    count += 1
                    conn.commit()
                    break
                except pyodbc.Error as e: 
                    if isinstance(e, pyodbc.IntegrityError):
                        if "FOREIGN KEY constraint \"FK__TimeSheet__emp_i__" in str(e):
                            print(pushUsers(wkSpaceID, conn, cursor) + ". Called by Approval Function")
                        elif "PRIMARY KEY constraint" in str(e):
                            print(pushEntries(approve, conn, cursor, wkSpaceID) + ". Called by  Approval Function")
                            print(pushExpenses(approve, aID, conn, cursor) + ". Called by Approval Function") 
                            break
                        else:
                            print(f"Error: {str(e)}")
                            break
                    else: 
                        print(f"Error: {str(e)}")
                        break
        else:
            continue
    return(f"Operation Completed. TimeSheet table has {count} new records")

def pushPolicies(wkSpaceID, conn, cursor):
    count = 0
    key = ClockifyPull.getApiKey()
    policies = ClockifyPull.getPolocies(wkSpaceID , key)
    for policy in policies:
        pId = policy["id"]
        pName = policy["name"]
        accrual_amount = policy["automaticAccrual"]["amount"]
        accrual_period = policy["automaticAccrual"]["period"]
        timeUnit = policy["automaticAccrual"]["timeUnit"]
        try:
            cursor.execute(
                '''
                INSERT INTO TimeOffPolicies(id, policy_name ,accrual_amount, accrual_period , time_unit, wID)
                VALUES (?, ?, ?, ?, ? ,?)
                ''', (pId, pName, accrual_amount, accrual_period, timeUnit, wkSpaceID)
            )
            conn.commit()
            count += 1
        except pyodbc.Error as e:
            if isinstance(e, pyodbc.IntegrityError): 
                continue 
            print(f"Error: {e}")
    return(f"Operation Completed. Policies table has {count} new records")

def pushTimeOff(wkSpaceID, conn, cursor, window):
    timeOff = ClockifyPull.getTimeOff(wkSpaceID, window)
    try:
        for requests in timeOff["requests"]:
            userID = requests["userId"]
            balance = requests["balance"]
            policyID = requests["policyId"]
            requestID = requests["id"]
            startDate = requests["timeOffPeriod"]["period"]["start"]
            startFromatString = '%Y-%m-%dT%H:%M:%SZ' if len(startDate) == 20 else '%Y-%m-%dT%H:%M:%S.%fZ'
            endDate = requests["timeOffPeriod"]["period"]["end"]
            endFromatString = '%Y-%m-%dT%H:%M:%SZ' if len(endDate) == 20 else '%Y-%m-%dT%H:%M:%S.%fZ'
            duration = (datetime.strptime(endDate, endFromatString) - datetime.strptime(startDate, startFromatString)).days
            while True:
                try:
                    cursor.execute(
                        '''
                        INSERT INTO TimeOffRequests (id, eID, pID, startDate, end_date, duration)
                        VALUES (?, ?, ?, ?, ?, ?)
                        ''', (requestID, userID, policyID, startDate, endDate, duration)
                    )
                    conn.commit()
                    break
                except pyodbc.Error as e:
                    print(f"Error inserting into TimeOffRequests: {e}")
                    # If an integrity error occurs, try to insert into TimeOffAccrual
                    if isinstance(e, pyodbc.IntegrityError):
                        try:
                            cursor.execute(
                                '''
                                INSERT INTO TimeOffAccrual (id, balance)
                                VALUES (?, ?)
                                ''', (userID, balance)
                            )
                            conn.commit()
                        except pyodbc.Error as e:
                            print(f"Error inserting into TimeOffAccrual: {e}")
                        try:
                            pushPolicies(wkSpaceID, conn, cursor)
                        except pyodbc.Error as e:
                            print(f"Error inserting into TimeOffAccrual: {e}")
    except KeyError as e:
        pass
     
