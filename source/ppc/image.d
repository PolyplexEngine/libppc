module ppc.image;
import ppc;
import imageformats;
import std.stdio;

public class ImageFactory : ContentFactory {
	public this() {
		super(TypeId.Texture2D);
	}

	public override Content Construct(ubyte[] data) {
		return new Image(data);
	}
}

public class Image : Content {
	public long Width;
	public long Height;
	public ubyte[] Colors;

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

	private ubyte[] pp_write_img(string extr) {
		const(char)[] ext = extr;

		void function(Writer, long, long, in ubyte[], long) write_image;
		switch (ext) {
			case "png": write_image = &write_png; break;
			case "tga": write_image = &write_tga; break;
			case "bmp": write_image = &write_bmp; break;
			default: throw new ImageIOException("unknown image extension/type");
		}
		scope writer = new MemWriter();
		write_image(writer, this.Width, this.Height, this.Colors, 0);
		return writer.result;
	}
}