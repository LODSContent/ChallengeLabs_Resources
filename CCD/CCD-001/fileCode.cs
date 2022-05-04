using System;
using System.Linq;


namespace labfiles
{
    public class FileCode
    {
        public Customer readCustomer(string dataPath, string fileName)
        {
            throw new  NotImplementedException();
        }
        public List<Product> readProducts(string dataPath, string fileName)
        {
            throw new  NotImplementedException();
        }

        public List<Order> generateOrdersReport(string dataPath, string searchPattern)
        {
            throw new  NotImplementedException();
        }

        public List<Order> processMonthlyOrders(string[] orderData)
        {
            throw new  NotImplementedException();
        }
    }

    public class Customer
    {
        public int customerNumber { get; set; }
        public string customerName { get; set; }
        public string phone { get; set; }
        public string city { get; set; }
        public string state { get; set; }
        public string processingCenter { get; set; }
    }

    public class Product
    {
        public string productCode { get; set; }
        public string productName { get; set; }
        public decimal MSRP { get; set; }

    }

    public class Order
    {
        //10100,2003-01-06,Shipped,363,10223.83
        public int orderNumber { get; set; }
        public System.DateTime orderDate { get; set; }
        public string status { get; set; }
        public int customerNumber { get; set; }
        public decimal orderTotal { get; set; }
    }

}