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
module ppc.backend.ppc;
import ppc.backend;
import ppc.backend.cfile;
import ppc.backend.signatures;
import ppc.exceptions;

enum PPCLoaderVersion = 1;

public enum ContentType : ubyte {
    Script              = 1,
    Shader              = 2,
    Image               = 3,
    Model               = 4,
    Audio               = 5,
    GenericData         = 6
}

public struct PPC {
private:
    ubyte   [  ]    dataStr;

public:
    /// Version of the PPC file
    uint            version_;

    /// Content type of the internal content
    ContentType     contentType;

    /// Options for the file
    ulong           options;

    /// Author of the file
    char    [32]    author;

    /// License of the content
    char    [16]    license;

    /// The content data
    MemFile data;

    /// Create a new PPC file from file
    this(string file) {
        MemFile mf = loadFile(file);
        this(mf);
    }

    /// Create a new PPC file from memory
    this(MemFile file) {
        // Throw exception if not PPC file
        if (!file.hasSignature(FileSignature.ContainerPPC)) 
            throw new InvalidMagicBytesException("ppc");

        // Skip the file signature
        file.seek(&file, FileSignature.ContainerPPC.length, SeekStart);

        // Read all the data into the variables.
        file.read(&version_, uint.sizeof, 1, &file);
        file.read(&options, ulong.sizeof, 1, &file);
        file.read(&contentType, ubyte.sizeof, 1, &file);
        file.read(&author, char.sizeof, 32, &file);
        file.read(&license, char.sizeof, 16, &file);
        file.read(&dataStr, ubyte.sizeof, file.length - file.tell(&file), &file);

        // Set up pointer to internal data
        data.arrayptr = dataStr.ptr;
        data.readhead = data.arrayptr;
        data.length = dataStr.length;

        // Destroy the ppc file from memory since we already have the needed data.
        destroy(file);
    }
}

//  TODO: Replace this with some prettier code
/// Returns a writable PPC file as a ubyte array
ubyte[] savePPC(PPC ppc) {
    ubyte[] oArr = new ubyte[FileSignature.ContainerPPC.length];
    MemFile mf = MemFile(oArr.ptr, oArr.length);
    // Write file signature.
    mf.write(FileSignature.ContainerPPC.ptr, FileSignature.ContainerPPC.length, 1, &mf);
    mf.write(&ppc.version_, uint.sizeof, 1, &mf);
    mf.write(&ppc.options, ulong.sizeof, 1, &mf);
    mf.write(&ppc.contentType, ubyte.sizeof, 1, &mf);
    mf.write(&ppc.author, char.sizeof, 32, &mf);
    mf.write(&ppc.license, char.sizeof, 16, &mf);
    mf.write(&ppc.dataStr, ubyte.sizeof, mf.length - mf.tell(&mf), &mf);
    return oArr;
}