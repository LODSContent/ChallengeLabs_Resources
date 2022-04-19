import sys
import mysqlCode
import json

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
host = settings["sqlHost"]
port = settings["sqlPort"]
database = "classicmodels"
user=settings["user"]
password=settings["password"]

# Manage results files
def saveResults(file,object):
    path = "/home/coder/challenge/results.{}.json".format(file)
    fileName = "results.{}.json".format(file)
    with open(path,"w") as f:
        json.dump(object,f,indent=2)
    print("To view the results, open the {} file ".format(fileName))


#Code for testing insert, update and delete
productlineName="Graphene Cars"
productlineDescription="Graphene Cars are literally made of the strongest material we can get our hands on."
productlineHtmlDescription="<div class'productline'>Graphene Cars are literally <b>made of the strongest material we can get our hands on</b>.</div>"

def clearProductline(conn):
    sql = "DELETE FROM productlines WHERE productLine = '{}'".format(productlineName)
    csr = conn.cursor(named_tuple=True)
    csr.execute(sql)
    conn.commit()
    csr.close()

def getProductline(conn):
    sql = "SELECT * FROM productlines WHERE productLine = '{}'".format(productlineName)
    csr = conn.cursor(named_tuple=True)
    csr.execute(sql)
    output = csr.fetchone()
    csr.close()
    return output

if test == 1: # Test the connection
    try:
        conn = mysqlCode.getConnection(host, port, database, user, password)
        if conn.database == database:
            print('You have successfully connected to the classicmodels database.')
        else:
            print("You did not connect to the classicmodels database.")
    except Exception as ex:
        print("There was an error connecting to the database:\n{}".format(ex))


# Test data retrieval
if test == 2: 
    try:
        conn = mysqlCode.getConnection(host, port, database, user, password)
        customerNumber = 175
        testCustomerName = "Gift Depot Inc."
        try:
            (customerName, phone) = mysqlCode.retrieveCustomerByNumber(conn, customerNumber)
            if customerName == testCustomerName:
                print('You have successfully retrieved a customer by the customerNumber: Name={}, Phone={}'.format(customerName,phone))
            else:
                print("You did not retrieve the correct customer information.")

            customers = mysqlCode.retrieveCustomersByState(conn, 'NY')
            if (customers==None):
                print("The retrieveCustomersByState function did not return any data.")
            elif type(customers) != list:
                print("The retrieveCustomersByState function did not return a list type")
            elif type(customers[0]) != dict:
                print("The retrieveCustomersByState function did not return customer records as dictionaries.")
            elif len(customers)!=6:
                print("The retrieveCustomersByState function retrieved the wrong # of customers.")
            else:
                print("You have retrieved the correct customer records")
                saveResults("customersByState", customers)                
        except Exception as exData:
            print("There was an error retrieving data:\n{}".format(exData))
    except Exception as ex:
        print("There was an error connecting to the database:\n{}".format(ex))

if test == 3: # Test the data modification
    try:
        conn = mysqlCode.getConnection(host, port, database, user, password)
        customerNumber = 175
        testCustomerName = "Gift Depot Inc."
        try:
            clearProductline(conn)
            rowCount = mysqlCode.insertProductLine(conn, productlineName, productlineDescription)
            if rowCount == 1:
                print("You have properly inserted a product line record.")
                saveResults("insert",getProductline(conn))
            else:
                print("You have not properly inserted a product line record")

            rowCount = mysqlCode.updateProductLine(conn, productlineName, productlineHtmlDescription)
            if rowCount == 1:
                print("You have properly updated a product line record.")
                saveResults("update",getProductline(conn))
            elif rowCount > 1:
                print("You have updated too many product line records. You updated {} records".format(rowCount))
            else:
                print("You have not updated a product line record")

            rowCount = mysqlCode.deleteProductLine(conn, productlineName)
            if rowCount == 1:
                print("You have properly deleted a product line record.")
            elif rowCount > 1:
                print("You have deleted too many product line records. You deleted {} records".format(rowCount))
            else:
                print("You have not deleted a product line record")

        except Exception as exData:
            print("There was an error modifying data:\n{}".format(exData))
    except Exception as ex:
        print("There was an error connecting to the database:\n{}".format(ex))

# Test the exception handling
if test == 4: 
    #Connection exception check
    try:
        output = mysqlCode.getConnection(host, port, database, 'bob', password)
        if output is not None:
            print("You have not handled the mysql.connector.InterfaceError exception.")
        else:
            print("You have successfully handled the mysql.connector.InterfaceError exception.")
    except Exception as ex:
        print("There was an unhandled error in the getConnection function:\n{}".format(ex))

    #Data retrieval exception check
    try:
        conn = mysqlCode.getConnection(host, port, database, user, password)
        customerNumber = 'Bad'
        testCustomerName = "Gift Depot Inc."
        output = mysqlCode.retrieveCustomerByNumber(conn, customerNumber)
        if output is not None:
            print("You have not handled an empty result properly.")
        else:
            print("You have successfully handled an empty result.")
    except Exception as ex:
        print("There was an unhandled error in the retrieveCustomerByNumber function:\n{}".format(ex))
    
    #Integrity exception check
    try:
        conn = mysqlCode.getConnection(host, port, database, user, password)
        output = mysqlCode.insertProductLine(conn, productlineName, productlineDescription)
        output = mysqlCode.insertProductLine(conn, productlineName, productlineDescription)
        if output is not None:
            print("You have not handled the mysql.connector.IntegrityError exception.")
        else:
            print("You have successfully handled the mysql.connector.IntegrityError exception.")
    except Exception as ex:
        print("There was an unhandled error:\n{}".format(ex))

