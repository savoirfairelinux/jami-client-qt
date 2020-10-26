
#ifndef TST_TEST
#define TST_TEST
#include <gtest/gtest.h>

TEST(DummyTest, TestDummy)
{
    EXPECT_EQ(1, 1);
    ASSERT_EQ(0, 0);
}

#endif
