using SharpGen.Runtime;
using System.Runtime.InteropServices;
using Vortice.Direct3D;

namespace HedgeDev.Shaders.HE2.Compiler
{
    internal static class D3D11Extensions
    {
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
