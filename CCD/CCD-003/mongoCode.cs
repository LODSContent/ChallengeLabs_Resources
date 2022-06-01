using System;
using System.Collections.Generic;

namespace labfiles {
    public class MongoCode {
        public IMongoCollection<CustomerOrder> GetCollection(string host, string port, string database, string collection) {
            throw new NotImplementedException();
        }

        public int LoadData(IMongoCollection<CustomerOrder> collection, string dataPath) {
            throw new NotImplementedException();
        }

        public CustomerOrder getCustomerOrders(IMongoCollection<CustomerOrder> collection, int customerNumber) {
            throw new NotImplementedException();
        }

        public List<CustomerOrder> getProductOrders(IMongoCollection<CustomerOrder> collection, string productCode) {
            throw new NotImplementedException();
        }

        public  int insertCustomer(IMongoCollection<CustomerOrder> collection, CustomerOrder customer) {
            throw new NotImplementedException();
        }

        public void updateCustomer(IMongoCollection<CustomerOrder> collection, int customerNumber, Order newOrder) {
            throw new NotImplementedException();
        }
        public void deleteCustomer(IMongoCollection<CustomerOrder> collection, int customerNumber) {
            throw new NotImplementedException();
        }

    }
    public class CustomerOrder {
        public string _id { get; set; }
        public int customerNumber { get; set; }
        public List<Order> orders { get; set; }

        public CustomerOrder(){
            orders = new List<Order>();

        }

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

    /*
      "details": [
        {
          "orderLineNumber": 1,
          "productName": "1966 Shelby Cobra 427 S/C",
          "productCode": "S24_1628",
          "priceEach": 43.27,
          "quantityOrdered": 50,
          "lineTotal": 2163.5
        },

    */
}