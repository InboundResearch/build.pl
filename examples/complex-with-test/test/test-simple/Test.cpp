#include    "Test.h"

TEST_CASE(Test1) {
    TEST_ASSERTION(true);
}

TEST_CASE(Test2) {
    double x = 1.0;
    double y = 2.0;
    TEST_XYF(x / y, 0.5, 1.0e-6);
    TEST_ASSERTION(true);
}

// comment this definition to see what a test failure looks like
#define     SKIP_FAILURE_TEST_CASE
#ifndef     SKIP_FAILURE_TEST_CASE
TEST_CASE(ForceFailure) {
    TEST_XY(true, false);
}
#endif

int main (int argc, char** argv) {
	cerr << "TESTS COMPLETED SUCCESSFULLY!" << endl << endl;
	return EXIT_SUCCESS;
}
