/*
 * Copyright (C) 2021-2026 Savoir-faire Linux Inc.
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

#include "authority/storagehelper.h"

#include <QBuffer>
#include <QImage>
#include <QRandomGenerator>

using namespace lrc;

/*!
 * Test fixture for AccountAdapter testing
 */
class ContactFixture : public ::testing::Test
{
public:
    // Prepare unit test context. Called at
    // prior each unit test execution
    void SetUp() override {}

    // Close unit test context. Called
    // after each unit test ending
    void TearDown() override {}
};

/*!
 * WHEN  Add an SIP contact.
 * THEN  ContactAdded signal should be emitted once.
 */
TEST_F(ContactFixture, AddSIPContactTest)
{
    // AccountAdded signal spy
    QSignalSpy accountAddedSpy(&globalEnv.lrcInstance->accountModel(), &lrc::api::AccountModel::accountAdded);

    // Create SIP Acc
    globalEnv.accountAdapter->createSIPAccount(QVariantMap());

    accountAddedSpy.wait();
    EXPECT_EQ(accountAddedSpy.count(), 1);

    QList<QVariant> accountAddedArguments = accountAddedSpy.takeFirst();
    EXPECT_TRUE(accountAddedArguments.at(0).typeId() == qMetaTypeId<QString>());

    // Select the created account
    globalEnv.lrcInstance->set_currentAccountId(accountAddedArguments.at(0).toString());

    // Make sure the account setup is done
    QSignalSpy accountStatusChangedSpy(&globalEnv.lrcInstance->accountModel(),
                                       &lrc::api::AccountModel::accountStatusChanged);

    accountStatusChangedSpy.wait();
    EXPECT_GE(accountStatusChangedSpy.count(), 1);

    // ModelUpdated signal spy
    QSignalSpy modelUpdatedSpy(globalEnv.lrcInstance->getCurrentContactModel(), &lrc::api::ContactModel::contactUpdated);

    // Add temp contact test
    globalEnv.lrcInstance->getCurrentConversationModel()->setFilter("test");

    modelUpdatedSpy.wait();
    EXPECT_EQ(modelUpdatedSpy.count(), 1);

    QList<QVariant> modelUpdatedArguments = modelUpdatedSpy.takeFirst();
    EXPECT_TRUE(modelUpdatedArguments.at(0).typeId() == qMetaTypeId<QString>());

    // Get conversation id
    auto convId = globalEnv.lrcInstance->getConversationFromPeerUri(modelUpdatedArguments.at(0).toString()).uid;
    ASSERT_EQ(convId.isEmpty(), false);

    // ContactAdded signal spy
    QSignalSpy contactAddedSpy(globalEnv.lrcInstance->getCurrentContactModel(), &lrc::api::ContactModel::contactAdded);

    globalEnv.lrcInstance->getCurrentConversationModel()->makePermanent(convId);

    contactAddedSpy.wait();
    EXPECT_EQ(contactAddedSpy.count(), 1);

    // Remove the account
    QSignalSpy accountRemovedSpy(&globalEnv.lrcInstance->accountModel(), &lrc::api::AccountModel::accountRemoved);

    globalEnv.lrcInstance->accountModel().removeAccount(globalEnv.lrcInstance->get_currentAccountId());

    accountRemovedSpy.wait();
    EXPECT_EQ(accountRemovedSpy.count(), 1);

    auto accountListSize = globalEnv.lrcInstance->accountModel().getAccountCount();
    ASSERT_EQ(accountListSize, 0);
}

/*!
 * WHEN  A peer profile has a base display name and a local override that is then cleared.
 * THEN  Profile data resolution should fall back to the base display name.
 */
TEST_F(ContactFixture, ProfileDataFallsBackToBaseAliasWhenOverrideCleared)
{
    const QString accountId = "test_profile_account";
    const QString peerUri = "peer@example.org";
    const QString avatarData
        = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAAAAAA6fptVAAAACklEQVR42mNgAAAAAgAB9HFkPgAAAABJRU5ErkJggg==";

    authority::storage::removeProfile(accountId, peerUri);

    api::profile::Info baseProfile;
    baseProfile.uri = peerUri;
    baseProfile.type = api::profile::Type::SIP;
    baseProfile.alias = "Base Display Name";
    baseProfile.avatar = avatarData;

    authority::storage::vcard::setProfile(accountId, baseProfile, true /*isPeer*/, false /*ov*/);
    auto profileData = authority::storage::getProfileData(accountId, peerUri);
    EXPECT_EQ(profileData["alias"], "Base Display Name");

    auto overrideProfile = baseProfile;
    overrideProfile.alias = "Custom Override Name";
    authority::storage::vcard::setProfile(accountId, overrideProfile, true /*isPeer*/, true /*ov*/);
    profileData = authority::storage::getProfileData(accountId, peerUri);
    EXPECT_EQ(profileData["alias"], "Custom Override Name");

    overrideProfile.alias = "";
    authority::storage::vcard::setProfile(accountId, overrideProfile, true /*isPeer*/, true /*ov*/);
    profileData = authority::storage::getProfileData(accountId, peerUri);
    EXPECT_EQ(profileData["alias"], "Base Display Name");

    authority::storage::removeProfile(accountId, peerUri);
}

/*!
 * WHEN  a contact request is sent with a big avatar, as a PNG or a JPEG
 * THEN  its vCard stays under the 16 KiB a DHT value carries reliably,
 *       with a JPEG thumbnail of the avatar
 */
TEST_F(ContactFixture, TrustRequestVCardFitsInDhtValue)
{
    // Noise does not compress: worst case for the size of the avatar
    QImage avatar(374, 350, QImage::Format_RGB32);
    QRandomGenerator rng(42);
    for (int y = 0; y < avatar.height(); ++y)
        for (int x = 0; x < avatar.width(); ++x)
            avatar.setPixel(x, y, rng.generate());

    for (const auto* format : {"PNG", "JPEG"}) {
        QByteArray image;
        QBuffer buffer(&image);
        buffer.open(QIODevice::WriteOnly);
        ASSERT_TRUE(avatar.save(&buffer, format));

        api::profile::Info profile;
        profile.uri = "529e3a6708878bf57c1aa99e563f2a26f63a41e4";
        profile.alias = "Cyrille";
        profile.type = api::profile::Type::JAMI;
        profile.avatar = image.toBase64();

        auto vCard = authority::storage::vcard::profileToVcard(profile, true /*compressImage*/);
        EXPECT_LE(vCard.toUtf8().size(), 16 * 1024) << format;
        EXPECT_TRUE(vCard.contains("FN:Cyrille")) << format;
        EXPECT_TRUE(vCard.contains("PHOTO;ENCODING=BASE64;TYPE=JPEG:/9j/")) << format;
    }
}
