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

public enum ImageStorageType {
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

	public override void Convert(ubyte[] data) {
		IFImage im = read_image_from_mem(data, ColFmt.RGBA);
		this.Width = im.w;
		this.Height = im.h;
		this.Colors = im.pixels;
	}

	public override ubyte[] Compile() {
		return pp_write_img("png");
	}

	public void SavePng(string name) {
		write_image(name~".png", this.Width, this.Height, this.Colors);
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

	private ubyte[] pp_write_img(string extr) {
		const(char)[] ext = extr;
		scope writer = new MemWriter();
		if (ext == "png") create_png(writer, this.Width, this.Height, this.Colors, 0);
		else if (ext == "tga") create_tga(writer, this.Width, this.Height, this.Colors, 0);
		else if (ext == "ppimg") create_ppimg(writer, this.Width, this.Height, this.Colors, 0);
		else throw new Exception("Unknown format!");
		return writer.result;
	}
}