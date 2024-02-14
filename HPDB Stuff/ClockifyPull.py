import requests
import pyodbc
from datetime import datetime, timedelta, timezone
import pytz


def is_within(date_string, window):
    """
    Checks if the given date string is within the specified window of days from the current date.

    Args:
        date_string (str): A string representing the date in the format '%Y-%m-%dT%H:%M:%SZ'.
        window (int): The number of days to consider for the window.

    Returns:
        bool: True if the date is within the window, False otherwise.
    """
    # Convert the date string to a datetime object
    date_object = datetime.strptime(date_string, '%Y-%m-%dT%H:%M:%SZ')

    # Get the current date
    current_date = datetime.now(timezone.utc)

    # Calculate the difference between the two dates
    difference = current_date - date_object

    # Check if the difference is less than or equal to 7 days
    return difference <= timedelta(days=window)

def getApiKey():
    API_KEY = 'YWUzMTBiZTYtNjUzNi00MzJmLWFjNmUtYmZlMjM1Y2U5MDY3'
    return API_KEY

def sqlConnect():
    """
    Connects to a SQL Server database.

    Returns:
        tuple: A tuple containing a cursor object and a connection object if the connection is successful, otherwise dict().
    """
    try:
        #server info 
        server = 'hpcs.database.windows.net'
        database = 'hpdb'
        username = 'hpUser'
        password = '0153HP!!'
        driver = '{ODBC Driver 18 for SQL Server}'
        # Establish the connection
        conn_str = f'DRIVER={driver};SERVER={server};DATABASE={database};UID={username};PWD={password};Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;'
        conn = pyodbc.connect(conn_str)
        # Create a cursor object to interact with the database
        cursor = conn.cursor()
        return cursor, conn
    except pyodbc.Error as e:
        print(f"Error: {e}")
        return dict()

def cleanUp(conn, cursor):
    """
    Closes the cursor and connection objects.

    Args:
        conn: The connection object to be closed.
        cursor: The cursor object to be closed.

    Returns:
        int: 1 if the cleanup is successful, 0 otherwise.
    """
    try: 
        cursor.close()
        conn.close()
        return 1
    except pyodbc.Error as e:
        print(f"Error: {str(e)}")
        return 0
    
def getWorkspaces(key):
    """
    Retrieves the workspaces associated with the provided API key.

    Args:
        key (str): The API key for accessing the Clockify API.

    Returns:
        dict or dict(): A dictionary containing workspace names as keys and their corresponding IDs as values,
                      or dict() if an error occurs.
    """    
    headers = {
    'X-Api-Key': key,  
    }
    url = 'https://api.clockify.me/api/v1/workspaces'
    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        workSpace = {workspaces['name']:workspaces['id'] for workspaces in response.json()}
        return workSpace
    else:
        print(f"Error: {response.status_code}, {response.text}")
        return dict()

def getWorkspaceUsers( workspaceId, key):
    """
    Retrieves the users associated with a specific workspace.

    Args:
        workspaceId (str): The ID of the workspace.
        key (str): The API key for accessing the Clockify API.

    Returns:
        dict or dict(): A dictionary containing user details, or dict() if an error occurs.
    """
    headers = {
        'X-Api-Key': key
    }
    url = f'https://api.clockify.me/api/v1/workspaces/{workspaceId}/users'
    response = requests.get(url, headers= headers)
    if response.status_code == 200:
        users = response.json()
        return users
    else:
        print(f"Error: {response.status_code}, {response.text}")
        return dict()

def getProjects(workspaceId, key):
    """
    Retrieves the projects associated with a specific workspace.

    Args:
        workspaceId (str): The ID of the workspace.
        key (str): The API key for accessing the Clockify API.

    Returns:
        dict or dict(): A dictionary containing project details, or dict() if an error occurs.
    """    
    headers = {
        'X-Api-Key': key
    }
    url = f'https://api.clockify.me/api/v1/workspaces/{workspaceId}/projects'
    response = requests.get(url, headers= headers)
    if response.status_code == 200:
        projects = response.json()
        return projects
    else:
        print(f"Error: {response.status_code}, {response.text}")
        return dict()

def getApprovedRequests(workspaceId, key):
    """
    Retrieves the approved requests for a specific workspace.

    Args:
        workspaceId (str): The ID of the workspace.
        key (str): The API key for accessing the Clockify API.

    Returns:
        dict or dict(): A dictionary containing approved request details, or dict() if an error occurs.
    """
    headers = {
        'X-Api-Key': key
    }
    url = f'https://api.clockify.me/api/v1/workspaces/{workspaceId}/approval-requests?status=APPROVED&page=1&page-size=50'    
    response = requests.get(url, headers= headers)
    if response.status_code == 200:
        return response.json()
    else:
        print(f"Error: {response.status_code}, {response.text}")
        return dict()
        
def getClients(workspaceId, key): 
    """
    Retrieves the clients associated with a specific workspace.

    Args:
        workspaceId (str): The ID of the workspace.
        key (str): The API key for accessing the Clockify API.

    Returns:
        dict or dict(): A dictionary containing client details, or dict() if an error occurs.
    """
    headers = {
        'X-Api-Key': key
    }
    url = f'https://api.clockify.me/api/v1/workspaces/{workspaceId}/clients'
    response = requests.get(url, headers=headers)
    if response.status_code==200:
        return response.json()
    else:
        print(f"Error: {response.status_code}, {response.text}")
        return dict()

def getPolocies(workspaceId, key):
    """
    Retrieves the policies associated with a specific workspace.

    Args:
        workspaceId (str): The ID of the workspace.
        key (str): The API key for accessing the Clockify API.

    Returns:
        dict or dict(): A dictionary containing policy details, or dict() if an error occurs.
    """
    headers = {
        'X-Api-Key': key
    }
    url = f'https://pto.api.clockify.me/v1/workspaces/{workspaceId}/policies'
    response = requests.get(url, headers=headers)
    if response.status_code==200:
        return response.json()
    else:
        print(f"Error: {response.status_code}, {response.text}")
        return dict()

def getTimeOff(workspaceId, window):
    """
    Retrieves time off requests for a specific workspace within a given window.

    Args:
        workspaceId (str): The ID of the workspace.
        window (int): The number of days window to consider.

    Returns:
        dict or dict(): A dictionary containing time off request details, or dict() if an error occurs.
    """
    key = getApiKey()
    mst_timezone = pytz.timezone('US/Mountain')
    endDate = datetime.now(mst_timezone) 
    startDate = endDate - timedelta(days=window)
    endDateFormated = endDate.strftime("%Y-%m-%dT%H:%M:%S.%fZ")
    startDateFormated = startDate.strftime("%Y-%m-%dT%H:%M:%S.%fZ")

    headers = {
        'Content-Type': 'application/json',
        'X-Api-Key': key
    }
    url2 =  f"https://api.clockify.me/api/v1/workspaces/{workspaceId}/user-groups?name=AllUsers"
    userGroups = requests.get(url2, headers=headers).json()
    request_body = {
        "end": endDateFormated,
        "page": 1,
        "page-size": 30,
        "start": startDateFormated,
        "statuses": ["APPROVED"],
        "userGroups": [userGroups[0]['id']],
        "users": []
    }
    url = f'https://pto.api.clockify.me/v1/workspaces/{workspaceId}/requests'
    response = requests.post(url=url, json=request_body, headers=headers)
    if response.status_code == 200:
        return response.json()
    else: 
        print(f"Error: {response.status_code}, {response.reason}")
        return dict()
    

    