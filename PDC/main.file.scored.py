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
    test = 4
    #print("Invalid test specification.")
    #sys.exit()


#Set up globals

basepath = "/home/coder/challenge"
dataPath = basepath + "/data"
#JSON -> dictionary test
success = False
writeFail = False
if test <= 4:
    try:
        outputFile = basepath + "/output1.json"
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
        if test == 4:
            try:
                f = open(outputFile,'w')
                f.write(json.dumps(customer))
                f.close
            except:
                writeFail = True
    except Exception as ex:
        success = False
elif test <= 9:
    try:
        fileName = "products.json"
        products = fileCode.readProducts(dataPath, fileName)
        outputFile = basepath + "/output2.json"
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
        if test == 9:
            try:
                f = open(outputFile,'w')
                f.write(json.dumps(products))
                f.close
            except:
                writeFail = True
    except Exception as ex:
        success = False
else:
    try:
        path = "/home/coder/challenge/data/*.csv"
        result = fileCode.generateOrdersReport(path)
        outputFile = basepath + "/output3.json"
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
        if test == 14:
            try:
                f = open(outputFile,'w')
                f.write(json.dumps(result))
                f.close
            except:
                writeFail = True
    except Exception as ex:
        success = False
if writeFail:
    print("Results could not be written to a file.")
print(success)
