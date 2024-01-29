/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
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

#include <QtHttpServer/QHttpServer>

class PreviewEngineFixture : public ::testing::Test
{
public:
    // Prepare unit test context. Called at
    // prior each unit test execution
    void SetUp() override {
        server = new QHttpServer();
        // Setup a server that can return an HTML body.
        server->listen(QHostAddress::LocalHost, 8000);
    }

   // Close unit test context. Called
   // after each unit test ending
    void TearDown() override {
        delete server;
    }

    // An instance of QHttpServer used to create a server.
    QHttpServer* server;
};

/*!
 * WHEN  We parse a link
 * THEN  The infoReady signal should be emitted once with the correct info.
 */
TEST_F(PreviewEngineFixture, ParsingALinkEmitsInfoReadySignal)
{
    auto link = QString("http://localhost:8000/test");
    server->route("/test", [] () {
        return QString("<meta property=\"og:title\" content=\"Test title\">");
    });

    QSignalSpy infoReadySpy(globalEnv.previewEngine.data(), &PreviewEngine::infoReady);

    Q_EMIT globalEnv.previewEngine->parseLink("msgId_01", link);

    // Wait for the infoReady signal which should be emitted once with the correct ID.
    infoReadySpy.wait();
    EXPECT_EQ(infoReadySpy.count(), 1) << "infoReady signal should be emitted once";

    QList<QVariant> infoReadyArguments = infoReadySpy.takeFirst();
    EXPECT_TRUE(infoReadyArguments.at(0).typeId() == qMetaTypeId<QString>());
    EXPECT_EQ(infoReadyArguments.at(0).toString(), "msgId_01");
}

/*!
 * WHEN  We parse a link that has a description containing characters encoded using UTF-8
 * THEN  The description should be parsed and match the original string
 */
TEST_F(PreviewEngineFixture, UTF8CharactersAreParsedCorrectly)
{
    auto link = QString("http://localhost:8000/test");
    server->route("/test", [] () {
        return QString("<meta property=\"og:description\" content=\"Test de caractères Utf-8");
    });

    QSignalSpy infoReadySpy(globalEnv.previewEngine.data(), &PreviewEngine::infoReady);

    Q_EMIT globalEnv.previewEngine->parseLink("msgId_01", link);

    // Wait for the infoReady signal which should be emitted once.
    infoReadySpy.wait();
    EXPECT_EQ(infoReadySpy.count(), 1) << "infoReady signal should be emitted once";

    QList<QVariant> infoReadyArguments = infoReadySpy.takeFirst();
    EXPECT_TRUE(infoReadyArguments.at(1).typeId() == qMetaTypeId<QVariantMap>());

    // Check that the description is parsed correctly.
    QVariantMap info = infoReadyArguments.at(1).toMap();
    EXPECT_TRUE(info.contains("description"));
    EXPECT_EQ(info["description"].toString(), "Test de caractères Utf-8");
}
