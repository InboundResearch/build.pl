#include "Test.h"
#include "TextContainer.h"

TEST_CASE(TestTextLess) {
    Text    a ("hello");
    Text    b ("there");
    Text    c ("world");
    TextLess textLess;
    TEST_XY (textLess (a, b), true);
    TEST_XY (textLess (b, c), true);
    TEST_XY (textLess (a, c), true);
    TEST_XY (textLess (c, a), false);
}

TEST_CASE(TestTextSet) {
    TextSet ts;
    TEST_XY (ts.size(), 0);
    ts.put ("Hello");
    TEST_XY (ts.size(), 1);
    TEST_XY (ts.contains(Text ("Hello")), true);
    ts.put ("World");
    TEST_XY (ts.size(), 2);
    TEST_XY (ts.contains(Text ("Hello")), true);
    TEST_XY (ts.contains(Text ("World")), true);

    TEST_XY (ts.contains(Text ("JOE")), false);
    TEST_XY (ts.contains(Text ("Hell")), false);
    TEST_XY (ts.contains(Text ("Hello1")), false);

    TEST_XY (ts.toText (), "Hello, World");
    cerr << ts << endl;
}

TEST_CASE(TestTextMap) {
    TextMap<Text>   tm;
    TEST_XY (tm.size(), 0);
    tm.set ("Hello", "World");
    TEST_XY (tm.size(), 1);
    TEST_XYOP (tm.get ("Hello"), 0, !=);
    TEST_XY (*(tm.get ("Hello")), "World");

    tm.set ("xxx", "yyy");
    TEST_XY (tm.size(), 2);
    TEST_XYOP (tm.get ("Hello"), 0, !=);
    TEST_XY (*(tm.get ("Hello")), "World");
    TEST_XYOP (tm.get ("xxx"), 0, !=);
    TEST_XY (*(tm.get ("xxx")), "yyy");

    tm.set ("Hello", "Joe");
    TEST_XY (tm.size(), 2);
    TEST_XYOP (tm.get ("Hello"), 0, !=);
    TEST_XY (*(tm.get ("Hello")), "Joe");
    TEST_XYOP (tm.get ("xxx"), 0, !=);
    TEST_XY (*(tm.get ("xxx")), "yyy");

    TEST_XY (tm.toText (), "Hello: Joe, xxx: yyy");
    cerr << tm << endl;
}
