using Amicitia.IO.Binary;
using Amicitia.IO.Streams;
using SharpGen.Runtime;
using SharpNeedle.Framework.HedgehogEngine.Needle.Shader;
using SharpNeedle.Framework.SonicTeam;
using SharpNeedle.Utilities;
using Vortice.Win32;

namespace HedgeDev.NeedleShaders.HE2.Compiler
{
    internal static class CommandExtract
    {
        public static void Run(string[] args)
        {
            string file = args[1];

            if(!File.Exists(file))
            {
                throw new ArgumentException($"The file \"{file}\" does not exist!");
            }

            string outputDirectory = args[2];

            if(!Directory.Exists(outputDirectory))
            {
                throw new ArgumentException($"The directory \"{outputDirectory}\" does not exist!");
            }

            bool nodump = false;
            bool fullname = false;

            for(int i = 3; i < args.Length; i++)
            {
                string rawArg = args[i];
                if(!rawArg.StartsWith('-'))
                {
                    throw new ArgumentException($"Invalid argument \"{rawArg}\"! (All arguments must start with a dash)");
                }

                string arg = rawArg[1..].ToLower();

                switch(arg)
                {
                    case "nodump":
                        nodump = true;
                        break;
                    case "fullname":
                        fullname = true;
                        break;
                    default:
                        Console.WriteLine($"Unknown argument \"{rawArg}\", ignoring...");
                        break;
                }
            }

            if(string.IsNullOrWhiteSpace(outputDirectory))
            {
                throw new ArgumentException("Missing -odir option!");
            }

            using FileStream stream = File.OpenRead(file);
            using BinaryObjectReader reader = new(stream, StreamOwnership.Retain, Endianness.Little);

            const ulong hhneedle = 0x454C4445454E4848u;
            int shaderIndex = 0;

            Console.WriteLine($" Address  |   Size   | Type | Name ");
            Console.WriteLine($"----------+----------+------+----------------------------------");

            while(reader.Position < reader.Length)
            {
                long position = reader.Position;
                SeekToken start = reader.At();

                if(reader.ReadUInt64() != hhneedle)
                {
                    continue;
                }

                SeekToken resumeStart = reader.At();
                uint length = reader.ReadBig<uint>();
                if(length == 0)
                {
                    resumeStart.Dispose();
                    continue;
                }

                string fullShaderPath = reader.ReadString(StringBinaryFormat.NullTerminated);
                string filename;
                string shaderName;
                string shaderType;

                if(!string.IsNullOrWhiteSpace(fullShaderPath))
                {
                    filename = Path.GetFileName(fullShaderPath);
                    shaderName = fullname
                        ? fullShaderPath
                        : Path.GetFileNameWithoutExtension(filename);
                    shaderType = Path.GetExtension(filename)[1..];
                }
                else
                {
                    filename = $"embedded_shader_{shaderIndex}.bin";
                    shaderName = "???";
                    shaderType = "???";
                }

                
                Console.WriteLine($" {position:X8} | {length,8} | {shaderType,-4} | {shaderName} ");
                shaderIndex++;

                if(!nodump)
                {
                    start.Dispose();
                    byte[] shader = reader.ReadArray<byte>((int)length + 8);

                    if(shaderType == "ncs")
                    {
                        filename = Path.ChangeExtension(filename, ".cso");
                    }
                    else if(shaderType == "???")
                    {
                        filename += ".bin";
                    }
                    else if(shaderType is "ps" or "vs" or "cs")
                    {
                        filename += 'o';
                    }

                    string outputPath = Path.Combine(outputDirectory, filename);
                    File.WriteAllBytes(outputPath, shader);
                }


                start.Dispose();
                reader.Seek(length + 8, SeekOrigin.Current);
                reader.Align(8);
            }
        }
    }
}
