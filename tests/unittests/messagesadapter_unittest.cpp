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
#include <QPointer>
#include <QSignalSpy>

#include <gtest/gtest.h>

class MessagesAdapterFixture : public ::testing::Test
{
public:
    void SetUp() override
    {
        QSignalSpy accountAddedSpy(&globalEnv.lrcInstance->accountModel(), &AccountModel::accountAdded);
        globalEnv.accountAdapter->createSIPAccount(QVariantMap());
        ASSERT_TRUE(accountAddedSpy.wait());
        accountId = accountAddedSpy.takeFirst().at(0).toString();
        globalEnv.lrcInstance->set_currentAccountId(accountId);

        messagesAdapter.reset(new MessagesAdapter(globalEnv.settingsManager.data(),
                                                  globalEnv.previewEngine.data(),
                                                  globalEnv.lrcInstance.data()));
    }

    void TearDown() override
    {
        messagesAdapter.reset();
        QSignalSpy accountRemovedSpy(&globalEnv.lrcInstance->accountModel(), &AccountModel::accountRemoved);
        globalEnv.lrcInstance->accountModel().removeAccount(accountId);
        accountRemovedSpy.wait();
    }

    QObject* exposedMediaModel() const
    {
        return messagesAdapter->property("mediaMessageListModel").value<QObject*>();
    }

    QString accountId;
    QScopedPointer<MessagesAdapter> messagesAdapter;
};

/*!
 * WHEN  A new media search replaces the media message list model.
 * THEN  The model exposed to QML never refers to the destroyed model,
 *       even while that model is being destroyed, and ends up pointing
 *       to a live model.
 *
 * Regression test for INVALID_POINTER_READ in QV4::QObjectWrapper::wrap,
 * where QML read a dangling mediaMessageListModel pointer.
 */
TEST_F(MessagesAdapterFixture, MediaModelReplacementNeverExposesDestroyedModel)
{
    messagesAdapter->startSearch(QString(), false);
    QPointer<QObject> oldModel = exposedMediaModel();
    ASSERT_FALSE(oldModel.isNull());

    bool exposedWhileDestroyed = false;
    QObject::connect(oldModel.data(), &QObject::destroyed, [&](QObject* destroyed) {
        exposedWhileDestroyed = exposedMediaModel() == destroyed;
    });

    messagesAdapter->startSearch(QString(), false);
    QCoreApplication::sendPostedEvents(nullptr, QEvent::DeferredDelete);

    EXPECT_TRUE(oldModel.isNull());
    EXPECT_FALSE(exposedWhileDestroyed);

    EXPECT_NE(exposedMediaModel(), nullptr);
}
