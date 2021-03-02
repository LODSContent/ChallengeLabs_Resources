using CSSTDModels;
using System;
using System.Collections.Generic;

namespace CSSTDSolution.Models
{
    #region "Instructions (all challenges)"
    /*
     *  1. The connection string for the MySQL database is passed into the contructor and the ConnectionString property is set to its value
     *  2. Create a table to hold VendorData information. Depending on the framework you are using this might not be necessary
     *  3. Implement LoadData to upload a collection of VendorData instances to the database
     *  4. Retrieve a collection of VendorData instances from the database
     * 
     * */
    #endregion

    #region "Data structures"
    /*
        namespace CSSTDModels
        {

            [Description("Simple class representing basic vendor data for an Azure database for MySQL")]
            public class VendorData
            {
                [Description("Arbitrary primary key")]
                [Key]
                public int ID { get; set; }

                [Description("Vendor name")]
                public string Name { get; set; }

                [Description("Industry designation, currently 'Training' or 'Swimming'")]
                public string Industry { get; set; }
            }
        }
     * */
    #endregion

    public class MySQLContext : IMySQLContext
    {
        public MySQLContext(string connectionString)
        {
            this.ConnectionString = connectionString;
        }

        public string ConnectionString { get; set; }

        public void CreateTable(string tableName)
        {
            throw new NotImplementedException();
        }

        public List<VendorData> GetData(string tableName)
        {
            throw new NotImplementedException();
        }

        public void LoadData(List<VendorData> vendors, string tableName)
        {
            throw new NotImplementedException();
        }
    }
}