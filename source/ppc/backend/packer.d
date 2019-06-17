module ppc.backend.packer;
import ppc.backend;

/++
    Node used in generating a texture.
+/
struct FNode {
    this(PVector origin, PVector size) {
        this.origin = origin;
        this.size = size;
        this.empty = true;
        this.left = null;
        this.right = null;
    }

    /// Origin of texture
    PVector origin;
    
    /// Size of texture
    PVector size;

    /// Wether the node is taken
    bool empty = true;

    /// Node branch left
    FNode* left;

    /// Node branch right
    FNode* right;
}

/++
    Packing algorithm implementation
+/
class TexturePacker {
    /// Size of texture so far
    PSize textureSize;

    /// The output buffer
    ubyte[] buffer;

    /// The root node for the packing
    FNode* root;

    this() {
        root = new FNode(PVector(0, 0), PVector(int.max, int.max));
        textureSize = PSize(1024, 1024);
        buffer = new ubyte[](1024*1024);
    }

    /++
        Packing algorithm

        Based on the packing algorithm from straypixels.net
        https://straypixels.net/texture-packing-for-fonts/
    +/
    FNode* pack(FNode* node, PVector size) {
        if (!node.empty) {
            return null;
        } else if (node.left !is null && node.right !is null) {
            FNode* rval = pack(node.left, size);
            return rval !is null ? rval : pack(node.right, size);
        } else {
            PVector realSize = PVector(node.size.x, node.size.y);

            // Calculate actual size if on boundary
            if (node.origin.x + node.size.x == int.max) {
                realSize.x = textureSize.width-node.origin.x;
            }
            if (node.origin.y + node.size.y == int.max) {
                realSize.y = textureSize.height-node.origin.y;
            }

            
            if (node.size.x == size.x && node.size.y == size.y) {
                // Size is perfect, pack here
                node.empty = false;
                return node;
            }

            // Not big enough?
            if (realSize.x < size.x || realSize.y < size.y) {
                return null;
            }

            FNode* left;
            FNode* right;

            PVector remain = PVector(realSize.x - size.x, realSize.y - size.y);
            bool vsplit = remain.x < remain.y;
            if (remain.x == 0 && remain.y == 0) {
                // Edgecase, hitting border of texture atlas perfectly, split at border instead
                if (node.size.x > node.size.y) vsplit = false;
                else vsplit = true;
            }

            if (vsplit) {
                left = new FNode(node.origin, PVector(node.size.x, size.y));
                right = new FNode(  PVector(node.origin.x, node.origin.y + size.y), 
                                    PVector(node.size.x, node.size.y - size.y));
            } else {
                left = new FNode(node.origin, PVector(size.x, node.size.y));
                right = new FNode(  PVector(node.origin.x + size.x, node.origin.y), 
                                    PVector(node.size.x - size.x, node.size.y));
            }

            node.left = left;
            node.right = right;
            return pack(node.left, size);
        }
    }

    void resizeBuffer(PSize newSize) {
        ubyte[] newBuffer = new ubyte[](newSize.width*newSize.height);
        foreach(y; 0..textureSize.height) {
            foreach(x; 0..textureSize.width) {
                newBuffer[y * newSize.width + x] = buffer[y * textureSize.width + x];
            }
        }

        textureSize = newSize;
        buffer = newBuffer;
    }

    /++
        Pack a texture

        Returns the position that the texture can be found at.
    +/
    PVector packTexture(ubyte[] textureBuffer, PVector size) {
        FNode* node = pack(root, size);
        if (node == null) {
            this.resizeBuffer(PSize(textureSize.width*2, textureSize.height*2));
            node = pack(root, size);

            assert(node !is null, "Was unable to pack texture!");
        }

        assert(size.x == node.size.x, "Sizes did not match! This is as bug in the texture packer.");
        assert(size.y == node.size.y, "Sizes did not match! This is as bug in the texture packer.");

        foreach (ly; 0..size.y) {
            foreach(lx; 0..size.x) {
                int y = cast(int)node.origin.y + cast(int)ly;
                int x = cast(int)node.origin.x + cast(int)lx;
                this.buffer[y * textureSize.width + x] = textureBuffer[ly * size.x + lx];
            }
        }

        return node.origin;
    }
}