/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
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

#include <QJSEngine>
#include <QQmlEngine>
#include <QObject>

#define NS_MODELS      "net.jami.Models"
#define NS_ADAPTERS    "net.jami.Adapters"
#define NS_CONSTANTS   "net.jami.Constants"
#define NS_HELPERS     "net.jami.Helpers"
#define NS_ENUMS       "net.jami.Enums"
#define MODULE_VER_MAJ 1
#define MODULE_VER_MIN 1

class SystemTray;
class LRCInstance;
class AppSettingsManager;
class PreviewEngine;
class ScreenInfo;
class MainApplication;
class ConnectivityMonitor;

// Hack for QtCreator autocomplete (part 1)
// https://bugreports.qt.io/browse/QTCREATORBUG-20569
namespace dummy {
Q_NAMESPACE
Q_CLASSINFO("RegisterEnumClassesUnscoped", "false")
} // namespace dummy

// clang-format off
#define QML_REGISTERSINGLETONTYPE_POBJECT(NS, I, N) \
    QQmlEngine::setObjectOwnership(I, QQmlEngine::CppOwnership); \
    { using T = std::remove_reference<decltype(*I)>::type; \
    qmlRegisterSingletonType<T>(NS, MODULE_VER_MAJ, MODULE_VER_MIN, N, \
                                [i=I](QQmlEngine*, QJSEngine*) -> QObject* { \
                                    return i; }); }

#define QML_REGISTERSINGLETONTYPE_CUSTOM(NS, T, P) \
    QQmlEngine::setObjectOwnership(P, QQmlEngine::CppOwnership); \
    qmlRegisterSingletonType<T>(NS, MODULE_VER_MAJ, MODULE_VER_MIN, #T, \
                                [p=P](QQmlEngine*, QJSEngine*) -> QObject* { \
                                    return p; \
                                });

#define QML_REGISTERSINGLETONTYPE_WITH_INSTANCE(T) \
    QQmlEngine::setObjectOwnership(&T::instance(), QQmlEngine::CppOwnership); \
    qmlRegisterSingletonType<T>(NS_MODELS, MODULE_VER_MAJ, MODULE_VER_MIN, #T, \
                                [](QQmlEngine* e, QJSEngine* se) -> QObject* { \
                                    Q_UNUSED(e); Q_UNUSED(se); \
                                    return &(T::instance()); \
                                });

#define QML_REGISTERSINGLETONTYPE_URL(NS, URL, T) \
    qmlRegisterSingletonType(QUrl(QStringLiteral(URL)), NS, MODULE_VER_MAJ, MODULE_VER_MIN, #T);

#define QML_REGISTERTYPE(NS, T) qmlRegisterType<T>(NS, MODULE_VER_MAJ, MODULE_VER_MIN, #T);

#define QML_REGISTERNAMESPACE(NS, T, NAME) \
    qmlRegisterUncreatableMetaObject(T, NS, MODULE_VER_MAJ, MODULE_VER_MIN, NAME, "")

#define QML_REGISTERUNCREATABLE(N, T) \
    qmlRegisterUncreatableType<T>(N, MODULE_VER_MAJ, MODULE_VER_MIN, #T, "Don't try to add to a qml definition of " #T);

#define QML_REGISTERUNCREATABLE_IN_NAMESPACE(T, NAMESPACE) \
    qmlRegisterUncreatableType<NAMESPACE::T>(NS_MODELS, \
                                             MODULE_VER_MAJ, MODULE_VER_MIN, #T, \
                                             "Don't try to add to a qml definition of " #T);
// clang-format on

namespace Utils {
void registerTypes(QQmlEngine* engine);
}
