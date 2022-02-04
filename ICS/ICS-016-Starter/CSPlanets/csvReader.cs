using System;
using Microsoft.VisualBasic.FileIO;

namespace CSPlanets
{
    class CsvReader {
        public static void FillArrays(string[,] thePlanetsStringData, int[] thePlanetsIntegerData, decimal[,] thePlanetsDecimalData ) {
            string path = @"D:\labfiles\ArrayDataFiller\ICS-016 Data.csv";
            string[] theFields = new string[8];

            using (TextFieldParser csvParser = new TextFieldParser(path))
            {
                csvParser.SetDelimiters(new string[] { "," });
                while (!csvParser.EndOfData)
                {
                    for (int i = 0; i < 8; i++)
                    {
                        theFields = csvParser.ReadFields();
                        thePlanetsStringData[i, 0] = theFields[0];
                        thePlanetsDecimalData[i, 0] = decimal.Parse(theFields[1]);
                        thePlanetsDecimalData[i, 1] = decimal.Parse(theFields[2]);
                        thePlanetsDecimalData[i, 2] = decimal.Parse(theFields[3]);
                        thePlanetsIntegerData[i] = Int16.Parse(theFields[4]);
                        thePlanetsStringData[i, 1] = theFields[5];
                        thePlanetsDecimalData[i, 3] = decimal.Parse(theFields[6]);

                        //woohoo - full arrays!!
                        //Console.WriteLine(thePlanetsStringData[i, 0] + " " + thePlanetsDecimalData[i, 0] + " " + thePlanetsDecimalData[i, 1] + " " + thePlanetsDecimalData[i, 2] + " " + thePlanetsIntegerData[i] + " " + thePlanetsStringData[i, 1] + " " + thePlanetsDecimalData[i, 3]);
                    }
                   // Console.ReadKey(true);
                }
            }
            
        }

    }
}
