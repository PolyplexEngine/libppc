module ppc.backend.ft;
import bindbc.freetype;
import std.string;
import ppc.backend.cfile;
import ppc.backend;

/++
    The format of a Glyph
    Usually the format is Bitmap.
+/
enum GlyphFormat {
    Bitmap = FT_GLYPH_FORMAT_BITMAP,
    Composite = FT_GLYPH_FORMAT_COMPOSITE,
    None = FT_GLYPH_FORMAT_NONE,
    Outline = FT_GLYPH_FORMAT_OUTLINE,
    Plotter = FT_GLYPH_FORMAT_PLOTTER
}

/++
    The type of pixels the glyph contains
+/
enum GlyphPixels {
    None = FT_PIXEL_MODE_NONE,
    Mono = FT_PIXEL_MODE_MONO,
    Gray = FT_PIXEL_MODE_GRAY,
    Gray2 = FT_PIXEL_MODE_GRAY2,
    Gray4 = FT_PIXEL_MODE_GRAY4,
    LCD = FT_PIXEL_MODE_LCD,
    LCDV = FT_PIXEL_MODE_LCD_V,
    Max = FT_PIXEL_MODE_MAX
}

alias FTVector = PVector;

/++
    A glyph is a single character
+/
struct Glyph {
private:
    char represents;
    ubyte[] bitmap;

    FTVector size;
    FTVector bufferSize;

    uint grays;

    FTVector advance;
    FTVector bearing;

    GlyphPixels pixels;
    GlyphFormat fmt;

public:

    /++
        Constructs a new glyph
    +/
    this(FT_GlyphSlot slot, char rep) {
        this.represents = rep;

        size = FTVector(slot.bitmap.width, slot.bitmap.rows);
        bufferSize = FTVector(slot.bitmap.pitch, slot.bitmap.rows);
        grays = slot.bitmap.num_grays;
        pixels = cast(GlyphPixels)slot.bitmap.pixel_mode;
        fmt = cast(GlyphFormat)slot.format;

        advance = FTVector(slot.advance.x, slot.advance.y);
        bearing = FTVector(slot.bitmap_left, slot.bitmap_top);


        // Copy pixels in to the bitmap this glyph represents
        size_t toAllocate = slot.bitmap.pitch*slot.bitmap.rows;
        bitmap = new ubyte[](toAllocate);
        bitmap[] = slot.bitmap.buffer[0..toAllocate];
    }

    /++
        Gets advance (how much to offset position after rendering this character)
    +/
    FTVector getAdvance() {
        return advance;
    }

    /++
        Gets the bearing (offset from origin)
    +/
    FTVector getBearing() {
        return bearing;
    }

    /++
        Gets the size of the glyph in pixels
    +/
    PVector getSize() {
        return size;
    }

    /++
        Gets the size of the glyph in bytes on each axis
    +/
    PVector getDataSize() {
        return bufferSize;
    }

    /++
        Get number of gray levels used
    +/
    uint getGrays() {
        return grays;
    }

    /++
        Gets the pixel mode of the glyph.
    +/
    GlyphPixels getPixelMode() {
        return pixels;
    }

    ubyte[] getPixels() {
        return bitmap;
    }

    /++
        Gets the stored buffer of the glyph
    +/
    ubyte* getBuffer() {
        return bitmap.ptr;
    }

    /++
        Gets the size in byte of the stored glyph pixel buffer
    +/
    size_t getBufferSize() {
        return bitmap.length;
    }
}

/++
    Load options for glpyhs
+/
enum FTLoadOption : uint {
    Default = FT_LOAD_DEFAULT,

    ComputeMetrics = FT_LOAD_COMPUTE_METRICS,
    LinearDesign = FT_LOAD_LINEAR_DESIGN,
    CropBitmap = FT_LOAD_CROP_BITMAP,
    ForceAutohint = FT_LOAD_FORCE_AUTOHINT,

    IgnoreGlobalAdvanceWidth = FT_LOAD_IGNORE_GLOBAL_ADVANCE_WIDTH,
    IgnoreTransform = FT_LOAD_IGNORE_TRANSFORM,

    Color = FT_LOAD_COLOR,
    Monochrome = FT_LOAD_MONOCHROME,
    Render = FT_LOAD_RENDER
}

/++
    A font face
+/
class FontFace {
private:
    FreeType parent;
    FT_Face face;

public:
    ~this() {
        // HACK: This should really be cleaned up, but it causes crashes rn.
        // if (face !is null) {
        //     FT_Done_Face(face);
        // }
    }

    this(FreeType ft, string fontName, uint faceIndex = 0) {
        this.parent = ft;
        FT_New_Face(parent.lib, fontName.toStringz, faceIndex, &face);
        if (face is null) throw new Exception("Unable to find font "~fontName~"! (Make sure to use full paths)");
    }

    this(FreeType ft, ubyte[] fontData, uint faceIndex = 0) {
        this.parent = ft;
        FT_New_Memory_Face(parent.lib, fontData.ptr, cast(int)fontData.length, cast(int)faceIndex, &face);
    }

    void setPixelSizes(size_t width, size_t height) {
        FT_Set_Pixel_Sizes(face, cast(uint)width, cast(uint)height);
    }

    Glyph* getChar(char c, FTLoadOption options = FTLoadOption.Render) {
        FT_Load_Char(face, c, options);
        // TODO: Allow conversion
        //FT_Render_Glyph(face.glyph, FT_RENDER_MODE_NORMAL);
        if (face.glyph is null) return null;
        return new Glyph(face.glyph, c);
    }
}

/++
    FreeType library
+/
class FreeType {
private:
    FT_Library lib;
    FontFace[] faces;

public:
    ~this() {
        destroy(faces);
        FT_Done_Library(lib);
    }

    this() {
        FT_Init_FreeType(&lib);
    }

    /++
        Opens a font from a file
    +/
    FontFace open(string file, uint faceIndex = 0) {
        faces ~= new FontFace(this, file, faceIndex);
        return faces[$-1];
    }

    /++
        Opens a font from a memory buffer
    +/
    FontFace open(ubyte[] file, uint faceIndex = 0) {
        faces ~= new FontFace(this, file, faceIndex);
        return faces[$-1];
    }

    /++
        Opens a font from a memfile buffer
    +/
    FontFace open(MemFile file, uint faceIndex = 0) {
        faces ~= new FontFace(this, file.arrayptr[0..file.length], faceIndex);
        return faces[$-1];
    }
}

void initFT() {
    auto ret = loadFreeType();
    switch(ret) {
        case (FTSupport.noLibrary):
            throw new Exception("FreeType was not found, please install freetype.");
        case (FTSupport.badLibrary):
            throw new Exception("Failed to load some symbols, the application might crash!");
        default: break;
    }
}
