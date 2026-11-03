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

#include <QPointer>
#include <QQmlComponent>
#include <QSignalSpy>

#include <gtest/gtest.h>

#include <memory>

class QmlRegistration : public ::testing::TestWithParam<bool>
{};

TEST_P(QmlRegistration, AppOwnedSingletonSurvivesEnginesButNotItsOwner)
{
    const char* uri = GetParam() ? "Test.Singleton.Custom" : "Test.Singleton.Pointer";
    auto owner = std::make_unique<QObject>();
    auto object = new QObject(owner.get());
    QPointer<QObject> guardedObject(object);

    if (GetParam()) {
        QML_REGISTERSINGLETONTYPE_CUSTOM(uri, QObject, object)
    } else {
        QML_REGISTERSINGLETONTYPE_POBJECT(uri, object, "QObject")
    }

    const int typeId = qmlTypeId(uri, MODULE_VER_MAJ, MODULE_VER_MIN, "QObject");
    ASSERT_GE(typeId, 0);
    for (int i = 0; i < 2; ++i) {
        {
            QQmlEngine engine;
            QQmlComponent component(&engine);
            component.setData(QByteArray("import QtQml\nimport ") + uri
                                  + " 1.1\nQtObject { property QtObject singleton: QObject }",
                              QUrl());
            std::unique_ptr<QObject> root(component.create());
            ASSERT_TRUE(root) << component.errorString().toStdString();
            EXPECT_EQ(root->property("singleton").value<QObject*>(), object);
        }
        ASSERT_FALSE(guardedObject.isNull());
    }

    owner.reset();
    ASSERT_TRUE(guardedObject.isNull());
    QQmlEngine engine;
    QSignalSpy warnings(&engine, &QQmlEngine::warnings);
    EXPECT_EQ(engine.singletonInstance<QObject*>(typeId), nullptr);
    EXPECT_FALSE(warnings.isEmpty());
}

INSTANTIATE_TEST_SUITE_P(RegistrationMacros, QmlRegistration, ::testing::Bool());
