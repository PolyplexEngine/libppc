module ppc.backend.loaders.audio;
import ppc.backend.cfile;
import ppc.types.audio;

/// Sample bit depth being 8 bit
enum SAMPLE_DEPTH_8BIT     = 1;

/// Sample bit depth being 16 bit
enum SAMPLE_DEPTH_16BIT    = 2;

/// Samples are signed
enum SAMPLE_SIGNED         = true;

/// Samples are unsigned
enum SAMPLE_UNSIGNED       = false;

/// Sample should be stored little endian
enum SAMPLE_LITTLE_ENDIAN  = 0;

/// Sample should be stored big endian
enum SAMPLE_BIG_ENDIAN     = 1;

/// We need to use this cus templates are anoying
public class AudioStream {
    abstract AudioInfo genericInfo();

    abstract long read(byte* ptr, uint bufferLength = 4096, uint bitdepth = SAMPLE_DEPTH_16BIT, bool signed = SAMPLE_SIGNED);

    /// Seek to position in file
    abstract void seek(long position = 0);

    /// Seek to a PCM position in file
    abstract void seekSample(long position = 0);

    /**
        Reads entire stream in at once
        Not recommended for streams longer than a few seconds
    */
    abstract byte[] readAll();

    /**
        Read data of ogg stream in to array of specified type.
        This in untested and should probably not be used
        see the read() function instead.
    */
    deprecated("It's recommended not to use this function, but rather use the read() function instead.")
    abstract T[] readArray(T)(uint bufferLength = 4096, uint bitdepth = SAMPLE_DEPTH_16BIT, bool signed = SAMPLE_SIGNED);
}