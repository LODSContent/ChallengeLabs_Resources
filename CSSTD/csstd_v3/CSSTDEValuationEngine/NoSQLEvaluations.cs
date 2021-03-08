using CSSTDModels;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace CSSTDEvaluation
{
    public class NoSQLEvaluationProcessor
    {
        private SampleData sampleData;
        public NoSQLEvaluationProcessor(string baseFolder, string encryptionKey)
        {
            sampleData = new SampleData(baseFolder);
        }
        public NoSQLEvaluationProcessor() { }

        public EvaluationResult<ProductDocument> CosmosDBSQLUpload(ICosmosDBSQLContext context, string containerName)
        {
            var result = new EvaluationResult<ProductDocument>();
            var data = sampleData.ProductData();
            try
            {
                Task t = Task.Run(async () =>
                {
                    await context.CreateCollection(containerName);
                    await context.UploadDocuments(data, containerName);
                });
                t.Wait();

            }
            catch (Exception ex)
            {
                result.Code = 2;
                result.Text = $"There was an error uploading product documents to Cosmos DB: {ex.Message}";
            }

            return result;
        }
        public EvaluationResult<ProductDocument> CosmosDBSQLDownload(ICosmosDBSQLContext context, string containerName)
        {
            var result = new EvaluationResult<ProductDocument>();
            try
            {
                result.Results = context.GetDocuments(containerName);
                result.Code = result.Results.Count > 0 ? 0 : 1;
                result.Text = result.Results.Count > 0 ? "Successfully returned product documents from Cosmos DB" : "Did not return any documents from Cosmos DB";

            }
            catch (Exception ex)
            {
                result.Code = 2;
                result.Text = $"There was an error downloading product documents from Cosmos DB: {ex.Message}";
            }
            return result;
        }

        public EvaluationResult<IProductMention> CosmosDBTableUpload(ICosmosDBTableContext context, string tableName)
        {
            var result = new EvaluationResult<IProductMention>();
            try
            {
                var data = sampleData.ProductMentionData();
                context.CreateTable(tableName);
                context.LoadMentions(data, tableName);
                result.Code = 0;
                result.Text = "Successfully uploaded table data to Cosmos DB account.";
            }
            catch (Exception ex)
            {
                result.Code = 2;
                result.Text = $"There was an error uploading table data: {ex.Message}";
            }


            return result;
        }

        public EvaluationResult<IProductMention> CosmosDBTableDownload(ICosmosDBTableContext context, string tableName)
        {
            var result = new EvaluationResult<IProductMention>();
            try
            {
                result.Results = new List<IProductMention>(context.GetMentions(tableName));
                result.Code = result.Results.Count > 0 ? 0 : 1;
                result.Text = result.Code == 0 ? "Successfully downloaded table data from Cosmos DB account" :
                    "There were no errors, but no records were returned from Cosmos DB table.";
            }
            catch (Exception ex)
            {
                result.Code = 2;
                result.Text = $"There was an error retrieving tabular data from Cosmos DB: {ex.Message}";
            }

            return result;
        }

    }

}