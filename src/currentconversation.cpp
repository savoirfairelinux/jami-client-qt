/*
 * Copyright (C) 2021 by Savoir-faire Linux
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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

#include "currentconversation.h"

CurrentConversation::CurrentConversation(LRCInstance* lrcInstance, QObject* parent)
    : QObject(parent)
    , lrcInstance_(lrcInstance)
{
    connect(lrcInstance_,
            &LRCInstance::selectedConvUidChanged,
            this,
            &CurrentConversation::updateData);
    updateData();
}

void
CurrentConversation::updateData()
{
    auto convId = lrcInstance_->get_selectedConvUid();
    if (convId.isEmpty())
        return;
    set_Id(convId);
    try {
        auto accountId = lrcInstance_->get_currentAccountId();
        const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
        if (auto optConv = accInfo.conversationModel->getConversationForUid(convId)) {
            set_Title(accInfo.conversationModel->title(convId));
            set_Uris(accInfo.conversationModel->peersForConversation(convId).toList());
            set_isSwarm(optConv->get().isSwarm());
            set_IsCoreDialog(optConv->get().isCoreDialog());
            set_isRequest(optConv->get().isRequest);
            set_ReadOnly(optConv->get().readOnly);
            set_needsSyncing(optConv->get().needsSyncing);
            set_isSip(accInfo.profileInfo.type == profile::Type::SIP);
        }
    } catch (...) {
        qWarning() << "Can't update current conversation data for" << convId;
    }
}
