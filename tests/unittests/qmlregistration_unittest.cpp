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

#include "qmlregister.h"

#include <QTest>

#include <gtest/gtest.h>

#include <memory>

TEST(QmlRegistration, SingletonFactoryIgnoresDestroyedObject)
{
    auto object = std::make_unique<QObject>();
    QPointer<QObject> guardedObject(object.get());

    EXPECT_EQ(Utils::qmlSingletonObject(guardedObject, "TestSingleton"), object.get());

    object.reset();
    QTest::ignoreMessage(QtWarningMsg,
                         "Ignoring QML singleton request for destroyed object TestSingleton");
    EXPECT_EQ(Utils::qmlSingletonObject(guardedObject, "TestSingleton"), nullptr);
}
