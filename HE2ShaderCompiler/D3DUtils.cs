using SharpGen.Runtime;
using System.Runtime.InteropServices;
using Vortice.D3DCompiler;
using Vortice.Direct3D;

namespace HedgeDev.NeedleShaders.HE2.Compiler
{
    internal static class D3DUtils
    {
        public unsafe static ReadOnlyMemory<byte> Compile(string shaderSource, string entryPoint, string sourceName, string profile, out string? errors, ShaderFlags shaderFlags = ShaderFlags.OptimizationLevel1, EffectFlags effectFlags = EffectFlags.None)
        {
            if(string.IsNullOrEmpty(shaderSource))
            {
                throw new ArgumentNullException("shaderSource");
            }

            nint num = Marshal.StringToHGlobalAnsi(shaderSource);
            try
            {
                Result result = Vortice.D3DCompiler.Compiler.Compile(num.ToPointer(), (nuint)shaderSource.Length, sourceName, null, null, entryPoint, profile, shaderFlags, effectFlags, out Blob code, out Blob errorMsgs);
                if(result.Failure)
                {
                    if(errorMsgs != null)
                    {
                        throw new SharpGenException(result, errorMsgs.AsString());
                    }

                    throw new SharpGenException(result);
                }

                errors = errorMsgs?.AsString();
                errorMsgs?.Dispose();

                ReadOnlyMemory<byte> result2 = code.AsMemory();
                code.Dispose();

                return result2;
            }
            finally
            {
                if(num != IntPtr.Zero)
                {
                    Marshal.FreeHGlobal(num);
                }
            }
        }

        public static string Preprocess(string shaderSource, string sourceName, ShaderMacro[]? defines, Include? include)
        {
            if(string.IsNullOrEmpty(shaderSource))
            {
                throw new ArgumentNullException("shaderSource");
            }

            nint num = Marshal.StringToHGlobalAnsi(shaderSource);
            try
            {
                Blob? codeText = null;
                Blob? errorMsgs = null;

                try
                {
                    Vortice.D3DCompiler.Compiler.Preprocess(num, (nuint)shaderSource.Length, sourceName, defines, include, out codeText, out errorMsgs);
                }
                catch(SharpGenException)
                {
                    if(errorMsgs != null)
                    {
                        throw new SharpGenException(errorMsgs.AsString());
                    }

                    throw;
                }

                string result = codeText.AsString();

                errorMsgs?.Dispose();
                codeText.Dispose();

                return result;
            }
            finally
            {
                if(num != IntPtr.Zero)
                {
                    Marshal.FreeHGlobal(num);
                }
            }
        }

        public static unsafe string Disassemble(byte[] shaderByteCode)
        {
            fixed(byte* shaderByteCodePtr = shaderByteCode)
            {
                Blob codeText = Vortice.D3DCompiler.Compiler.Disassemble((nint)shaderByteCodePtr, (nuint)shaderByteCode.Length, default, null);
                string result = codeText.AsString();
                codeText.Dispose();
                return result;
            }
        }

    }
}
