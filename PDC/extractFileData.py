import mysql.connector
import sys
import json
import os


from mysql.connector.abstracts import NAMED_TUPLE_CACHE


with open('settings.json') as sFile:
    settings = json.load(sFile)
host = settings["sqlHost"]
port = settings["sqlPort"]
database = "classicmodels"
user=settings["user"]
password=settings["password"]
directory_path = os.getcwd()

filePath = "{}/{}/{}.{}"

conn = mysql.connector.connect(user=user, password=password, host=host, port=port,database=database)
sqlProducts = "select CONCAT('42{\"productCode\":\"', productCode, '\",\"productName\":\"', productName, '\",\"MSRP\": ', MSRP, '}') as product  from products;"
sqlDates = "select DISTINCT YEAR(orderDate) as orderYear, MONTH(orderDate) as orderMonth from orders;"
sqlOrders = "select o.orderNumber, o.orderDate, o.status, o.customerNumber, SUM(od.quantityOrdered*od.priceEach) AS orderTotal from orders as o inner join orderdetails AS od on o.orderNumber = od.orderNumber WHERE YEAR(o.orderDate) = %s AND MONTH(o.orderDate) = %s GROUP BY o.orderNumber, o.orderDate, o.status, o.customerNumber;"
sqlCustomer = "select 1000000 AS customerNumber, customerName, phone,city,state from customers where customerNumber = 112;"


#generate customer file
def saveCustomer():
    csr = conn.cursor(dictionary=True)
    csr.execute(sqlCustomer)
    output = csr.fetchone()
    csr.close()
    with open(filePath.format(directory_path,"data","customer","json"),"w") as f:
        json.dump(output,f,indent=2)


#generate products file
def saveProducts():
    csr = conn.cursor(named_tuple=True)
    csr.execute(sqlProducts)
    with open(filePath.format(directory_path,"data","products","json"),"w") as f:
        for product in csr:
            f.write("{}\n".format(product.product))
        csr.close()

#generate orders files
def saveOrders():
    months = []
    csr = conn.cursor(named_tuple=True)
    csr.execute(sqlDates)
    for month in csr:
        months.append(month)
    csr.close()

    for month in months:
        csrMonth = conn.cursor(named_tuple=True)
        csr = conn.cursor(named_tuple=True)
        csr.execute(sqlOrders,(month.orderYear, month.orderMonth))
        with open(filePath.format(directory_path,"data","{}-{}".format(month.orderYear, month.orderMonth),"csv"),"w") as f:
            for order in csr:
                f.write("{},{},{},{},{}\n".format(order.orderNumber, order.orderDate, order.status, order.customerNumber, order.orderTotal))
        csr.close()

saveCustomer()
saveProducts()
saveOrders()