/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "globaltestenvironment.h"
#include "collaborativeadapter.h"
#include "dbus/configurationmanager.h"

#include <api/conversationmodel.h>

#include <QSignalSpy>
#include <QTest>

class CollaborativeDocumentsFixture : public ::testing::Test
{
public:
    void SetUp() override
    {
        QSignalSpy accountAddedSpy(globalEnv.accountAdapter.get(), &AccountAdapter::accountAdded);
        globalEnv.accountAdapter->createJamiAccount(
            {{"alias", "Writer"}, {"registeredName", ""}, {"password", ""}, {"archivePath", ""}, {"avatar", ""}});
        ASSERT_TRUE(accountAddedSpy.wait(30000));
        accountId = accountAddedSpy.takeFirst().at(0).toString();
        globalEnv.lrcInstance->set_currentAccountId(accountId);
    }

    void TearDown() override
    {
        globalEnv.lrcInstance->accountModel().removeAccount(accountId);
        QTRY_COMPARE_WITH_TIMEOUT(globalEnv.lrcInstance->accountModel().getAccountCount(), 0, 10000);
    }

    // A group of the account, ready to hold documents.
    QString createGroup(const QString& title)
    {
        auto* model = globalEnv.lrcInstance->getCurrentConversationModel();
        const auto convId = model->createConversation({}, {{"title", title}});
        EXPECT_TRUE(QTest::qWaitFor([&] { return model->title(convId) == title; }, 10000));
        return convId;
    }

    QString accountId;
};

/*!
 * WHEN  Documents are written in two groups of the account.
 * THEN  All of them are listed, the most recent first, each with the
 *       conversation it comes from and who wrote it.
 */
TEST_F(CollaborativeDocumentsFixture, ListsTheDocumentsOfEveryConversationWithTheirProvenance)
{
    const auto team = createGroup("Team");
    // A conversation is named after its first commit, dated to the second: two
    // groups started within the same second would collide.
    QTest::qWait(1100);
    const auto family = createGroup("Family");
    auto& daemon = ConfigurationManager::instance();
    const auto plan = daemon.createCollaborativeDocument(accountId, team, "Plan", "text/html");
    ASSERT_FALSE(plan.isEmpty());
    // Documents are dated to the second: let the second one be clearly newer.
    QTest::qWait(1100);
    const auto menu = daemon.createCollaborativeDocument(accountId, family, "Menu", "text/html");
    ASSERT_FALSE(menu.isEmpty());

    CollaborativeAdapter adapter(globalEnv.lrcInstance.data());
    adapter.refreshAllDocuments();
    // The conversations are read one at a time, the window staying responsive meanwhile.
    EXPECT_TRUE(adapter.get_loadingAllDocuments());
    QTRY_VERIFY_WITH_TIMEOUT(!adapter.get_loadingAllDocuments(), 10000);

    const auto documents = adapter.get_allDocuments();
    ASSERT_EQ(documents.size(), 2);

    const auto newest = documents.at(0).toMap();
    EXPECT_EQ(newest["documentId"].toString(), menu);
    EXPECT_EQ(newest["name"].toString(), "Menu");
    EXPECT_EQ(newest["convId"].toString(), family);
    EXPECT_EQ(newest["conversationTitle"].toString(), "Family");
    EXPECT_FALSE(newest["isCoreDialog"].toBool());
    EXPECT_TRUE(newest["authorIsSelf"].toBool());

    const auto oldest = documents.at(1).toMap();
    EXPECT_EQ(oldest["documentId"].toString(), plan);
    EXPECT_EQ(oldest["convId"].toString(), team);
    EXPECT_EQ(oldest["conversationTitle"].toString(), "Team");
}

/*!
 * WHEN  The account has no document.
 * THEN  The list is empty once read, rather than left loading.
 */
TEST_F(CollaborativeDocumentsFixture, AnAccountWithoutDocumentsListsNothing)
{
    createGroup("Empty");

    CollaborativeAdapter adapter(globalEnv.lrcInstance.data());
    adapter.refreshAllDocuments();
    QTRY_VERIFY_WITH_TIMEOUT(!adapter.get_loadingAllDocuments(), 10000);
    EXPECT_TRUE(adapter.get_allDocuments().isEmpty());
}
