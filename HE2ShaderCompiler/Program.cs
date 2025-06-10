using System.Diagnostics;
using System.Reflection;

namespace HedgeDev.Shaders.HE2.Compiler
{
    internal class Program
    {
        static void Main(string[] args)
        {
            if(args.Length == 0 || args[0].ToLower() is "help" or "--help" or "?" or "-?" or "-help" or "--h" or "-h")
            {
                PrintHelp("cmdhelp.txt");
                return;
            }

            string command = args[0].ToLower();

            if(args.Length == 1 || args[1].ToLower() is "help" or "--help" or "?" or "-?" or "-help" or "--h" or "-h")
            {
                try
                {
                    PrintHelp($"cmdhelp_{command}.txt");
                }
                catch
                {
                    PrintHelp("cmdhelp.txt");
                }

                return;
            }

            try
            {
                switch(command)
                {
                    case "compile":
                        CommandCompile.Run(args);
                        break;
                    case "dump":
                        CommandDump.Run(args);
                        break;
                    case "info":
                        CommandInfo.Run(args);
                        break;
                    default:
                        Console.WriteLine($"Unknown command {args[0]}.");
                        return;
                }
            }
            catch(Exception exception)
            {
                Console.WriteLine($"A(n) {exception.GetType().Name} exception occured:");
                Console.WriteLine(exception.Message);
            }
        }

        private static void PrintHelp(string name)
        {
            Assembly assembly = Assembly.GetExecutingAssembly();
            FileVersionInfo fvi = FileVersionInfo.GetVersionInfo(assembly.Location);

            string resourceName = "HedgeDev.Shaders.HE2.Compiler." + name;
            string print;
            using(Stream stream = assembly.GetManifestResourceStream(resourceName) ?? throw new NullReferenceException())
            {
                print = new StreamReader(stream).ReadToEnd();
            }

            Console.WriteLine("Hedgehog Engine 2 Shader Compiler @Hedge-Dev");
            Console.WriteLine("Version " + fvi.FileVersion);
            Console.WriteLine(print);
        }
    }
}
