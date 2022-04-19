import mysql.connector
import sys
import json


host = "localhost"
port = 3306
database = "classicmodels"
user="student"
password="Passw0rd!"
conn = mysql.connector.connect(user=user, password=password, host=host, port=port,database=database)
sqlCustomers = "SELECT customerNumber FROM customers;"
sqlOrders = "SELECT * FROM orders WHERE customerNumber = %s;"
sqlDetails = "SELECT OD.orderLineNumber, P.productName, OD.productCode,OD.priceEach, OD.quantityOrdered, (OD.priceEach * OD.quantityOrdered) AS lineTotal FROM orderdetails AS OD INNER JOIN products AS P ON OD.productCode = P.productCode WHERE orderNumber = %s ORDER BY orderLineNumber;"


output = []
csrCust = conn.cursor(named_tuple=True)
csrCust.execute(sqlCustomers)
customers = []
for customer in csrCust:
    customers.append({'customerNumber':customer.customerNumber})
csrCust.close()

for customer in customers:
    csrOrd = conn.cursor(dictionary=True)
    csrOrd.execute(sqlOrders,(customer["customerNumber"],))
    orders = []
    for order in csrOrd:
        orders.append(order)
    csrOrd.close()
    for order in orders:
        order["orderDate"] = order["orderDate"].strftime('%Y-%m-%d') if order["orderDate"] is not None else None
        order["requiredDate"] = order["requiredDate"].strftime('%Y-%m-%d') if order["requiredDate"] is not None else None
        order["shippedDate"] = order["shippedDate"].strftime('%Y-%m-%d') if order["shippedDate"] is not None else None
        csrDet = conn.cursor(dictionary=True)
        csrDet.execute(sqlDetails,(order["orderNumber"],))
        details = []
        for detail in csrDet:
            detail["priceEach"] = float(detail["priceEach"]) if detail["priceEach"] is not None else None
            detail["lineTotal"] = float(detail["lineTotal"])  if detail["lineTotal"] is not None else None
            details.append(detail)
        order["details"] = details
        csrDet.close()
    if len(orders) > 0:
        customer["orders"]=orders
        with open("d:/labfiles/orders/{}.json".format(customer["customerNumber"]),"w") as o:
            o.write(json.dumps(customer, indent=2))
conn.close()