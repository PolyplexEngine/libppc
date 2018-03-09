module ppc;
import ppc.image;
import ppc.exceptions;
import std.file;
import std.stdio;
import std.array;

/**
	PPCoHead Header Name
*/
public static ubyte[] ContentHeader() {
	return [0x50, 0x50, 0x43, 0x6f, 0x48, 0x65, 0x61, 0x64];
}

public enum TypeId : ubyte {
	Texture2D,
	Texture3D,
	Audio,
	Shader,
	Dictionary,
	Data
}

public class Content {
	this(TypeId id, ubyte[] data) {
		this.Type = id;
		this.Data = data;
	}

	public ubyte[] Data;
	public TypeId Type;
	public ubyte TypeID() { return cast(ubyte) Type; }

	public static byte[] SaveRaw(string name) {
		File f = File(name);
		ubyte[] ts = ContentHeader;
		ts.length += 1;
		ts[ts.length-1] = cast(ubyte)this.Type;
		join([ts, Data]);
		f.rawWrite(ts);
		f.close();
	}
}

public class ContentLoader {
	public static Content LoadRaw(string file) {
		File f = File(file);
		ubyte[ContentHeader.length] header;
		ubyte[1] tyid;
		ubyte[] data;

		f.byChunk(header);
		if (header != ContentHeader) throw new InvalidFileFormatException();
		f.byChunk(tyid);
		foreach(ubyte[] buff; f.byChunk(4096)) {
			join([data, buff]);
		}
		f.close();
		return new Content(cast(TypeId)tyid[0], data);
	}

	public static Image LoadImage(string file) {
		return null;
	}
}