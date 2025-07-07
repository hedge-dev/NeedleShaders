using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HedgeDev.Shaders.HE2.Compiler
{
    internal class CompilerException : Exception
    {
        public int PermutationIndex { get; }

        public CompilerException(int permutationIndex, string? message, Exception? innerException) : base(message, innerException)
        {
            PermutationIndex = permutationIndex;
        }
    }
}
