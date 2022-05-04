using System;
using System.IO;
using System.Text.Json;

namespace labfiles.mongo
{
    internal class Program
    {
        private static int Main(string[] args)
        {
            if ( args.Length < 1 || args.Length > 2 || !int.TryParse(args[0], out var i) || i < 1 || i > TestMongo.NumberOfTests )
            {
                Console.WriteLine(@"To run this console application enter the following:
                \n\n dotnet run <test#>
                \n\n Where <test#> is between 1 and 5.");
                return 1;
            }

            var showDisplay = args.Length == 2 && args[1].Contains("verbose", StringComparison.OrdinalIgnoreCase);
                
            var testMongo = new TestMongo();
            
            // Test number arg starts at 1.
            var result = TestMongo.RunTest(i - 1);
                
            var fileName = SaveResults(result.title, result.data, true);

            if (showDisplay) {
                Console.WriteLine(result.message);

                if (fileName != null)
                {
                    Console.WriteLine($"You can view the results in the file {fileName}.");
                }
            }

            // Flip "success" to represent an exit code.
            return result.success ? 0 : 1;
        }

        private static string SaveResults(string title, object data, bool prettify)
        {
            if ( data == null ) return null;
            
            string output;
            try
            {
                output = JsonSerializer.Serialize(data,
                    options: new JsonSerializerOptions { WriteIndented = prettify });
            }
            catch
            {
                output = "There was an error deserializing your data."; 
            }
            
            var fileName = $"D:\\labfiles\\{title}.json";
            
            File.WriteAllText(fileName, output);
            
            return fileName;
        }
    }
}