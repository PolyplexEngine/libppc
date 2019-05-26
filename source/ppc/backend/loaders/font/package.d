module ppc.backend.loaders.font;
public import ppc.backend.loaders.font.freetype;

/// The maximum size the canvas can be before it gets split.
version (LowMem) {
    // 512x512 for low memory mode
    enum MaxCanvasSize = 512;
} else {
    enum MaxCanvasSize = 2048;
}

struct GlyphPosition {
    ptrdiff_t x;
    ptrdiff_t y;
}

/++
    A canvas of 8-bit colored glyphs
+/
struct GlyphCanvas {
private:
    size_t placementX;
    size_t placementY;

public:
    @property size_t width() {
        return canvas[0].length;
    }

    @property size_t height() {
        return canvas.length;
    }

    /// the canvas
    ubyte[][] canvas;

    /// The constructor
    this(size_t size = MaxCanvasSize) {
        canvas = new ubyte[][](size, size);
    }

    bool canPlaceGlyph(size_t width, size_t height) {
        return (placementX+width < canvas[0].length && placementY+height < canvas.length);
    }

    GlyphPosition placeGlyph(ubyte* glyphData, size_t width, size_t height) {
        GlyphPosition position = GlyphPosition(placementX, placementY);
        if (!canPlaceGlyph(width, height) && (width == MaxCanvasSize || height == MaxCanvasSize)) return GlyphPosition(-1, -1);
        foreach(y; 0..width) {
            foreach(x; 0..height) {
                size_t pixelArrPos = (x/width)+(x%width);
                canvas[placementX+x][placementY+y] = glyphData[pixelArrPos];
            }
        }
        placementX += width;
        placementX += height;
        return position;
    }
}

struct GlyphInfo {
    /// The canvas the glyph refers to
    GlyphCanvas* canvas;

    /// the glyph X position in canvas
    size_t x;

    /// the glyph Y position in canvas
    size_t y;

    /// the glyph width in canvas
    size_t width;

    /// the glyph height in canvas
    size_t height;

    /// How far inside the glyph texture that the glyph starts at
    ptrdiff_t bearingX;

    /// How far inside the glyph texture that the glyph starts at
    ptrdiff_t bearingY;
    
    /// How many pixels between this and the next glyph
    size_t advance;
}

class FontSystem {
protected:
    size_t glyphSize;

public:
    this(ubyte[] fFile, size_t size) {
        glyphSize = size;
    }

    this(string fFile, size_t size) {
        glyphSize = size;
    }

    abstract GlyphInfo getGlyph(char ch);
}