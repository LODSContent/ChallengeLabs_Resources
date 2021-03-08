using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;

namespace CSSTDModels
{

    [Description("Simple class representing basic vendor data for an Azure database for MySQL")]
    public class VendorData
    {
        [Description("Arbitrary primary key")]
        [Key]
        public int ID { get; set; }

        [Description("Vendor name")]
        public string Name { get; set; }

        [Description("Industry designation, currently 'Training' or 'Swimming'")]
        public string Industry { get; set; }
    }
}