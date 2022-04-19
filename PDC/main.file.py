import sys
import json
import os
import fileCode

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
    print("Invalid test specification.\nUsage: python3 main.py [test #]\nWhere [test #] is the test you want to run:\n1 - Test JSON record\n2 - Test JSON list\n3 - Test CSV handing")
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

dataPath = "/home/coder/challenge/data"

#JSON -> dictionary test
if test == 1:
    try:
        fileName = "customer.json"
        customer = fileCode.readCustomer(dataPath,fileName)
        if type(customer) != dict:
            print("You have not returned a dictionary object.")
        elif "customerName" not in customer:
            print("You have not returned the correct customer data.")
        elif "processCenter" not in customer:
            print("You have not added the processCenter element to the customer data.")
        elif customer["processCenter"] != "LODS":
            print("the processCenter element did not have the correct data.")
        else:
            print("You have returned a dictionary object containing customer data.")
    except Exception as ex:
        print("There was an error reading the customer data: {}".format(ex))

if test == 2:
    try:
        fileName = "products.json"
        products = fileCode.readProducts(dataPath, fileName)
        if type(products) != list:
            print("You did not return a list.")
        elif len(products) != 110:
            print("You did not return the proper number of products. You returned {} products.".format(len(products)))
        elif type(products[0])!= dict:
            print("You did not return a list of dictionaries.")
        elif "MSRP" not in products[0]:
            print("You returned the wrong data.")
        elif type(products[0]["MSRP"]) != float:
            print("You returned the wrong data.")
        else:
            results = {
                "ResultType":"{}".format(type(products)),
                "RowCount":"{}".format(len(products)),
                "RowType":"{}".format(type(products[0])),
                "MSRPType":"{}".format(type(products[0]["MSRP"])),
            }
            print("You have returned the product data in the correct format.\n{}".format(json.dumps(results,indent=2)))
    except Exception as ex:
        print("There was an error processing product data: {}".format(ex))

if test == 3:
    try:
        path = "/home/coder/challenge/data/*.csv"
        result = fileCode.generateOrdersReport(path)
        if type(result) != list:
            print("You did not return a list data type")
        elif len(result)!= 143:
            print("You did not return the correct number of orders.")
        else:
            rowLengthCorrect = True
            filterCorrect = True
            for row in result:
                if len(row)!=5:
                    rowLengthCorrect = False
                elif row[2] != 'Shipped':
                    filterCorrect = False
            if rowLengthCorrect != True:
                print("You did not read the order records correctly.")
            elif filterCorrect != True:
                print("You did not filter the order data correctly.")
            else:
                orderCorrect = True
                lastValue = result[0][4]
                for i in range(1,5):
                    if result[i][4] > lastValue:
                        orderCorrect = False
                    lastValue = result[i][4]
                if orderCorrect:
                    print("You have properly read, filtered, sorted, and sliced the order data files.")
                else:
                    print("You have not sorted the order data correctly")          
    except Exception as ex:
        print("There was an error processing the data: {}".format(ex))
