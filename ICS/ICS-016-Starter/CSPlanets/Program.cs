using System;

namespace CSPlanets
{
    class Program
    {
        static void Main(string[] args)
        {
            var tasks = new MyTasks();
            string test = args[0];
            switch (test)
            {
                case "3":
                    tasks.Requirement3();
                    break;
                case "4":
                    tasks.Requirement4();
                    break;
                case "5":
                    tasks.Requirement5();
                    break;
                case "6":
                    tasks.Requirement6();
                    break;
            }
        }
    }
}
