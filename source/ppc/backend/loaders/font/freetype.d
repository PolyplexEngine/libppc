/**
Copyright (c) 2018 Clipsey (clipseypone@gmail.com)

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
*/
module ppc.backend.loaders.font.freetype;
import ppc.backend.loaders.font;
import ppc.backend.cfile;
import bindbc.freetype;

class FreeTypeSystem : FontSystem {
private:
    ubyte[] ftFont;
    FT_Face ftFace;

    GlyphCanvas[] canvases;
    GlyphInfo[char] glyphs;

    void tryPlaceGlyph(char glyph) {
        FT_Load_Char(ftFace, glyph, FT_LOAD_RENDER);
        foreach(i, canvas; canvases) {
            if (canvas.canPlaceGlyph(ftFace.glyph.bitmap.width, ftFace.glyph.bitmap.rows)) {
                size_t width = ftFace.glyph.bitmap.width;
                size_t height = ftFace.glyph.bitmap.rows;
                GlyphPosition pos = canvas.placeGlyph(ftFace.glyph.bitmap.buffer, width, height);
                glyphs[glyph] = GlyphInfo(&canvases[i], pos.x, pos.y, width, height, ftFace.glyph.bitmap_left, ftFace.glyph.bitmap_top, ftFace.glyph.advance.x);
                return;
            }
        }

        // Add new canvas and try rendering glyph again.
        canvases ~= GlyphCanvas(MaxCanvasSize);
        tryPlaceGlyph(glyph);   
    }

public:
    this(string freetypeFont, size_t glyphSize) {
        MemFile mf = loadFile(freetypeFont);
        this(mf.toArray(), glyphSize);
    }

    this(ubyte[] freetypeFont, size_t glyphSize) {
        super(freetypeFont, glyphSize);
        ftFont = freetypeFont;
        FT_New_Memory_Face(ftLib, ftFont.ptr, ftFont.length, 0, &ftFace);
        FT_Set_Pixel_Sizes(ftFace, 0u, cast(uint)glyphSize);
    }

    override GlyphInfo getGlyph(char ch) {
        if (ch !in glyphs) {
            tryPlaceGlyph(ch);
        }
        return glyphs[ch];
    }
}

private __gshared static FT_Library ftLib;

shared static this() {
    auto ret = loadFreeType();
    switch(ret) {
        case (FTSupport.noLibrary):
            throw new Exception("FreeType was not found, please install freetype.");
        case (FTSupport.badLibrary):
            throw new Exception("Failed to load some symbols, the application might crash!");
        default: break;
    }

    /// Initialize freetype
    FT_Init_FreeType(&ftLib);
}