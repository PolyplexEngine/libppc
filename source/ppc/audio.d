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
	public byte[] Samples;
	private byte[] oggdat;

	public int Channels;
	public long SampleRate;
	public long Length;
	public AudioStorageType Type;

	public this(string name) {
		super(TypeId.Audio, name);
	}

	this(ubyte[] data) {
		super(data);
		this.Type = cast(AudioStorageType)data[0];
		if (this.Type == AudioStorageType.OGG) {
			oggdat = cast(byte[])data[1..$];
			parse_audio_ogg(data[1..$]);
		} else {
			parse_audio_ppsnd(data[1..$]);
		}
	}

	public override void Convert(ubyte[] data, ubyte type) {
		this.Type = cast(AudioStorageType)type;
		parse_audio_ogg(data);
	}

	public override ubyte[] Compile() {
		ubyte type = cast(ubyte)this.Type;
		if (Type == AudioStorageType.OGG) {
			// USE OGG DATA
			return [type] ~ cast(ubyte[])oggdat;
		} else {
			// USE PCM DATA
		}
		return [];
	}

	private static bool has_vorbis_loaded = false;
	public static void LoadVorbis() {
		DerelictOgg.load();
		DerelictVorbis.load();
		DerelictVorbisFile.load();
		has_vorbis_loaded = true;
	}

	public void parse_audio_ppsnd(ubyte[] data) {

	}

	private extern (C) nothrow {
		import core.stdc.config;
		import core.stdc.stdlib;
		struct fakefile {
			ubyte* arrayptr;
			size_t length;
			ubyte* readhead;
		}

		extern (C) int pp_seek(void* data, ogg_int64_t offset, int whence) {
			fakefile* ff = cast(fakefile*)data;
			if (whence == SEEK_SET) {
				ff.readhead = cast(ubyte*)(cast(size_t)ff.arrayptr+cast(size_t)offset);
				return 0;
			}
			if (whence == SEEK_CUR) {
				ff.readhead = cast(ubyte*)(cast(size_t)ff.readhead+cast(size_t)offset);
				return 0;
			}
			if (whence == SEEK_END) {
				ff.readhead = cast(ubyte*)(cast(size_t)ff.arrayptr+cast(size_t)ff.length);
				return 0;
			}
			return -1;
		}

		extern (C) size_t pp_read(void* data, size_t bytes, size_t to_read, void* source) {
			fakefile* ff = cast(fakefile*)source;
			void* odat = malloc(bytes*to_read);
			void* odat_writehead = odat;
			ubyte* read_end = cast(ubyte*)(cast(size_t)ff.readhead+(cast(size_t)bytes*cast(size_t)to_read));
			size_t bytes_written = 0;
			while (ff.readhead < read_end) {
				*cast(ubyte*)odat_writehead = *cast(ubyte*)ff.readhead;
				odat_writehead++;
				ff.readhead++;
				bytes_written++;
			}
			*cast(ubyte*)data = *cast(ubyte*)odat;
			free(odat);
			free(odat_writehead);
			free(read_end);
			free(&bytes_written);
			return bytes_written;
		}

		extern (C) c_long pp_tell(void* data) {
			fakefile* ff = cast(fakefile*)data;
			return cast(c_long)ff.arrayptr-cast(c_long)ff.readhead;
		}
	}

	public void parse_audio_ogg(ubyte[] data) {
		// Load libogg, libvorbis and libvorbisfile, if not already.
		if (!has_vorbis_loaded) LoadVorbis();

		fakefile ff = fakefile(data.ptr, data.length, null);

		// Load file from byte array.
		OggVorbis_File* file;
		ov_callbacks callbacks;
		callbacks.seek_func = &pp_seek;
		callbacks.read_func = &pp_read;
		callbacks.tell_func = &pp_tell;
		
		if (ov_open_callbacks(&ff, file, null, 0, callbacks) < 0) {
			writeln("A");
			throw new Exception("Audio does not seem to be an ogg bitstream!...");
		}
		writeln("A");

		// Get info about stream.	
		vorbis_info* v_info = ov_info(file, -1);
		
		// Amount of channels in ogg file
		this.Channels = v_info.channels;

		// The sampling rate
		this.SampleRate = v_info.rate;

		// The length (of total pcm samples)
		this.Length = cast(long)ov_pcm_total(file, -1);
		writeln("A");

		// Read file to buffer
		byte[4096] buff;
		int current_section = 0;
		while (true) {
			long bytes_read = ov_read(file, buff.ptr, 4096, 0, 2, 1, &current_section);
			writeln("A");

			// End of file, no bytes read.
			if (bytes_read == 0) break;
			if (bytes_read == OV_HOLE) throw new Exception("Flow of data interrupted! Corrupt page?");
			if (bytes_read == OV_EBADLINK) throw new Exception("Stream section or link corrupted!");
			if (bytes_read == OV_EINVAL) throw new Exception("Initial file headers unreadable or corrupt!");
			Samples ~= buff;
		}
		writeln("A");

		// Clears the ogg file data from memory.
		if (ov_clear(file) != 0) {
			throw new Exception("Failed to do cleanup of vorbis file data!");
		}
	}
}