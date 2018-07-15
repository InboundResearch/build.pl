#include "Test.h"
#include "RawText.h"

TEST_CASE(TestRawText) {
    const char* helloWorld = "Hello World";
    uint helloWorldLength = strlen (helloWorld);
    PtrToRawText rawText = RawText::make (helloWorld, helloWorldLength);
    TEST_XY (rawText->getCapacity(), 16);
    TEST_XY (rawText->getLength (), helloWorldLength);
    TEST_XY (memcmp (helloWorld, rawText->get(), rawText->getLength()), 0);

    const char* hello = "Hello";
    uint helloLength = strlen (hello);
    rawText = RawText::make (helloWorld, helloLength);
    TEST_XY (rawText->getCapacity(), 8);
    TEST_XY (rawText->getLength (), helloLength);
    TEST_XY (memcmp (hello, rawText->get(), rawText->getLength()), 0);

    TEST_XY (rawText->append (hello, strlen (hello)), false);
    TEST_XY (rawText->getLength (), helloLength);
    TEST_XY (memcmp ("Hello", rawText->get(), rawText->getLength()), 0);

    rawText = RawText::make(50);
    rawText->set (hello, helloLength);
    TEST_XY (rawText->getCapacity(), 64);
    TEST_XY (rawText->getLength (), helloLength);
    TEST_XY (memcmp (hello, rawText->get(), rawText->getLength()), 0);
    rawText->append (hello, helloLength);
    TEST_XY (rawText->getLength (), helloLength * 2);
    TEST_XY (memcmp ("HelloHello", rawText->get(), rawText->getLength()), 0);

    PtrToRawText empty = RawText::getEmpty();
    TEST_XY (empty->getCapacity(), 0);
    TEST_XY (empty->getLength(), 0);
    TEST_XY ((empty->get ())[0], 0);
}
