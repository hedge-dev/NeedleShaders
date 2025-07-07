using SharpGen.Runtime;
using Vortice.Direct3D;

namespace HedgeDev.NeedleShaders.HE2.Compiler
{
    internal class IncludeResolver : CallbackBase, Include
    {
        private readonly Dictionary<Stream, string> _streams = [];
        private readonly Dictionary<string, Stream> _invStreams = [];
        private readonly string _sourcePath;

        public IncludeResolver(string sourcePath)
        {
            _sourcePath = Path.GetFullPath(sourcePath);
        }

        public void Close(Stream stream)
        {
            if(_streams.TryGetValue(stream, out string? filepath))
            {
                stream.Close();
                _streams.Remove(stream);
                _invStreams.Remove(filepath);
            }
        }

        public void DisposeCore()
        {
            foreach(Stream stream in _streams.Keys)
            {
                stream.Close();
            }

            _streams.Clear();
            _invStreams.Clear();
        }

        public Stream Open(IncludeType type, string fileName, Stream? parentStream)
        {
            if(type == IncludeType.System)
            {
                throw new InvalidOperationException();
            }

            string relativeTo = parentStream == null
                ? _sourcePath
                : _streams[parentStream];

            string filepath = Path.GetFullPath(fileName, Path.GetDirectoryName(relativeTo)!);

            if(!_invStreams.TryGetValue(filepath, out Stream? stream))
            {
                stream = File.OpenRead(filepath);
                _streams.Add(stream, filepath);
                _invStreams.Add(filepath, stream);
            }

            return stream;
        }
    }
}
