/*
 * Copyright (C) 2020-2022 Savoir-faire Linux Inc.
 * Author: Edric Ladent Milaret <edric.ladent-milaret@savoirfairelinux.com>
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
 * Author: Mingrui Zhang   <mingrui.zhang@savoirfairelinux.com>
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

#include "contactadapter.h"

#include "lrcinstance.h"

ContactAdapter::ContactAdapter(LRCInstance* instance, QObject* parent)
    : QmlAdapterBase(instance, parent)
{
    if (lrcInstance_) {
        connectSignals();
        connect(lrcInstance_, &LRCInstance::currentAccountIdChanged, this, [this] {
            connectSignals();
        });
    }
}

void
ContactAdapter::removeContact(const QString& peerUri, bool banContact)
{
    auto& accInfo = lrcInstance_->getCurrentAccountInfo();
    accInfo.contactModel->removeContact(peerUri, banContact);
}

void
ContactAdapter::connectSignals()
{
    if (lrcInstance_->getCurrentContactModel())
        connect(lrcInstance_->getCurrentContactModel(),
                &ContactModel::bannedStatusChanged,
                this,
                &ContactAdapter::bannedStatusChanged,
                Qt::UniqueConnection);
}
