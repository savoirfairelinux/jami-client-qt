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

#include "webengineutils.h"

#include "globaltestenvironment.h"

#include <QVariant>

TEST(WebEngineUtils, ChromiumFlagsPreserveExistingValues)
{
    EXPECT_EQ(Utils::chromiumFlagsForWebEngine("--remote-debugging-port=9222"),
              "--remote-debugging-port=9222 --disable-web-security --single-process --disable-gpu");
}

TEST(WebEngineUtils, RuntimeAvailabilityRequiresSupportedCpu)
{
    EXPECT_FALSE(Utils::webEngineRuntimeAvailable(false));
    EXPECT_EQ(Utils::webEngineRuntimeAvailable(true), static_cast<bool>(WITH_WEBENGINE));
}

TEST(WebEngineUtils, QmlAvailabilityUsesRuntimeProperty)
{
    qApp->setProperty(Utils::WebEngineRuntimeAvailableProperty, false);
    EXPECT_FALSE(Utils::isWebEngineEnabledForQml());

    qApp->setProperty(Utils::WebEngineRuntimeAvailableProperty, true);
    EXPECT_EQ(Utils::isWebEngineEnabledForQml(), static_cast<bool>(WITH_WEBENGINE));

    qApp->setProperty(Utils::WebEngineRuntimeAvailableProperty, QVariant());
}
