#include <QtCore/QString>
#include <QtTest>
#include <QQmlEngine>
#include <QQmlContext>
#include <QLineEdit>

#include "mainapplication.h"
#include "tst_test.h"

#if (TEST_LEVEL == 1)

#include <gtest/gtest.h>

TEST(Test, Test)
{
    EXPECT_EQ(true, true); // OK
    ASSERT_EQ(true, true); // OK
}

int main(int argc, char *argv[])
{

    //MainApplication app(argc, argv);
    //app.processEvents();

    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}

#endif
