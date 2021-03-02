using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace CSSTDEvaluation
{
    public class EvaluationResult<T>
    {
        public EvaluationResult()
        {
            Results = new List<T>();
        }
            
        public int Code { get; set; }
        public string Text { get; set; }
        public List<T> Results { get; set; }
        public string Encrypted { get; set; }
    }
}