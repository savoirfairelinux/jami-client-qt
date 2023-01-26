/*
 * Copyright (C) 2020-2022 Savoir-faire Linux Inc.
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

#pragma once

#include <QObject>

class LRCInstance;

// Base class for adapters that need an LRC instance.
class QmlAdapterBase : public QObject
{
    Q_OBJECT
public:
    explicit QmlAdapterBase(LRCInstance* instance, QObject* parent = nullptr)
        : QObject(parent)
        , lrcInstance_(instance) {};

    virtual ~QmlAdapterBase() = default;

protected:
    // LRCInstance pointer
    LRCInstance* lrcInstance_ {nullptr};
};
