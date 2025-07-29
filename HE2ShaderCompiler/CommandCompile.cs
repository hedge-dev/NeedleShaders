using HedgeDev.Shaders.HE2.Compiler;
using SharpGen.Runtime;
using SharpNeedle.Framework.HedgehogEngine.Needle.Shader;
using SharpNeedle.Resource;
using System.Text;
using System.Text.RegularExpressions;
using Vortice.Direct3D;

namespace HedgeDev.NeedleShaders.HE2.Compiler
{
    internal static class CommandCompile
    {
        public static void Run(string[] args)
        {
            string file = args[1];

            if(!File.Exists(file))
            {
                throw new ArgumentException($"The file \"{file}\" does not exist!");
            }

            CompileArguments compilerArgs = CompileArguments.ParseCompilerArguments(file, args);

            Console.WriteLine(Utils.GetStringHeader($"Compiling {compilerArgs.OutputFile}", '='));
            Console.WriteLine();

            Shader shader = new ShaderCompiler(compilerArgs.ShaderCompilerArguments, true, null).CompileFile(file);

            shader.Write(Path.Combine(compilerArgs.OutputDirectory, compilerArgs.OutputFile));
        }

    }
}
