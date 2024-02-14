import ClockifyPull
import pyodbc
import csv
import datetime

def getMonthYear():
    # Get the current date
    current_date = datetime.datetime.now()
    
    # Extract the month and year
    month = str(current_date.month)
    year = str(current_date.year)[2:]
    
    return month.rjust(2, '0'), year

def main():
    month, year = getMonthYear()
    cursor, conn = ClockifyPull.sqlConnect()
    range = 60
    try:
        cursor.execute(
            '''
            Select 
                DISTINCT en.project_id
            FROM TimeSheet TS
            INNER JOIN Entry en ON en.time_sheet_id = ts.id
            WHERE ts.start_time BETWEEN GETDATE() - 10 AND GETDATE()
            '''
        )
        pIds = cursor.fetchall()
        with open('output.csv', 'w', newline = '') as file:
            writer = csv.writer(file)
            writer.writerow(
                ['Number', 'Number', 'Name', 'Supplier', 'Qty', 'Unit', 'Unit Cost', 'Amount']
                )
            for pId in pIds:
                cursor.execute(
                    '''
                    DECLARE @ProjID VARCHAR(100)= ?;
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
                        mb.start_time between GETDATE() - ? AND GETDATE() AND
                        mb.project_id = @ProjID
                    ORDER BY [Number] DESC;
                    ''', (pId[0], range)
                )
                outputRows = cursor.fetchall()
                for row in outputRows:
                    month, year = getMonthYear()
                    row[0] = f"HP-IND-{year}-{month}-{row[0]}"
                    writer.writerow(row)
                writer.writerow([])
        ClockifyPull.cleanUp(conn, cursor)        
    except pyodbc.Error as e:
        print( f"Error: {e}")


if __name__ == "__main__": 
    main()