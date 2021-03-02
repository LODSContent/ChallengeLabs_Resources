using CSSTDModels;
using System;
using System.Collections.Generic;
using System.IO;
using Azure.Storage.Blobs;

namespace CSSTDSolution.Models
{
    public class StorageContext : IStorageContext
    {
        private string connectionString;
        public StorageContext(string connectionString)
        {
            this.connectionString = connectionString;
        }

        public List<BlobFileData> GetFileList(string containerName, bool isPrivate)
        {
            var results = new List<BlobFileData>();
            var container = new BlobContainerClient(connectionString, containerName);
            
            var sas = isPrivate ? GetSAS(containerName) : "";
            foreach (var blob in container.GetBlobs())
            {
                var blobClient = container.GetBlobClient(blob.Name);
                results.Add(new BlobFileData
                {
                    Name = blobClient.Name,
                    URL = blobClient.Uri.AbsoluteUri,
                    SAS = sas
                }); ;
            }
            return results;
        }

        public string GetSAS(string containerName)
        {
            var container = new BlobContainerClient(connectionString, containerName);
            container.CreateIfNotExists();
            return container.GenerateSasUri(Azure.Storage.Sas.BlobContainerSasPermissions.Read, DateTime.UtcNow.AddDays(1)).Query;
        }

        public void UploadFile(string containerName, BlobFileData fileData, bool isPrivate)
        {
            var container = new BlobContainerClient(connectionString, containerName);
            if (!container.Exists())
            {
                container.Create();
                var accessType = isPrivate ? Azure.Storage.Blobs.Models.PublicAccessType.None : Azure.Storage.Blobs.Models.PublicAccessType.Blob;
                container.SetAccessPolicy(accessType);
            }
            using (MemoryStream blobStream = new MemoryStream(fileData.Contents))
            {
                container.UploadBlob(fileData.Name, blobStream);
            }

        }
    }
}