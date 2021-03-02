using CSSTDModels;
using MySql.Data.MySqlClient;
using System.Collections.Generic;

namespace CSSTDSolution.Models
{
    public class MySQLContext : IMySQLContext
    {
        public MySQLContext(string connectionString)
        {
            this.ConnectionString = connectionString;
        }

        public string ConnectionString { get; set; }

        public void CreateTable(string tableName)
        {
            string tableSQL = $"CREATE TABLE {tableName}(ID INT, Name VARCHAR(100), Industry VARCHAR(100) );";
            using (var conn = new MySqlConnection(this.ConnectionString))
            {
                conn.Open();
                using (var cmd = new MySqlCommand(tableSQL, conn))
                {
                    try
                    {
                        cmd.ExecuteNonQuery();
                    }
                    catch { }
                }
                string clearSQL = $"DELETE FROM {tableName};";
                using (var cmdClear = new MySqlCommand(clearSQL, conn))
                {
                    cmdClear.ExecuteNonQuery();
                }
                conn.Close();

            }
        }

        public List<VendorData> GetData(string tableName)
        {
            var result = new List<VendorData>();
            using (var conn = new MySqlConnection(this.ConnectionString))
            {
                var SQL = $"SELECT * FROM {tableName};";
                using (var cmd = new MySqlCommand(SQL, conn))
                {
                    conn.Open();
                    var rdr = cmd.ExecuteReader();
                    while (rdr.Read())
                    {
                        result.Add(new VendorData
                        {
                            ID = (int)rdr["ID"],
                            Industry = rdr["Industry"].ToString(),
                            Name = rdr["Name"].ToString()
                        });
                    }
                }
                conn.Close();
            }
            return result;


        }

        public void LoadData(List<VendorData> vendors, string tableName)
        {
            CreateTable(tableName);
            var sql = $"INSERT INTO {tableName}(ID,Name,Industry) VALUES(@ID, @Name, @Industry);";
            using (var conn = new MySqlConnection(this.ConnectionString))
            {
                using (var cmd = new MySqlCommand(sql, conn))
                {
                    cmd.Parameters.Add("@ID", MySqlDbType.Int32);
                    cmd.Parameters.Add("@Name", MySqlDbType.String);
                    cmd.Parameters.Add("@Industry", MySqlDbType.String);
                    conn.Open();
                    foreach (var vendor in vendors)
                    {
                        cmd.Parameters["@ID"].Value = vendor.ID;
                        cmd.Parameters["@Name"].Value = vendor.Name;
                        cmd.Parameters["@Industry"].Value = vendor.Industry;
                        cmd.ExecuteNonQuery();
                    }
                }
                conn.Close();


            }
        }
    }

}