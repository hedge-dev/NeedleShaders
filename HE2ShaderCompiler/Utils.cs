using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HedgeDev.Shaders.HE2.Compiler
{
    internal static class Utils
    {
        public static string GetStringHeader(string text, char line = '-')
        {
            string result = " " + text.Trim() + " ";
            int remaining = 50 - result.Length;
            int half = remaining / 2;
            result = new string(line, half) + result + new string(line, remaining - half);

            return result;
        }
    }
}
