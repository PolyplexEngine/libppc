/**
Copyright (c) 2018 Clipsey (clipseypone@gmail.com)

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
*/
module ppc.backend.loaders.shader.psgl;
import ppc.backend.cfile;
import ppc.types.shader;
import ppc.backend.signatures;
/**
    Polyplex Split GLSL
    A simple GLSL format combining GLSL shaders in to one file.
*/

///
void loadPSGL(MemFile file, Shader* shader) {
    import std.stdio;
    GLSLShader[ShaderType] shaderCode;
    size_t index;
    size_t length = file.length-WritableFileSigs.ShaderPSGL.length;

    // Seek to data beginning
    file.seek(&file, WritableFileSigs.ShaderPSGL.length, SeekStart);
    while(index < length) {
        ShaderType currentShaderType;
        uint shaderLength;
        ubyte[] shaderData;

        // Read data into temp variables
        index += file.read(&currentShaderType,  ShaderType.sizeof,  1,              &file);
        index += file.read(&shaderLength,       uint.sizeof,        1,              &file);

        // Ensure array is big enough
        shaderData.length = shaderLength;
        index += file.read(shaderData.ptr,      ubyte.sizeof,       shaderLength,   &file);

        shaderCode[currentShaderType] = GLSLShader(shaderData);
    }
    shader.shaders = shaderCode;
}

/// 
ubyte[] savePSGL(Shader shader) {
    ubyte[] oArr = new ubyte[1];
    MemFile mf = MemFile(oArr.ptr, oArr.length);
    mf.write(WritableFileSigs.ShaderPSGL.ptr, ubyte.sizeof, WritableFileSigs.ShaderPSGL.length, &mf);
    foreach(typ, shd; shader.shaders) {
        
        // Enforce proper EOF.
        ubyte[] code = shd.code;
        if (typ != ShaderType.Compiled) {
            if (code[$-2..$] != [0x0a, 0x00]) {
                code ~= [0x0a, 0x00];
            }
        }

        // Write it down.
        size_t len = code.length;
        mf.write(&typ, ShaderType.sizeof, 1, &mf);
        mf.write(&len, uint.sizeof, 1, &mf);
        mf.write(code.ptr, ubyte.sizeof, len, &mf);
    }
    return mf.toArray();
}