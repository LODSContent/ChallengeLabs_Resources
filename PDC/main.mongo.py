import sys
import json
import mongoCode
import os

#Read in the test #.
test = 0
noTest = False
if len(sys.argv) < 2:
    noTest = True
else:
    try:
      test = int(sys.argv[1])
      if  test < 1 or test > 5:
          noTest = True
    except:
        noTest = True
if noTest:
    print("Invalid test specification.\nUsage: python3 main.py [test #]\nWhere [test #] is the test you want to run:\n1 - Test connection\n2 - Test data retrieval\n3 - Test data modification\n4 - Test exception handling")
    sys.exit()


#Set up globals

with open('settings.json') as sFile:
    settings = json.load(sFile)
host = settings["mongoHost"]
port = settings["mongoPort"]
database = settings["database"]
user=settings["user"]
password=settings["password"]
collection = "orders"

# Manage results files
def saveResults(file,object):
    path = "/home/coder/challenge/results.{}.json".format(file)
    fileName = "results.{}.json".format(file)
    with open(path,"w") as f:
        json.dump(object,f,indent=2)
    print("To view the results, open the {} file ".format(fileName))

#Set up test data

existingCustomerNumber = 103
newCustomerNumber = 1000000
productCode = "S24_2766"
path = "/home/coder/challenge/orders"

def getCustomerOrders(collection,customerNumber):
    return collection.find_one({"_id":customerNumber})

def removeCustomerOrders(collection,customerNumber):
    collection.delete_one({"_id":customerNumber})

def generateTestData():
    customer = {
        "customerNumber":newCustomerNumber,
        "orders":[
            {
                "orderNumber":1000000,
                "orderDate": "2021-05-20",
                "requiredDate": "2021-05-29",
                "shippedDate": "2021-05-22",
                "status": "Shipped",
                "comments": "Test record",
                "customerNumber": newCustomerNumber,
                "details":[
                    {
                        "orderLineNumber": 1,
                        "productName": "1966 Shelby Cobra 427 S/C",
                        "productCode": "S24_1628",
                        "priceEach": 43.27,
                        "quantityOrdered": 50,
                        "lineTotal": 2163.5
                    }                  
                ]               
            }
        ]
    }
    order=  {
        "orderNumber":1000001,
        "orderDate": "2021-05-20",
        "requiredDate": "2021-05-29",
        "shippedDate": "2021-05-22",
        "status": "Shipped",
        "comments": "Test record",
        "customerNumber": newCustomerNumber,
        "details":[
            {
                "orderLineNumber": 1,
                "productName": "1966 Shelby Cobra 427 S/C",
                "productCode": "S24_1628",
                "priceEach": 43.27,
                "quantityOrdered": 50,
                "lineTotal": 2163.5
            } ,
            {
                "orderLineNumber": 2,
                "productName": "1965 Aston Martin DB5",
                "productCode": "S18_1589",
                "priceEach": 120.71,
                "quantityOrdered": 26,
                "lineTotal": 3138.46
            },                
        ]               
    }
    return (customer,order)

if test == 1: # Test the connection
    try:
        coll = mongoCode.getCollection(user, password, host, port, database, collection)
        if coll.name == collection:
            print('You have successfully connected to the {} collection.'.format(collection))
        else:
            print("You did not connect to the {} collection.".format(collection))
    except Exception as ex:
        print("There was an error connecting to the collection:\n{}".format(ex))


# Test data load
if test == 2: 
    try:
        coll = mongoCode.getCollection(user, password, host, port, database, collection)
        try:
            customer = getCustomerOrders(coll,existingCustomerNumber)

            if customer is not None:
                print("You have previously loaded the files into the collection.")
                saveResults("load",customer)
            else:
                mongoCode.loadData(coll, path)
                customer = getCustomerOrders(coll,existingCustomerNumber)
                if customer is not None:
                    print("You have successfully loaded the files into the collection. Here is the order data from the collection for customer {}:\n{}")
                    saveResults("load",customer)
                else:
                    print("You have not successfully loaded the customer order files into the collection.")
        except Exception as exData:
            print("There was an error while verifying the data:\n{}".format(exData))
    except Exception as ex:
        print("There was an error connecting to the collection:\n{}".format(ex))

