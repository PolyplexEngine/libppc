module ppc.backend.loaders.font;
// public import ppc.backend.loaders.font.freetype;
import ppc.backend.ft;

struct GlyphPosition {
    size_t x;
    size_t y;
}


struct FontRange {
    size_t start;
    size_t end;
}

struct FontDescription {
    /++
        Width of a character
    +/
    size_t width;

    /++
        Height of a character
    +/
    size_t height;

    /++
        Range of characters to pack
    +/
    FontRange characters = FontRange(32, 128);
}





/++
    A canvas of 8-bit colored glyphs
+/
// class GlyphCanvas!(size_t width, size_t height) {
// private:
//     size_t placementX;
//     size_t placementY;

// public:
//     const size_t WIDTH = width;
//     const size_t HEIGHT = height;

//     /// the canvas
//     ubyte[WIDTH*4][HEIGHT] canvas;

//     void placeGlyphAt(Glyph* glyph, GlyphPosition pos) {
//         ubyte[] pixelBuffer = glyph.getPixels();
//         foreach(x; 0..glyph.getPixelWidth()) {
//             uint ex = (pos.x+x)*4;
//             foreach(y; 0..glyph.getPixelHeight()) {
//                 ubyte pixel = pixelBuffer[(x*y)+x];

//                 uint exy = (ex*(pos.y+y))+ex;
//                 (cast(ubyte[])canvas)[exy..exy+4] = [pixel, pixel, pixel, 255];
//             }
//         }
//     }

//     bool canPlaceGlyph(size_t width, size_t height) {
//         return (placementX+width < WIDTH && placementY+height < HEIGHT);
//     }

//     // GlyphPosition placeGlyph(ubyte* glyphData, size_t width, size_t height) {
//     //     GlyphPosition position = GlyphPosition(placementX, placementY);
//     //     if (!canPlaceGlyph(width, height) && (width == MaxCanvasSize || height == MaxCanvasSize)) return GlyphPosition(-1, -1);
//     //     foreach(y; 0..width) {
//     //         foreach(x; 0..height) {
//     //             size_t pixelArrPos = (x/width)+(x%width);
//     //             canvas[placementX+x][placementY+y] = glyphData[pixelArrPos];
//     //         }
//     //     }
//     //     placementX += width;
//     //     placementX += height;
//     //     return position;
//     // }
// }

// struct GlyphInfo {
//     /// The canvas the glyph refers to
//     GlyphCanvas* canvas;

//     /// the glyph X position in canvas
//     size_t x;

//     /// the glyph Y position in canvas
//     size_t y;

//     /// the glyph width in canvas
//     size_t width;

//     /// the glyph height in canvas
//     size_t height;

//     /// How far inside the glyph texture that the glyph starts at
//     ptrdiff_t bearingX;

//     /// How far inside the glyph texture that the glyph starts at
//     ptrdiff_t bearingY;
    
//     /// How many pixels between this and the next glyph
//     size_t advance;
// }