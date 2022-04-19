from datetime import date
import sys
import modifyCustomerCode
import exportCode
import json
import os
import importCode
import reportCode

#Set up test control
resultCode = 0
test = "0"
debug = False

if len(sys.argv) > 1:
    test = sys.argv[1]

if "--debug" in sys.argv:
    debug = True
nullPrint = open('/dev/null','w')
stdPrint = sys.stdout
if debug == False:
    sys.stdout = nullPrint

resultCode = 1

#Retrieve settings
with open('settings.json') as sFile:
    settings = json.load(sFile)
sqlHost = settings["sqlHost"]
sqlPort = settings["sqlPort"]
mongoHost = settings["mongoHost"]
mongoPort = settings["mongoPort"]
database = "classicmodels"
user=settings["user"]
password=settings["password"]
collection = "orders"

#Set up test data
testOrderNumber = 1000000
customerNumber = 128


testOrder = {
    "orderNumber":testOrderNumber,
    "orderDate": date.fromisoformat("2020-12-05"),
    "requiredDate": date.fromisoformat("2020-12-23"),
    "shippedDate": date.fromisoformat("2020-12-10"),
    "status":"Shipped",
    "customerNumber":119
}

testDetails = [
    {
        "orderNumber":testOrderNumber,
        "productCode":"S18_1749",
        "quantityOrdered": 50,
        "priceEach":153.00,
        "orderLineNumber":1
    },
    {
        "orderNumber":testOrderNumber,
        "productCode":"S18_2325",
        "quantityOrdered": 40,
        "priceEach":120.00,
        "orderLineNumber":2
    }
]

def clearTestOrders(conn):
    sql1 = "DELETE FROM orderdetails where orderNumber = %s;" 
    sql2 = "DELETE from orders where orderNumber = %s;"
    csr = conn.cursor(dictionary=True)
    csr.execute(sql1, (testOrderNumber,))
    conn.commit()
    csr.close()
    csr = conn.cursor(dictionary=True)
    csr.execute(sql2, (testOrderNumber,))
    conn.commit()
    csr.close()

def getOrder(conn):
    sql = "SELECT * FROM orders WHERE orderNumber = {}".format(testOrderNumber)
    csr = conn.cursor(dictionary=True)
    csr.execute(sql)
    output = csr.fetchone()
    csr.close()    
    return output

def getOrderDetails(conn):
    sql = "SELECT * FROM orderdetails WHERE orderNumber = {}".format(testOrderNumber)
    csr = conn.cursor(dictionary=True)
    output = []
    csr.execute(sql)
    for result in csr:
        output.append(result)
    csr.close()    
    return output

def getCustomerOrders(collection,customerNumber):
    return collection.find_one({"_id":customerNumber})

