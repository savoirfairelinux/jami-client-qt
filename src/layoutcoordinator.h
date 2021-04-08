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
 *
 * \file layoutcoordinator.h
 */

#pragma once

#include <QObject>
#include <QString>

class LayoutCoordinator : public QObject
{
    Q_OBJECT
public:
    explicit LayoutCoordinator(QObject* parent = nullptr)
        : QObject(parent) {};
    ~LayoutCoordinator() = default;

    Q_INVOKABLE void setRootView(QObject* obj)
    {
        rootView_ = obj;
    }

Q_SIGNALS:
    void pushView()

private:
    std::map<QString, QObject*> views_;
    QObject* rootView_ {nullptr};
};
