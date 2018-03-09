module ppc;
public import ppc.image;
public import ppc.exceptions;
import ppc.utils;

import std.file;
import std.stdio;

/**
	PPCoHead Header Name
*/
public static ubyte[] ContentHeader() {
	return [0x50, 0x50, 0x43, 0x6f, 0x48, 0x65, 0x61, 0x64];
}

public enum TypeId : ubyte {
	Texture2D,
	Texture3D,
	Model,
	Mesh,
	Audio,
	Shader,
	Dictionary,
	Data,
	Raw
}

public class Content {
	/**
		The data used to construct a higher level content type.
	*/
	public ubyte[] Data;
	
	/**
		The type id of the content.
	*/
	public ubyte Type;

	/**
		ubyte representation of the type.
	*/
	public TypeId TypeID() { return cast(TypeId) Type; }

	/**
		Construct a raw content class.
	*/
	this(ubyte id, ubyte[] data) {
		this.Type = id;
		this.Data = data;
	}

	/**
		Construct a raw content class.
	*/
	this(TypeId id, ubyte[] data) {
		this.Type = cast(ubyte)id;
		this.Data = data;
	}

	/**
		Saves the content to disk.
	*/
	public void Save(string name) {
		File f = File(name, "w+");
		f.rawWrite(CreateRaw());
		f.close();
	}

	/**
		Turn the Content class into a file-writable byte array.
	*/
	public ubyte[] CreateRaw() {
		ubyte[] ts = ContentHeader;
		ts.length += 1;
		ts[ts.length-1] = this.TypeID;
		return Combine(ts, this.Data);
	}
}

public class BaseContent {
	protected Content Parent;
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
			data = Combine(data, buff);
		}
		f.close();
		return new Content(cast(TypeId)tyid[0], data);
	}

	public static Image LoadImage(string file) {
		return new Image(LoadRaw(file));
	}
}

public class ContentConverter {
	public static void ConvertImage(string input, string output) {
		Image img = ConvertImage(input);
		img.Save(output, "png");
	}
	
	public static Image ConvertImage(string input) {
		File fr = File(input);
		ubyte[] frd;
		foreach(ubyte[] chunk; fr.byChunk(4096)) {
			frd = Combine(frd, chunk);
		}
		fr.close();
		Content t = new Content(TypeId.Texture2D, frd);
		Image img = new Image(t);
		return img;
	}

	public static void ConvertToFile(string input, string output) {
		if (is_ext(input, "png") || is_ext(input, "jpg") || is_ext(input, "tga")) {
			ConvertImage(input, output);
			return;
		}
		throw new Exception("Unsupported file format");
	}

	private static bool is_ext(string input, string ext) {
		return input[input.length-3..input.length] == ext;
	}
}