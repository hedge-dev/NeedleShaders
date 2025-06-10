using SharpNeedle.Framework.HedgehogEngine.Needle.Shader;
using SharpNeedle.Resource;
using System.Text.RegularExpressions;
using Vortice.Direct3D;

namespace HedgeDev.Shaders.HE2.Compiler
{
    internal static partial class CommandCompile
    {
        public static void Run(string[] args)
        {
            string file = args[1];
            
            if(!File.Exists(file))
            {
                throw new ArgumentException($"The file \"{file}\" does not exist!");
            }

            CompileArguments compilerArgs = CompileArguments.ParseCompilerArguments(file, args);
            IncludeResolver includeResolver = new(file);

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

                baseMacros[^1] = new(null, null);
            }

            string shaderCode = File.ReadAllText(file);
            string preprocessedShaderCode = D3D11Extensions.Preprocess(shaderCode, file, baseMacros, includeResolver);

            string[] features = FeatureRegex().Matches(preprocessedShaderCode).Select(x => x.Groups[1].Value).ToArray();

            List<ReadOnlyMemory<byte>> variants = [];
            int[] permutations = new int[(int)Math.Pow(2, features.Length)];

            for(int i = 0; i < permutations.Length; i++)
            {
                List<ShaderMacro> macros = [];
                macros.AddRange(compilerArgs.ExtraMacros);

                for(int j = 0; j < features.Length; j++)
                {
                    string feature = features[j];

                    if((i & (1 << j)) == 0 || baseMacroLUT.Contains(feature))
                    {
                        continue;
                    }

                    macros.Add(new(features[j], 1));
                }

                macros.Add(new(null, null));

                ReadOnlyMemory<byte> compiledShader = Vortice.D3DCompiler.Compiler.Compile(
                    shaderCode, 
                    macros.ToArray(),
                    includeResolver,
                    compilerArgs.EntryPoint, 
                    file, 
                    compilerArgs.ShaderProfile,
                    compilerArgs.CompilerFlags
                );

                ReadOnlySpan<byte> span = compiledShader.Span;

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
                    variants.Add(compiledShader);
                }

                permutations[i] = foundIndex;
            }

            Shader output = new();

            if(!compilerArgs.NoBuildPath)
            {
                output.BuildPath = file;
            }

            output.Features.AddRange(features.Select(x => new Shader.Feature() { Name = x }));
            output.Variants.AddRange(variants.Select(ShaderByteCodeProcessor.ProcessShaderByteCode));
            output.Permutations.AddRange(permutations);

            if(!compilerArgs.BuildV1)
            {
                foreach(ShaderVariant variant in output.Variants)
                {
                    variant.GlobalVariables.IncludeTerminator = true;
                }
            }

            output.Write(Path.Combine(compilerArgs.OutputDirectory, compilerArgs.OutputFile));
        }

        [GeneratedRegex("static const uint FEATURE_([A-Za-z0-9_]*) ;")]
        private static partial Regex FeatureRegex();
    }
}
