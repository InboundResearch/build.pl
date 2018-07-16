#include "Test.h"
#include "PtrTo.h"

MAKE_PTR_TO(TestClass) {
    private:
        static set<void*> ptrs;

    public:
        TestClass () {}
        virtual ~TestClass () {}

        void* operator new (size_t size) {
            void* ptr = ::operator new (size);
            ptrs.insert(ptr);
            cerr << "Allocate ptr " << ptr << endl;
            return ptr;
        }

        void operator delete (void* ptr) {
            set<void*>::iterator it = ptrs.find (ptr);
            if (it != ptrs.end ()) {
                cerr << "Deallocate known ptr " << ptr << endl;
                ptrs.erase(it);
            } else {
                cerr << "Unknown ptr " << ptr << endl;
            }
            ::operator delete (ptr);
        }

        static void checkPtrs (uint expect = 0) {
            for (set<void*>::iterator it = ptrs.begin (); it != ptrs.end (); ++it) {
                cerr << "Known ptr " << *it << endl;
            }
            TEST_XY (ptrs.size(), expect);
        }
};

MAKE_PTR_TO_SUB (DerivedTestClass, TestClass) {
    public:
        DerivedTestClass () {}
        virtual ~DerivedTestClass () {}
};

set<void*> TestClass::ptrs;

// this function tests the copy-by-value semantics of the PtrTo class - which should be the
// normal usage when the callee will take ownership of the pointer - such as putting it into
// a data structure for later use
void testFunctionScope (PtrToTestClass ptrToTestClass, PtrToTestClass ptrToTestClassToo) {
    // two new copies of the pointer should have a ref count of 3, they should be ==, and
    // they should not be unique
    TEST_XY(ptrToTestClass->getReferenceCount(), 3);
    TEST_XY(ptrToTestClass, ptrToTestClassToo);
    TEST_XY(ptrToTestClass.isUnique(), false);

    // make one of the pointers unique, it's ref count should be 1, and the pointers
    // should be !=
    ptrToTestClass.makeUnique ();
    TEST_XY(ptrToTestClass->getReferenceCount(), 1);
    TEST_XYOP(ptrToTestClass, ptrToTestClassToo, !=);
}

// this function tests the copy-by-reference semantics of the PtrTo class, which should be the
// normal usage if the callee is not going to take ownership of the pointer
void testFunctionScopeRef (const PtrToTestClass& ptrToTestClass) {
    // this shouldn't create a new pointer object, so the ref count shouldn't change
    TEST_XY(ptrToTestClass->getReferenceCount(), 1);
}

// the PtrTo class should be a code-only wrapper on a normal pointer, so this test confirms that
// the size of the Ptrto is the same as the size of a bare pointer - this might change if the
// PtrTo class is modified to support derivation, which would add a virtual table pointer to the
// class that would substantially change performance
TEST_CASE(TestPtrTo0) {
    TEST_XY(sizeof(PtrToTestClass), sizeof(TestClass*));
}

TEST_CASE(TestPtrTo1) {
    // create a false scope so the pointer will go out of scope before the program closes
    if (1) {
        PtrToDerivedTestClass ptrToDerivedTestClass = new DerivedTestClass ();
        TEST_XY(ptrToDerivedTestClass->getReferenceCount(), 1);

        // a pointer to the object so we can check it after it has gone out of scope
        PtrToTestClass* atPtrTo;

        // create a scope...
        if (1) {
            PtrToTestClass ptrToTestClass = ptr_upcast<TestClass> (ptrToDerivedTestClass);
            TEST_XY(ptrToDerivedTestClass->getReferenceCount(), 2);
            TEST_XY(ptrToTestClass->getReferenceCount(), 2);

            // and try to downcast
            PtrToDerivedTestClass ptr3 = ptr_downcast<DerivedTestClass> (ptrToTestClass);
            TEST_XY(ptrToDerivedTestClass->getReferenceCount(), 3);
            TEST_XY(ptrToTestClass->getReferenceCount(), 3);
            TEST_XY(ptr3->getReferenceCount(), 3);

            // prepare to check that the memory space got zeroed after it went out of scope
            atPtrTo = &ptrToTestClass;
        }

        // confirm that the out of scope pointer got zeroed in the destructor (waves hands in fear
        // over looking at memory that has been abandoned) - note that this test fails on redhat7 in
        // release builds
        #ifndef _NDEBUG_
        TEST_XY(*(void**)atPtrTo, 0);
        #endif

        // call a function to test the copy semantics
        testFunctionScope (ptr_upcast<TestClass> (ptrToDerivedTestClass), ptr_upcast<TestClass> (ptrToDerivedTestClass));
    }

    // after exiting the scope, check that everything is cleaned up
    TestClass::checkPtrs ();
}

TEST_CASE(TestPtrTo2) {
    // create a false scope so the pointer will go out of scope before the program closes
    if (1) {
        // a basic empty object to start
        PtrToTestClass ptrToTestClass;
        TEST_XY(ptrToTestClass.getPtr(), 0);
        TEST_XY(ptrToTestClass.isUnique(), true);

        // create an object and check it's ref count is 1
        ptrToTestClass = new TestClass ();
        TEST_XY(ptrToTestClass->getReferenceCount(), 1);

        // call a few functions to test the copy semantics
        testFunctionScope (ptrToTestClass, ptrToTestClass);
        testFunctionScopeRef (ptrToTestClass);

        // when done, it should be a unique object again
        TEST_XY(ptrToTestClass->getReferenceCount(), 1);
        TEST_XY(ptrToTestClass.isUnique(), true);

        // forcibly terminate the object, check that everything is cleaned up
        ptrToTestClass = 0;
        TestClass::checkPtrs ();

        // and add one more reference to check out of scope deletion
        ptrToTestClass = new TestClass ();
        TEST_XY(ptrToTestClass->getReferenceCount(), 1);
    }

    // after exiting the scope, check that everything is cleaned up
    TestClass::checkPtrs ();
}
