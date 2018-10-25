module ppc.audio;
import ppc;
import std.stdio;
import std.bitmanip;
import std.functional;
import derelict.ogg.ogg;
import derelict.vorbis;

public class AudioFactory : ContentFactory {
	public this() {
		super(TypeId.Audio);
	}

	public override Content Construct(ubyte[] data) {
		return new Audio(data);
	}
}

public enum AudioStorageType : ubyte {
	OGG,
	PPSND
}

public class Audio : Content {

	public OGGAudioStream Stream;

	/**
		What kind of storage is used for the audio content.
		Either ogg or ppsnd
	*/
	public AudioStorageType Type;

	/**
		Constructor
	*/
	public this(string name) {
		super(TypeId.Audio, name);
	}

	/**
		Constructor
	*/
	public this(ubyte[] data) {
		super(data);
		Stream = OGGAudioStream(data);
		this.Type = cast(AudioStorageType)data[0];
		
	}

	/**
		Converts an OGG to a PPC ready OGG (or PPSND if chosen)
	*/
	public override void Convert(ubyte[] data, ubyte type) {
		this.Type = cast(AudioStorageType)type;
		Stream = OGGAudioStream(data);
	}

	public override void Load(ubyte[] data) {
		this.Type = cast(AudioStorageType)data[0];
		Stream = OGGAudioStream(data[1..$]);
	}

	/**
		Compiles the sound in to the PPC format.
	*/
	public override ubyte[] Compile() {
		ubyte type = cast(ubyte)this.Type;
		if (Type == AudioStorageType.OGG) {
			// USE OGG DATA
			return [type] ~ cast(ubyte[])Stream.OggData;
		} else {
			// USE PCM DATA
		}
		return [];
	}

	private void parse_audio_ppsnd(ubyte[] data) {

	}
}

public struct OGGAudioStream {
	private static bool has_vorbis_loaded = false;
	/**
		Don't run this.
		Is automatically run to load OGG Vorbis libraries.
	*/
	public static void LoadVorbis() {
		DerelictOgg.load();
		DerelictVorbis.load();
		DerelictVorbisFile.load();
		has_vorbis_loaded = true;
	}

	private ubyte[] oggdat;
	private fakefile fake;
	private OggVorbis_File file;
	private vorbis_info* v_info;
	private ov_callbacks callbacks;
	private int current_section = 0;

	public ubyte[] OggData() {
		return oggdat;
	}

	/**
		Gets if the audio is to be streamed.
	*/
	public bool Streamed;

	/**
		The amount of channels.
	*/
	public int Channels;

	/**
		The sample rate of the audio
	*/
	public int SampleRate;

	/**
		The amount of sample data (bytes)
	*/
	public long Length;

	/**
		The amount of PCM samples (single channel)
	*/
	public long PCMLength;

	this(ubyte[] oggFile) {
		// Load libogg, libvorbis and libvorbisfile, if not already.
		if (!has_vorbis_loaded) LoadVorbis();

		this.oggdat = oggFile;

		fake.arrayptr = oggdat.ptr;
		fake.readhead = oggdat.ptr;
		fake.length = oggdat.length;

		// Callbacks
		callbacks.read_func = &pp_read;
		callbacks.seek_func = &pp_seek;
		callbacks.close_func = &pp_close;
		callbacks.tell_func = &pp_tell;

		if (ov_open_callbacks(&fake, &file, null, 0, callbacks) < 0) {
			throw new Exception("Audio does not seem to be an ogg bitstream!...");
		}

		// Get info about stream.	
		v_info = ov_info(&file, -1);
	
		// Amount of channels in ogg file
		this.Channels = v_info.channels;

		// The sampling rate
		this.SampleRate = v_info.rate;

		// The amount of PCM data, as told by libvorbisfile.
		this.PCMLength = cast(ulong)ov_pcm_total(&file, -1);
	}

	~this() {
		Dispose();
	}

	public void Dispose() {
		// Clears the ogg file data from memory.
		if (ov_clear(&file) != 0) {
			throw new Exception("Failed to do cleanup of vorbis file data!");
		}
	}

	public byte[] ReadFrame(uint bufferLength = 4096) {
		byte[] buff;
		buff.length = bufferLength;
		long bytes_read = ov_read(&file, buff.ptr, cast(int)bufferLength, 0, 2, 1, &current_section);
		// End of file, no bytes read.
		if (bytes_read == 0) return [];
		if (bytes_read == OV_HOLE) throw new Exception("Flow of data interrupted! Corrupt page?");
		if (bytes_read == OV_EBADLINK) throw new Exception("Stream section or link corrupted!");
		if (bytes_read == OV_EINVAL) throw new Exception("Initial file headers unreadable or corrupt!");

		// Reverse order if big-endian.
		version(BigEndian) {
			import std.algorithm.mutation;
			buff.reverse;
		}
		return buff[0..bytes_read];
	}

	public byte[] ReadAll() {
		byte[] Samples;

		// Read file to buffer
		byte[] buff = ReadFrame();
		while (buff != []) {
			Samples ~= buff;
			buff = ReadFrame();
		}

		// The length in bytes
		this.Length = cast(int)Samples.length;
		return Samples;
	}
}

private extern (C) nothrow {
	import core.stdc.config;
	import core.stdc.stdlib;
	import core.stdc.string;

	struct fakefile {
		ubyte* arrayptr;
		ubyte* readhead;
		size_t length;
	}

	extern (C) int pp_seek(void* data, ogg_int64_t offset, int whence) {
		fakefile* ff = cast(fakefile*)data;
		switch (whence) {
			case SEEK_CUR:
				ff.readhead += offset;
				break;
			case SEEK_SET:
				ff.readhead = ff.arrayptr + offset;
				break;
			case SEEK_END:
				ff.readhead = ff.arrayptr + ff.length-offset;
				break;
			default:
				return -1;
		}

		if (ff.readhead < ff.arrayptr) {
			ff.readhead = ff.arrayptr;
			return -1;
		}

		if (ff.readhead > ff.arrayptr + ff.length) {
			ff.readhead = ff.arrayptr + ff.length;
		}

		return 0;
	}

	extern (C) size_t pp_read(void* data, size_t bytes, size_t to_read, void* source) {
		fakefile* ff = cast(fakefile*)source;
		
		size_t len = bytes*to_read;
		if (ff.readhead + len > ff.arrayptr+ff.length) {
			len = ff.arrayptr+ff.length-ff.readhead;
		}
		memcpy(data, ff.readhead, len);
		ff.readhead += len;
		return len;
	}

	extern (C) int pp_close(void* data) {
		return 0;
	}

	extern (C) c_long pp_tell(void* data) {
		fakefile* ff = cast(fakefile*)data;
		return ff.readhead-ff.arrayptr;
	}
}