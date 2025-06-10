using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Vortice.D3DCompiler;
using Vortice.Direct3D;

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


        public string ShaderProfile { get; private set; } = string.Empty;

        public ShaderFlags CompilerFlags { get; private set; }

        public bool NoBuildPath { get; private set; }

        public bool BuildV1 { get; private set; }

        public string OutputDirectory { get; private set; } = string.Empty;

        public string OutputFile { get; private set; } = string.Empty;

        public string EntryPoint { get; private set; } = "main";

        public List<ShaderMacro> ExtraMacros { get; private set; } = [];


        private CompileArguments() { }


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
                result.ShaderProfile = profileExtension[1..] + "_5_0";
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
                    result.CompilerFlags |= flag;
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
                        result.NoBuildPath = true;
                        break;

                    case "v1":
                        result.BuildV1 = true;
                        break;

                    case "t":
                        i++;

                        if(i >= arguments.Length)
                        {
                            throw new ArgumentException("Missing profile parameter for argument -t");
                        }

                        result.ShaderProfile = arguments[i].ToLower();

                        if(result.ShaderProfile is "vs" or "ps" or "cs")
                        {
                            result.ShaderProfile += "_5_0";
                        }

                        break;

                    case "e":
                        i++;

                        if(i >= arguments.Length)
                        {
                            throw new ArgumentException("Missing entry parameter for argument -e");
                        }

                        result.EntryPoint = arguments[i];
                        break;

                    case "d":
                        i++;

                        if(i >= arguments.Length)
                        {
                            throw new ArgumentException("Missing macro definition parameter for argument -d");
                        }

                        string macro = arguments[i];
                        int macroAssign = macro.IndexOf('=');

                        if(macroAssign == -1)
                        {
                            throw new ArgumentException("Invalid macro! Must be like <macro>=<text>");
                        }

                        result.ExtraMacros.Add(new(macro[..macroAssign], macro[(macroAssign + 1)..]));

                        break;

                    default:
                        Console.WriteLine($"Unknown argument \"{rawArg}\", ignoring...");
                        break;
                }
            }

            if(string.IsNullOrWhiteSpace(result.ShaderProfile))
            {
                throw new ArgumentException("File has no profile extension, please specify a profile using -T");
            }

            if(!result.ShaderProfile.StartsWith("vs") && !result.ShaderProfile.StartsWith("ps") && !result.ShaderProfile.StartsWith("cs"))
            {
                throw new ArgumentException("Invalid profile! Must be a \"vs\", \"ps\" or \"cs\" profile!");
            }

            if(!hasFileExtension)
            {
                result.OutputFile += "." + result.ShaderProfile[..2] + 'o';
            }

            return result;
        }
    }
}
