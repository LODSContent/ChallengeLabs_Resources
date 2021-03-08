using CSSTDModels;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.IO;

namespace CSSTDEvaluation
{
    public class SampleData
    {
        public string dataFolder;
        public SampleData(string dataFolder)
        {
            this.dataFolder = dataFolder;
        }
        public SampleData() { }

        public List<BlobFileData> BlobData()
        {
            var files = new List<BlobFileData>();
            string[] fileNames = { "doors.jpg", "labondemand.jpg", "lodslogo.png" };
            string[][] tags = { new string[] { "Abstract", "Physical" }, new string[] { "Learning", "Person" }, new string[] { "Corporate", "Logo" } };
            for (int i = 0; i < 3; i++)
            {
                string filePath = $"{dataFolder}\\{fileNames[i]}";
                files.Add(new BlobFileData
                {
                    Contents = File.ReadAllBytes(filePath),
                    Name = fileNames[i],
                    Tags = new List<string>(tags[i])
                });

            }
            return files;
        }
        public List<CustomerData> CustomerData()
        {
            return JsonConvert.DeserializeObject<List<CustomerData>>(File.ReadAllText($"{dataFolder}\\Customers.json"));
        }
        public List<VendorData> VendorData()
        {
            return JsonConvert.DeserializeObject<List<VendorData>>(File.ReadAllText($"{dataFolder}\\Vendors.json"));
        }
        public List<ProductDocument> ProductData()
        {
            return JsonConvert.DeserializeObject<List<ProductDocument>>(File.ReadAllText($"{dataFolder}\\Products.json"));
        }

        public List<IProductMention> ProductMentionData()
        {
            List<IProductMention> results = new List<IProductMention>();
            string[] platforms = new string[] { "Twitter", "LinkedIn", "Reddit", "Instagram" };
            string[] mentions = new string[] {
                "We just tried %product% and it was amazing #%industry%",
                "Shout out to %product%! It's amazing",
                "I learned a lot from %product%! Kudos to LODS."};
            var products = ProductData();
            var rnd = new Random();
            foreach (var product in products)
            {
                foreach (var platform in platforms)
                {
                    foreach (var mention in mentions)
                    {
                        results.Add(new ProductMention
                        {
                            MentionID = Guid.NewGuid().ToString(),
                            Mention = mention.Replace("%product%", product.Name).Replace("%industry%", product.Industry),
                            MentionedAt = DateTime.Now.AddDays(-rnd.Next(1, 100)).AddMinutes(-rnd.Next(1200)).ToString(),
                            Platform = platform,
                            Product = product.Name
                        });
                    }
                }
            }
            return results;
        }
    }

    internal class ProductMention : IProductMention
    {
        public string MentionID { get; set; }
        public string Mention { get; set; }
        public string MentionedAt { get; set; }
        public string Platform { get; set; }
        public string Product { get; set; }
    }
}