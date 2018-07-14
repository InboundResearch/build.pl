#include "Test.h"
#include "ReferenceCountedObject.h"

TEST_CASE(TestReferenceCountedObject) {
    // base object constructor, addRef, and geCount
    ReferenceCountedObject  rcObject;
    TEST_XY(rcObject.getReferenceCount (), 0);
    rcObject.addRef ();
    TEST_XY(rcObject.getReferenceCount (), 1);
    rcObject.addRef ();
    TEST_XY(rcObject.getReferenceCount (), 2);

    // remove ref
    rcObject.removeRef ();
    TEST_XY(rcObject.getReferenceCount (), 1);

    // copy constructor
    ReferenceCountedObject rcObject2 (rcObject);
    TEST_XY(rcObject2.getReferenceCount (), 0);

    // finish and clean up
    rcObject.removeRef ();
    TEST_XY(rcObject.getReferenceCount (), 0);

    // don't bother to formally test the debug id
}