#Test data retrieval
if test == 3: 
    try:
        coll = mongoCode.getCollection(user, password, host, port, database, collection)
        try:
            customer = mongoCode.getCustomerOrders(coll,existingCustomerNumber)
            if customer is not None:
                print("You have successfully returned a document from the collection")
                saveResults("customerOders",customer)
            else:
                print("You have not successfully returned a document from the collection.")

            documents = mongoCode.getProductOrders(coll, productCode)
            if documents is not None:
                if len(documents) == 18:
                    print("You have successfully retrieved documents with the productCode filter.")
                    saveResults("productCode",documents)
                else:
                    issue = "too few" if len(documents) < 18 else "too many"
                    print("You have not filtered the documnents based on the productCode properly. You have returned {} results.".format(issue))
            else:
                print("You did not return any documents with the productCode filter.")

            orderTotals = mongoCode.getCustomerOrderTotals(coll, existingCustomerNumber)
            if orderTotals is None:
                print("You did not return any order totals")
            elif len(orderTotals) != 3:
                print("You did not return the correct number of order totals.")
            elif "total" not in orderTotals[0]:
                print("You did not return the correct data with the order totals")
            else:
                print("You have returned the correct order totals.")
                saveResults("orderTotals",orderTotals)
        except Exception as exData:
            print("There was an error while verifying the data:\n{}".format(exData))
    except Exception as ex:
        print("There was an error connecting to the collection:\n{}".format(ex))

# Test data modification
if test==4:
    coll = mongoCode.getCollection(user, password, host, port, database, collection)
    removeCustomerOrders(coll, newCustomerNumber)
    (customer,order) = generateTestData()
    mongoCode.insertCustomer(coll, customer)
    customer = getCustomerOrders(coll, newCustomerNumber)
    if customer is None:
        print("A document was not added to collection.")
    else:
        print("A document was added to the collection.")
        saveResults("insertCustomer",customer)
        mongoCode.addCustomerOrder(coll, newCustomerNumber, order)
        customer = getCustomerOrders(coll, newCustomerNumber)
        if len(customer["orders"]) != 2:
            print("You did not add an order to the customer orders document.")
        else:
            print("You successfully added an order to the customer orders document.")
            saveResults("addOrder",customer)
        mongoCode.removeCustomerOrders(coll, newCustomerNumber)
        customer = getCustomerOrders(coll, newCustomerNumber)
        if customer is not None:
            print("You did not delete the customer orders document.")
        else:
            print("You successfully deleted the customer orders document.")

# Test the exception handling
if test == 5: 
    #Connection exception check
    try:
        coll = mongoCode.getCollection('bob', password, host, port, database, collection)
        customer = mongoCode.getCustomerOrders(coll, existingCustomerNumber)
        if customer is not None:
            print("The pymongo.errors.OperationFailure exception was handled, but the wrong result was returned from the function")
        else:
            print("You have successfully handled the pymongo.errors.OperationFailure exception.")
    except Exception:
        print("The pymongo.errors.OperationFailure exception was not handled in the getCollection function")


    (customer,order) = generateTestData()
    coll = mongoCode.getCollection(user, password, host, port, database, collection)
    try:
        result = mongoCode.insertCustomer(coll, customer)
        result = mongoCode.insertCustomer(coll, customer)
        if result != -1:
            print("You have handled the pymongo.errors.DuplicateKeyError exception, but did not return the correct value from the function")
        else:
            print("You have successfully handled the pymongo.errors.DuplicateKeyError exception.")
    except Exception:
        print("The pymongo.errors.DuplicateKeyError exception was not handled in the insertCustomer function.")

