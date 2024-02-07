/*
 * Copyright (C) 2022-2024 Savoir-faire Linux Inc.
 * Author: Sébastien Blin <sebastien.blin@savoirfairelinux.com>
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "tipsmodel.h"

#include <algorithm>
#include <random>

TipsModel::TipsModel(AppSettingsManager* settingsManager, QObject* parent)
    : QAbstractListModel(parent)
    , settingsManager_(settingsManager)
{
    QObject::connect(settingsManager_, &AppSettingsManager::retranslate, this, &TipsModel::reset);
    reset();
}

int
TipsModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid())
        return 0;
    return tips_.size();
}

QVariant
TipsModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid())
        return QVariant();

    auto tip = tips_.at(index.row());

    switch (role) {
    case Tips::Role::TipId:
        return QVariant::fromValue(tip["id"].toInt());
    case Tips::Role::Title:
        return QVariant::fromValue(tip["title"]);
    case Tips::Role::Description:
        return QVariant::fromValue(tip["desc"]);
    case Tips::Role::Type:
        return QVariant::fromValue(tip["type"]);
    }
    return QVariant();
}

QHash<int, QByteArray>
TipsModel::roleNames() const
{
    using namespace Tips;
    QHash<int, QByteArray> roles;
#define X(role) roles[role] = #role;
    TIPS_ROLES
#undef X
    return roles;
}

void
TipsModel::reset()
{
    beginResetModel();
    tips_.clear();

#if !APPSTORE
    QDate date = QDate::currentDate();
    if (date >= QDate::fromString("2023-11-27", "yyyy-MM-dd")) {
        tips_.append({{"id", "14"}, {"title", tr("Donate")}, {"desc", ""}, {"type", "donation"}});
    }
#endif

    tips_.append({{"id", "0"}, {"title", tr("Customize")}, {"desc", ""}, {"type", "customize"}});
    tips_.append({{"id", "13"}, {"title", tr("Backup account")}, {"desc", ""}, {"type", "backup"}});
    tips_.append({{"id", "1"},
                  {"title", tr("What does Jami mean?")},
                  {"desc",
                   tr("The choice of the name Jami was inspired by the Swahili word 'jamii', which "
                      "means 'community' as a noun and 'together' as an adverb.")},
                  {"type", "tip"}});
    tips_.append({{"id", "2"},
                  {"title", tr("What is the green dot next to my account?")},
                  {"desc",
                   tr("A red dot means that your account is disconnected from the network; it "
                      "turns green when it's connected.")},
                  {"type", "tip"}});
    tips_.append(
        {{"id", "3"},
         {"title", tr("Why should I back up my account?")},
         {"desc",
          tr("Jami is distributed and your account is only stored locally on your device. If "
             "you lose your password or your local account data, you WILL NOT be able to "
             "recover your account if you did not back it up earlier.")},
         {"type", "tip"}});
    tips_.append(
        {{"id", "4"},
         {"title", tr("Can I make a conference call?")},
         {"desc",
          tr("In a call, you can click on \"Add participants\" to add a contact to a call.")},
         {"type", "tip"}});
    tips_.append({{"id", "6"},
                  {"title", tr("What is a Jami account?")},
                  {"desc",
                   tr("A Jami account is an asymmetric encryption key. Your account is identified "
                      "by a Jami ID, which is a fingerprint of your public key.")},
                  {"type", "tip"}});
    tips_.append({{"id", "7"},
                  {"title", tr("What information do I need to provide to create a Jami account?")},
                  {"desc",
                   tr("When you create a new Jami account, you do not have to provide any private "
                      "information like an email, address, or phone number.")},
                  {"type", "tip"}});
    tips_.append(
        {{"id", "8"},
         {"title", tr("Why don't I have to use a password?")},
         {"desc",
          tr("With Jami, your account is stored in a directory on your device. The password "
             "is only used to encrypt your account in order to protect you from someone "
             "who has physical access to your device.")},
         {"type", "tip"}});
    tips_.append(
        {{"id", "9"},
         {"title", tr("Why don't I have to register a username?")},
         {"desc",
          tr("The most permanent, secure identifier is your Jami ID, but since these are difficult "
             "to use for some people, you also have the option of registering a username.")},
         {"type", "tip"}});
    tips_.append(
        {{"id", "10"},
         {"title", tr("How can I back up my account?")},
         {"desc", tr("In Account Settings, a button is available to create a backup your account.")},
         {"type", "tip"}});
    tips_.append(
        {{"id", "11"},
         {"title", tr("What happens when I delete my account?")},
         {"desc",
          tr("Your account is only stored on your own devices. If you delete your account "
             "from all of your devices, the account is gone forever and you CANNOT recover it.")},
         {"type", "tip"}});
    tips_.append({{"id", "12"},
                  {"title", tr("Can I use my account on multiple devices?")},
                  {"desc",
                   tr("Yes, you can link your account from the settings, or you can import your "
                      "backup on another device.")},
                  {"type", "tip"}});

    std::random_device rd;
    std::mt19937 g(rd());
    std::shuffle(tips_.begin() + 2, tips_.end(), g);
    endResetModel();
}
