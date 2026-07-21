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

#include "globaltestenvironment.h"

#include <QFile>

TEST(WebEngineQml, GeneralViewDoesNotWrapNavigationRequests)
{
    QFile generalView(QStringLiteral(JAMI_SOURCE_DIR
                                     "/src/app/webengine/GeneralWebEngineView.qml"));

    ASSERT_TRUE(generalView.open(QIODevice::ReadOnly | QIODevice::Text));

    const auto source = QString::fromUtf8(generalView.readAll());
    EXPECT_FALSE(source.contains(QStringLiteral("onNavigationRequested")))
        << "QML navigationRequested handlers make Qt wrap QWebEngineNavigationRequest "
           "objects and can crash in QJSEngine::newQObject during teardown";
}
