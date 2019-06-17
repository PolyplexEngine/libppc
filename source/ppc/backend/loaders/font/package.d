module ppc.backend.loaders.font;
public import ppc.backend.loaders.font.bitmap;
import ppc.backend.ft;
import vibe.data.serialization;
import ppc.backend;

class Font {
public:
    /++
        Size of atlas.
    +/
    PSize atlasSize;

    /++
        Returns reference to texture data
    +/
    abstract ref ubyte[] getTexture();
    
    /++
        Get GlyphInfo for character
    +/
    abstract GlyphInfo* opIndex(char c);

    /++
        Returns true if the graphics frontend should update the texture
    +/
    bool shouldUpdateTexture() {
        return false;
    }
}

struct FontRange {
    size_t start;
    size_t end;
}

struct CharRange {
    FontRange range;
}

struct FontDescription {
    /++
        The height of a character in pixels
    +/
    size_t size;

    /++
        The font file
    +/
    string font;

    /++
        Face Index, useful in some regions
    +/
    @optional
    uint faceIndex = 0;

    /++
        Range of characters to pack
    +/
    @optional
    CharRange[] characters = [CharRange(FontRange(32, 128))];
}

struct GlyphInfo {
    FTVector origin;
    FTVector size;

    FTVector advance;
    FTVector bearing;
}
