


def getCollection(user,password,host,port,database,collection):
    return None


def loadData(collection,path):
    return None


def getCustomerOrders(collection,customerNumber):
    return None


def getProductOrders(collection,productCode):
    return None


def getCustomerOrderTotals(collection,customerNumber):
    return None


def insertCustomer(collection,customer):
    return None


def addCustomerOrder(collection,customerNumber,order):
    return None


def removeCustomerOrders(collection,customerNumber):
    return None


#Test your code directly by uncommenting the following code, adding test code and running python3 mongoCode.py
#if __name__ == "__main__":
#    with open('settings.json') as sFile:
#        settings = json.load(sFile)
#    host = settings["host"]
#    port = settings["port"]
#    database = settings["database"]
#    user=settings["user"]
#    password=settings["password"]
#    collection = "orders"
