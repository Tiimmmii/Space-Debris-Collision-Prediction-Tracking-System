from database import get_connection
connection = get_connection()
if connection.is_connected():
    print("SUCCESS: Python connected to MySQL!")
    print("Database:", connection.database)
connection.close()