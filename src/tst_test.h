#ifndef TST_TEST
#define TST_TEST
#include <QDebug>
#include <gtest/gtest.h>

int raise_error_example(bool tryExit) {
    if (tryExit) {
        std::cerr << "Error: Negative Input\n";
        exit(-1);
    } else {
        return 1;
    }
}

TEST(Test, TestExit)
{
    EXPECT_EQ(1,1);
    ASSERT_EQ(1, raise_error_example(false));
    //ASSERT_EXIT(raise_error_example(true), ::testing::ExitedWithCode(-1), "Error Test!");
}

TEST(Test, TestComp)
{
    EXPECT_EQ(0, 0); // OK
    //EXPECT_EQ(1, 0); // ERROR but continues
    ASSERT_EQ(0, 0); // OK
    //ASSERT_EQ(1, 0); // ERROR and stops execution
}
#endif
