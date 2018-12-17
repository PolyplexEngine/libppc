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
module ppc.backend.loaders.audio.ogg;
import derelict.ogg.ogg;
import derelict.vorbis;
import ppc.backend.loaders.audio;
import ppc.backend.cfile;
import ppc.types.audio;

/// Info associated with the OGG file
public struct OggInfo {
public:
    /// Which version of OGG is used.
    int oggVersion;

    /// The amount of channels present
    int channels;

    /// Bitrate of OGG
    int bitrate;

    /// Bitrate upper value
    size_t bitrateUpper;

    /// Bitrate nominal value
    size_t bitrateNominal;

    /// Bitrate lower value
    size_t bitrateLower;

    /// Bitrate window
    size_t bitrateWindow;

    /// Length of OGG in samples
    size_t pcmLength;

    /// Length of OGG in bytes.
    size_t rawLength;

    /// Creates a new OggInfo
    this(Ogg oggFile) {

        vorbis_info* inf = ov_info(&oggFile.vfile, -1);
        
        this.oggVersion     = (*inf)._version;
        this.channels       = (*inf).channels;
        this.bitrate        = (*inf).rate;
        this.bitrateUpper   = cast(size_t)(*inf).bitrate_upper;
        this.bitrateNominal = cast(size_t)(*inf).bitrate_nominal;
        this.bitrateLower   = cast(size_t)(*inf).bitrate_lower;
        this.bitrateWindow  = cast(size_t)(*inf).bitrate_window;

        this.pcmLength      = cast(size_t)ov_pcm_total(&oggFile.vfile, -1);
        this.rawLength      = cast(size_t)ov_raw_total(&oggFile.vfile, -1);

    }
}

/// An OGG audio file
public class Ogg : AudioStream {
private:
    OggVorbis_File vfile;
    static ov_callbacks callbacks;
    int currentSection;
    long bytesRead;

public:
    /// information related to the OGG file
    OggInfo info;

    /// Gets info in the generic AudioInfo format.
    override AudioInfo genericInfo() {
        return AudioInfo(AudioType.OGG, cast(ubyte)info.oggVersion, cast(ubyte)info.channels, info.bitrate, info.pcmLength, info.rawLength);
    }

    /// Construct file from memory
    /// Check loadFile from ppc.backend.cfile if you want to load from a raw file.
    this(MemFile file) {
        // Open file from memory
        if (ov_open_callbacks(&file, &vfile, null, 0, Ogg.callbacks) < 0) {
            throw new Exception("Audio does not seem to be an ogg bitstream!...");
        }

        // Load and set file info.
        info = OggInfo(this);
    }

    ~this() {
        if (ov_clear(&vfile) != 0) {
            throw new Exception("Failed to do cleanup of vorbis file data!");
        }
    }

    /**
        Read data of ogg stream in to specified buffer array by pointer.
        returns amount of bytes read
    */
    override long read(byte* ptr, uint bufferLength = 4096, uint bitdepth = SAMPLE_DEPTH_16BIT, bool signed = SAMPLE_SIGNED) {
        // Read samples of size bufferLength to specified ptr
		version(BigEndian)  bytesRead = ov_read(&vfile, ptr, cast(int)bufferLength, SAMPLE_BIG_ENDIAN, bitdepth, cast(int)signed, &currentSection);
        else                bytesRead = ov_read(&vfile, ptr, cast(int)bufferLength, SAMPLE_LITTLE_ENDIAN, bitdepth, cast(int)signed, &currentSection);
        switch(bytesRead) {
            case (OV_HOLE):
                throw new Exception("Flow of data interrupted! Corrupt page?");
            case (OV_EBADLINK):
                throw new Exception("Stream section or link corrupted!");
            case (OV_EINVAL):
                throw new Exception("Initial file headers unreadable or corrupt!");
            default:
                return bytesRead;
        }
    }

    /// Seek to position in file
    override void seek(long position = 0) {
        ov_raw_seek(&vfile, position);
    }

    /// Seek to a PCM position in file
    override void seekSample(long position = 0) {
        ov_pcm_seek(&vfile, position);
    }

    /**
        Reads entire stream in at once
        Not recommended for streams longer than a few seconds
    */
    override byte[] readAll() {
        byte[] bytes = new byte[info.rawLength];
        size_t read;
        size_t totalRead;
        while (true) {
            read = this.read(bytes.ptr+totalRead);
            totalRead += read;
            if (read == 0) return bytes;
        }
    }

    /**
        Read data of ogg stream in to array of specified type.
        This in untested and should probably not be used
        see the read() function instead.
    */
    deprecated("It's recommended not to use this function, but rather use the read() function instead.")
    override T[] readArray(T)(uint bufferLength = 4096, uint bitdepth = SAMPLE_DEPTH_16BIT, bool signed = SAMPLE_SIGNED) if (isNumeric!T) {
        T[] arr = new T[bufferLength];
        read(cast(byte*)&arr, bufferLength, bitdepth, signed);
        return arr;
    }
}

// TODO: Replace this with bindbc!
///Load libogg and libvorbis
void loadOggFormat() {
    DerelictOgg.load();
    DerelictVorbis.load();
}


// Keep one instance of the callback pointer instead of many.
shared static this() {
    Ogg.callbacks.read_func = &MemFile.read;
    Ogg.callbacks.seek_func = &MemFile.seek;
    Ogg.callbacks.close_func = &MemFile.close;
    Ogg.callbacks.tell_func = &MemFile.tell;
}