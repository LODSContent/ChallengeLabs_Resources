using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CSSTDModels
{
    public interface ICosmosDBTableContext
    {
        string ConnectionString { get; set; }
        void CreateTable(string tableName);
        List<IProductMention> GetMentions(string tableName);
        List<IProductMention> GetMentions(string product, string platform, string tableName);
        void LoadMentions(List<IProductMention> mentions, string tableName);

    }
}
