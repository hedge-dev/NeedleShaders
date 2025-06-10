using SharpNeedle.Framework.HedgehogEngine.Needle.Shader;
using SharpNeedle.Resource;

namespace HedgeDev.Shaders.HE2.Compiler
{
    internal static class CommandDump
    {
        public static void Run(string[] args)
        {
            string file = args[1];

            if(!File.Exists(file))
            {
                throw new ArgumentException($"The file \"{file}\" does not exist!");
            }

            string outputDirectory = Path.GetDirectoryName(file)!;
            bool all = false;
            int index = -1;
            bool dumpBin = false;
            bool dumpAsm = true;

            for(int i = 2; i < args.Length; i++)
            {
                string rawArg = args[i];
                if(!rawArg.StartsWith('-'))
                {
                    throw new ArgumentException($"Invalid argument \"{rawArg}\"! (All arguments must start with a dash)");
                }

                string arg = rawArg[1..].ToLower();

                switch(arg)
                {
                    case "odir":
                        i++;

                        if(i >= args.Length)
                        {
                            throw new ArgumentException("Missing path parameter for argument -od");
                        }

                        outputDirectory = args[i];

                        break;
                    case "i":
                        i++;

                        if(i >= args.Length)
                        {
                            throw new ArgumentException("Missing index parameter for argument -i");
                        }
                        else if(!int.TryParse(args[i], out index))
                        {
                            throw new ArgumentException("Option -i has to be followed by a number");
                        }

                        break;
                    case "all":
                        all = true;
                        break;
                    case "bin":
                        dumpBin = true;
                        break;
                    case "noasm":
                        dumpAsm = false;
                        break;
                    default:
                        Console.WriteLine($"Unknown argument \"{rawArg}\", ignoring...");
                        break;
                }
            }
        
            if(index == -1 && !all)
            {
                throw new ArgumentException("Must provide either -all or -i option!");
            }

            Shader shader = ResourceManager.Instance.Open<Shader>(file);

            void DumpBinary(int variantIndex)
            {
                string path = Path.Combine(outputDirectory, $"{shader.Name}_{variantIndex}");
                byte[] byteCode = shader.Variants[variantIndex].ShaderByteCode;

                if(dumpBin)
                {
                    File.WriteAllBytes(path + ".bin", byteCode);
                }

                if(dumpAsm)
                {
                    string asm = D3D11Extensions.Disassemble(byteCode);
                    File.WriteAllText(path + ".txt", asm);
                }
            }

            if(all)
            {
                for(int i = 0; i < shader.Variants.Count; i++)
                {
                    DumpBinary(i);
                }
            }
            else
            {
                DumpBinary(index);
            }

        }
    }
}
