#include    "Types.h"

#pragma once

class ReferenceCountedObject
{
    public:
        ReferenceCountedObject (void){
            referenceCount = 0;
            #ifndef NDEBUG
            debugId = ++nextDebugId;
            #endif
        }

        ReferenceCountedObject (const ReferenceCountedObject& object){
            referenceCount = 0;
            #ifndef NDEBUG
            debugId = ++nextDebugId;
            #endif
        }

virtual ~ReferenceCountedObject (void) {};

        void addRef (void){
            referenceCount++;
        }

        uint removeRef (void){
            return --referenceCount;
        }

        uint getReferenceCount (void) const{
            return referenceCount;
        }

    private:
        uint referenceCount;

        #ifndef NDEBUG
        uint debugId;
static  uint nextDebugId;
        #endif
};
