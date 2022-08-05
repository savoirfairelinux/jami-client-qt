/*
 * Copyright (C) 2020-2022 Savoir-faire Linux Inc.
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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

#pragma once

#include "abstractlistmodelbase.h"

// TODO: many of these roles should probably be factored out
#define CONV_ROLES \
    X(Title) \
    X(BestId) \
    X(Presence) \
    X(Alias) \
    X(RegisteredName) \
    X(URI) \
    X(UnreadMessagesCount) \
    X(LastInteractionTimeStamp) \
    X(LastInteractionDate) \
    X(LastInteraction) \
    X(ContactType) \
    X(IsSwarm) \
    X(IsCoreDialog) \
    X(IsBanned) \
    X(UID) \
    X(InCall) \
    X(IsAudioOnly) \
    X(CallStackViewShouldShow) \
    X(CallState) \
    X(SectionName) \
    X(AccountId) \
    X(Draft) \
    X(IsRequest) \
    X(Mode) \
    X(Uris) \
    X(Monikers)

namespace ConversationList {
Q_NAMESPACE
enum Role {
    DummyRole = Qt::UserRole + 1,
#define X(role) role,
    CONV_ROLES
#undef X
};
Q_ENUM_NS(Role)
} // namespace ConversationList

// A generic wrapper view model around ConversationModel's underlying data
class ConversationListModelBase : public AbstractListModelBase
{
    Q_OBJECT

public:
    using item_t = const conversation::Info&;

    ConversationListModelBase(QObject* parent = nullptr);
    explicit ConversationListModelBase(LRCInstance* instance, QObject* parent = nullptr);
    ~ConversationListModelBase() = default;

protected:
    Q_SLOT void onInitialized() override;

    Q_SIGNAL void modelUpdated();
    void updateModel();
    // Classes that implement ConversationListModelBase may
    // override this to connect if needed to the model's signals
    // post initialization and if the model changes.
    Q_SLOT virtual void onModelUpdated() {};

    void connectModel();

public:
    QHash<int, QByteArray> roleNames() const override;
    QVariant dataForItem(item_t item, int role) const;

protected:
    using Role = ConversationList::Role;

    // Convenience pointer to be pulled from lrcinstance
    ConversationModel* model_ {nullptr};
    QVector<QMetaObject::Connection> modelBindings_;
};
