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

#include "instancemanager.h"

#include <QApplication>
#include <QCryptographicHash>
#include <QLocalServer>
#include <QLocalSocket>

#include <gtest/gtest.h>

#include <memory>

// The primary instance listens on a local server so that secondary instances
// can reach it. The server name must be the hex-encoded digest of the
// application identity, not the raw digest bytes (which are not valid text and
// yield an unreadable, mangled socket name).
TEST(InstanceManager, ServerNameIsHexEncodedDigest)
{
    const QString appName = QApplication::applicationName();
    const QString appDomain = QApplication::organizationDomain();
    QApplication::setApplicationName("jami-instancemanager-test");
    QApplication::setOrganizationDomain("instancemanager.test.invalid");

    QCryptographicHash hash(QCryptographicHash::Sha256);
    hash.addData(QApplication::applicationName().toUtf8());
    hash.addData(QApplication::organizationDomain().toUtf8());
    const QString serverName = QString::fromLatin1(hash.result().toHex());

    // Clean up any leftover socket from a previous, interrupted run.
    QLocalServer::removeServer(serverName);

    {
        auto instanceManager = std::make_unique<InstanceManager>(nullptr);
        ASSERT_TRUE(instanceManager->tryToRun({}));

        QLocalSocket socket;
        socket.connectToServer(serverName);
        EXPECT_TRUE(socket.waitForConnected(1000)) << "no server listening as " << serverName.toStdString();
    }

    QLocalServer::removeServer(serverName);
    QApplication::setApplicationName(appName);
    QApplication::setOrganizationDomain(appDomain);
}
