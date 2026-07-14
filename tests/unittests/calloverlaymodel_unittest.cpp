/*
 * Copyright (C) 2024-2026 Savoir-faire Linux Inc.
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

#include "calloverlaymodel.h"
#include "pttlistener.h"

#include <QMouseEvent>
#include <QQuickItem>
#include <QQuickWindow>

class CallOverlayModelFixture : public ::testing::Test
{
public:
    void SetUp() override
    {
        listener_.reset(new PTTListener(globalEnv.settingsManager.get(), nullptr));
        model_.reset(new CallOverlayModel(globalEnv.lrcInstance.data(), listener_.data(), nullptr));
    }

    void TearDown() override
    {
        model_.reset();
        listener_.reset();
    }

    QScopedPointer<PTTListener> listener_;
    QScopedPointer<CallOverlayModel> model_;
};

/*!
 * WHEN  A watched item is destroyed without being unregistered and a mouse-move
 *       event is delivered to the window it belonged to,
 * THEN  The event filter must not dereference or emit the dangling pointer,
 *       preventing the QV4::QObjectWrapper::wrap crash.
 */
TEST_F(CallOverlayModelFixture, DestroyedWatchedItemDoesNotCrashEventFilter)
{
    QQuickWindow window;
    auto* item = new QQuickItem(window.contentItem());

    model_->setEventFilterActive(&window, item, true);

    QSignalSpy mouseMovedSpy(model_.data(), &CallOverlayModel::mouseMoved);

    // Simulate the item being destroyed without QML calling unregister
    // (e.g. an abrupt window teardown).
    delete item;

    QMouseEvent moveEvent(QEvent::MouseMove,
                          QPointF(10, 10),
                          QPointF(10, 10),
                          Qt::NoButton,
                          Qt::NoButton,
                          Qt::NoModifier);

    // Before the fix this dereferenced/emitted the dangling QQuickItem*.
    EXPECT_FALSE(model_->eventFilter(&window, &moveEvent));

    // No signal is emitted for the destroyed item.
    EXPECT_EQ(mouseMovedSpy.count(), 0);
}
