using CSSTDModels;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace CSSTDSolution.Models
{
    public class CosmosDBTableContext : ICosmosDBTableContext
    {
        public string ConnectionString { get; set; }
        public CosmosDBTableContext(string accountName, string key)
        {
        }



        public void CreateTable(string tableName)
        {
            throw new NotImplementedException();
        }

        public List<IProductMention> GetMentions(string tableName)
        {
            throw new NotImplementedException();
        }

        public List<IProductMention> GetMentions(string product, string platform, string tableName)
        {
            throw new NotImplementedException();
        }

        public void LoadMentions(List<IProductMention> mentions, string tableName)
        {
            throw new NotImplementedException();
        }
    }
    /*  This class has everything necessary to process a ProductMention in a CosmosDB table
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
    */
}