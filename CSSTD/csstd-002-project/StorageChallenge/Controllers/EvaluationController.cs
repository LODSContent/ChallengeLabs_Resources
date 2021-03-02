using System.Web.Http;
using CSSTDSolution.Models;
using CSSTDModels;
using CSSTDEvaluation;
using System.Configuration;

namespace CSSTDSolution.Controllers
{
    [RoutePrefix("evaluate")]
    public class EvaluationController : ApiController
    {
        private string baseFolder = System.Web.HttpContext.Current.Server.MapPath("~/SampleData/");

        [Route("blobupload")]
        [HttpGet]
        public EvaluationResult<BlobFileData> BlobUploadTest(string storageAccountConnectionString, string containerName, bool isPrivate, string encryptionKey)
        {
            EnsureValue(ref storageAccountConnectionString, "StorageAccountConnectionString");
            return new BlobEvaluationProcessor(baseFolder, encryptionKey).BlobUpload(new StorageContext(storageAccountConnectionString), containerName, isPrivate);
        }

        [Route("blobdownload")]
        [HttpGet]
        public EvaluationResult<BlobFileData> BlobDownloadTest(string storageAccountConnectionString, string containerName, bool isPrivate, string encryptionKey)
        {
            EnsureValue(ref storageAccountConnectionString, "StorageAccountConnectionString");
            return new BlobEvaluationProcessor(baseFolder, encryptionKey).BlobDownload(new StorageContext(storageAccountConnectionString), containerName, isPrivate);
        }


        [Route("blobsas")]
        [HttpGet]
        public EvaluationResult<string> BlobSASTest(string storageAccountConnectionString, string containerName, string encryptionKey)
        {
            EnsureValue(ref storageAccountConnectionString, "StorageAccountConnectionString");
            return new BlobEvaluationProcessor(baseFolder, encryptionKey).ContainerSAS(new StorageContext(storageAccountConnectionString), containerName);
        }

        [Route("sqlupload")]
        [HttpGet]
        public EvaluationResult<CustomerData> SQLServerUploadTest(string connectionString, string tableName, string encryptionKey)
        {
            EnsureValue(ref connectionString, "SQLConnection");
            return new RelationalEvaluationProcessor(baseFolder, encryptionKey).SQLServerUpload(new SQLServerContext(connectionString), tableName);
        }

        [Route("sqldownload")]
        [HttpGet]
        public EvaluationResult<CustomerData> SQLServerDownloadTest(string connectionString, string tableName, string encryptionKey)
        {
            EnsureValue(ref connectionString, "SQLConnection");
            return new RelationalEvaluationProcessor(baseFolder, encryptionKey).SQLServerDownload(new SQLServerContext(connectionString), tableName);
        }

        [Route("mysqlupload")]
        [HttpGet]
        public EvaluationResult<VendorData> MySQLUploadTest(string connectionString, string tableName, string encryptionKey)
        {
            EnsureValue(ref connectionString, "MySQLConnection");
            return new RelationalEvaluationProcessor(baseFolder, encryptionKey).MySQLUpload(new MySQLContext(connectionString), tableName);
        }

        [Route("mysqldownload")]
        [HttpGet]
        public EvaluationResult<VendorData> MySQLDownloadTest(string connectionString, string tableName, string encryptionKey)
        {
            EnsureValue(ref connectionString, "MySQLConnection");
            return new RelationalEvaluationProcessor(baseFolder, encryptionKey).MySQLDownload(new MySQLContext(connectionString), tableName);
        }

        [Route("cosmossqlupload")]
        [HttpGet]
        public EvaluationResult<ProductDocument> CosmosDBSQLUploadTest(string uri, string key, string collectionName, string encryptionKey)
        {
            EnsureValue(ref uri, "CosmosDBSQLUri");
            EnsureValue(ref key, "CosmosDBSQLKey");
            return new NoSQLEvaluationProcessor(baseFolder, encryptionKey).CosmosDBSQLUpload(new CosmosDBSQLContext(uri, key), collectionName);
        }

        [Route("cosmossqldownload")]
        [HttpGet]
        public EvaluationResult<ProductDocument> CosmosDBSQLDownloadTest(string uri, string key, string collectionName, string encryptionKey)
        {
            EnsureValue(ref uri, "CosmosDBSQLUri");
            EnsureValue(ref key, "CosmosDBSQLKey");
            return new NoSQLEvaluationProcessor(baseFolder, encryptionKey).CosmosDBSQLDownload(new CosmosDBSQLContext(uri, key), collectionName);
        }

        [Route("cosmostableupload")]
        [HttpGet]
        public EvaluationResult<IProductMention> CosmosDBTableUploadTest(string accountName, string key, string tableName, string encryptionKey)
        {
            EnsureValue(ref accountName, "CosmosDBTableAccount");
            EnsureValue(ref key, "CosmosDBTableKey");
            return new NoSQLEvaluationProcessor(baseFolder, encryptionKey).CosmosDBTableUpload(new CosmosDBTableContext(accountName, key), tableName);
        }

        [Route("cosmostabledownload")]
        [HttpGet]
        public EvaluationResult<IProductMention> CosmosDBTableDownloadTest(string accountName, string key, string tableName, string encryptionKey)
        {

            EnsureValue(ref accountName, "CosmosDBTableAccount");
            EnsureValue(ref key, "CosmosDBTableKey");
            return new NoSQLEvaluationProcessor(baseFolder, encryptionKey).CosmosDBTableDownload(new CosmosDBTableContext(accountName, key), tableName);

        }

        void EnsureValue(ref string value, string settingName)
        {
            if (value == "-1")
                value = ConfigurationManager.AppSettings[settingName];
        }

    }
}
