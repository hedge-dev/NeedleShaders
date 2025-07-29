echo off
cd /D "%~dp0"

if exist ".\Releases" (
	rmdir ".\Releases" /s /q
)

mkdir .\Releases
cd .\Releases

mkdir .\linux-arm64
mkdir .\linux-x64
mkdir .\osx-arm64
mkdir .\osx-x64
mkdir .\win-x64
mkdir .\win-x86
mkdir .\bin

cd ..

cd "HE2ShaderCompiler"
dotnet publish -p:PublishProfile=linux-arm64
dotnet publish -p:PublishProfile=linux-x64
dotnet publish -p:PublishProfile=osx-arm64
dotnet publish -p:PublishProfile=osx-x64
dotnet publish -p:PublishProfile=win-x64
dotnet publish -p:PublishProfile=win-x86
dotnet publish -p:PublishProfile=bin

cd ..

cd .\Releases

set version="1.1.0"

tar --strip-components 1 -acf HE2ShaderCompiler-%version%-linux-arm64.zip -C .\linux-arm64 .
tar --strip-components 1 -acf HE2ShaderCompiler-%version%-linux-x64.zip -C .\linux-x64 .
tar --strip-components 1 -acf HE2ShaderCompiler-%version%-osx-arm64.zip -C .\osx-arm64 .
tar --strip-components 1 -acf HE2ShaderCompiler-%version%-osx-x64.zip -C .\osx-x64 .
tar --strip-components 1 -acf HE2ShaderCompiler-%version%-win-x64.zip -C .\win-x64 .
tar --strip-components 1 -acf HE2ShaderCompiler-%version%-win-x86.zip -C .\win-x86 .
tar --strip-components 1 -acf HE2ShaderCompiler-%version%-bin.zip -C .\bin .

cd ..