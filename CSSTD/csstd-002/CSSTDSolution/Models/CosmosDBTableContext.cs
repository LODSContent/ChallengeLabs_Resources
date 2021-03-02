using CSSTDModels;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Azure.Cosmos.Table;

namespace CSSTDSolution.Models
{
    public class CosmosDBTableContext : ICosmosDBTableContext
    {
        public string ConnectionString { get; set; }

        private CloudTableClient client;
        public CosmosDBTableContext(string accountName, string key)
        {
            var endpoint = $"https://{accountName}.table.cosmosdb.azure.com";
            var uri = new Uri(endpoint);
            client = new CloudTableClient(uri, new Microsoft.Azure.Cosmos.Table.StorageCredentials(accountName, key));

        }

        public void CreateTable(string tableName)
        {
            var table = client.GetTableReference(tableName);
            table.CreateIfNotExists();
            

        }

        public List<IProductMention> GetMentions(string tableName)
        {
            var table = client.GetTableReference(tableName);
            var query = new TableQuery<ProductMention>();
            return new List<IProductMention>(table.ExecuteQuery(query));


        }

        public List<IProductMention> GetMentions(string product, string platform, string tableName)
        {
            var table = client.GetTableReference(tableName);
            var query = new TableQuery<ProductMention>()
            {
                FilterString = TableQuery.GenerateFilterCondition("PartitionKey", QueryComparisons.Equal, $"{platform}:{product}"),
            };

            return new List<IProductMention>(table.ExecuteQuery(query).ToList());
        }

        public void LoadMentions(List<IProductMention> mentions, string tableName)
        {
            var table = client.GetTableReference(tableName);
            foreach (var mention in mentions)
            {
                try
                {
                    var tableMention = new ProductMention(mention);
                    var op = TableOperation.Insert(tableMention);
                    table.Execute(op);
                }
                catch(Exception ex)
                {
                    System.Diagnostics.Trace.TraceError($"There was an error processing the mentions: {ex.ToString()}");
                }


            }
            
        }
    }
    public class ProductMention : TableEntity, IProductMention
    {
        public ProductMention() { }

        public ProductMention(IProductMention source)
        {
            this.MentionID = source.MentionID;
            this.Product = source.Product;
            this.Platform = source.Platform;
            this.Mention = source.Mention;
            this.MentionedAt = source.MentionedAt;
        }
        private string product, platform;

        public string Product
        {
            get { return this.product; }
            set
            {
                this.product = value;
                setPartition();
            }
        }
        public string Platform
        {
            get { return this.platform; }
            set
            {
                this.platform = value;
                setPartition();
            }
        }

        private void setPartition()
        {
            this.PartitionKey = $"{platform}:{product}";
        }

        public string MentionedAt { get; set; }
        public string Mention { get; set; }
        public string MentionID { get => this.RowKey; set => this.RowKey = value; }
    }
}