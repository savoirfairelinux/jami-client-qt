/*
 * Copyright (C) 2020-2026 Savoir-faire Linux Inc.
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

#include <QSortFilterProxyModel>

class LRCInstance;

class MediaCodecListModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(LRCInstance* lrcInstance READ lrcInstance WRITE setLrcInstance NOTIFY lrcInstanceChanged)
    Q_PROPERTY(int mediaType READ mediaType WRITE setMediaType NOTIFY mediaTypeChanged)
public:
    enum MediaType { VIDEO, AUDIO };

    explicit MediaCodecListModel(QObject* parent = nullptr);
    ~MediaCodecListModel();

    bool filterAcceptsRow(int sourceRow, const QModelIndex& sourceParent) const override;

    Q_INVOKABLE void reset();

    LRCInstance* lrcInstance() const;
    void setLrcInstance(LRCInstance* instance);

    int mediaType();
    void setMediaType(int mediaType);

Q_SIGNALS:
    void lrcInstanceChanged();
    void mediaTypeChanged();

private Q_SLOTS:
    void connectAccount();

private:
    void refreshFilter();

    LRCInstance* lrcInstance_ {nullptr};
    int mediaType_ {AUDIO};
};
