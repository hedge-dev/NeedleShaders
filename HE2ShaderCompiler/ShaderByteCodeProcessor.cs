using SharpNeedle.Framework.HedgehogEngine.Needle.Shader;
using SharpNeedle.Framework.HedgehogEngine.Needle.Shader.Variable;
using Vortice.Direct3D;
using Vortice.Direct3D11.Shader;

namespace HedgeDev.NeedleShaders.HE2.Compiler
{
    internal static class ShaderByteCodeProcessor
    {
        public static ShaderVariant ProcessShaderByteCode(ReadOnlyMemory<byte> shader)
        {
            ReadOnlySpan<byte> span = shader.Span;

            return new()
            {
                ShaderByteCode = span.ToArray(),
                InputSignatureByteCode = Vortice.D3DCompiler.Compiler.GetInputSignatureBlob(span).AsBytes(),
                GlobalVariables = GetVariables(span)
            };
        }

        private static ShaderGlobalVariables GetVariables(ReadOnlySpan<byte> shader)
        {
            ShaderGlobalVariables result = new();

            Vortice.D3DCompiler.Compiler.Reflect(shader, out ID3D11ShaderReflection? reflection);

            foreach(ID3D11ShaderReflectionConstantBuffer constantBuffer in reflection!.ConstantBuffers)
            {
                if(constantBuffer.Description.Type != ConstantBufferType.ConstantBuffer)
                {
                    continue;
                }

                InputBindingDescription? bindingDescription = reflection.BoundResources.FirstOrDefault(
                    x => x.Name == constantBuffer.Description.Name 
                        && x.Type == ShaderInputType.ConstantBuffer);
                
                if(!bindingDescription.HasValue)
                {
                    throw new InvalidDataException($"Could not find resource binding for constant buffer \"{constantBuffer.Description.Name}\"");
                }

                int id = (int)bindingDescription.Value.BindPoint;

                result.ConstantBuffers.Add(new()
                {
                    ID = id,
                    Name = constantBuffer.Description.Name,
                    Size = (int)constantBuffer.Description.Size,
                });

                foreach(ID3D11ShaderReflectionVariable variable in constantBuffer.Variables)
                {
                    ConstantBufferField field = new()
                    {
                        ConstantBufferIndex = id,
                        Name = variable.Description.Name,
                        Offset = (int)variable.Description.StartOffset,
                        Size = (int)variable.Description.Size,
                    };

                    switch(variable.VariableType.Description.Type)
                    {
                        case ShaderVariableType.Bool:
                            result.CBBooleans.Add(field);
                            break;
                        case ShaderVariableType.Int:
                            result.CBIntegers.Add(field);
                            break;
                        case ShaderVariableType.Float:
                            result.CBFloats.Add(field);
                            break;
                        default:
                            throw new InvalidDataException($"Unsupported variable type \"{variable.VariableType.Description.Type}\" for variable \"{variable.Description.Name}\" in constant buffer \"{constantBuffer.Description.Name}\"");
                    }
                }
            }

            foreach(InputBindingDescription resource in reflection!.BoundResources)
            {
                switch(resource.Type)
                {
                    case ShaderInputType.ConstantBuffer:
                        // handled above
                        break;

                    case ShaderInputType.Texture:
                        result.Textures.Add(new()
                        {
                            ID = (int)resource.BindPoint,
                            Name = resource.Name,
                            Type = (ResourceType)((int)resource.Dimension - 1)
                        });
                        break;

                    case ShaderInputType.Sampler:
                        result.Samplers.Add(new()
                        {
                            ID = (int)resource.BindPoint,
                            Name = resource.Name
                        });
                        break;

                    case ShaderInputType.Structured:
                        result.Textures.Add(new()
                        {
                            ID = (int)resource.BindPoint,
                            Name = resource.Name,
                            Type = ResourceType.BufferExtended
                        });
                        break;

                    case ShaderInputType.UnorderedAccessViewRWStructured:
                    case ShaderInputType.UnorderedAccessViewRWByteAddress:
                        result.UnorderedAccessViews.Add(new()
                        {
                            ID = (int)resource.BindPoint,
                            Name = resource.Name,
                            Type = ResourceType.BufferExtended
                        });
                        break;

                    case ShaderInputType.UnorderedAccessViewRWTyped:
                        result.UnorderedAccessViews.Add(new()
                        {
                            ID = (int)resource.BindPoint,
                            Name = resource.Name,
                            Type = (ResourceType)((int)resource.Dimension - 1)
                        });
                        break;

                    default:
                        Console.WriteLine($"Unsupported resource type \"{resource.Type}\" with name \"{resource.Name}\" at bind point {resource.BindPoint}");
                        break;
                }
            }

            return result;
        }
    }
}
