namespace labfiles.mysql
{
    public class CustomerLocation
    {
        public int customerNumber { get; set; }
        public string customerName { get; set; }
        public string state { get; set; }
        public string postalCode { get; set; }
    }

    public class ProductLine
    {
        public string productLine { get; set; }
        public string textDescription { get; set; }
        public string htmlDescription { get; set; }
    }
    class Settings
    {
        internal static string mysqlHost = "localhost";
        internal static string mysqlPort = "3309";
        internal static string mongoHost = "localhost";
        internal static string mongoPort = ",";
        internal static string user = "student";
        internal static string password = "Passw0rd!";
        internal static string database = "classicmodels";
        internal static string collection = "customerOrders";

    }

}