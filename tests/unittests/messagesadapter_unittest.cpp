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

#include <QPointer>
#include <QSignalSpy>

class MessagesAdapterFixture : public ::testing::Test
{
public:
    void SetUp() override
    {
        auto& accountModel = globalEnv.lrcInstance->accountModel();
        QSignalSpy accountAddedSpy(&accountModel, &AccountModel::accountAdded);
        globalEnv.accountAdapter->createSIPAccount(QVariantMap());
        ASSERT_TRUE(accountAddedSpy.count() > 0 || accountAddedSpy.wait());
        accountId = accountAddedSpy.takeFirst().at(0).toString();
        globalEnv.lrcInstance->set_currentAccountId(accountId);

        messagesAdapter.reset(new MessagesAdapter(globalEnv.settingsManager.data(),
                                                  globalEnv.previewEngine.data(),
                                                  globalEnv.lrcInstance.data()));
    }

    void TearDown() override
    {
        messagesAdapter.reset();
        if (!accountId.isEmpty()) {
            auto& accountModel = globalEnv.lrcInstance->accountModel();
            QSignalSpy accountRemovedSpy(&accountModel, &AccountModel::accountRemoved);
            accountModel.removeAccount(accountId);
            accountRemovedSpy.wait();
        }
    }

    QObject* publishedMediaModel()
    {
        return messagesAdapter->get_mediaMessageListModel().value<QObject*>();
    }

    QString accountId;
    QScopedPointer<MessagesAdapter> messagesAdapter;
};

/*!
 * WHEN  A new search replaces the media message list model.
 * THEN  mediaMessageListModel must never expose the old model while it is
 *       being destroyed, otherwise QML bindings reading the property during
 *       teardown dereference a dangling pointer (QObjectWrapper::wrap crash).
 */
TEST_F(MessagesAdapterFixture, MediaModelIsNotPublishedWhileBeingDestroyed)
{
    messagesAdapter->startSearch(QString(), false);
    QPointer<QObject> previousModel = publishedMediaModel();
    ASSERT_FALSE(previousModel.isNull());

    bool destroyedModelWasPublished = false;
    QObject::connect(previousModel.data(), &QObject::destroyed, [&](QObject* destroyed) {
        destroyedModelWasPublished = publishedMediaModel() == destroyed;
    });
    QSignalSpy changedSpy(messagesAdapter.data(), &MessagesAdapter::mediaMessageListModelChanged);

    messagesAdapter->startSearch(QString(), false);

    EXPECT_TRUE(previousModel.isNull());
    EXPECT_FALSE(destroyedModelWasPublished);
    EXPECT_EQ(changedSpy.count(), 1);
    EXPECT_NE(publishedMediaModel(), nullptr);
}
