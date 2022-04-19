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
      if  test < 1 or test > 14:
          noTest = True
    except:
        noTest = True
if noTest:
    print("Invalid test specification.\nUsage: python3 main.py [test #]\nWhere [test #] is the test you want to run:\n1 - Test JSON record\n2 - Test JSON list\n3 - Test CSV handing")
    sys.exit()


#Set up globals


dataPath = "/home/coder/challenge/data"

#JSON -> dictionary test
success = False
if test <= 4:
    try:
        fileName = "customer.json"
        customer = fileCode.readCustomer(dataPath,fileName)
        if type(customer) == dict:
            if test == 1:
                success = True
            elif test == 2:
                success =  "customerName"  in customer
            elif test == 3:
                success = "processCenter" in customer
            else:
                success = customer["processCenter"] == "LODS"
    except Exception as ex:
        success = False
elif test <= 9:
    try:
        fileName = "products.json"
        products = fileCode.readProducts(dataPath, fileName)
        if type(products) == list:
            if test == 5:
                success = True
            elif test == 6:
                success = len(products) == 110
            else:
                if len(products) > 0:
                    if test == 7:
                        success = type(products[0]) == dict
                    elif test == 8:
                        success = "MSRP" in products[0]
                    else:
                        success = type(products[0]["MSRP"]) == float
    except Exception as ex:
        success = False
else:
    try:
        path = "/home/coder/challenge/data/*.csv"
        result = fileCode.generateOrdersReport(path)
        if type(result) == list:
            if test == 10:
                success = True
            elif test == 11:
                success = len(result) == 143
            else:
                rowLengthCorrect = True
                filterCorrect = True
                for row in result:
                    if len(row)!=5:
                        rowLengthCorrect = False
                    elif row[2] != 'Shipped':
                        filterCorrect = False
                if test == 12:
                    success = rowLengthCorrect
                elif test == 13:
                    success = filterCorrect
                elif rowLengthCorrect and filterCorrect:
                    orderCorrect = True
                    lastValue = result[0][4]
                    for i in range(1,5):
                        if result[i][4] > lastValue:
                            orderCorrect = False
                        lastValue = result[i][4]
                    success = orderCorrect
    except Exception as ex:
        success = False
print(success)
