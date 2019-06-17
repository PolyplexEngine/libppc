module ppc.backend.loaders.font.bitmap;
import ppc.backend.loaders.font;
import ppc.backend.packer;
import ppc.backend.ft;

class BitmapFont {
private:
public:
    ubyte[] bitmapTexture;
    GlyphInfo[char] glyphs;

}

/++
    Takes a font description and builds a bitmap font out of it via FreeType
+/
BitmapFont fromFontDescription(FontDescription description) {
    BitmapFont bmf = new BitmapFont();
    TexturePacker packer = new TexturePacker();
    FreeType ft = new FreeType();
    FontFace face = ft.open(description.font, description.faceIndex);
    face.setPixelSizes(description.width, description.height);

    foreach(series; description.characters) {
        foreach(i; series.range.start..series.range.end) {
            char ch = cast(char)i;

            // If we already have packed that glyph, skip packing it again.
            if (ch in bmf.glyphs) continue;

            // Get character and pack it in to the texture
            Glyph* glyph = face.getChar(ch);

            GlyphInfo info;
            info.size = glyph.getSize();
            info.bearing = glyph.getBearing();
            info.advance = glyph.getAdvance();
            info.origin = packer.packTexture(glyph.getPixels(), glyph.getDataSize());
            bmf.glyphs[ch] = info;
        }
    }
    bmf.bitmapTexture[] = packer.buffer;
    return bmf;
}