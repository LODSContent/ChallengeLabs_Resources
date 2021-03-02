using System.ComponentModel;

namespace CSSTDModels
{
    public interface IProductMention
    {
        [Description("Arbitrary ID for the mention.  Tied to RowKey value")]
        string MentionID { get; set; }

        [Description("Name of the product")]
        string Product { get; set; }

        [Description("Social media platform")]
        string Platform { get; set; }

        [Description("Date of the mention stored as a string")]
        string MentionedAt { get; set; }

        [Description("Content of mention")]
        string Mention { get; set; }
    }
}
