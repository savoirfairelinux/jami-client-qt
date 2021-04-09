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

#pragma once

#include <QObject>
#include <QKeyEvent>
#include <QDebug>

class CloseHandler : public QObject
{
    Q_OBJECT

public:
    explicit CloseHandler(QObject* parent = nullptr)
        : QObject(parent)
    {}

    Q_INVOKABLE void installFilter(QObject* object)
    {
        if (!object)
            return;
        object->installEventFilter(this);
    }

    bool eventFilter(QObject* object, QEvent* event) override
    {
        if (event->type() == QEvent::Close) {
            Q_EMIT closeEventReceived();
            return true;
        }
        return QObject::eventFilter(object, event);
    }

Q_SIGNALS:
    void closeEventReceived();
};
