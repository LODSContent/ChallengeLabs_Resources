using CSSTDEvaluation;
using CSSTDModels;
using System;
using System.Collections.Generic;

#region "Instructions (all challenges)"
/*
 *  1. The connection string for the SQL Server database is passed into the contructor and the ConnectionString property is set to its value
 *  2. Create a table to hold CustomerData information. Depending on the framework you are using this might not be necessary
 *  3. Implement LoadData to upload a collection of CustomerData instances to the database
 *  4. Retrieve a collection of CustomerData instances from the database
 * 
 * */
#endregion

#region "Data structures"
        /*
         namespace CSSTDModels
        {

            [Description("Simple class representing basic customer data for an Azure SQL database")]
            public class CustomerData
            {
                [Description("Arbitrary primary key")]
                [Key]
                public int ID { get; set; }

                [Description("Customer name")]
                public string Name { get; set; }

                [Description("Customer postal/zip code")]
                public string PostalCode { get; set; }
            }
        }
 * */
#endregion

namespace CSSTDSolution.Models
{
    public class SQLServerContext : ISQLServerContext
    {
        public SQLServerContext(string connectionString) : base()
        {
            this.ConnectionString = connectionString;
        }

        public string ConnectionString { get; set; }

        public void CreateTable(string tableName)
        {
            throw new NotImplementedException();
        }

        public List<CustomerData> GetData(string tableName)
        {
            throw new NotImplementedException();
        }

        public void LoadData(List<CustomerData> customers, string tableName)
        {
            throw new NotImplementedException();
        }
    }
}