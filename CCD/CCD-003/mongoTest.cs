using System;
using System.Collections.Generic;
using System.Linq;
using MongoDB.Driver;

namespace labfiles.mongo
{
    internal delegate (bool success, string message, object data) TestFunction();

    internal class TestMongo
    {
        private const string dataPath = "d:\\labfiles\\orders";
        private const string host = "localhost";
        private const string port = "27017";
        private const string database = "classicmodels";
        private const string collectionName = "orders";
        private const int customerNumber = 471;
        private const int newCustomerNumber = 1000000;
        public const int NumberOfTests = 9;

        private static CustomerOrder newCustomerOrder
        {
            get
            {
                var newCO = new CustomerOrder
                {
                    _id = newCustomerNumber.ToString(),
                    customerNumber = newCustomerNumber

                };
                var order = new Order
                {
                    customerNumber = newCustomerNumber,
                    status = "Shipped",
                    orderNumber = 1000000,
                    orderDate = DateTime.Parse("2021-05-20"),
                    requiredDate = DateTime.Parse("2021-05-20"),
                    shippedDate = DateTime.Parse("2021-05-20"),
                };
                order.details.Add(new OrderDetail
                {
                    orderLineNumber = 1,
                    productName = "1966 Shelby Cobra 427 S/C",
                    productCode = "S24_1628",
                    priceEach = 43.27M,
                    quantityOrdered = 50,
                    lineTotal = 2163.50M
                });
                newCO.orders.Add(order);
                return newCO;
            }
        }

        private static Order newOrder
        {
            get
            {
                var order = new Order
                {
                    customerNumber = newCustomerNumber,
                    status = "Shipped",
                    orderNumber = 1000000,
                    orderDate = DateTime.Parse("2021-05-20"),
                    requiredDate = DateTime.Parse("2021-05-20"),
                    shippedDate = DateTime.Parse("2021-05-20"),
                };
                order.details.Add(new OrderDetail
                {
                    orderLineNumber = 1,
                    productName = "1966 Shelby Cobra 427 S/C",
                    productCode = "S24_1628",
                    priceEach = 43.27M,
                    quantityOrdered = 50,
                    lineTotal = 2163.50M
                });
                return order;
            }
        }

        private static void clearDocuments(IMongoCollection<CustomerOrder> collection)
        {
            collection.DeleteMany(co => co._id != "deleteme");
        }

        private static CustomerOrder getTestDocument(IMongoCollection<CustomerOrder> collection)
        {
            return collection.Find(co => co._id == newCustomerNumber.ToString()).FirstOrDefault();
        }

        internal static (bool success, string title, string message, object data) RunTest(int testNumber)
        {
            var tests = new List<(string title, TestFunction testFunction)>
            {
                ("testGetCollection", TestGetCollection),
                ("testLoad", TestLoad),
                ("testGetCustomerOrders", TestGetCustomerOrders),
                ("testGetProductOrders", TestGetProductOrders),
                ("testInsert", TestInsert),
                ("testUpdate", TestUpdate),
                ("testDelete", TestDelete),
                ("testNoResult", TestNoDocument),
                ("testInsertException", TestInsertError)
            };

            var title = tests[testNumber].title;

            try
            {
                var result = tests[testNumber].testFunction();
                return (result.success, title, result.message, result.data);
            }
            catch (Exception ex)
            {
                return (success: false, title,
                    message: $"{title} \n Your code threw an exception. \n Exception: {ex.Message}", data: null);
            }
        }

        private static (bool success, string message, object data) TestGetCollection()
        {
            var testObject = new MongoCode();
            var collection = testObject.GetCollection(host, port, database, collectionName);

            return collection.CollectionNamespace.CollectionName == collectionName
                ? (true, "You have successfully connected to the MongoDB collection.", collectionName)
                : (false, "You have not connected to the MongoDB collection.", null);
        }

