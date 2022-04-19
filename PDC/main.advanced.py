#Add test code here.
from datetime import date
import sys
import modifyCustomerCode
import exportCode
import json
import os
import importCode
import reportCode

#Read in the test #.
test = 0
noTest = False
if len(sys.argv) < 2:
    noTest = True
else:
    try:
      test = int(sys.argv[1])
      if  test < 1 or test > 4:
          noTest = True
    except:
        noTest = True
if noTest:
    print("Invalid test specification.\nUsage: python3 main.py [test #]\nWhere [test #] is the test you want to run:\n1 - Test connection\n2 - Test data retrieval\n3 - Test data modification\n4 - Test exception handling")
    sys.exit()


#Set up globals

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

# Manage results files
def saveResults(file,object):
    path = "/home/coder/challenge/results.{}.json".format(file)
    fileName = "results.{}.json".format(file)
    with open(path,"w") as f:
        json.dump(object,f,indent=2)
    return "To view the results, open the {} file ".format(fileName)



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

def clearDocuments(collection):
    return 0

if test == 1:
    try:
        conn = modifyCustomerCode.getConnection(sqlHost, sqlPort, database, user, password)
        if conn.database == database:
            print('You have successfully connected to the classicmodels database.')
            clearTestOrders(conn)
            rowCount = modifyCustomerCode.insertOrder(conn,testOrder)
            verify = getOrder(conn)
            if verify is None:
                print("You did not insert an order record.")
            else:
                verify["orderDate"] = str(verify["orderDate"] )
                verify["requiredDate"] = str(verify["requiredDate"] )
                verify["shippedDate"] = str(verify["shippedDate"] )
                print("You inserted the order record. {}".format(saveResults("insertOrder", verify)))
                try:
                    rowCount = modifyCustomerCode.insertOrder(conn,testOrder)
                    if rowCount is None:
                        print("You have successfully handled the IntegrityError exception in the insertOrder function.")
                    else:
                        print("You have not properly handled the IntegrityError exception in the insertOrder function.")
                except Exception as exin:
                    print("You have not properly handled the IntegrityError exception in the insertOrder function.")
                rowCount = modifyCustomerCode.insertDetails(conn,testDetails)
                verify = getOrderDetails(conn)
                if verify is None:
                    print("You did not insert order details")
                else:
                    for item in verify:
                        item["priceEach"] = float(item["priceEach"])
                    print("You inserted the order details. {}".format(saveResults("insertDetails", verify)))
                    try:
                        rowCount = modifyCustomerCode.insertDetails(conn,testDetails)
                        if rowCount is None:
                            print("You have successfully handled the IntegrityError exception in the insertDetails function.")
                        else:
                            print("You have not properly handled the IntegrityError exception in the insertDetails function.")
                    except Exception as exin:
                        print("You have not properly handled the IntegrityError exception in the insertDetails function.")
        else:
            print("You did not connect to the classicmodels database.")
    except Exception as ex:
        print("There was an exception raised while modifying relational data:\n{}".format(ex))


if test == 2:
    try:
        os.system("rm /home/coder/challenge/orders/* > /dev/null 2>&1")
        conn = modifyCustomerCode.getConnection(sqlHost, sqlPort, database, user, password)
        exportCode.exportCustomerOrders(conn)
        documents = os.listdir("/home/coder/challenge/orders")
        if documents is None:
            print("You did not export any customer order documents.")
        elif len(documents) != 98:
            print("You did not generate the proper number of customer order documents. There should be 98 documents, you generated {} documents.".format(len(documents)))
        else:
            filePath = "/home/coder/challenge/orders/{}.json".format(customerNumber)
            with open(filePath) as f:
                customerOrders = json.load(f)
            if not "_id" in customerOrders:
                print("You did not define the customer order document correctly. The '_id' element is missing.")
            elif not "customerNumber" in customerOrders:
                print("You did not define the customer order document correctly. The 'customerNumber' element is missing.")
            elif not "orders" in customerOrders:
                print("You did not define the customer order document correctly. The 'orders' element is missing.")
            elif type(customerOrders["orders"]) is not list:
                print("You did not define the customer order document correctly. The 'orders' element is not a list.")
            elif len(customerOrders["orders"]) != 4:
                print("You did not define the customer order document correctly. The document does not have the proper number of orders.")
            else:
                print("You have exported all of the customer order documents with the correct data structures.")
    except Exception as ex:
        print("There was an error exporting order data:\n {}".format(ex))


if test == 3:
    try:
        collection = importCode.getCollection(user, password, mongoHost, mongoPort, database, collection)
        collection.delete_many({})
        importCode.importDocuments(collection,"/home/coder/challenge/orders")
        documentCount = collection.count_documents({})
        if documentCount!=98:
            print("You did not import the correct number of customer order documents. There should be 98, but your count is {}".format(documentCount))
        else:
            document = getCustomerOrders(collection, customerNumber)
            if document is None:
                print("You have imported the correct number of documents, but the structure of the documents you imported is incorrect.")
            elif not "orders" in document:
                print("You have imported the correct number of documents, but the structure of the documents you imported is incorrect.")
            else:
                print("You have properly imported the customer order documents")
                testOrder["orderDate"] = str(testOrder["orderDate"] )
                testOrder["requiredDate"] = str(testOrder["requiredDate"] )
                testOrder["shippedDate"] = str(testOrder["shippedDate"] )
                importCode.addCustomerOrder(collection,customerNumber, testOrder)
                document = getCustomerOrders(collection, customerNumber)
                if len(document["orders"]) != 5:
                    print("You have not properly added an order to a customer orders document in MongoDB")
                else:
                    print("You have successfully added an order to a customer orders document. {}".format(saveResults("document", document)))
            try:
                result = importCode.importDocuments(collection,"/home/coder/challenge/orders")
                if result != -1:
                    print("You handled the DuplicateKeyError exception, but you did not return the correct value.")
                else:
                    print("You have properly handled the DuplicateKeyError exception.")
            except:
                print("You did not handle the DuplicateKeyError exception.")
    except Exception as ex:
        print("There was an error managing MongoDB data:\n {}".format(ex))


if test == 4:
    try:
        conn = reportCode.getConnection(sqlHost, sqlPort, database, user, password)
        collection = reportCode.getCollection(user, password, mongoHost, mongoPort, database, collection)
        customerData = reportCode.getCustomerData(conn, collection, customerNumber)
        if type(customerData ) is None:
            print("You did not return any data for the customer.")
        elif type(customerData) is not dict:
            print("You did not return the right data type for the customer.")
        elif "customerNumber" not in customerData:
            print("You did not return the customer number in the customer data.")
        elif "customerName" not in customerData:
            print("You did not return the customer name in the customer data.")
        elif "phone" not in customerData:
            print("You did not return the customer phone in the customer data.")
        elif "orders" not in customerData:
            print("You did not return the customer orders in the customer data.")
        elif type(customerData["orders"]) is not list:
            print("The orders element is not returned as a list.")
        else:
            print("You have returned the correct data for the customer. {}".format(saveResults("report", customerData)))
        #print(customerData)
    except Exception as ex:
        print("There was an error retrieving customer data: {}".format(ex))
