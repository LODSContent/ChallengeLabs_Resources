using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using CSSTDModels;

namespace CSSTDModels
{
    public interface ICosmosDBSQLContext
    {
        string ConnectionString { get; set; }
        Task CreateCollection(string collectionName);
        List<ProductDocument> GetDocuments(string collectionName);
        List<ProductDocument> GetDocuments( string industry, string collectionName);
        Task UploadDocuments( List<ProductDocument> documents, string collectionName);
    }
}