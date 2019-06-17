module ppc.backend.loaders.font;
// public import ppc.backend.loaders.font.freetype;
import ppc.backend.ft;

struct FontRange {
    size_t start;
    size_t end;
}

struct CharRange {
    FontRange range;
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
        The font file
    +/
    string font;

    /++
        Face Index, useful in some regions
    +/
    uint faceIndex = 0;

    /++
        Range of characters to pack
    +/
    CharRange[] characters = [CharRange(FontRange(32, 128))];
}

struct GlyphInfo {
    FTVector origin;
    FTVector size;

    FTVector advance;
    FTVector bearing;
}
