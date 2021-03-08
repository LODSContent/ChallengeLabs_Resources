using CSSTDModels;
using System.Collections.Generic;
using System.Data.SqlClient;

namespace CSSTDSolution.Models
{
    public class SQLServerContext :  ISQLServerContext
    {
        public SQLServerContext(string connectionString) 
        {
            this.ConnectionString = connectionString;
        }

        public string ConnectionString { get; set; }


        public void CreateTable(string tableName)
        {
            var SQL = $"If not Exists(SELECT * FROM sys.tables WHERE name = '{tableName}')" +
                $" CREATE TABLE dbo.{tableName}(ID int, Name VARCHAR(500), PostalCode VARCHAR(500));" +
                $" DELETE FROM {tableName};";
            using (var conn = new SqlConnection(this.ConnectionString))
            {
                using (var cmd = new SqlCommand(SQL, conn))
                {
                    conn.Open();
                    cmd.ExecuteNonQuery();
                    conn.Close();
                }

            }
        }

        public List<CustomerData> GetData(string tableName)
        {
            List<CustomerData> results = new List<CustomerData>();
            var SQL = $"SELECT * FROM dbo.{tableName};";
            using (var conn = new SqlConnection(this.ConnectionString))
            {
                using (var cmd = new SqlCommand(SQL, conn))
                {
                    conn.Open();
                    var rdr = cmd.ExecuteReader();
                    while (rdr.Read())
                    {
                        results.Add(new CustomerData
                        {
                            ID = (int)rdr["ID"],
                            Name = rdr["Name"].ToString(),
                            PostalCode = rdr["PostalCode"].ToString()
                        });
                    }
                    conn.Close();
                }

            }
            return results;
        }

        public void LoadData(List<CustomerData> customers, string tableName)
        {
            var SQL = $"INSERT INTO {tableName}(ID,Name,PostalCode) VALUES (@ID, @Name, @PostalCode);";
            using (var conn = new SqlConnection(this.ConnectionString))
            {
                using (var cmd = new SqlCommand(SQL, conn))
                {
                    cmd.Parameters.Add(new SqlParameter("@ID", System.Data.SqlDbType.Int));
                    cmd.Parameters.Add(new SqlParameter("@Name", System.Data.SqlDbType.VarChar, 500));
                    cmd.Parameters.Add(new SqlParameter("@PostalCode", System.Data.SqlDbType.VarChar, 500));
                    conn.Open();
                    foreach(var customer in customers)
                    {
                        cmd.Parameters["@ID"].Value = customer.ID;
                        cmd.Parameters["@Name"].Value = customer.Name;
                        cmd.Parameters["@PostalCode"].Value = customer.PostalCode;
                        cmd.ExecuteNonQuery();
                    }
                    conn.Close();
                }

            }
        }
    }

}