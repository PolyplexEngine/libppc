module ppc.backend.packer;
import ppc.backend;



class TexturePacker {
    struct FNode {
        PVector origin;
        PVector size;
        bool empty = true;

        FNode* left;
        FNode* right;
    }
    size_t MAX;
    PVector textureSize;

    /++
        Packing algorithm

        Based on the packing algorithm from straypixels.net
        https://straypixels.net/texture-packing-for-fonts/
    +/
    FNode* pack(FNode* node, PVector size) {
        if (!node.empty) {
            return null;
        } else if (node.left && node.right) {
            FNode* rval = pack(node.left, size);
            return rval !is null ? rval : pack(node.right, size);
        } else {
            PVector realSize = PVector(node.size.x, node.size.y);

            // Calculate actual size if on boundary
            if (node.origin.x + node.size.x == MAX) {
                realSize.x = textureSize.x-node.origin.x;
            }
            if (node.origin.y + node.size.y == MAX) {
                realSize.y = textureSize.y-node.origin.y;
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

    
}