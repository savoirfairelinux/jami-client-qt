/*
 * Copyright (C) 2019-2025 Savoir-faire Linux Inc.
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

#include <memory>

class MainApplication;

class InstanceManager final : public QObject
{
    Q_OBJECT;
    Q_DISABLE_COPY(InstanceManager)
public:
    explicit InstanceManager(MainApplication* mainApp);
    ~InstanceManager();

    bool tryToRun(const QByteArray& startUri);
    void tryToKill();

private:
    class Impl;
    std::unique_ptr<Impl> pimpl_;
};
