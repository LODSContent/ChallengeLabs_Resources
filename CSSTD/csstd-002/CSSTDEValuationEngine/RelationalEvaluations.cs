using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using CSSTDModels;
using System.Data.SqlClient;

namespace CSSTDEvaluation
{
    public class RelationalEvaluationProcessor
    {
        private SampleData sampleData;
        public RelationalEvaluationProcessor(string baseFolder, string encryptionKey)
        {
            sampleData = new SampleData(baseFolder);
        }
        public RelationalEvaluationProcessor() { }
 
        public EvaluationResult<CustomerData> SQLServerUpload(ISQLServerContext context, string tableName)
        {
            var result = new EvaluationResult<CustomerData>();
            try
            {
                var sample = sampleData.CustomerData();
                context.CreateTable(tableName);
                context.LoadData( sample, tableName);
                int recCount = testCountSQL(context.ConnectionString);
                result.Code = recCount == sample.Count ? 0 : 1;
                result.Text = result.Code == 0 ? "Successfully uploaded customer data to SQL Server" : (recCount > -1 ? $"No errors were encountered during upload but the database record count is {recCount} and the sample record count is {sample.Count}" : "The upload did not return an error, but there was an error retrieving the SQL Server record count.");
            }
            catch (Exception ex)
            {
                result.Code = 2;
                result.Text = $"Error loading customer data to SQL Server: {ex.Message}";
            }
            return result;
        }

        private int testCountSQL(string connectionString)
        {
            var SQL = "SELECT COUNT(*) FROM dbo.customers;";
            int result = -1;
            try
            {
                using (var connection = new SqlConnection(connectionString))
                {
                    var cmd = new SqlCommand(SQL, connection);
                    connection.Open();
                    result = (int)cmd.ExecuteScalar();
                    connection.Close();
                }
            } catch
            {
                result = -1;
            }
            return result;

        }

        public EvaluationResult<CustomerData> SQLServerDownload(ISQLServerContext context, string tableName)
        {
            var result = new EvaluationResult<CustomerData>();
            try
            {
                int recCount = testCountSQL(context.ConnectionString);
                result.Results = context.GetData(tableName);
                result.Code = result.Results.Count > 0 ? 0 : 1;
                result.Text = result.Results.Count>0 ? "Successfully downloaded customer data" : "There was no customer data downloaded.";
            }
            catch (Exception ex)
            {
                result.Code = 2;
                result.Text = $"Error loading data: {ex.Message}";
            }
            return result;
        }

        public EvaluationResult<VendorData> MySQLUpload(IMySQLContext context, string tableName)
        {
            var result = new EvaluationResult<VendorData>();
            try
            {
                context.CreateTable(tableName);
                context.LoadData(sampleData.VendorData(), tableName);
                result.Text = "Successfully uploaded vendor data to MySQL";
                result.Code = 0;
            }
            catch (Exception ex)
            {
                result.Code = 2;
                result.Text = $"Error loading vendor data to MySQL: {ex.Message}";
            }
            return result;
        }

        public EvaluationResult<VendorData> MySQLDownload(IMySQLContext context, string tableName)
        {
            var result = new EvaluationResult<VendorData>();
            try
            {
                result.Results = context.GetData(tableName);
                result.Code = result.Results.Count > 0 ? 0 : 1;
                result.Text = result.Results.Count > 0 ? "Successfully downloaded vendor data" : "There was no vendor data downloaded.";
            }
            catch (Exception ex)
            {
                result.Code = 2;
                result.Text = $"Error loading data: {ex.Message}";
            }
            return result;
        }
    }

}