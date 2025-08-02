using HedgeDev.NeedleShaders.HE2.Compiler;
using SharpNeedle.Framework.HedgehogEngine.Needle.Shader;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using Vortice.Direct3D;

namespace HedgeDev.Shaders.HE2.Compiler
{
    public partial class ShaderCompiler
    {
#pragma warning disable CS8625 // Cannot convert null literal to non-nullable reference type.
        private static readonly ShaderMacro _nullMacro = new(null, null);
#pragma warning restore CS8625

        private readonly ShaderCompilerArguments _arguments;
        private readonly Action<string>? _log;
        private readonly bool _consoleOutput;
        private readonly ShaderMacro[] _baseMacros;
        private readonly HashSet<string> _baseMacroLUT;

        private static readonly Regex _shaderFeatureRegex = FeatureRegex();

        [GeneratedRegex(@"^ *static const uint FEATURE_([A-Za-z0-9_]*) *; *$", RegexOptions.Multiline)]
        private static partial Regex FeatureRegex();

        public ShaderCompiler(ShaderCompilerArguments arguments, bool consoleOutput, Action<string>? log)
        {
            _arguments = arguments.Clone();
            _baseMacros = GetBaseMacros();
            _baseMacroLUT = _baseMacros.Select(x => x.Name).ToHashSet();

            _log = log;
            _consoleOutput = consoleOutput;
        }

        private ShaderMacro[] GetBaseMacros()
        {
            List<ShaderMacro> baseMacros = [];

            if(!_arguments.NoShaderTypeMacros)
            {
                if(_arguments.ShaderProfile.StartsWith("vs_"))
                {
                    baseMacros.Add(new("IS_VERTEX_SHADER", string.Empty));
                    baseMacros.Add(new("SHADER_TYPE", "Vertex"));
                }
                else if(_arguments.ShaderProfile.StartsWith("ps_"))
                {
                    baseMacros.Add(new("IS_PIXEL_SHADER", string.Empty));
                    baseMacros.Add(new("SHADER_TYPE", "Pixel"));
                }
                else if(_arguments.ShaderProfile.StartsWith("cs_"))
                {
                    baseMacros.Add(new("IS_COMPUTE_SHADER", string.Empty));
                    baseMacros.Add(new("SHADER_TYPE", "Compute"));
                }
            }

            baseMacros.AddRange(_arguments.ExtraMacros);
            baseMacros.Add(_nullMacro);

            return baseMacros.ToArray();
        }

        private void Log()
        {
            _log?.Invoke(string.Empty);

            if(_consoleOutput)
            {
                Console.WriteLine();
            }
        }

        private void Log(string value)
        {
            _log?.Invoke(value);

            if(_consoleOutput)
            {
                Console.WriteLine(value);
            }
        }

        private void LogHeader(string text)
        {
            string print = Utils.GetStringHeader(text);
            _log?.Invoke(print);

            if(_consoleOutput)
            {
                Console.WriteLine(print);
            }
        }


        public Shader CompileFile(string file)
        {
            return Compile(File.ReadAllText(file), file);
        }

        public Shader Compile(string shaderCode, string sourceName)
        {
            string[] features = CollectFeatures(shaderCode, sourceName);
            ReadOnlyMemory<byte>[] permutations = CompilePermutations(shaderCode, sourceName, features);
            (ReadOnlyMemory<byte>[] variants, int[] variantMap) = GetVariants(permutations);
            Shader result = ComposeShader(sourceName, features, variants, variantMap);
            Log("Compiling finished!");
            return result;
        }


        private string[] CollectFeatures(string shaderCode, string sourceName)
        {
            LogHeader("1. Collecting features");

            string preprocessedShaderCode = D3DUtils.Preprocess(shaderCode, sourceName, _baseMacros, IncludeResolver.CreateForSource(sourceName));

            string[] features = _shaderFeatureRegex.Matches(preprocessedShaderCode).Select(x => x.Groups[1].Value).ToArray();

            if(features.Length == 0)
            {
                Log("No features found.");
            }
            else
            {
                Log($"Found {features.Length} features:");

                foreach(string feature in features)
                {
                    Log("- " + feature);
                }

            }

            Log();

            return features;
        }

