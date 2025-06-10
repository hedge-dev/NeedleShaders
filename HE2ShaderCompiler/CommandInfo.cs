using SharpNeedle.Framework.HedgehogEngine.Needle.Shader;
using SharpNeedle.Framework.HedgehogEngine.Needle.Shader.Variable;
using SharpNeedle.Resource;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HedgeDev.Shaders.HE2.Compiler
{
    internal static class CommandInfo
    {
        private static int _indentationLevel = 0;
        private static string _indentation = " ";

        private static int IndentationLevel
        {
            get => _indentationLevel;
            set
            {
                _indentationLevel = value;
                _indentation = new(' ', value * 2 + 1);
            }
        }

        private static void WriteIndented()
        {
            Console.Write(_indentation);
        }

        private static void WriteLine(string text)
        {
            Console.Write(_indentation);
            Console.WriteLine(text);
        }

        private static void WriteLine()
        {
            Console.WriteLine();
        }


        public static void Run(string[] args)
        {
            string file = args[1];

            if(!File.Exists(file))
            {
                throw new ArgumentException($"The file \"{file}\" does not exist!");
            }

            int columns = 0;
            int variantGlobals = -1;

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
                    case "pm":
                        columns = 8;
                        break;
                    case "pmc":
                        i++;

                        if(i >= args.Length)
                        {
                            throw new ArgumentException("Missing columns parameter for argument -pmc");
                        }
                        else if(!int.TryParse(args[i], out columns))
                        {
                            throw new ArgumentException("Option -pmc has to be followed by a number");
                        }

                        break;
                    case "gv":
                        i++;

                        if(i >= args.Length)
                        {
                            throw new ArgumentException("Missing index parameter for argument -gv");
                        }
                        else if(!int.TryParse(args[i], out variantGlobals))
                        {
                            throw new ArgumentException("Option -gv has to be followed by a number");
                        }

                        break;
                    default:
                        WriteLine($"Unknown argument \"{rawArg}\", ignoring...");
                        break;
                }
            }

            Shader shader = ResourceManager.Instance.Open<Shader>(file);

            PrintHeader(shader);

            if(columns > 0)
            {
                PrintPermutations(shader, columns);
            }

            if(variantGlobals >= 0)
            {
                PrintVariantGlobals(shader, variantGlobals);
            }
        }

        private static void PrintHeader(Shader shader)
        {
            WriteLine(" ====== Shader Info ======");
            WriteLine();
            IndentationLevel++;

            WriteLine($"Name: {shader.Name}");
            WriteLine($"Build Path: {shader.BuildPath}");
            WriteLine($"Unknown info: {shader.Unknown}");
            WriteLine($"Feature count: {shader.Features.Count}");
            WriteLine($"Permutation count: {shader.Permutations.Count}");
            WriteLine($"Variant count: {shader.Variants.Count}");
            WriteLine();


            if(shader.Features.Count > 0)
            {
                WriteLine("===== Features =====");
                WriteLine();

                int featureLength = shader.Features.Max(x => x.Name.Length);
                string legend = $" Id | {"Name".PadRight(featureLength)} | Unknown ";

                WriteLine(legend);
                WriteLine(new string('-', legend.Length));

                for(int i = 0; i < shader.Features.Count; i++)
                {
                    Shader.Feature feature = shader.Features[i];
                    WriteLine($" {i,2} | {feature.Name.PadRight(featureLength)} | {feature.Unknown} ");
                }

                WriteLine();
            }

        }

        private static void PrintPermutations(Shader shader, int columns)
        {
            WriteLine("===== Permutation Map =====");
            WriteLine();

            for(int i = 0; i < shader.Features.Count; i++)
            {
                Shader.Feature permutation = shader.Features[i];
                WriteLine($"{NumberToBitDisplay(1 << i, shader.Features.Count)} = {permutation.Name}");
            }

            WriteLine();

            int rows = shader.Permutations.Count / columns;

            for(int r = 0; r < rows; r++)
            {
                WriteIndented();

                for(int c = 0; c < columns; c++)
                {
                    int index = (c * rows) + r;
                    Console.Write($"{NumberToBitDisplay(index, shader.Features.Count)} {shader.Permutations[index],3}");

                    if(c < columns - 1)
                    {
                        Console.Write(" | ");
                    }
                }

                Console.WriteLine();
            }

            WriteLine();
        }

        private static string NumberToBitDisplay(int number, int numSize)
        {
            const char whenTrueS = '▬';
            const char whenTrueL = '■';
            const char whenFalseS = '.';
            const char whenFalseL = ':';

            string raw = number.ToString("b" + numSize).Replace('0', whenFalseS).Replace('1', whenTrueS);
            StringBuilder builder = new(raw);

            for(int i = 4; i <= numSize; i += 4)
            {
                if(builder[^i] == whenFalseS)
                {
                    builder[^i] = whenFalseL;
                }
                else if(builder[^i] == whenTrueS)
                {
                    builder[^i] = whenTrueL;
                }
            }

            return builder.ToString();
        }

        private enum FieldType
        {
            Float,
            Integer,
            Boolean,
        }

        private static void PrintVariantGlobals(Shader shader, int index)
        {
            if(index >= shader.Variants.Count)
            {
                WriteLine($"Invalid variant index {index}! Has to be between 0 and {shader.Variants.Count - 1} for this shader");
                return;
            }

            WriteLine($"===== Global Variables {index} ===== ");
            WriteLine();
            IndentationLevel++;

            ShaderGlobalVariables variables = shader.Variants[index].GlobalVariables;
            
            if(variables.ConstantBuffers.Count > 0)
            {
                WriteLine("==== Constant Buffers ==== ");
                WriteLine();
                IndentationLevel++;

                bool first = true;

                foreach(ConstantBuffer constantBuffer in variables.ConstantBuffers.OrderBy(x => x.ID))
                {
                    if(!first)
                    {
                        WriteLine(new string('=', 50));
                        WriteLine();
                    }
                    first = false;

                    List<(ConstantBufferField field, FieldType type)> fields = [
                        ..variables.CBFloats.Where(x => x.ConstantBufferIndex == constantBuffer.ID).Select(x => (x, FieldType.Float)),
                        ..variables.CBIntegers.Where(x => x.ConstantBufferIndex == constantBuffer.ID).Select(x => (x, FieldType.Integer)),
                        ..variables.CBBooleans.Where(x => x.ConstantBufferIndex == constantBuffer.ID).Select(x => (x, FieldType.Boolean)),
                    ];

                    WriteLine($"Name: {constantBuffer.Name}");
                    WriteLine($"ID: {constantBuffer.ID}");
                    WriteLine($"Size: {constantBuffer.Size}");
                    WriteLine($"Unknown: {constantBuffer.Unknown1}");
                    WriteLine($"Field count: {fields.Count}");
                    WriteLine();

                    int nameLength = fields.Max(x => x.field.Name.Length);
                    string legend = $" Offset | Size   | Type    | {"Name".PadRight(nameLength)} | Unknown ";
                    WriteLine(legend);
                    WriteLine(new string('-', legend.Length));

                    foreach((ConstantBufferField field, FieldType type) in fields.OrderBy(x => x.field.Offset))
                    {
                        WriteLine($" {field.Offset,6} | {field.Size, 6} | {type, 7} | {field.Name.PadRight(nameLength)} | {field.Unknown1}");
                    }

                    WriteLine();
                }

                IndentationLevel--;
            }

            if(variables.Samplers.Count > 0)
            {
                WriteLine("==== Samplers ==== ");
                WriteLine();

                int nameLength = variables.Samplers.Max(x => x.Name.Length);
                string legend = $" ID | {"Name".PadRight(nameLength)} | Unknown ";
                WriteLine(legend);
                WriteLine(new string('-', legend.Length));

                foreach(Sampler sampler in variables.Samplers.OrderBy(x => x.ID))
                {
                    WriteLine($" {sampler.ID,2} | {sampler.Name.PadRight(nameLength)} | {sampler.Unknown1}");
                }

                WriteLine();
            }

            if(variables.Textures.Count > 0)
            {
                WriteLine("==== Textures ==== ");
                WriteLine();

                int nameLength = variables.Textures.Max(x => x.Name.Length);
                string legend = $" ID | {"Name".PadRight(nameLength)} | Type ";
                WriteLine(legend);
                WriteLine(new string('-', legend.Length));

                foreach(Texture texture in variables.Textures.OrderBy(x => x.ID))
                {
                    WriteLine($" {texture.ID,2} | {texture.Name.PadRight(nameLength)} | {texture.Type}");
                }

                WriteLine();
            }

            if(variables.ComputeBuffers.Count > 0)
            {
                WriteLine("==== Compute Buffers ==== ");
                WriteLine();

                int nameLength = variables.ComputeBuffers.Max(x => x.Name.Length);
                string legend = $" ID | {"Name".PadRight(nameLength)} | Unknown ";
                WriteLine(legend);
                WriteLine(new string('-', legend.Length));

                foreach(ComputeBuffer computeBuffer in variables.ComputeBuffers.OrderBy(x => x.ID))
                {
                    WriteLine($" {computeBuffer.ID,2} | {computeBuffer.Name.PadRight(nameLength)} | {computeBuffer.Unknown1}");
                }

                WriteLine();
            }

            IndentationLevel--;
        }
    }
}
