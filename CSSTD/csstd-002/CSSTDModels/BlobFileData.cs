using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Web;

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