        private ReadOnlyMemory<byte>[] CompilePermutations(string shaderCode, string sourceName, string[] features)
        {
            LogHeader("2. Compiling permutations");

            int permutationCount = (int)Math.Pow(2, features.Length);
            ReadOnlyMemory<byte>[] result = new ReadOnlyMemory<byte>[permutationCount];
            int compileFinishedCount = 0;

            int consoleTop = 0;
            if(_consoleOutput)
            {
                consoleTop = Console.GetCursorPosition().Top;
                Console.SetCursorPosition(0, consoleTop);
                Console.WriteLine($"0 of {permutationCount} permutations compiled");
            }

            HashSet<string> baseMacroLUT = _baseMacros.Select(x => x.Name).ToHashSet();

            int warningIndex = -1;
            ShaderMacro[]? warningMacros = null;
            string? outWarnings = null;

            int statusWidth = 0, statusRows = 0;

            if(_consoleOutput && features.Length > 0)
            {
                Console.WriteLine();

                statusWidth = int.Min(32, (int)Math.Pow(2, MathF.Ceiling((features.Length + 1) / 2f)));
                statusRows = permutationCount / statusWidth;

                Console.ForegroundColor = ConsoleColor.DarkGray;
                for(int i = 0; i < statusRows; i++)
                {
                    Console.WriteLine(new string('.', statusWidth));
                }

                Console.ResetColor();
            }


            void CompilePermutation(int index)
            {
                if(_consoleOutput && features.Length > 0)
                {
                    lock(baseMacroLUT) // just for locking
                    {
                        int row = index / statusWidth;
                        int column = index % statusWidth;
                        Console.SetCursorPosition(column, row + consoleTop + 2);
                        Console.ForegroundColor = ConsoleColor.Yellow;
                        Console.Write('▬');
                        Console.ResetColor();
                    }
                }

                List<ShaderMacro> macros = new(_baseMacros);

                for(int j = 0; j < features.Length; j++)
                {
                    string feature = features[j];

                    if((index & (1 << j)) == 0 || baseMacroLUT.Contains(feature))
                    {
                        continue;
                    }

                    macros.Insert(macros.Count - 1, new(features[j], j));
                }

                ReadOnlyMemory<byte> compiledShader;
                ShaderMacro[] compilerMacros = macros.ToArray();

                try
                {
                    string preprocessedShaderCode = D3DUtils.Preprocess(
                        shaderCode,
                        sourceName,
                        compilerMacros,
                        IncludeResolver.CreateForSource(sourceName)
                    );

                    preprocessedShaderCode = _shaderFeatureRegex.Replace(preprocessedShaderCode, string.Empty);

                    compiledShader = D3DUtils.Compile(
                        preprocessedShaderCode,
                        _arguments.EntryPoint,
                        sourceName,
                        _arguments.ShaderProfile,
                        out string? warnings,
                        _arguments.CompilerFlags
                    );

                    if(!_arguments.NoWarnings && warnings != null && (warningIndex == -1 || warningIndex > index))
                    {
                        lock(baseMacroLUT) // just using it to lock
                        {
                            warningIndex = index;
                            warningMacros = compilerMacros;
                            outWarnings = warnings;
                        }
                    }
                }
                catch(Exception exception)
                {
                    throw new CompilerException(index, "Compiling shader failed! " + MacroMessage(compilerMacros), exception);
                }


                lock(result)
                {
                    result[index] = compiledShader;
                    compileFinishedCount++;

                    if(_consoleOutput)
                    {
                        lock(baseMacroLUT) // just for locking
                        {
                            Console.SetCursorPosition(0, consoleTop);
                            Console.WriteLine($"{compileFinishedCount} of {permutationCount} permutations compiled");

                            if(features.Length > 0)
                            {
                                int row = index / statusWidth;
                                int column = index % statusWidth;
                                Console.SetCursorPosition(column, consoleTop + 2 + row);
                                Console.ForegroundColor = ConsoleColor.Green;
                                Console.Write('■');
                                Console.ResetColor();
                            }
                        }
                    }

                    _log?.Invoke($"Compiled permutation no. {index + 1}");
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

            if(_consoleOutput)
            {
                Console.SetCursorPosition(0, consoleTop + (features.Length > 0 ? 2 : 1) + statusRows);
            }
            Log();

            if(outWarnings != null)
            {
                LogHeader("2.1. HLSL Warnings");
                Log(MacroMessage(warningMacros!));
                Log(outWarnings);
            }

            return result;
        }

        private (ReadOnlyMemory<byte>[] variants, int[] map) GetVariants(ReadOnlyMemory<byte>[] compiledPermutations)
        {
            LogHeader("3. Comparing permutations");

            List<ReadOnlyMemory<byte>> variants = [];
            int[] map = new int[compiledPermutations.Length];

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

                map[i] = foundIndex;
            }

            Log($"Shader contains a total of {variants.Count} variants");
            Log();

            return (variants.ToArray(), map);
        }

        private Shader ComposeShader(string sourceName, string[] features, ReadOnlyMemory<byte>[] variants, int[] permutations)
        {
            LogHeader("4. Processing meta data");

            Shader output = new();

            if(!_arguments.NoBuildPath)
            {
                try
                {
                    output.BuildPath = Path.GetFullPath(sourceName);
                }
                catch
                {
                    output.BuildPath = string.Empty;
                }
            }

            output.Features.AddRange(features.Select(x => new Shader.Feature() { Name = x }));
            output.Variants.AddRange(variants.Select(ShaderByteCodeProcessor.ProcessShaderByteCode));
            output.Permutations.AddRange(permutations);

            if(_arguments.BuildV1)
            {
                foreach(ShaderVariant variant in output.Variants)
                {
                    variant.GlobalVariables.IncludeTerminator = true;
                }
            }

            Log();

            return output;
        }

        private static string MacroMessage(IEnumerable<ShaderMacro> macros)
        {
            string result = string.Empty;

            foreach(ShaderMacro item in macros)
            {
                if(!string.IsNullOrEmpty(item.Name))
                {
                    if(string.IsNullOrEmpty(item.Definition))
                    {
                        result += $"  {item.Name}\n";
                    }
                    else
                    {
                        result += $"  {item.Name}={item.Definition}\n";
                    }
                }
            }

            if(string.IsNullOrEmpty(result))
            {
                result = "No macros used";
            }
            else
            {
                result = "\nMacros used:\n" + result[..^1] + "\n";
            }

            return result;
        }
    }
}
