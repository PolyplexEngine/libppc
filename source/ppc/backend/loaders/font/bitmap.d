module ppc.backend.loaders.font.bitmap;
import ppc.backend.loaders.font;
import ppc.backend.packer;
import ppc.backend.cfile;
import ppc.backend.ft;
import ppc.backend;
import ppc.backend.signatures;

/++
    A font that uses a bitmap as texture.
+/
class BitmapFont : Font{
private:
    ubyte[] bitmapTexture;
    GlyphInfo*[char] glyphs;

public:
    override ref ubyte[] getTexture() {
        return bitmapTexture;
    }

    override GlyphInfo* opIndex(char c) {
        if (c !in glyphs) return null;
        return glyphs[c];
    }
}

ubyte[] saveBMF(BitmapFont font) {
    import msgpack : pack;
    return WritableFileSigs.FontBMF~pack(font);
}

BitmapFont loadBMF(MemFile file) {
    import msgpack : unpack;
    return unpack!BitmapFont(file.arrayptr[WritableFileSigs.FontBMF.length..file.length]);
}

/++
    Takes a font description and builds a bitmap font out of it via FreeType
+/
BitmapFont fromFontDescription(FontDescription description) {
    BitmapFont bmf = new BitmapFont();
    TexturePacker packer = new TexturePacker();
    FreeType ft = new FreeType();
    FontFace face = ft.open(description.font, description.faceIndex);
    face.setPixelSizes(0u, description.size);

    foreach(series; description.characters) {
        foreach(i; series.range.start..series.range.end) {
            char ch = cast(char)i;

            // If we already have packed that glyph, skip packing it again.
            if (ch in bmf.glyphs) continue;

            // Get character and pack it in to the texture
            Glyph* glyph = face.getChar(ch);
            PVector origin = packer.packTexture(glyph.getPixels(), glyph.getDataSize());
            GlyphInfo* info = new GlyphInfo(origin, glyph.getSize(), glyph.getAdvance(), glyph.getBearing());
            bmf.glyphs[ch] = info;
        }
    }
    bmf.bitmapTexture[] = packer.buffer;
    return bmf;
}