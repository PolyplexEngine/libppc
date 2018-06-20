module ppc;
public import ppc.image;
public import ppc.bundle;
public import ppc.shader;
public import ppc.audio;

public import ppc.exceptions;
import ppc.utils;

import std.file;
import std.stdio;
import std.conv;
import std.bitmanip;

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
	Texture2D = 0,
	Bundle = 1,
	Script = 2,
	TextureList = 3,
	Model = 4,
	Mesh = 5,
	Audio = 6,
	Sample = 7,
	Shader = 8,
	Dictionary = 9,
	Data = 10,
	Raw = 11
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
		The name of the content.
	*/
	public string Name;

	/**
		ubyte representation of the type.
	*/
	public TypeId TypeID() { return cast(TypeId) Type; }

	/**
		Constructs content type from data.
	*/
	public this(TypeId type) {
		this.Type = type;
		this.data = [];
	}

	/**
		Constructs content type from data.
	*/
	public this(TypeId type, string name) {
		this.Type = type;
		this.Name = name;
		this.data = [];
	}

	/**
		Constructs content type from data.
	*/
	public this(ubyte[] data, bool convert = false) {
		if (convert) this.ConvertFull(data, 0);
		else this.LoadFull(data);
	}

	/**
		Loads input bytes into this type of content.
	*/
	public abstract void Load(ubyte[] data);

	public void LoadFull(ubyte[] data) {
		this.Type = data[0];
		int name_len = bigEndianToNative!int(data[1..5]);

		this.Name = cast(string)data[5..5+name_len];
		this.Load(data[5+name_len..$]);
	}

	/**
		Converts input bytes into this type of content.
	*/
	protected abstract void Convert(ubyte[] data, ubyte type);

	public void ConvertFull(ubyte[] data, ubyte type) {
		this.Type = type;
		int name_len = bigEndianToNative!int(data[1..5]);
		this.Name = cast(string)data[5..5+name_len];

		ubyte[] d = data[5+name_len..$];
		this.Convert(d, type);
	}

	/**
		Returns an ubyte array of the compiled representation of the content.
	*/
	protected abstract ubyte[] Compile();

	public ubyte[] CompileFull() {
		auto n = cast(ubyte[])this.Name;
		return [this.Type] ~ nativeToBigEndian(cast(int)n.length) ~ n ~ Compile();
	}
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
		ubyte[4] author_len = nativeToBigEndian(cast(int)author.length);

		ubyte[] msg = cast(ubyte[])Message;
		ubyte[4] msg_len = nativeToBigEndian(cast(int)msg.length);
		
		return author_len ~ author ~ msg_len ~ msg ~ [cast(ubyte)License];
	}

	public this() {
		this.Author = "Nobody";
		this.License = ContentLicense.Propriatary;
		this.Message = "<Insert Message Here>";
	}

	public static ContentInfo FromBytes(ubyte[] data) {
		ContentInfo inf = new ContentInfo();
		//Author Length
		int author_len = bigEndianToNative!int(data[0..4]);

		//Message Length
		ubyte[4] msg_ba = data[4+author_len..4+author_len+4];
		int msg_len = bigEndianToNative!int(msg_ba);
		
		//Set Author, Message and License.
		inf.Author = cast(string)data[4..4+author_len];
		inf.Message = cast(string)data[4+author_len+4..4+author_len+4+msg_len];
		inf.License = cast(ContentLicense)data[$-1];
		return inf;
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

	this(FileTypeId type) {
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
	this(FileTypeId id, ubyte[] data) {
		this.Type = cast(ubyte)id;
		this.Data = from_file_data(data);
	}

	/**
		Saves the content to disk.
	*/
	public void Save(string name) {
		File f = File(name, "w+");
		f.rawWrite(Compile());
		f.close();
	}

	/**
		Turn the Content class into a file-writable byte array.
	*/
	public ubyte[] Compile() {
		// Info
		ubyte[] inf = this.Info.Bytes;
		ubyte[8] infl = nativeToBigEndian(inf.length);

		// Data
		ubyte[] dat = this.Data.CompileFull();

		return ContentHeader ~ [this.Type] ~ infl ~ inf ~ dat;
	}

	public static ContentFile ReadContentFile(ubyte[] data) {
		// TODO: Make a check for the content headers presence (PPCoHead)

		ContentFile cf = new ContentFile(cast(FileTypeId)data[ContentHeader.length]);

		// Data
		ubyte[] dat = data[ContentHeader.length+1..data.length];

		// Info Length
		long infl = bigEndianToNative!long(dat[0..8]);

		// Info
		cf.Info = ContentInfo.FromBytes(dat[8..8+infl]);

		//Data
		cf.Data = from_file_data(dat[8+infl..dat.length]);
		return cf;
	}
}

/**
	Adds a type to the type factory.
*/
public void AddFactory(ContentFactory fac) {
	factories[fac.Id.text] = fac;
}

private ContentFactory[string] factories;
private bool factories_setup = false;

/**
	Imports all of the factories needed to build types automagically.
*/
public void SetupBaseFactories() {
	factories_setup = true;
	AddFactory(new RawContentFactory());
	AddFactory(new ImageFactory());
	AddFactory(new BundleFactory());
	AddFactory(new ShaderFactory());
	AddFactory(new AudioFactory());
}

private Content from_file_data(ubyte[] data) {
	if (!factories_setup) SetupBaseFactories(); //throw new Exception("Base factories has not been set up, please run SetupBaseFactories();");
	if(factories[data[0].text] is null) throw new Exception("No content factory to handle type id " ~ data[0].text);
	return factories[data[0].text].Construct(data);
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
	public this(string name) {
		super(TypeId.Raw, name);
	}

	public this(ubyte[] b) {
		super(b);
	}

	public override void Convert(ubyte[] data, ubyte type) {
		this.data = data;
	}

	public override void Load(ubyte[] data) {
		this.data = data;
	}

	public override ubyte[] Compile() {
		return this.data;
	}
	
}

public class ContentManager {

	/**
		Load loads a content file (from memory)
	*/
	public static Content Load(ubyte[] data) {
		return from_file_data(data);
	}

	/**
		Load loads a content file.
	*/
	public static Content Load(string file) {
		File f = File(file);
		ubyte[] data;
		foreach(ubyte[] buff; f.byChunk(4096)) {
			data = Combine(data, buff);
		}

		ContentFile fl = ContentFile.ReadContentFile(data);
		f.close();
		return fl.Data;
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