using System;
using System.Threading.Tasks;
using System.Collections.Generic;

namespace csharp_data
{
    public class mysqlCode
    {
        public async Task<MySqlConnection> getConnection(string host, string port, string database, string user, string password) {
           await Task.CompletedTask;
           throw new NotImplementedException();
        }
        public async Task<(string,string)> retrieveCustomerByNumber(MySqlConnection connection, string customerNumber) {
           await Task.CompletedTask;
           throw new NotImplementedException();
        }
        public async Task<List<CustomerLocation>> retrieveCustomersByState(MySqlConnection connection, string state) {
           await Task.CompletedTask;
           throw new NotImplementedException();
        }
        public async Task<int> insertProductLine(MySqlConnection connection, string productLine, string textDescription) {
           await Task.CompletedTask;
           throw new NotImplementedException();
        }
        public async Task<int> updateProductLine(MySqlConnection connection, string productLine, string htmlDescription) {
           await Task.CompletedTask;
           throw new NotImplementedException();
       }
        public async Task<int> deleteProductLine(MySqlConnection connection, string productLine) {
           await Task.CompletedTask;
           throw new NotImplementedException();
       }        
    }
    
}