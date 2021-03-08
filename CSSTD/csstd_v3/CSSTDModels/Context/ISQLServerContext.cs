using CSSTDModels;
using System.Collections.Generic;

namespace CSSTDModels
{
    public interface ISQLServerContext
    {
        string ConnectionString { get; set; }
        void CreateTable(string tableName);
        void LoadData(List<CustomerData> customers, string tableName);
        List<CustomerData> GetData(string tableName);

    }

}