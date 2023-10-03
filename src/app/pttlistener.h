/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Edric Ladent Milaret <edric.ladent-milaret@savoirfairelinux.com>
 * Author: Anthony Léonard <anthony.leonard@savoirfairelinux.com>
 * Author: Olivier Soldano <olivier.soldano@savoirfairelinux.com>
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
 * Author: Isa Nanic <isa.nanic@savoirfairelinux.com>
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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

#pragma once

#include <QObject>
#include <QThread>
#include <QKeyEvent>

class PTTListener : public QObject
{
    Q_OBJECT
    Q_DISABLE_COPY(PTTListener)
    Q_PROPERTY(bool pttState READ getPttState WRITE setPttState NOTIFY PTTStateChanged)

public:
    static PTTListener& getInstance()
    {
        static PTTListener instance;
        return instance;
    }

    Q_INVOKABLE bool getPttState()
    {
        return pttState_;
    }

    Q_INVOKABLE void setPttState(bool on)
    {
        if (pttState_ != on) {
            pttState_ = on;
            PTTStateChanged();
        }
    }

    Q_INVOKABLE Qt::Key getCurrentKey()
    {
        return currentKey_;
    }

Q_SIGNALS:
    void PTTKeyPressed();
    void PTTKeyReleased();
    void PTTStateChanged();

public Q_SLOTS:
    void startListening();
    void stopListening();

private:
    PTTListener(QObject* parent = nullptr);
    ~PTTListener();
    class Impl;
    std::unique_ptr<Impl> pimpl_;
    bool pttState_ = true;
    Qt::Key currentKey_ = Qt::Key_Space;
};
