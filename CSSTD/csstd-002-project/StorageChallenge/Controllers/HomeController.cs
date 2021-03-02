using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using System.Configuration;

namespace CSSTDSolution.Controllers
{
    public class HomeController : Controller
    {
        public HomeController() : base()
        {
            var testType = int.Parse(ConfigurationManager.AppSettings["TestType"]);
            var advanced = (testType < 255) && ((testType == 3) || (testType == 12) || (testType > 32));
            //For testing
            ViewBag.TestType = testType;
            ViewBag.Advanced = advanced;
            if (advanced)
            {
                ViewBag.StorageAccountConnectionString = ConfigurationManager.AppSettings["StorageAccountConnectionString"];
                ViewBag.SQLConnection = ConfigurationManager.AppSettings["SQLConnection"];
                ViewBag.MySQLConnection = ConfigurationManager.AppSettings["MySQLConnection"];
                ViewBag.CosmosDBSQLUri = ConfigurationManager.AppSettings["CosmosDBSQLUri"];
                ViewBag.CosmosDBSQLKey = ConfigurationManager.AppSettings["CosmosDBSQLKey"];
                ViewBag.CosmosDBTableAccount = ConfigurationManager.AppSettings["CosmosDBTableAccount"];
                ViewBag.CosmosDBTableKey = ConfigurationManager.AppSettings["CosmosDBTableKey"];

            }
        }
        public ActionResult Index()
        {
            return View();
        }

        public ActionResult Storage()
        {
            return View();
        }
        public ActionResult Relational()
        {
            return View();
        }
        public ActionResult NoSQL()
        {
            return View();
        }


    }
}