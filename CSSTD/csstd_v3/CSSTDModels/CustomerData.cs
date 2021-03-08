using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;

namespace CSSTDModels
{

    [Description("Simple class representing basic customer data for an Azure SQL database")]
    public class CustomerData
    {
        [Description("Arbitrary primary key")]
        [Key]
        public int ID { get; set; }

        [Description("Customer name")]
        public string Name { get; set; }

        [Description("Customer postal/zip code")]
        public string PostalCode { get; set; }
    }
}