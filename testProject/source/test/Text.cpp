#include "Test.h"
#include "Text.h"

TEST_CASE(TestText0) {
    TEST_XY(sizeof(Text), sizeof(void*));
}

TEST_CASE(TestText1) {
    const char* hello = "Hello";
    const char* world = "World";
    Text helloText = hello;
    TEST_XYOP(helloText, hello, ==);
    TEST_XY(helloText.length(), 5);

    Text worldText (world);
    TEST_XYOP(worldText, world, ==);
    TEST_XY(worldText.length(), 5);

    TEST_XY(helloText.compare(worldText), 'H' - 'W');
    TEST_XY(worldText.compare(helloText), 'W' - 'H');
    TEST_XY(helloText < worldText, true);
    TEST_XY(helloText <= worldText, true);
    TEST_XY(worldText > helloText, true);
    TEST_XY(worldText >= helloText, true);
    TEST_XY(helloText == helloText, true);
    TEST_XY(helloText != helloText, false);
    TEST_XY(helloText == "", false);
    TEST_XY(helloText != "", true);
    TEST_XY(helloText != 0, true);

    Text helloWorldText = helloText + " " + worldText;
    TEST_XYOP(helloWorldText, "Hello World", ==);
    TEST_XY(helloWorldText.length(), 11);

    helloWorldText.clear ();
    TEST_XY(helloWorldText.length(), 0);

    helloWorldText.clear () << world << "-" << hello;
    TEST_XYOP(helloWorldText, "Hello World", !=);
    TEST_XYOP(helloWorldText, "World-Hello", ==);

    helloWorldText.clear () += worldText;
    TEST_XYOP(helloWorldText, "Hello World", !=);
    TEST_XYOP(helloWorldText, "World", ==);

    Text emptyText;
    TEST_XY(emptyText, "");
    TEST_XY(emptyText.isEmpty (), true);
}

TEST_CASE(TestTextFind) {
    Text longString = "This is a long string that we want to find an offset in xxx";
    TEST_XY(longString.find ("long"), 10);
    TEST_XY(longString.find ("short"), -1);
    TEST_XY(longString.find ("This"), 0);
    TEST_XY(longString.find ("xxx"), (int) (longString.length()) - 3);
}

TEST_CASE(TestTextSubstring) {
    Text longString = "This is a long string";
    TEST_XY(longString.substring (0), "This is a long string");
    TEST_XY(longString.substring (10), "long string");
    TEST_XY(longString.substring (10, 100), "long string");
    TEST_XY(longString.substring (10, 4), "long");
    TEST_XY(longString.substring (50, 4), "");
}

TEST_CASE(TestTextSplitEmpty) {
    Text longString = "abcdefghijk";
    vector<Text> splitResult = longString.splitFirst ("/");
    TEST_XY(splitResult.size (), 1);
    TEST_XY(splitResult[0], longString);
}

TEST_CASE(TestTextSplit) {
    Text longString = "xxx##yyy##zzz##aaa";
    vector<Text> splitResult = longString.splitFirst ("##");
    TEST_XY(splitResult.size (), 2);
    TEST_XY(splitResult[0], "xxx");
    TEST_XY(splitResult[1], "yyy##zzz##aaa");

    splitResult = longString.split ("##");
    TEST_XY(splitResult.size (), 4);
    TEST_XY(splitResult[0], "xxx");
    TEST_XY(splitResult[1], "yyy");
    TEST_XY(splitResult[2], "zzz");
    TEST_XY(splitResult[3], "aaa");

    longString = "xxx##yyy##zzz##aaa##";
    splitResult = longString.split ("##");
    TEST_XY(splitResult.size (), 5);
    TEST_XY(splitResult[0], "xxx");
    TEST_XY(splitResult[1], "yyy");
    TEST_XY(splitResult[2], "zzz");
    TEST_XY(splitResult[3], "aaa");
    TEST_XY(splitResult[4].isEmpty (), true);

    longString = "##xxx##yyy##zzz##aaa##";
    splitResult = longString.split ("##");
    TEST_XY(splitResult.size (), 6);
    TEST_XY(splitResult[0].isEmpty (), true);
    TEST_XY(splitResult[1], "xxx");
    TEST_XY(splitResult[2], "yyy");
    TEST_XY(splitResult[3], "zzz");
    TEST_XY(splitResult[4], "aaa");
    TEST_XY(splitResult[5].isEmpty (), true);

    longString = ",,a,,";
    splitResult = longString.split (",");
    TEST_XY(splitResult.size (), 5);
    TEST_XY(splitResult[0].isEmpty (), true);
    TEST_XY(splitResult[1].isEmpty (), true);
    TEST_XY(splitResult[2], "a");
    TEST_XY(splitResult[3].isEmpty (), true);
    TEST_XY(splitResult[4].isEmpty (), true);
}
