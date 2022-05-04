using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace labfiles.mysql
{
    internal delegate Task<(bool success, string message, object data)> TestFunction();

    internal class MySqlTest
    {
        internal async Task<(bool success, string title, string message, object data)> RunTest(int testNumber)
        {
            var tests = new List<(string title, TestFunction testFunction)>
            {
                ("getConnection", TestConnect),
                ("retrieveCustomerByNumber", TestGetCustomerByCustomerNumber),
                ("retrieveCustomersByState", TestGetCustomersByState),
                ("insertProductLine", TestInsertProductLine),
                ("updateProductLine", TestUpdateProductLine),
                ("deleteProductLine", TestDeleteProductLine),
                ("Connection exception", TestConnectionExceptionHandling),
                ("No results", TestGetCustomerByCustomerNumberEmpty),
                ("Insert exception", TestInsertExceptionHandling)
            };

            var title = tests[testNumber].title;

            try
            {
                var result = await tests[testNumber].testFunction();
                return (result.success, title, result.message, result.data );
            }
            catch (Exception ex)
            {
                return (success: false, title, message: $"{title} \n Your code threw an exception. \n Exception: {ex.Message}", data: null );
            }
        }
        
        private const string testCustomerNumber = "161";
        private const string testCustomerName = "Technics Stores Inc.";
        private const string testProductLine = "Graphene Cars";
        private const string testProductLineDescription = "Graphene Cars are literally made of the strongest material we can get our hands on.";
        private const string testProductLineHtml = "<div class'productline'>Graphene Cars are literally <b>made of the strongest material we can get our hands on</b>.</div>";
        
        internal const int NumberOfTests = 9;


        private static async Task<ProductLine> GetProductLineAsync()
        {
            var testObject = new MysqlCode();
            var connection = await testObject.getConnection(Settings.mysqlHost, Settings.mysqlPort, Settings.database, Settings.user, Settings.password);
            var SQL = $"SELECT * FROM productlines WHERE productLine = '{testProductLine}'";
            ProductLine productLine = null;
            await using var cmd = connection.CreateCommand();
            cmd.CommandText = SQL;
            await using var rdr = await cmd.ExecuteReaderAsync();
            if (await rdr.ReadAsync())
            {
                productLine = new ProductLine
                {
                    productLine = rdr.GetString("productLine"),
                    textDescription = rdr["textDescription"].ToString(),
                    htmlDescription = rdr["htmlDescription"].ToString()
                };
            }

            return productLine;
        }

        internal static async Task<int> deleteProductLineAsync()
        {
            var testObject = new MysqlCode();
            var connection = await testObject.getConnection(Settings.mysqlHost, Settings.mysqlPort, Settings.database, Settings.user, Settings.password);
            var deleteSQL = @"DELETE FROM productlines WHERE productLine = @productLine";
            int rowCount = 0;
            using (var cmd = connection.CreateCommand())
            {
                cmd.CommandText = deleteSQL;
                cmd.Parameters.AddWithValue("@productLine", testProductLine);
                rowCount = await cmd.ExecuteNonQueryAsync();
            }
            return rowCount;
        }

        static async Task<(bool success, string message, object data)> TestConnect()
        {
            var testObject = new MysqlCode();
            
            var conn = await testObject.getConnection(Settings.mysqlHost, Settings.mysqlPort, Settings.database, Settings.user, Settings.password);
            
            return conn.Database == Settings.database
                ? (true, "You have successfully connected to the MariaDB database.", null)
                : (false, "You have not connected to the MariaDB database.", null);
        }
        
        static async Task<(bool success, string message, object data)> TestGetCustomerByCustomerNumber()
        {
            var testObject = new MysqlCode();
            var conn = await testObject.getConnection(Settings.mysqlHost, Settings.mysqlPort, Settings.database, Settings.user, Settings.password);
            
            string customerName, phone;
            
            //Read a single 
            (customerName, phone) = await testObject.retrieveCustomerByNumber(conn, testCustomerNumber);

            return customerName == testCustomerName
                ? (true, $"You have successfully returned a customer record for {customerName} with a phone number of {phone}", (customerName, phone))
                : (false, "You have not returned the correct customer information.", (customerName, phone));
        }
        
        static async Task<(bool success, string message, object data)> TestGetCustomersByState()
        {

            var testObject = new MysqlCode();
            var conn = await testObject.getConnection(Settings.mysqlHost, Settings.mysqlPort, Settings.database, Settings.user, Settings.password);
            var customers = await testObject.retrieveCustomersByState(conn, "NY");

            return customers.Count switch
            {
                0 => (false, "You did not return any customers.", null),
                6 => (true, "You successfully returned customers based on their state.", customers),
                _ => ((bool success, string message, object data))(false,
                    $"You did not return the correct number of customers. You returned {customers.Count}.", null)
            };
        }

        static async Task<(bool success, string message, object data)> TestInsertProductLine()
        {
            var testObject = new MysqlCode();
            var conn = await testObject.getConnection(Settings.mysqlHost, Settings.mysqlPort, Settings.database, Settings.user, Settings.password);
            
            var rowCount = await testObject.insertProductLine(conn, testProductLine, testProductLineDescription);
            
            if (rowCount <= 0) return (false, "You have not properly inserted a product line record.", null);
            
            var productLine = await GetProductLineAsync();

            return productLine is { textDescription: testProductLineDescription } 
                ? (true, "You have successfully inserted a product line record.", productLine) 
                : (false, "You have not properly inserted a product line record.", null);
        }

        static async Task<(bool success, string message, object data)> TestUpdateProductLine()
        {
            var testObject = new MysqlCode();
            var conn = await testObject.getConnection(Settings.mysqlHost, Settings.mysqlPort, Settings.database, Settings.user, Settings.password);
            var rowCount = await testObject.updateProductLine(conn, testProductLine, testProductLineHtml);
            
            var productLine = await GetProductLineAsync();

            if (rowCount == 0) return (false, "You have not updated a product line record.", productLine);

            return productLine is { htmlDescription: testProductLineHtml }
                ? (true, "You have successfully updated a product line record", productLine)
                : (false, "You have not properly updated a product line record.", productLine);
        }
                
        static async Task<(bool success, string message, object data)> TestDeleteProductLine()
        {
            var testObject = new MysqlCode();
            var conn = await testObject.getConnection(Settings.mysqlHost, Settings.mysqlPort, Settings.database, Settings.user, Settings.password);
            var rowCount = await testObject.deleteProductLine(conn, testProductLine);
            var productLine = await GetProductLineAsync();

            if (rowCount == 0) return (false, "", productLine);
            
            return productLine == null 
                ? (true, "You have successfully deleted a product line record.", null) 
                : (false, "You have not properly updated a product line record.", productLine);
        }
        
        static async Task<(bool success, string message, object data)> TestConnectionExceptionHandling()
        {
            var testObject = new MysqlCode();
            try
            {
                var conn = await testObject.getConnection(Settings.mysqlHost, Settings.mysqlPort, Settings.database,
                    $"bad{Settings.user}", Settings.password);

                return conn == null
                    ? (true, "You have successfully handled a bad MySQL connection string.", null)
                    : (false, "There was an error generation an exception to test.", conn);
            }
            catch(Exception e) { return (false, "You have not handled a bad MySQL connection string.", e); }
        }
        
        static async Task<(bool success, string message, object data)> TestGetCustomerByCustomerNumberEmpty()
        {
            var testObject = new MysqlCode();
            var conn = await testObject.getConnection(Settings.mysqlHost, Settings.mysqlPort, Settings.database, Settings.user, Settings.password);
            
            var customer = await testObject.retrieveCustomerByNumber(conn, testCustomerNumber + 1000000);
            
            return customer.Item1 == null
                ? (true, "\tYou have successfully handled an empty result set." , null)
                : (false, "\tYou have not handled an empty result set.", customer );
        }
        
        static async Task<(bool success, string message, object data)> TestInsertExceptionHandling()
        {
            var testObject = new MysqlCode();
            var conn = await testObject.getConnection(Settings.mysqlHost, Settings.mysqlPort, Settings.database, Settings.user, Settings.password);
            
            await testObject.insertProductLine(conn, null, testProductLineDescription);
            var duplicate = await testObject.insertProductLine(conn, testProductLine, testProductLineDescription);

            return duplicate == 0 
                ? (true, "You have successfully implemented exception handling for a DuplicateKeyEntry exception.", null)
                : (false, "You have not implemented exception handling specifically for a DuplicateKeyEntry exception.", duplicate);
        }
    }
}