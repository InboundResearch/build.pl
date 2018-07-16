#include    "PtrTo.h"

#pragma once

// RawText is generally presumed to be a buffer containing a valid UTF-8 encoding of text. As such,
// no wide-char support is provided, nor is there a direct indexing capability. the user must read
// the text buffer as a stream text as a stream. NOTE: this means that count and length might be two
// different things...
MAKE_PTR_TO(RawText) {
    private:
        uint capacity;
        uint length;
        char bytes[1];

        // we will use capacities that are powers of 2 in size to make growing strings logarithmic
        // in time complexity, but after a certain size it's probably better to grow incrementally.
        enum { MAX_CAPACITY = 16384 };

        // an empty string is generally useful, but we don't want lots of them running around
        static PtrToRawText empty;

        static uint mapCapacity (uint capacity) {
            if (capacity < MAX_CAPACITY) {
                // bump capacity to the next power of 2 above it
                ulong bitsNeeded = static_cast<ulong> (ceil (log2 (capacity)));
                capacity = 1 << bitsNeeded;
            } else {
                // make the size be the next multiple of MAX_CAPACITY
                capacity = ((capacity / MAX_CAPACITY) + 1) * MAX_CAPACITY;
            }
            return capacity;
        }

        // capacity is always one less than the total capacity, so there is always room to include
        // a null terminator for the string
        RawText (uint _capacity) : capacity (_capacity), length (0) {
            bytes[0] = 0;
        }

        RawText (uint _capacity, const char* source, uint sourceLength) : capacity (_capacity), length (sourceLength) {
            set (source, sourceLength);
        }

        // we want to allocate RawText objects on 16-byte memory boundaries for performance, so this
        // structure gives us a tool to do that
        struct BlockType { byte a[16]; };

        // function to encapsulate making the raw text pointer, using an already mapped capacity
        static void* makeRawTextPtr (uint capacity) {
            // we want to allocate RawText objects on 16-byte memory boundaries for performance
            uint totalAlloc = sizeof (RawText) + capacity;
            uint blocksToAlloc = (totalAlloc / sizeof(BlockType)) + ((totalAlloc % sizeof(BlockType)) ? 1 : 0);
            return new BlockType[blocksToAlloc];
        }

    public:
        static PtrToRawText make (uint capacity) {
            capacity = mapCapacity (capacity);
            return new (makeRawTextPtr (capacity)) RawText (capacity);
        }

        static PtrToRawText make (uint capacity, const char* source, uint sourceLength) {
            capacity = mapCapacity (capacity);
            return new (makeRawTextPtr (capacity)) RawText (capacity, source, sourceLength);
        }

        static PtrToRawText make (const char* source, uint sourceLength) {
            return make (sourceLength, source, sourceLength);
        }

        ~RawText () {}

        void operator delete (void* ptr) {
            // the memory was allocated using the new byte[] method
            delete[] reinterpret_cast<BlockType*> (ptr);
        }

        bool set (const char* source, uint sourceLength) {
            if (sourceLength <= capacity) {
                memcpy (&bytes[0], source, sourceLength);
                length = sourceLength;
                bytes[length] = 0;
                return true;
            }
            return false;
        }

        /*
        bool set (const char* source) {
            return set (source, strlen (source));
        }
        */

        char* get () {
            return bytes;
        }

        const char* get () const {
            return bytes;
        }

        uint getLength () const {
            return length;
        }

        uint getCapacity () const {
            return capacity;
        }

        int compare (const char* source, uint sourceLength) const {
            uint minLength = min (length, sourceLength);
            int comparison = memcmp (bytes, source, minLength);
            if ((comparison != 0) or (length == sourceLength)) {
                return comparison;
            } else {
                return length - sourceLength;
            }
        }

        /*
        int compare (const RawText* rawText) {
            return compare (rawText->bytes, rawText->length);
        }
        */

        bool append (const char* source, uint sourceLength) {
            if ((length + sourceLength) <= capacity) {
                memcpy (&bytes[length], source, sourceLength);
                length += sourceLength;
                bytes[length] = 0;
                return true;
            }
            return false;
        }

        /*
        bool append (const RawText* rawText) {
            return append (rawText->bytes, rawText->length);
        }
        */

        /*
        bool append (const char* source) {
            return append (source, strlen (source));
        }
        */

        static PtrToRawText getEmpty () {
            if (! empty) {
                empty = new RawText (0);
            }
            return empty;
        }
};
