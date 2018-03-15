module ppc;
public import ppc.image;
public import ppc.exceptions;
import ppc.utils;

import std.file;
import std.stdio;
import std.conv;

/**
	PPCoHead Header Name
*/
public static ubyte[] ContentHeader() {
	return [0x50, 0x50, 0x43, 0x6f, 0x48, 0x65, 0x61, 0x64];
}

public enum FileTypeId : ubyte {
	Content,
	Bundle,
	PlainText
}

public enum TypeId : ubyte {
	Bundle,
	Script,
	Texture2D,
	TextureList,
	Model,
	Mesh,
	Audio,
	Sample,
	Shader,
	Dictionary,
	Data,
	Raw
}

public abstract class ContentFactory {
	private ubyte id;

	/**
		Constructs a new factory.
	*/
	public this(ubyte id) {
		this.id = id;
	}

	/**
		Construct constructs a new content type.
	*/
	public abstract Content Construct(ubyte[] data);

	/**
		The ID representation of the content.
	*/
	public @property ubyte Id() { return this.id; }
}

/**
	Content is a basic content construct.
*/
public class Content {
	/**
		<Protected> data is the byte data the content is made out of.
	*/
	protected ubyte[] data;
		
	/**
		The type id of the content file.
	*/
	public ubyte Type;

	/**
		ubyte representation of the type.
	*/
	public TypeId TypeID() { return cast(TypeId) Type; }

	/**
		Constructs content type from data.
	*/
	public this(ubyte[] data) {
		this.Type = data[0];
		this.data = data[1..data.length];
	}

	/**
		Returns an ubyte array of the compiled representation of the content.
	*/
	public abstract ubyte[] Compile();
}

public class RawContentFactory : ContentFactory {
	public this() {
		super(TypeId.Raw);
	}

	public override Content Construct(ubyte[] data) {
		return new RawContent(data);
	}
}

public class RawContent : Content {
	public this(ubyte[] b) {
		super(b);
	}

	public override ubyte[] Compile() {
		ubyte[] data = new ubyte[this.data.length+1];
		data[0] = this.Type;
		for (int i = 1; i < data.length; i++)
			data[i] = this.data[i];
		return data;
	}
	
}

public enum ContentLicense : ubyte {
	Propriatary,
	MIT,
	GPL2,
	LGPL2,
	GPL3,
	LGPL3,
	CC,
	CC_BY_A,
	//TODO: Add more license types.
}

public class ContentInfo {

	/**
		The author.
	*/
	public string Author;

	/**
		The License.
	*/
	public ContentLicense License;

	/**
		A message left by its creator, usually for license text.
		But can be used to hide angry messages to people decompiling the content.
	*/
	public string Message;

	/**
		Binary representation of the content info header portion.
	*/
	public @property ubyte[] Bytes() {
		ubyte[] author = cast(ubyte[])Author;
		ubyte[] msg = cast(ubyte[])Message;
		ubyte[] data;
		data.length++;
		data[0] = License;
		for (int i = 0; i < author.length; i++) {
			data.length++;
			data[i+1] = author[i];
		}
		for (int i = 0; i < msg.length; i++) {
			data.length++;
			data[i+1+author.length] = msg[i];
		}
		return data;
	}	
}

/**
	ContentFile is a content file.
*/
public class ContentFile {
	/**
		The data used to construct a higher level content type.
	*/
	public Content Data;

	/**
		Header information for the content file.
	*/
	public ContentInfo Info;
	
	/**
		The type id of the content file.
	*/
	public ubyte Type;

	/**
		ubyte representation of the type.
	*/
	public FileTypeId TypeID() { return cast(FileTypeId) Type; }

	this(TypeId type) {
		this.Type = type;
	}

	/**
		Construct a raw content class.
	*/
	this(ubyte id, ubyte[] data) {
		this.Type = id;
		this.Data = from_file_data(data);
	}

	/**
		Construct a raw content class.
	*/
	this(TypeId id, ubyte[] data) {
		this.Type = cast(ubyte)id;
		this.Data = from_file_data(data);
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
		return Combine(ts, this.Data.Compile());
	}
}

public void AddFactory(ContentFactory fac) {
	factories[fac.Id] = fac;
}

private ContentFactory[ubyte] factories;

public void SetupBaseFactories() {
	AddFactory(new RawContentFactory());
	AddFactory(new ImageFactory());
}

private Content from_file_data(ubyte[] data) {
	if(factories[data[0]] is null) throw new Exception("No content factory to handle type id " ~ data[0].text);
	return factories[data[0]].Construct(data);
}

public class ContentFileLoader {

	public static Content Load(string file) {
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
		return from_file_data(data);
	}
	/*
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
	}*/
}
/*
public class ContentConverter {
	public static void ConvertImage(string input, string output) {
		Image img = ConvertImage(input);
		img.Compile();
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
}*/