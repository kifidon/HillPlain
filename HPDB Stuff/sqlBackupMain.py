import ClockifyPull
import ClockifyPush

def getWID(wSpace_Name):
    while True:
        quickCursor, quickConn = ClockifyPull.sqlConnect()
        quickCursor.execute('''SELECT id FROM Workspace WHERE name = ? ''', wSpace_Name)
        row = quickCursor.fetchone()
        if row is not None:
            break
        else:
            ClockifyPush.pushWorkspaces(quickConn, quickCursor) 
    check = ClockifyPull.cleanUp(quickConn, quickCursor)
    if check:
        return row[0]
    else:
        print("An error occured on the system. Please Contact Administrator. Cannot close connection.")

def main():
    cursor, conn = ClockifyPull.sqlConnect()
    wid = getWID('Hill Plain')
    print(ClockifyPush.pushUsers(wid, conn, cursor) +"\n")
    print(ClockifyPush.pushClients(wid, conn, cursor) + "\n")
    print(ClockifyPush.pushProjects(wid, conn, cursor) + "\n")
    print(ClockifyPush.pushPolicies(wid, conn, cursor)+ "\n")
    print(ClockifyPush.pushApprovedTime(wid, conn, cursor) +  "\n")
    print(ClockifyPush.pushTimeOff(wid, conn, cursor, 14))

    # add time off push

    print(ClockifyPull.cleanUp(conn, cursor))    
if __name__ == "__main__":
    main()
    
