/*
 * Copyright (C) 2021 by Savoir-faire Linux
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

#include <QAbstractListModel>
#include <QObject>

#define PF_ROLES \
    X(FileName) \
    X(FileSizeInByte) \
    X(IsImage)

namespace PendingFiles {
Q_NAMESPACE
enum Role {
    DummyRole = Qt::UserRole + 1,
#define X(role) role,
    PF_ROLES
#undef X
};
Q_ENUM_NS(Role)

struct Item
{
    QString filePath;
    bool isImage;
    qint64 fileSizeInByte;
};
} // namespace PendingFiles

class PendingFilesToSendListModel : public QAbstractListModel
{
    Q_OBJECT
public:
    PendingFilesToSendListModel(QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void addToPending(QString filePath);
    Q_INVOKABLE void removeFromPending(int index);
    Q_INVOKABLE void flush(int index);

private:
    QList<PendingFiles::Item> pendingFiles_;
};
