using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;
using CSSTDModels;

namespace CSSTDModels
{
    public interface IMySQLContext
    {
        string ConnectionString { get; set; }
        void CreateTable(string tableName);
        void LoadData(List<VendorData> vendors, string tableName);
        List<VendorData> GetData(string tableName);

    }


}