using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using CSSTDModels;
using System.IO;
using System.Net;

namespace CSSTDEvaluation
{
    public class BlobEvaluationProcessor
    {
        private SampleData sampleData;
        public BlobEvaluationProcessor(string baseFolder, string encryptionKey)
        {
            this.sampleData = new SampleData(baseFolder);
        }
        /*
        public EvaluationResult<BlobFileData> PublicBlobUpload(IStorageContext context)
        {
            return BlobUpload(context, "public", false);
        }
        public EvaluationResult<BlobFileData> PublicBlobDownload(IStorageContext context)
        {
            return BlobDownload(context, "public",false);
        }
        public EvaluationResult<BlobFileData> PrivateBlobUpload(IStorageContext context)
        {
            return BlobUpload(context, "private", true);
        }
        public EvaluationResult<BlobFileData> PrivateBlobDownload(IStorageContext context)
        {
            return BlobDownload(context, "private",true);
        }
        public EvaluationResult<string> PrivateContainerSAS(IStorageContext context)
        {
            var result = new EvaluationResult<string>();
            try
            {
                var sas = context.GetSAS("private");
                result.Text = sas;
                result.Results.Add(sas);
            }
            catch (Exception ex)
            {
                result.Code = 2;
                result.Text = $"Encountered an error generating the SAS: {ex.Message}";
            }
            return result;
        }
*/


        #region Direct Blob methods
        public EvaluationResult<BlobFileData> BlobUpload(IStorageContext context, string container, bool isPrivate)
        {
            var result = new EvaluationResult<BlobFileData>();
            var data = sampleData.BlobData();
            try
            {
                foreach (var fileData in data)
                {
                    context.UploadFile( container, fileData, isPrivate);
                }
                result.Code = 0;
                result.Text = $"Upload test to {container} container completed successfully";
            }
            catch (Exception ex)
            {
                result.Code = 2;
                result.Text = $"An error occurred during upload to {container} container: {ex.Message}";

            }
            return result;
        }

        public EvaluationResult<BlobFileData> BlobDownload(IStorageContext context, string container, bool isPrivate)
        {
            var result = new EvaluationResult<BlobFileData>();
            try
            {
                result.Results = context.GetFileList(container, isPrivate);
                result.Code = result.Results.Count > 0 ? 0 : 1;
                result.Text = result.Results.Count > 0 ? $"Download test from the {container} container completed successfully" : $"No files were retrieved from the {container} container";
                //Verify access to the files.
                if (result.Results.Count > 0)
                {
                    try
                    {

                        var rqst = WebRequest.CreateHttp(result.Results[0].URL + result.Results[0].SAS);
                        var response = rqst.GetResponse();
                        using (var results = response.GetResponseStream())
                        {
                            using (var rdr = new BinaryReader(results))
                            {
                                var file = rdr.ReadBytes((int)response.ContentLength);
                            }
                        }
                    }
                    catch (Exception accessException)
                    {
                        result.Code = 2;
                        result.Text = $"Download from {container} container returned results, but there was an error downloading the files:\t{accessException.Message}";
                    }
                }
            }
            catch (Exception ex)
            {
                result.Code = 2;
                result.Text = $"An error occurred during dowload from {container} container: {ex.Message}";
            }
            return result;
        }

        public EvaluationResult<string> ContainerSAS(IStorageContext context, string containerName)
        {
            var result = new EvaluationResult<string>();
            try
            {
                var sas = context.GetSAS(containerName);
                result.Text = sas;
                result.Results.Add(sas);
            }
            catch (Exception ex)
            {
                result.Code = 2;
                result.Text = $"Encountered an error generating the SAS: {ex.Message}";
            }
            return result;
        }

        #endregion
    }

}