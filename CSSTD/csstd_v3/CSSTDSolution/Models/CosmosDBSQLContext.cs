using CSSTDModels;
using Microsoft.Azure.Documents;
using Microsoft.Azure.Documents.Client;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace CSSTDSolution.Models
{
    public class CosmosDBSQLContext : ICosmosDBSQLContext
    {

        /*
         * 
         *                var CosmosDBKey = CloudConfigurationManager.GetSetting("ListingsKey");
                var CosmosDBUri = CloudConfigurationManager.GetSetting("ListingsURI");
                var databaseName = "realEstate";
                var collectionName = "listings";
                var databaseID = databaseName;
                DocumentClient client = new DocumentClient(new Uri(CosmosDBUri), CosmosDBKey);
                var database = await client.CreateDatabaseIfNotExistsAsync(new Database { Id = databaseID });
                DocumentCollection collectionSpec = new DocumentCollection
                {
                    Id = collectionName
                };
                DocumentCollection collection = await client.CreateDocumentCollectionIfNotExistsAsync(UriFactory.CreateDatabaseUri(databaseID), collectionSpec, new RequestOptions { OfferThroughput = 400  });


                IQueryable<Listing> query = client.CreateDocumentQuery<Listing>(
    UriFactory.CreateDocumentCollectionUri(databaseName, collectionName));
                if(query.Count<Listing>() == 0)
                {
                    string[] documents = { "https://lodschallenge.blob.core.windows.net/storagechallenges/Listing1.json",
    "https://lodschallenge.blob.core.windows.net/storagechallenges/Listing2.json",
    "https://lodschallenge.blob.core.windows.net/storagechallenges/Listing3.json"};
                    //Load Documents
                    foreach(string documentUri in documents)
                    {
                        await client.UpsertDocumentAsync(UriFactory.CreateDocumentCollectionUri("realEstate", "listings"), getListing(documentUri));
                    }

                }


            }
            catch
            {
                result = false;
            }
            return result;

         * */
        private DocumentClient client;
        private string databaseName = "productDB";
        public CosmosDBSQLContext(string uri, string key)
        {

            client = new DocumentClient(new Uri(uri), key);
            //this.ConnectionString = connectionString;
        }

        public string ConnectionString { get; set; }

        public async Task CreateCollection(string collectionName)
        {
            var database = await client.CreateDatabaseIfNotExistsAsync(new Database { Id = databaseName });
            DocumentCollection collectionSpec = new DocumentCollection
            {
                Id = collectionName
            };
            DocumentCollection collection = await client.CreateDocumentCollectionIfNotExistsAsync(
                UriFactory.CreateDatabaseUri(databaseName),
                collectionSpec,
                new RequestOptions { OfferThroughput = 400 });
        }

        public List<ProductDocument> GetDocuments(string collectionName)
        {
            IQueryable<ProductDocument> query = client.CreateDocumentQuery<ProductDocument>(
                UriFactory.CreateDocumentCollectionUri(databaseName, collectionName));
            return query.ToList();

        }

        public List<ProductDocument> GetDocuments(string industry, string collectionName)
        {
            IQueryable<ProductDocument> query = client.CreateDocumentQuery<ProductDocument>(
                UriFactory.CreateDocumentCollectionUri(databaseName, collectionName)).Where(p => p.Industry == industry);
            return query.ToList();
        }

        public Task UploadDocuments(List<ProductDocument> documents, string collectionName)
        {
            //await CreateCollection(collectionName);

            //Load Documents
            List<Task> tasks = new List<Task>();
            foreach (var document in documents)
            {
                tasks.Add(Task.Run(async () =>
               {
                   try
                   {
                       var uri = UriFactory.CreateDocumentCollectionUri(databaseName, collectionName);
                       var result = await client.UpsertDocumentAsync(uri, document);
                       System.Diagnostics.Trace.WriteLine(result.StatusCode);
                   }
                   catch (Exception ex)
                   {
                       System.Diagnostics.Trace.WriteLine(ex.ToString());

                   }

               }));
                tasks.Add(Task.Run(async () =>
                {
                    try
                    {
                        var uri = UriFactory.CreateDocumentCollectionUri(databaseName, collectionName);
                        var result = await client.UpsertDocumentAsync(uri, document);
                        System.Diagnostics.Trace.WriteLine(result.StatusCode);
                    }
                    catch (Exception ex)
                    {
                        System.Diagnostics.Trace.WriteLine(ex.ToString());

                    }
                }));
                //}

            }
            Task.WaitAll(tasks.ToArray());
            return Task.CompletedTask;

        }
    }
}