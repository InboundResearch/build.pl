#include    "ReferenceCountedObject.h"

#pragma once

// a smart pointer wrapper to a reference counted class
template <class aType>
class PtrTo {
    private:
        aType* ptrToType;

        static void addRefToPtr (ReferenceCountedObject* ptr) {
            if (ptr) {
                ptr->addRef ();
            }
        }

        static void removeRefFromPtr (ReferenceCountedObject* ptr) {
            if (ptr and (ptr->removeRef () == 0)) {
                delete ptr;
            }
        }

    public:
        PtrTo () : ptrToType (0) {
        }

        PtrTo (aType* ptr) : ptrToType (ptr) {
            addRefToPtr (ptrToType);
        }

        PtrTo (const aType* ptr) : ptrToType (const_cast<aType*> (ptr)) {
            addRefToPtr (ptrToType);
        }

        PtrTo (const PtrTo<aType>& ptr) : ptrToType (ptr.ptrToType) {
            addRefToPtr (ptrToType);
        }

        // do not subclass this template type, use composition or aggregation instead
        ~PtrTo (void) {
            removeRefFromPtr (ptrToType);
            ptrToType = 0;
        }

        const aType* getPtr () const {
            return ptrToType;
        }

        const aType& operator * () const {
            return *ptrToType;
        }

        const aType* operator -> () const {
            return ptrToType;
        }

        aType* getPtr () {
            return ptrToType;
        }

        aType& operator * () {
            return *ptrToType;
        }

        aType* operator -> () {
            return ptrToType;
        }

        operator const aType* () const {
            return ptrToType;
        }

        PtrTo<aType>& operator = (aType* ptr) {
            addRefToPtr (ptr);
            removeRefFromPtr (ptrToType);
            ptrToType = ptr;
            return *this;
        }

        PtrTo<aType>& operator = (const PtrTo<aType>& ptr) {
            addRefToPtr (ptr.ptrToType);
            removeRefFromPtr (ptrToType);
            ptrToType = ptr.ptrToType;
            return *this;
        }

        bool operator == (const aType* ptr) {
            return ptrToType == ptr;
        }

        bool operator != (const aType* ptr) {
            return ptrToType != ptr;
        }

        bool isUnique () const {
            // a null pointer is always unique
            return (ptrToType) ? (ptrToType->getReferenceCount () == 1) : true;
        }

        void makeUnique () {
            if (not isUnique ()) {
                aType* ptr = new aType (*ptrToType);
                addRefToPtr (ptr);
                removeRefFromPtr (ptrToType);
                ptrToType = ptr;
            }
        }
};

// a macro to help with defining classes derived from ReferenceCountedObject and the associated
// pointer types - a forward declaration and then the beginning of the class declaration
#define MAKE_PTR_TO_SUB(aType, derivedFromType) class aType; typedef PtrTo<aType> PtrTo ## aType; class aType : public derivedFromType
#define MAKE_PTR_TO(aType) MAKE_PTR_TO_SUB(aType, ReferenceCountedObject)

// support polymorphic casting up
template<typename TypeX, typename TypeY>
const PtrTo<TypeX> ptr_upcast (const PtrTo<TypeY>& ptrToY) {
    return PtrTo<TypeX> (static_cast<const TypeX*> (ptrToY.getPtr ()));
}

template<typename TypeX, typename TypeY>
PtrTo<TypeX> ptr_upcast (PtrTo<TypeY>& ptrToY) {
    return PtrTo<TypeX> (static_cast<TypeX*> (ptrToY.getPtr ()));
}

// support polymorphic casting down
template<typename TypeX, typename TypeY>
const PtrTo<TypeX> ptr_downcast (const PtrTo<TypeY>& ptrToY) {
    return PtrTo<TypeX> (dynamic_cast<const TypeX*> (ptrToY.getPtr ()));
}

template<typename TypeX, typename TypeY>
PtrTo<TypeX> ptr_downcast (PtrTo<TypeY>& ptrToY) {
    return PtrTo<TypeX> (dynamic_cast<TypeX*> (ptrToY.getPtr ()));
}
