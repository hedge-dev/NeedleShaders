using HedgeDev.NeedleShaders.HE2.Compiler;
using SharpNeedle.Framework.HedgehogEngine.Needle.Shader;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using Vortice.D3DCompiler;
using Vortice.Direct3D;

namespace HedgeDev.Shaders.HE2.Compiler
{
    public class ShaderCompilerArguments
    {
        public string ShaderProfile { get; set; } = string.Empty;

        public ShaderFlags CompilerFlags { get; set; }

        public bool NoBuildPath { get; set; }

        public bool BuildV1 { get; set; }

        public string EntryPoint { get; set; } = "main";

        public bool NoShaderTypeMacros { get; set; }

        public List<ShaderMacro> ExtraMacros { get; set; } = [];

        public bool NoWarnings { get; set; }

        public ShaderCompilerArguments() { }

        public ShaderCompilerArguments Clone()
        {
            return new()
            {
                ShaderProfile = ShaderProfile,
                CompilerFlags = CompilerFlags,
                NoBuildPath = NoBuildPath,
                BuildV1 = BuildV1,
                EntryPoint = EntryPoint,
                NoShaderTypeMacros = NoShaderTypeMacros,
                ExtraMacros = new(ExtraMacros),
                NoWarnings = NoWarnings
            };
        }
    }
}
