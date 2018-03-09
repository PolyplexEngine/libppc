module ppc.image;
import ppc;
import imageformats;

class Image : BaseContent {
	public long Width;
	public long Height;
	public ubyte[] Colors;

	this(Content base) {
		this.Parent = base;
		IFImage im = read_image_from_mem(base.Data, ColFmt.RGBA);
		this.Width = im.w;
		this.Height = im.h;
		this.Colors = im.pixels;
	}

	public void Save(string name, string extension) {
		ubyte[] data = pp_write_img(extension);
		this.Parent.Data = data;
		this.Parent.Save(name);
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