using System;
using System.IO;
using System.Text.Json;
using System.Threading.Tasks;

namespace labfiles.mysql
{
    class Program
    {
        private static async Task<int> Main(string[] args)
        {
            if ( args.Length < 1 || args.Length > 2 || !int.TryParse(args[0], out var i) || i < 1 || i > MySqlTest.NumberOfTests )
            {
                Console.WriteLine($@"To run this console application enter the following:
                \n\n dotnet run <test#>
                \n\n Where <test#> is between 1 and {MySqlTest.NumberOfTests}.");
                return 1;
            }

            var showDisplay = args.Length == 2 && args[1].Contains("verbose", StringComparison.OrdinalIgnoreCase);
                
            var testFile = new MySqlTest();
            
            // Test number arg starts at 1.
            var result = await testFile.RunTest(i - 1);
                
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

        internal static string SaveResults(string title, object data, bool prettify)
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