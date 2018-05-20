module ppc.sound;
import ppc;
import std.stdio;
import std.bitmanip;
import std.functional;
import derelict.vorbis;
import derelict.vorbis.file;

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

public enum AudioType : ubyte {
	Sound,
	Music
}

public class Audio : Content {
	public byte[] Samples;
	private byte[] oggdat;

	public int Channels;
	public long SampleRate;
	public long Length;
	public AudioType AType;
	public AudioStorageType Type;

	this(ubyte[] data) {
		super(data);
		this.Type = cast(AudioStorageType)data[0];
		if (this.Type == AudioStorageType.OGG) {
			parse_audio_ogg(data[1..$]);
		} else {

		}
	}

	public override void Convert(ubyte[] data) {

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
		DerelictVorbis.load();
		DerelictVorbisFile.load();
		has_vorbis_loaded = true;
	}

	public void parse_audio_ppsnd(ubyte[] data) {

	}

	public void parse_audio_ogg(ubyte[] data) {
		// Load libogg, libvorbis and libvorbisfile, if not already.
		if (!has_vorbis_loaded) LoadVorbis();

		// Load file from byte array.
		OggVorbis_File file;
		ov_callbacks callbacks = ov_callbacks(&Derelict_VorbisRead, &Derelict_VorbisSeek, &Derelict_VorbisClose, &Derelict_VorbisTell);
		if (ov_open_callbacks(data.ptr, &file, null, 0, callbacks) < 0) {
			throw new Exception("Audio does not seem to be an ogg bitstream!...");
		}

		// Get info about stream.	
		vorbis_info* v_info = ov_info(&file, -1);
		
		// Amount of channels in ogg file
		this.Channels = v_info.channels;

		// The sampling rate
		this.SampleRate = v_info.rate;

		// The length (of total pcm samples)
		this.Length = cast(long)ov_pcm_total(&file, -1);

		// Read file to buffer
		byte[4096] buff;
		int current_section = 0;
		while (true) {
			long bytes_read = ov_read(&file, buff.ptr, 4096, 0, 2, 1, &current_section);

			// End of file, no bytes read.
			if (bytes_read == 0) break;
			if (bytes_read == OV_HOLE) throw new Exception("Flow of data interrupted! Corrupt page?");
			if (bytes_read == OV_EBADLINK) throw new Exception("Stream section or link corrupted!");
			if (bytes_read == OV_EINVAL) throw new Exception("Initial file headers unreadable or corrupt!");
			Samples ~= buff;
		}

		// Clears the ogg file data from memory.
		if (ov_clear(&file) != 0) {
			throw new Exception("Failed to do cleanup of vorbis file data!");
		}
	}
}