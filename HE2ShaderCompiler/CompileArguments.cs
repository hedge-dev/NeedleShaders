using HedgeDev.Shaders.HE2.Compiler;
using System.Collections.ObjectModel;
using Vortice.D3DCompiler;

namespace HedgeDev.NeedleShaders.HE2.Compiler
{
    internal class CompileArguments
    {
        private static readonly ReadOnlyDictionary<string, ShaderFlags> _shaderFlagArgumentMap = new(new Dictionary<string, ShaderFlags>()
        {
            { "od", ShaderFlags.SkipOptimization },
            { "op", ShaderFlags.NoPreshader },
            { "o0", ShaderFlags.OptimizationLevel0 },
            { "o1", ShaderFlags.OptimizationLevel1 },
            { "o2", ShaderFlags.OptimizationLevel2 },
            { "o3", ShaderFlags.OptimizationLevel3 },
            { "wx", ShaderFlags.WarningsAreErrors },
            { "vd", ShaderFlags.SkipValidation },
            { "zi", ShaderFlags.Debug },
            { "zss", ShaderFlags.DebugNameForSource },
            { "zsb", ShaderFlags.DebugNameForBinary },
            { "zpr", ShaderFlags.PackMatrixRowMajor },
            { "zpc", ShaderFlags.PackMatrixColumnMajor },

            { "gpp", ShaderFlags.PartialPrecision },
            { "gfa", ShaderFlags.AvoidFlowControl },
            { "gfp", ShaderFlags.PreferFlowControl },
            { "ges", ShaderFlags.EnableStrictness },
            { "gec", ShaderFlags.EnableBackwardsCompatibility },
            { "gis", ShaderFlags.IeeeStrictness },
        });


        public string OutputDirectory { get; private set; } = string.Empty;

        public string OutputFile { get; private set; } = string.Empty;

        public ShaderCompilerArguments ShaderCompilerArguments { get; private set; }

        private CompileArguments() 
        {
            ShaderCompilerArguments = new();
        }


        public static CompileArguments ParseCompilerArguments(string inputFile, string[] arguments)
        {
            CompileArguments result = new()
            {
                OutputDirectory = Path.GetDirectoryName(inputFile)!,
                OutputFile = Path.GetFileNameWithoutExtension(inputFile)
            };

            string profileExtension = Path.GetExtension(Path.GetFileNameWithoutExtension(inputFile)).ToLower();
            if(profileExtension is ".vs" or ".ps" or ".cs")
            {
                result.ShaderCompilerArguments.ShaderProfile = profileExtension[1..] + "_5_0";
                result.OutputFile = Path.GetFileNameWithoutExtension(result.OutputFile);
            }

            string rawOutputFile = result.OutputFile;
            bool hasFileExtension = false;

            for(int i = 2; i < arguments.Length; i++)
            {
                string rawArg = arguments[i];
                if(!rawArg.StartsWith('-'))
                {
                    throw new ArgumentException($"Invalid argument \"{rawArg}\"! (All arguments must start with a dash)");
                }

                string arg = rawArg[1..].ToLower();

                if(_shaderFlagArgumentMap.TryGetValue(arg, out ShaderFlags flag))
                {
                    result.ShaderCompilerArguments.CompilerFlags |= flag;
                    continue;
                }

                switch(arg)
                {
                    case "o":
                        i++;

                        if(i >= arguments.Length)
                        {
                            throw new ArgumentException("Missing path parameter for argument -o");
                        }

                        result.OutputFile = Path.GetFileName(arguments[i]);
                        result.OutputDirectory = Path.GetDirectoryName(arguments[i])!;
                        hasFileExtension = true;
                        break;

                    case "odir":
                        i++;

                        if(i >= arguments.Length)
                        {
                            throw new ArgumentException("Missing path parameter for argument -od");
                        }

                        result.OutputDirectory = arguments[i];
                        result.OutputFile = rawOutputFile;
                        hasFileExtension = false;
                        break;

                    case "nobp":
                        result.ShaderCompilerArguments.NoBuildPath = true;
                        break;

                    case "v1":
                        result.ShaderCompilerArguments.BuildV1 = true;
                        break;

                    case "t":
                        i++;

                        if(i >= arguments.Length)
                        {
                            throw new ArgumentException("Missing profile parameter for argument -t");
                        }

                        result.ShaderCompilerArguments.ShaderProfile = arguments[i].ToLower();

                        if(result.ShaderCompilerArguments.ShaderProfile is "vs" or "ps" or "cs")
                        {
                            result.ShaderCompilerArguments.ShaderProfile += "_5_0";
                        }

                        break;

                    case "e":
                        i++;

                        if(i >= arguments.Length)
                        {
                            throw new ArgumentException("Missing entry parameter for argument -e");
                        }

                        result.ShaderCompilerArguments.EntryPoint = arguments[i];
                        break;

                    case "nostd":
                        result.ShaderCompilerArguments.NoShaderTypeMacros = true;
                        break;

                    case "d":
                        i++;

                        if(i >= arguments.Length)
                        {
                            throw new ArgumentException("Missing macro definition parameter for argument -d");
                        }

                        string macro = arguments[i];
                        int macroAssign = macro.IndexOf('=');

                        string macroName;
                        string macroValue;

                        if(macroAssign == -1)
                        {
                            macroName = macro;
                            macroValue = string.Empty;
                        }
                        else
                        {
                            macroName = macro[..macroAssign];
                            macroValue = macro[(macroAssign + 1)..];
                        }

                        result.ShaderCompilerArguments.ExtraMacros.Add(new(macroName, macroValue));

                        break;

                    case "nowarn":
                        result.ShaderCompilerArguments.NoWarnings = true;
                        break;

                    default:
                        Console.WriteLine($"Unknown argument \"{rawArg}\", ignoring...");
                        break;
                }
            }

            if(string.IsNullOrWhiteSpace(result.ShaderCompilerArguments.ShaderProfile))
            {
                throw new ArgumentException("File has no profile extension, please specify a profile using -T");
            }

            if(!result.ShaderCompilerArguments.ShaderProfile.StartsWith("vs") && !result.ShaderCompilerArguments.ShaderProfile.StartsWith("ps") && !result.ShaderCompilerArguments.ShaderProfile.StartsWith("cs"))
            {
                throw new ArgumentException("Invalid profile! Must be a \"vs\", \"ps\" or \"cs\" profile!");
            }

            if(!hasFileExtension)
            {
                result.OutputFile += "." + result.ShaderCompilerArguments.ShaderProfile[..2] + 'o';
            }

            return result;
        }
    
    }
}