        private static (bool success, string message, object data) TestLoad()
        {
            var testObject = new MongoCode();
            var collection = testObject.GetCollection(host, port, database, collectionName);
            clearDocuments(collection);
            var documents = testObject.LoadData(collection, dataPath);

            if (documents == 0)
            {
                return (false, "You did not load any documents.", null);
            }

            return documents == 98
                ? (true, "You successfully loaded the documents into MongoDB.", documents)
                : (false,
                    $"You loaded the wrong number of documents. You loaded {documents} documents, 98 were expected.",
                    null);
        }

        private static (bool success, string message, object data) TestGetCustomerOrders()
        {
            var testObject = new MongoCode();
            var collection = testObject.GetCollection(host, port, database, collectionName);
            var customerOrder = testObject.getCustomerOrders(collection, customerNumber);

            if (customerOrder == null)
            {
                return (false, "You did not return a customer order document.", null);
            }

            return customerOrder.orders.Count == 3 && customerOrder.orders[1].details[0].productCode == "S18_3482"
                ? (true, "You have successfully returned a customer orders document.", customerOrder.orders)
                : (false, "You did not return the correct customer order document.", customerOrder.orders);
        }

        private static (bool success, string message, object data) TestGetProductOrders()
        {
            const string testCode = "S18_2957";

            var testObject = new MongoCode();
            var collection = testObject.GetCollection(host, port, database, collectionName);

            var documents = testObject.getProductOrders(collection, testCode);

            if (documents == null || documents.Count == 0)
            {
                return (false, "You did not return any product order documents.", null);
            }

            return documents.Count == 27 && documents.OrderBy(d => d.customerNumber).Last().customerNumber == 475
                ? (true,
                    $"You have successfully returned the customer order documents for the product code. Note that the file only contains 3 of 27 documents for productCode {testCode}.",
                    documents)
                : (false, "You did not return the correct set of documents.", documents);
        }

        private static (bool success, string message, object data) TestInsert()
        {

            var testObject = new MongoCode();
            var collection = testObject.GetCollection(host, port, database, collectionName);

            testObject.insertCustomer(collection, newCustomerOrder);
            var verify = getTestDocument(collection);

            if (verify == null)
            {
                return (false, "You did not insert a customer orders document.", null);
            }

            return verify.customerNumber == newCustomerNumber
                ? (true, "You have successfully inserted a customer order document.", verify)
                : (false, "You did not insert the correct customer order data.", verify);
        }

        private static (bool success, string message, object data) TestUpdate()
        {

            var testObject = new MongoCode();
            var collection = testObject.GetCollection(host, port, database, collectionName);

            testObject.updateCustomer(collection, newCustomerNumber, newOrder);
            var verify = getTestDocument(collection);

            if (verify == null)
            {
                return (false, "The customer order document does not exist.", null);
            }

            return verify.orders.Count == 2
                ? (true, "You have successfully updated a customer order document.", verify.orders)
                : (false, "You did not correctly update the customer order document.", verify.orders);
        }

        private static (bool success, string message, object data) TestDelete()
        {

            var testObject = new MongoCode();
            var collection = testObject.GetCollection(host, port, database, collectionName);

            testObject.deleteCustomer(collection, newCustomerNumber);
            var verify = getTestDocument(collection);

            return verify == null
                ? (true, "You have deleted a document from the collection", null)
                : (false, "You have not deleted the document from the collection.", verify);
        }

        private static (bool success, string message, object data) TestNoDocument()
        {

            var testObject = new MongoCode();
            var collection = testObject.GetCollection(host, port, database, collectionName);
            var verify = testObject.getCustomerOrders(collection, newCustomerNumber + 100);

            return verify == null
                ? (true, "You have successfully handled an empty result from a MongoDB query.", null)
                : (false, "You have retrieved a customer orders document in error. This should be a null", verify);
        }

        private static (bool success, string message, object data) TestInsertError()
        {

            var testObject = new MongoCode();
            var collection = testObject.GetCollection(host, port, database, collectionName);

            testObject.insertCustomer(collection, newCustomerOrder);
            var duplicate = testObject.insertCustomer(collection, newCustomerOrder);

            return duplicate != 1
                ? (false, "You have not handled the MongoWriteException exception..", duplicate)
                : (true, "You have successfully handled the MongoWriteException exception.", duplicate);
        }
    }
}
