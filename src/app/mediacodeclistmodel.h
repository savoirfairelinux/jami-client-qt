/*
 * Copyright (C) 2020-2025 Savoir-faire Linux Inc.
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

class MediaCodecListModel : public AbstractListModelBase
{
    Q_OBJECT
    Q_PROPERTY(int mediaType READ mediaType WRITE setMediaType NOTIFY mediaTypeChanged)
public:
    enum MediaType { VIDEO, AUDIO };
    enum Role { MediaCodecName = Qt::UserRole + 1, IsEnabled, MediaCodecID, Samplerate };
    Q_ENUM(Role)

    explicit MediaCodecListModel(QObject* parent = nullptr);
    ~MediaCodecListModel();

    // QAbstractListModel override.
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;
    QModelIndex index(int row,
                      int column = 0,
                      const QModelIndex& parent = QModelIndex()) const override;
    Qt::ItemFlags flags(const QModelIndex& index) const override;

    Q_INVOKABLE void reset();

    int mediaType();
    void setMediaType(int mediaType);

Q_SIGNALS:
    void mediaTypeChanged();

private:
    int mediaType_;
};
