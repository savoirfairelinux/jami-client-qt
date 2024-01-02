/*
 *  Copyright (C) 2024 Savoir-faire Linux Inc.
 *
 *  Author: Nicolas Vengeon <nicolas.vengeon@savoirfairelinux.com>
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301 USA.
 */

#pragma once

#include "api/interaction.h"

#include <QAbstractListModel>

#define CALLINFO_ROLES \
    X(CALL_ID) \
    X(PEER_NUMBER) \
    X(SOCKETS) \
    X(VIDEO_CODEC) \
    X(AUDIO_CODEC) \
    X(AUDIO_SAMPLE_RATE) \
    X(HARDWARE_ACCELERATION) \
    X(VIDEO_BITRATE)

namespace InfoList {

Q_NAMESPACE
enum Role {
    DummyRole = Qt::UserRole + 1,
#define X(role) role,
    CALLINFO_ROLES
#undef X
};
Q_ENUM_NS(Role)
} // namespace InfoList

class CallInformationListModel : public QAbstractListModel
{
    Q_OBJECT

public:
    CallInformationListModel(QObject* parent = 0);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    Q_INVOKABLE QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    bool addElement(QPair<QString, MapStringString> callInfo);
    void editElement(QPair<QString, MapStringString> callInfo);
    QHash<int, QByteArray> roleNames() const override;
    void reset();
    void removeElement(QString callId);

protected:
    using Role = InfoList::Role;

private:
    QList<QPair<QString, MapStringString>> callsInfolist_;
};
