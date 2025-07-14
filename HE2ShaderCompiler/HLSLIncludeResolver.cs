using SharpGen.Runtime;
using Vortice.Direct3D;

namespace HedgeDev.NeedleShaders.HE2.Compiler
{
    internal class IncludeResolver : CallbackBase, Include
    {
        private readonly string _sourcePath;

        public IncludeResolver(string sourcePath)
        {
            _sourcePath = Path.GetFullPath(sourcePath);
        }

        public Stream Open(IncludeType type, string fileName, Stream? parentStream)
        {
            if(type == IncludeType.System)
            {
                throw new InvalidOperationException();
            }

            string sourcePath = parentStream != null
                ? ((FileStream)parentStream).Name
                : _sourcePath;

            string filepath = Path.GetFullPath(fileName, Path.GetDirectoryName(sourcePath)!);
            return File.OpenRead(filepath);
        }

        public void Close(Stream stream)
        {
            stream.Close();
        }

        public void DisposeCore()
        {

        }
    }
}
