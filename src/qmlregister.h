/*!
 * Copyright (C) 2020 by Savoir-faire Linux
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

#define NS_MODELS    "net.jami.Models"
#define NS_ADAPTERS  "net.jami.Adapters"
#define NS_CONSTANTS "net.jami.Constants"
#define NS_HELPERS   "net.jami.Helpers"
#define NS_ENUMS     "net.jami.Enums"
#define VER_MAJ      1
#define VER_MIN      0

// clang-format off
// Register a scoped/shared pointer
#define QML_REGISTERSINGLETONTYPE_SPOBJECT(NS, I, N) \
    QQmlEngine::setObjectOwnership(I.data(), QQmlEngine::CppOwnership); \
    { using T = std::remove_reference<decltype(*I.data())>::type; \
    qmlRegisterSingletonType<T>(NS, VER_MAJ, VER_MIN, N, \
                                [this](QQmlEngine*, QJSEngine*) -> QObject* { \
                                    return I.data(); }); }

#define QML_REGISTERSINGLETONTYPE_CUSTOM(NS, T, P) \
    qmlRegisterSingletonType<T>(NS, VER_MAJ, VER_MIN, #T, \
                                [p=P](QQmlEngine* e, QJSEngine* se) -> QObject* { \
                                    Q_UNUSED(e); Q_UNUSED(se); \
                                    return p; \
                                });
// clang-format on

void registerTypes();
