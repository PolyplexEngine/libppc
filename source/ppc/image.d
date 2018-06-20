module ppc.image;
import ppc;
import imageformats;
import std.stdio;
import std.bitmanip;
import std.functional;

public class ImageFactory : ContentFactory {
	public this() {
		super(TypeId.Texture2D);
	}

	public override Content Construct(ubyte[] data) {
		return new Image(data);
	}
}

public enum ImageStorageType : ubyte {
	PNG,
	TGA,
	PPIMG
}

public class Image : Content {
	public long Width;
	public long Height;
	public ubyte[] Colors;
	public ImageStorageType Type;

	public this(string name) {
		super(TypeId.Texture2D, name);
	}

	this(ubyte[] data) {
		super(data);
	}

	public override void Convert(ubyte[] data, ubyte type) {
		IFImage im = read_image_from_mem(data);
		this.Width = im.w;
		this.Height = im.h;
		this.Colors = im.pixels;
	}

	public override void Load(ubyte[] data) {
		load_image(data);
	}

	public override ubyte[] Compile() {
		return pp_write_img("png");
	}

	public void SavePng(string name) {
		write_image(name~".png", this.Width, this.Height, this.Colors);
	}

	private void load_image(ubyte[] data) {
		this.Type = cast(ImageStorageType)data[0];
		if (this.Type == ImageStorageType.PPIMG) ppimg_load(data[1..$]);
		else if_load(data[1..$]);
	}

	private void ppimg_load(ubyte[] data) {
		int w = bigEndianToNative!int(data[0..4]);
		int h = bigEndianToNative!int(data[4..8]);
		this.Colors = data[8..$];
		this.Width = cast(long)w;
		this.Height = cast(long)h;
	}

	private void if_load(ubyte[] data) {
		IFImage im = read_image_from_mem(data, ColFmt.RGBA);
		this.Width = im.w;
		this.Height = im.h;
		this.Colors = im.pixels;
	}

	private void create_ppimg(Writer w, long width, long height, in ubyte[] colors, long d)  {
		w.rawWrite(nativeToBigEndian(cast(int)width));
		w.rawWrite(nativeToBigEndian(cast(int)height));
		w.rawWrite(colors);
	}

	private void create_png(Writer w, long width, long height, in ubyte[] colors, long d) {
		import imageformats.png;
		w.rawWrite(write_png_to_mem(width, height, colors, d));
	}

	private void create_tga(Writer w, long width, long height, in ubyte[] colors, long d) {
		import imageformats.tga;
		w.rawWrite(write_tga_to_mem(width, height, colors, d));
	}

	private ubyte[] pp_write_img(string ext) {
		scope writer = new MemWriter();
		writer.rawWrite([this.Type]);
		if (ext == "png") create_png(writer, this.Width, this.Height, this.Colors, 0);
		else if (ext == "tga") create_tga(writer, this.Width, this.Height, this.Colors, 0);
		else if (ext == "ppimg") create_ppimg(writer, this.Width, this.Height, this.Colors, 0);
		else throw new Exception("Unknown format!");
		return writer.result;
	}
}