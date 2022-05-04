using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;

namespace Labfiles
{
    internal delegate (bool success, string message, object data) TestFunction();

    internal class TestFile
    {
        private const string dataPath = "d:\\labfiles\\data";
        private const string customerFile = "customer.json";
        private const string productsFile = "products.json";
        private const string orderFileSearch = "*.csv";
        private const string orderFileName = "2003-10.csv";
      
        internal const int NumberOfTests = 6;
        private static Customer testCustomer
        {
            get
            {
                var customerData = File.ReadAllText($"{dataPath}\\{customerFile}");
                var customer = JsonSerializer.Deserialize<Customer>(customerData);
                if (customer == null) return new Customer();

                customer.processingCenter = "LODS";
                return customer;
            }

        }

        private static Product testProduct
        {
            get
            {
                var products = File.ReadAllLines($"{dataPath}\\{productsFile}");
                return JsonSerializer.Deserialize<Product>(products[0].Substring(2));
            }
        }

        internal (bool success, string title, string message, object data) RunTest(int testNumber)
        {
            var tests = new List<(string title, TestFunction testFunction)>
            {
                ("Read data from a JSON file", TestReadCustomerFromFile),
                ("Modify an object on read", TestReadCustomerProcessingCenter),
                ("Generate a list of objects", TestReadProductCount),
                ("Parse substrings to create a list", TestReadProductData),
                ("Filter and sort lists", TestMonthlyOrders),
                ("Slice Lists", TestCustomerReport)
            };

            var title = tests[testNumber].title;

            try
            {
                var result = tests[testNumber].testFunction();
                return (result.success, title, result.message, result.data );
            }
            catch (Exception ex)
            {
                return (success: false, title, message: $"{title} \n Your code threw an exception. \n Exception: {ex.Message}", data: null );
            }
        }

        private (bool success, string message, object data) TestReadCustomerFromFile()
        {
            var testObject = new FileCode();
            var customer = testObject.readCustomer(dataPath, customerFile);

            if (customer == null) return (false, "Your code did not return a customer.", null);

            var customerString = $"{customer.customerName} \n {JsonSerializer.Serialize(customer)} \n";

            return customer.customerName == testCustomer.customerName
                ? (true, $"{customerString} \n You have successfully read in the customer data.", customer)
                : (false, $"{customerString} \n Your code did not return the correct data.", customer);
        }

        private (bool success, string message, object data) TestReadCustomerProcessingCenter()
        {
            var testObject = new FileCode();
            var customer = testObject.readCustomer(dataPath, customerFile);

            if (customer == null) return (false, "Your code did not return a customer object", null);

            return customer.processingCenter == "LODS"
                ? (true, "You have successfully set the processing center data.", customer)
                : (false, "Your code did not return the correct processing center data.", customer);
        }

        private (bool success, string message, object data) TestReadProductCount()
        {
            var testObject = new FileCode();
            var products = testObject.readProducts(dataPath, productsFile);

            if (products == null) return (false, "Your code did not return a List of Product objects", null);
            
            return products.Count == 110
                ? (true, "You have successfully returned the correct number of product objects.", products)
                : (false, "Your code did not return the correct number of Product objects", products);
        }

        private (bool success, string message, object data) TestReadProductData()
        {
            var testObject = new FileCode();
            var products = testObject.readProducts(dataPath, productsFile);

            if (products == null) return (false, "Your code did not return a List of Product objects", null);

            return products[0].msrp == testProduct.msrp
                ? (true, "You have successfully returned product data.", products)
                : (false, "Your code did not return the correct Product data", products);
        }

        private (bool success, string message, object data) TestMonthlyOrders()
        {
            var fileName = $"{dataPath}\\{orderFileName}";
            var orderData = File.ReadAllLines(fileName);

            var testData = orderData.Select(o => o.Split(","))
                .Select(order =>
                    new Order
                    {
                        orderNumber = int.Parse(order[0]),
                        orderDate = DateTime.Parse(order[1]),
                        status = order[2],
                        customerNumber = int.Parse(order[3]),
                        orderTotal = decimal.Parse(order[4])
                    })
                .ToList();

            var testTotal = testData.Where(o => o.status == "Shipped")
                                    .OrderByDescending(o => o.orderTotal)
                                    .Take(5).Last().orderTotal;

            var testObject = new FileCode();
            var orderResults = testObject.processMonthlyOrders(orderData);
            
            if (orderResults == null) return (false, "Your code did not return any orders.", null);

            return orderResults.Last().orderTotal == testTotal 
                ? (true, "Your code returned the correct order results.", orderResults) 
                : (false, "Your code did not return the correct data.", orderResults);
        }

        private (bool success, string message, object data) TestCustomerReport()
        { 
            var fileName = $"{dataPath}\\{orderFileName}";

            var testObject = new FileCode();
            var allOrderResults = testObject.generateOrdersReport(dataPath, orderFileSearch);
            
            if (allOrderResults == null || allOrderResults.Count == 0 )
            {
                return (false, "Your code did not return any data.", null);
            }
            
            if (allOrderResults.Count != 143)
            {
                return (false, $"Your code did not return the correct number of orders. The correct number is 143 and your code returned {allOrderResults.Count}.", allOrderResults );
            }
            
            return allOrderResults[30].customerNumber != 382 
                ? (true, "Your code did not return the correct order data.", allOrderResults )
                : (true, "You code returned the correct order data.", allOrderResults );
        }
    }
}