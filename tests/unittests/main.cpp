#include <QtCore/QString>
#include <QtTest>
#include <QQmlEngine>
#include <QQmlContext>
#include <QLineEdit>

#include "tst_test.h"

#ifdef ENABLE_TESTS

#include <gtest/gtest.h>

TEST(Test, Test)
{
    EXPECT_EQ(true, true); // OK
    ASSERT_EQ(true, true); // OK
}

int main(int argc, char *argv[])
{
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
#endif
