using MongoDB.Driver;
using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;

namespace labfiles.mongo {
    public class MongoCode {
        
        public IMongoCollection<CustomerOrder> GetCollection(string host, string port, string database, string collection) {
            string connectionstring = $"mongodb://{host}:{port}";
            MongoClient client = new MongoClient(connectionstring);
            IMongoDatabase db = client.GetDatabase(database);
            return db.GetCollection<CustomerOrder>(collection);
        }
        
        public int LoadData(IMongoCollection<CustomerOrder> collection, string dataPath) {
            var customerOrders = new List<CustomerOrder>();
            foreach(var fileName in Directory.GetFiles(dataPath)) {
                var fileContent = File.ReadAllText(fileName);
                var customer = JsonSerializer.Deserialize<CustomerOrder>(fileContent);
                customer._id = customer.customerNumber.ToString();
                customerOrders.Add(customer);
            }
            collection.InsertMany(customerOrders);
            return (int)collection.CountDocuments<CustomerOrder>(co => true);
        }

        public CustomerOrder getCustomerOrders(IMongoCollection<CustomerOrder> collection, int customerNumber) {
            return collection.Find<CustomerOrder>(co=> co._id == customerNumber.ToString()).FirstOrDefault();
        }
        
        public List<CustomerOrder> getProductOrders(IMongoCollection<CustomerOrder> collection, string productCode) {
            var filter = Builders<CustomerOrder>.Filter.Eq("orders.details.productCode",productCode);
            var results = collection.Find(filter).ToList();
            return results;
        }

        public  int insertCustomer(IMongoCollection<CustomerOrder> collection, CustomerOrder customer) {
            try {
                customer._id = customer.customerNumber.ToString();
                collection.InsertOne(customer);
            } catch (MongoWriteException ){
                return 1;
            } catch {
                return -1;
            }
            return 0;
        }

        public void updateCustomer(IMongoCollection<CustomerOrder> collection, int customerNumber, Order newOrder) {
            var customerOrders = collection.Find<CustomerOrder>(co => co._id==customerNumber.ToString()).First();
            customerOrders.orders.Add(newOrder);
            collection.ReplaceOne<CustomerOrder>(co => co._id == customerNumber.ToString(),customerOrders);
        }
        
        public void deleteCustomer(IMongoCollection<CustomerOrder> collection, int customerNumber) {
            collection.DeleteOne<CustomerOrder>(co => co._id == customerNumber.ToString());
        }

    }
    public class CustomerOrder {
        public string _id { get; set; }
        public int customerNumber { get; set; }
        public List<Order> orders { get; set; }

        public CustomerOrder() => orders = new List<Order>();

    }

    public class Order {
        public int orderNumber { get; set; }
        public DateTime orderDate { get; set; }
        public DateTime? requiredDate { get; set; }
        public DateTime? shippedDate { get; set; }
        public string status { get; set; }
        public string comments { get; set; }
        public int customerNumber { get; set; }
        public List<OrderDetail> details { get; set; }

        public Order(){
            details = new List<OrderDetail>();
        }
    }
    public class OrderDetail {
        public int orderLineNumber { get; set; }
        public string productName { get; set; }
        public string productCode { get; set; }
        public decimal priceEach { get; set; }
        public int quantityOrdered { get; set; }
        public decimal lineTotal { get; set; }
    }
}