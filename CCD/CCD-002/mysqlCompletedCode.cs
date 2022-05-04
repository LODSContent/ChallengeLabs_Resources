using System.Collections.Generic;
using System.Threading.Tasks;
using MySqlConnector;

namespace labfiles.mysql
{
    public class MysqlCode
    {
       public async Task<MySqlConnection> getConnection(string host, string port, string database, string user, string password) {
          var builder = new MySqlConnectionStringBuilder
          {
             Server = host,
             Database = database,
             UserID = user,
             Password = password,
          };
          try
          {
             var conn = new MySqlConnection(builder.ConnectionString);
             await conn.OpenAsync();
             return conn;
          }
          catch (MySqlException )
          {
             return null;
          }
       }
        
       public async Task<(string,string)> retrieveCustomerByNumber(MySqlConnection connection, string customerNumber) {
          var SQL = $"SELECT customerName, phone FROM customers WHERE customerNumber = '{customerNumber}'";
          string customerName = null;
          string phone = null;
          using(var cmd = connection.CreateCommand()){
             cmd.CommandText = SQL;
             using(var rdr = await cmd.ExecuteReaderAsync()){
                if (await rdr.ReadAsync()) {
                   customerName = rdr.GetString(0);
                   phone = rdr.GetString(1);
                }
             }
          }
          return (customerName, phone);
       }
       
       public async Task<List<CustomerLocation>> retrieveCustomersByState(MySqlConnection connection, string state) {
          var SQL = $"SELECT customerNumber, customerName, state, postalCode FROM customers WHERE state = '{state}'";
          var results = new List<CustomerLocation>();
          using(var cmd = connection.CreateCommand()){
             cmd.CommandText = SQL;
             using(var rdr = await cmd.ExecuteReaderAsync()){
                while (await rdr.ReadAsync()) {
                   results.Add(new CustomerLocation{
                      customerNumber=rdr.GetInt32("customerNumber"),
                      customerName=rdr.GetString("customerName"),
                      state = rdr.GetString("state"),
                      postalCode = rdr.GetString("postalCode")
                   });
                }
             }
          }
          return results;
       }
       
       public async Task<int> insertProductLine(MySqlConnection connection, string productLine, string textDescription) {
          var insertSQL = @"INSERT INTO productlines(productLine, textDescription) VALUES (@productLine, @textDescription)";
          int rowCount = 0;
          using(var cmd = connection.CreateCommand()){
             cmd.CommandText = insertSQL;
             cmd.Parameters.AddWithValue("@productLine", productLine);
             cmd.Parameters.AddWithValue("@textDescription", textDescription);
             try
             {
                rowCount = await cmd.ExecuteNonQueryAsync();
             }
             catch (MySqlException ex)
             {
                if (ex.ErrorCode == MySqlErrorCode.DuplicateKeyEntry)
                {
                   return 0;
                }
                else
                {
                   return -1;
                }
             }
          }
          return rowCount;
       }
       public async Task<int> updateProductLine(MySqlConnection connection, string productLine, string htmlDescription) {
          var updateSQL = @"UPDATE productlines SET htmlDescription = @htmlDescription WHERE productLine = @productLine";
          int rowCount = 0;
          using(var cmd = connection.CreateCommand()){
             cmd.CommandText = updateSQL;
             cmd.Parameters.AddWithValue("@productLine", productLine);
             cmd.Parameters.AddWithValue("@htmlDescription", htmlDescription);
             rowCount = await cmd.ExecuteNonQueryAsync();
          }
          return rowCount;
       }
       
       public async Task<int> deleteProductLine(MySqlConnection connection, string productLine) {
          var deleteSQL = @"DELETE FROM productlines WHERE productLine = @productLine";
          int rowCount = 0;
          using(var cmd = connection.CreateCommand()){
             cmd.CommandText = deleteSQL;
             cmd.Parameters.AddWithValue("@productLine", productLine);
             rowCount = await cmd.ExecuteNonQueryAsync();
          }
          return rowCount;
       }       
    }
    
}