#Execute tests
try:
    if test == "1a":
        conn = modifyCustomerCode.getConnection(sqlHost, sqlPort, database, user, password)
        print(conn)
        if conn.database == database:
            resultCode = 0
    elif test =="1b":
        conn = modifyCustomerCode.getConnection(sqlHost, sqlPort, database, user, password)
        clearTestOrders(conn)
        rowCount = modifyCustomerCode.insertOrder(conn,testOrder)
        verify = getOrder(conn)
        if verify is None:
            resultCode = 1
        else:
            resultCode = 0
    elif test =="1c":
        conn = modifyCustomerCode.getConnection(sqlHost, sqlPort, database, user, password)
        clearTestOrders(conn)
        rowCount = modifyCustomerCode.insertOrder(conn,testOrder)
        rowCount = modifyCustomerCode.insertDetails(conn,testDetails)
        verify = getOrderDetails(conn)
        print(verify)
        if verify is None:
            resultCode = 1
        elif len(verify) == 0:
            resultCode = 1
        else:
            resultCode = 0
    elif test =="1d":
        conn = modifyCustomerCode.getConnection(sqlHost, sqlPort, database, user, password)
        clearTestOrders(conn)
        try:
            orderTest = modifyCustomerCode.insertOrder(conn,testOrder)
            orderTest = modifyCustomerCode.insertOrder(conn,testOrder)
            detailsTest = modifyCustomerCode.insertDetails(conn,testDetails)
            detailsTest = modifyCustomerCode.insertDetails(conn,testDetails)
            if detailsTest is None and orderTest is None:
                resultCode = 0
            else:
                resultCode = 1
        except:
            resultCode = -2
    if test == "2a":
        os.system("rm /home/coder/challenge/orders/* > /dev/null 2>&1")
        conn = modifyCustomerCode.getConnection(sqlHost, sqlPort, database, user, password)
        exportCode.exportCustomerOrders(conn)
        documents = os.listdir("/home/coder/challenge/orders")
        if documents is None:
            resultCode = -1
        elif len(documents) != 98:
            resultCode = -2
        else:
            resultCode = 0
    elif test =="2b":
        os.system("rm /home/coder/challenge/orders/* > /dev/null 2>&1")
        conn = modifyCustomerCode.getConnection(sqlHost, sqlPort, database, user, password)
        exportCode.exportCustomerOrders(conn)
        filePath = "/home/coder/challenge/orders/{}.json".format(customerNumber)
        with open(filePath) as f:
            customerOrders = json.load(f)
        if not "_id" in customerOrders:
            resultCode = -1
        elif not "customerNumber" in customerOrders:
            resultCode = -1
        elif not "orders" in customerOrders:
            resultCode = -1
        elif type(customerOrders["orders"]) is not list:
            resultCode = -1
        elif len(customerOrders["orders"]) != 4:
            resultCode = -1
        else:
            resultCode = 0       
    if test == "3a":
        collection = importCode.getCollection(user, password, mongoHost, mongoPort, database, collection)
        collection.delete_many({})
        importCode.importDocuments(collection,"/home/coder/challenge/orders")
        documentCount = collection.count_documents({})
        if documentCount == 98:
            resultCode = 0
        else:
            resultCode = -1
    elif test =="3b":
        collection = importCode.getCollection(user, password, mongoHost, mongoPort, database, collection)
        collection.delete_many({})
        importCode.importDocuments(collection,"/home/coder/challenge/orders")
        testOrder["orderDate"] = str(testOrder["orderDate"] )
        testOrder["requiredDate"] = str(testOrder["requiredDate"] )
        testOrder["shippedDate"] = str(testOrder["shippedDate"] )
        print(testOrder)
        importCode.addCustomerOrder(collection,customerNumber, testOrder)
        document = getCustomerOrders(collection, customerNumber)
        if len(document["orders"]) != 5:
            resultCode = -1
        else:
            resultCode = 0

    elif test =="3c":
        try:
            collection = importCode.getCollection(user, password, mongoHost, mongoPort, database, collection)
            collection.delete_many({})
            importCode.importDocuments(collection,"/home/coder/challenge/orders")
            result = importCode.importDocuments(collection,"/home/coder/challenge/orders")
            resultCode = 0 if result == -1 else -1
        except:
            resultCode = -100
    if test == "4a":
        conn = reportCode.getConnection(sqlHost, sqlPort, database, user, password)
        collection = reportCode.getCollection(user, password, mongoHost, mongoPort, database, collection)
        customerData = reportCode.getCustomerData(conn, collection, customerNumber)
        if type(customerData ) is None:
            resultCode = -1
        elif type(customerData) is not dict:
            resultCode = -1
        elif "customerNumber" not in customerData:
            resultCode = -1
        elif "customerName" not in customerData:
            resultCode = -1
        elif "phone" not in customerData:
            resultCode = -1
        elif "orders" not in customerData:
            resultCode = -1
        elif type(customerData["orders"]) is not list:
            resultCode = -1
        else:
            resultCode = 0
    elif test =="4b":
        resultCode = 0
    elif test =="4c":
        resultCode = 0
except Exception as ex:
    print(ex)
    resultCode = -100

sys.stdout = stdPrint

print(resultCode)