using HedgeDev.Shaders.HE2.Compiler;
using SharpGen.Runtime;
using SharpNeedle.Framework.HedgehogEngine.Needle.Shader;
using SharpNeedle.Resource;
using System.Text.RegularExpressions;
using Vortice.Direct3D;

namespace HedgeDev.NeedleShaders.HE2.Compiler
{
    internal static partial class CommandCompile
    {
#pragma warning disable CS8625 // Cannot convert null literal to non-nullable reference type.
        private static readonly ShaderMacro _nullMacro = new(null, null);
#pragma warning restore CS8625

        public static void Run(string[] args)
        {
            string file = args[1];
            
            if(!File.Exists(file))
            {
                throw new ArgumentException($"The file \"{file}\" does not exist!");
            }

            CompileArguments compilerArgs = CompileArguments.ParseCompilerArguments(file, args);

            ShaderMacro[]? baseMacros = null;
            HashSet<string> baseMacroLUT = [];
            
            if(compilerArgs.ExtraMacros.Count > 0)
            {
                baseMacros = new ShaderMacro[compilerArgs.ExtraMacros.Count + 1];

                for(int i = 0; i < compilerArgs.ExtraMacros.Count; i++)
                {
                    baseMacros[i] = compilerArgs.ExtraMacros[i];
                    baseMacroLUT.Add(baseMacros[i].Name);
                }

                baseMacros[^1] = _nullMacro;
            }

            string shaderCode = File.ReadAllText(file);
            string preprocessedShaderCode = D3D11Extensions.Preprocess(shaderCode, file, baseMacros, new IncludeResolver(file));

            string[] features = FeatureRegex().Matches(preprocessedShaderCode).Select(x => x.Groups[1].Value).ToArray();

            if(features.Length == 0)
            {
                Console.WriteLine("No features found.");
                Console.WriteLine();
            }
            else
            {
                Console.WriteLine($"Found {features.Length} features:");
                
                foreach(string feature in features)
                {
                    Console.WriteLine("- " + feature);
                }

                Console.WriteLine();
            }

            int permutationCount = (int)Math.Pow(2, features.Length);
            ReadOnlyMemory<byte>[] compiledPermutations = new ReadOnlyMemory<byte>[permutationCount];
            int compileFinishedCount = 0;
            (int left, int top) = Console.GetCursorPosition();

            void CompilePermutation(int index)
            {
                List<ShaderMacro> macros = [];
                macros.AddRange(compilerArgs.ExtraMacros);

                for(int j = 0; j < features.Length; j++)
                {
                    string feature = features[j];

                    if((index & (1 << j)) == 0 || baseMacroLUT.Contains(feature))
                    {
                        continue;
                    }

                    macros.Add(new(features[j], j));
                }

                macros.Add(_nullMacro);
                ReadOnlyMemory<byte> compiledShader;

                try
                {

                    compiledShader = Vortice.D3DCompiler.Compiler.Compile(
                        shaderCode,
                        macros.ToArray(),
                        new IncludeResolver(file),
                        compilerArgs.EntryPoint,
                        file,
                        compilerArgs.ShaderProfile,
                        compilerArgs.CompilerFlags
                    );
                }
                catch(Exception exception)
                {
                    string macroMessage = string.Empty;

                    foreach(ShaderMacro item in macros)
                    {
                        if(!string.IsNullOrEmpty(item.Name))
                        {
                            macroMessage += $"  {item.Name}={item.Definition}\n";
                        }
                    }

                    if(string.IsNullOrEmpty(macroMessage))
                    {
                        macroMessage = "No macros used";
                    }
                    else
                    {
                        macroMessage = "\nMacros used:\n" + macroMessage[..^1];
                    }

                    throw new CompilerException(index, "Compiling shader failed! " + macroMessage, exception);
                }


                lock(compiledPermutations)
                {
                    compiledPermutations[index] = compiledShader;
                    compileFinishedCount++;
                    Console.SetCursorPosition(left, top);
                    Console.WriteLine($"Compiling permutations... ({compileFinishedCount}/{permutationCount})");
                }
            }
            
            try
            {
                Parallel.For(0, permutationCount, CompilePermutation);
            }
            catch(AggregateException aggrexc)
            {
                CompilerException throwException = (CompilerException)aggrexc.InnerExceptions[0];
                for(int i = 1; i < aggrexc.InnerExceptions.Count; i++)
                {
                    CompilerException next = (CompilerException)aggrexc.InnerExceptions[i];
                    if(next.PermutationIndex < throwException.PermutationIndex)
                    {
                        throwException = next;
                    }
                }

                throw throwException;
            }

            Console.WriteLine();
            Console.WriteLine("Comparing permutations...");

            List<ReadOnlyMemory<byte>> variants = [];
            int[] permutations = new int[(int)Math.Pow(2, features.Length)];

            for(int i = 0; i < compiledPermutations.Length; i++)
            {
                ReadOnlySpan<byte> span = compiledPermutations[i].Span;

                int foundIndex = -1;
                for(int j = 0; j < variants.Count; j++)
                {
                    if(variants[j].Span.SequenceEqual(span))
                    {
                        foundIndex = j;
                        break;
                    }
                }

                if(foundIndex == -1)
                {
                    foundIndex = variants.Count;
                    variants.Add(compiledPermutations[i]);
                }

                permutations[i] = foundIndex;
            }

            Console.WriteLine($"Shader contains a total of {variants.Count} variants");
            Console.WriteLine();

            Shader output = new();

            if(!compilerArgs.NoBuildPath)
            {
                output.BuildPath = file;
            }

            Console.WriteLine("Processing meta data");
            Console.WriteLine();
            output.Features.AddRange(features.Select(x => new Shader.Feature() { Name = x }));
            output.Variants.AddRange(variants.Select(ShaderByteCodeProcessor.ProcessShaderByteCode));
            output.Permutations.AddRange(permutations);

            if(compilerArgs.BuildV1)
            {
                foreach(ShaderVariant variant in output.Variants)
                {
                    variant.GlobalVariables.IncludeTerminator = true;
                }
            }

            Console.WriteLine("Compiling finished!");
            Console.WriteLine();
            output.Write(Path.Combine(compilerArgs.OutputDirectory, compilerArgs.OutputFile));
        }

        [GeneratedRegex("static const uint FEATURE_([A-Za-z0-9_]*) ;")]
        private static partial Regex FeatureRegex();
    }
}
