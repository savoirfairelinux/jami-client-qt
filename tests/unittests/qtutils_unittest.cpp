/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#include "app/qtutils.h"

#include <QMetaMethod>
#include <QTimer>

#include <gtest/gtest.h>

class TestTimer : public QTimer
{
public:
    bool isTimeoutConnected() const
    {
        return isSignalConnected(QMetaMethod::fromSignal(&QTimer::timeout));
    }
};

TEST(QtUtilsTest, SingleShotConnectionIsReentrantSafe)
{
    TestTimer sender;
    TestTimer interrupter;
    QObject context;
    int calls = 0;

    Utils::connectSingleShotUntil(
        &sender,
        &QTimer::timeout,
        &context,
        [&] {
            ++calls;
            EXPECT_TRUE(QMetaObject::invokeMethod(&sender, "timeout", Qt::DirectConnection));
        },
        &interrupter,
        &QTimer::timeout);

    EXPECT_TRUE(interrupter.isTimeoutConnected());
    EXPECT_TRUE(QMetaObject::invokeMethod(&sender, "timeout", Qt::DirectConnection));
    EXPECT_TRUE(QMetaObject::invokeMethod(&sender, "timeout", Qt::DirectConnection));

    EXPECT_EQ(calls, 1);
    EXPECT_FALSE(interrupter.isTimeoutConnected());
}

TEST(QtUtilsTest, InterrupterCancelsConnection)
{
    QTimer sender;
    QTimer interrupter;
    QObject context;
    int calls = 0;

    Utils::connectSingleShotUntil(&sender, &QTimer::timeout, &context, [&] { ++calls; }, &interrupter, &QTimer::timeout);

    EXPECT_TRUE(QMetaObject::invokeMethod(&interrupter, "timeout", Qt::DirectConnection));
    EXPECT_TRUE(QMetaObject::invokeMethod(&sender, "timeout", Qt::DirectConnection));

    EXPECT_EQ(calls, 0);
}

TEST(QtUtilsTest, ContextDestructionCancelsConnection)
{
    QTimer sender;
    QTimer interrupter;
    int calls = 0;

    {
        QObject context;
        Utils::connectSingleShotUntil(
            &sender, &QTimer::timeout, &context, [&] { ++calls; }, &interrupter, &QTimer::timeout);
    }

    EXPECT_TRUE(QMetaObject::invokeMethod(&sender, "timeout", Qt::DirectConnection));

    EXPECT_EQ(calls, 0);
}
