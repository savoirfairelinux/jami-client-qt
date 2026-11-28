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

#include "messagesadapter.h"

#include <QCoreApplication>
#include <QEvent>
#include <QPointer>

class MessagesAdapterFixture : public ::testing::Test
{
public:
    void SetUp() override
    {
        messagesAdapter.reset(new MessagesAdapter(globalEnv.settingsManager.data(),
                                                  globalEnv.previewEngine.data(),
                                                  globalEnv.lrcInstance.data()));
    }

    void TearDown() override
    {
        messagesAdapter.reset();
    }

    // MessagesAdapter::resetMediaInteractions() is private; the fixture is a
    // friend, but test bodies (fixture subclasses) are not.
    void resetMediaInteractions()
    {
        messagesAdapter->resetMediaInteractions(nullptr);
    }

    QObject* exposedMediaModel() const
    {
        return qvariant_cast<QObject*>(messagesAdapter->get_mediaMessageListModel());
    }

    QScopedPointer<MessagesAdapter> messagesAdapter;
};

/*!
 * WHEN  The media/search message list model is replaced.
 * THEN  The QML-exposed property never references the old model once it is
 *       being destroyed, so QML bindings can't wrap a dangling QObject.
 */
TEST_F(MessagesAdapterFixture, MediaModelResetNeverExposesDestroyedModel)
{
    resetMediaInteractions();
    QPointer<QObject> previous = exposedMediaModel();
    ASSERT_FALSE(previous.isNull());

    bool destroyedSeen = false;
    QObject* exposedDuringDestruction = nullptr;
    QObject::connect(previous, &QObject::destroyed, [&] {
        destroyedSeen = true;
        exposedDuringDestruction = exposedMediaModel();
    });

    resetMediaInteractions();

    auto* current = exposedMediaModel();
    ASSERT_NE(current, nullptr);
    EXPECT_NE(current, previous.data());

    QCoreApplication::sendPostedEvents(nullptr, QEvent::DeferredDelete);

    EXPECT_TRUE(destroyedSeen);
    EXPECT_TRUE(previous.isNull());
    EXPECT_EQ(exposedDuringDestruction, current);
}
