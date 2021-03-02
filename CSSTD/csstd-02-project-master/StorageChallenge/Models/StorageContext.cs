using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using CSSTDEvaluation;
using CSSTDModels;

#region "Advanced/Expert Storage Instructions"
/*
 * 1. The storage account connection string is passed in via the class constructor and assigned to the ConnectionString property.
 * 2. Implement the constructor to initialize a private variable of type CloudBlobClient to be used by all other methods
 * 3. Implement the UploadFile method to:
 *      a. Ensure that a container named by the containerName parameter exists and its access is set accoring to the isPrivate parameter
 *      b. Upload the file represented by the fileData parameter to the container named by the containerName parameter
 * 4. Implement the GetSAS method to:
 *      a. Generate a SAS token for the specified container.  The token should support read operations for at least 24 hours.
 *      b. Return the SAS token
 * 5. Implement the GetFileList method to:
 *      a. Retrieve the URLs of the files in the container named by the containerName parameter
 *      b. If the isPrivate parameter is true, call the GetSAS method to generate a SAS token
 *      c. Populate a List<BlobData> object with the name and URL of each file in the container.  
 *      d. If the isPrivate parameter is true, the URL must contain the SAS token.
 *      e. Return the List<BlobData> object
 * 
 * */
#endregion

#region "Data Structures"
/*
         namespace CSSTDModels
        {
            [Description("Object for transferring blob data into and out of the StorageContext class.")]
            public class BlobFileData
            {
                [Description("Blob name.  Used for data in and data out.")]
                public string Name { get; set; }

                [Description("Full Blob URL including SAS if appropriate. Used for data out.")]
                public string URL { get; set; }

                [Description("SAS token.  Used for data out.")]
                public string SAS { get; set; }

                [Description("Binary file contents used for upload.")]
                public byte[] Contents { get; set; }

                [Description("Blob metadata used for advanced and expert challenges.")]
                public List<string> Tags { get; set; }
            }
        }
 * */
#endregion

namespace CSSTDSolution.Models
{
    public class StorageContext : IStorageContext
    {
 
        public StorageContext(string connectionString)
        {
            
        }

        public  void UploadFile(string containerName, BlobFileData fileData, bool isPrivate)
        {
            throw new NotImplementedException();
        }

        public  string GetSAS(string containerName)
        {
            throw new NotImplementedException();
        }

        public  List<BlobFileData> GetFileList(string containerName, bool isPrivate)
        {
            throw new NotImplementedException();
        }

    }
}