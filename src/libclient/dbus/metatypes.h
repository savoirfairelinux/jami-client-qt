/******************************************************************************
 *   Copyright (C) 2009-2025 Savoir-faire Linux Inc.                          *
 *                                                                            *
 *   This library is free software; you can redistribute it and/or            *
 *   modify it under the terms of the GNU Lesser General Public               *
 *   License as published by the Free Software Foundation; either             *
 *   version 2.1 of the License, or (at your option) any later version.       *
 *                                                                            *
 *   This library is distributed in the hope that it will be useful,          *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU        *
 *   Lesser General Public License for more details.                          *
 *                                                                            *
 *   You should have received a copy of the Lesser GNU General Public License *
 *   along with this program.  If not, see <http://www.gnu.org/licenses/>.    *
 *****************************************************************************/
#pragma once

#include <QtCore/QMetaType>
#include <QtCore/QMap>
#include <QtCore/QVector>
#include <QtCore/QString>

#include "../typedefs.h"

#ifndef ENABLE_LIBWRAP
#include <QtDBus/QtDBus>
#endif
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wzero-as-null-pointer-constant"

Q_DECLARE_METATYPE(MapStringString)
Q_DECLARE_METATYPE(MapStringInt)
Q_DECLARE_METATYPE(VectorMapStringString)
Q_DECLARE_METATYPE(MapStringMapStringStringList)
Q_DECLARE_METATYPE(VectorInt)
Q_DECLARE_METATYPE(VectorUInt)
Q_DECLARE_METATYPE(VectorULongLong)
Q_DECLARE_METATYPE(VectorString)
Q_DECLARE_METATYPE(MapStringVectorString)
Q_DECLARE_METATYPE(VectorVectorByte)
Q_DECLARE_METATYPE(DataTransferInfo)
Q_DECLARE_METATYPE(SwarmMessage)
Q_DECLARE_METATYPE(uint64_t)
Q_DECLARE_METATYPE(Message)

#ifndef ENABLE_LIBWRAP
static inline QDBusArgument&
operator<<(QDBusArgument& argument, const DataTransferInfo& info)
{
    argument.beginStructure();
    argument << info.accountId;
    argument << info.lastEvent;
    argument << info.flags;
    argument << info.totalSize;
    argument << info.bytesProgress;
    argument << info.author;
    argument << info.peer;
    argument << info.conversationId;
    argument << info.displayName;
    argument << info.path;
    argument << info.mimetype;
    argument.endStructure();

    return argument;
}

static inline const QDBusArgument&
operator>>(const QDBusArgument& argument, DataTransferInfo& info)
{
    argument.beginStructure();
    argument >> info.accountId;
    argument >> info.lastEvent;
    argument >> info.flags;
    argument >> info.totalSize;
    argument >> info.bytesProgress;
    argument >> info.author;
    argument >> info.peer;
    argument >> info.conversationId;
    argument >> info.displayName;
    argument >> info.path;
    argument >> info.mimetype;
    argument.endStructure();

    return argument;
}

static inline QDBusArgument&
operator<<(QDBusArgument& argument, const SwarmMessage& m)
{
    argument.beginStructure();
    argument << m.id;
    argument << m.type;
    argument << m.linearizedParent;
    argument << m.body;
    argument << m.reactions;
    argument << m.editions;
    argument << m.status;
    argument.endStructure();

    return argument;
}

static inline const QDBusArgument&
operator>>(const QDBusArgument& argument, SwarmMessage& m)
{
    argument.beginStructure();
    argument >> m.id;
    argument >> m.type;
    argument >> m.linearizedParent;
    argument >> m.body;
    argument >> m.reactions;
    argument >> m.editions;
    argument >> m.status;
    argument.endStructure();

    return argument;
}

static inline QDBusArgument&
operator<<(QDBusArgument& argument, const Message& m)
{
    argument.beginStructure();
    argument << m.from;
    argument << m.payloads;
    argument << m.received;
    argument.endStructure();

    return argument;
}

static inline const QDBusArgument&
operator>>(const QDBusArgument& argument, Message& m)
{
    argument.beginStructure();
    argument >> m.from;
    argument >> m.payloads;
    argument >> m.received;
    argument.endStructure();

    return argument;
}
#endif

#ifndef ENABLE_LIBWRAP
static bool dbus_metaTypeInit = false;
#endif
inline void
registerCommTypes()
{
#ifndef ENABLE_LIBWRAP
    qRegisterMetaType<MapStringString>("MapStringString");
    qDBusRegisterMetaType<MapStringString>();
    qRegisterMetaType<MapStringInt>("MapStringInt");
    qDBusRegisterMetaType<MapStringInt>();
    qRegisterMetaType<VectorMapStringString>("VectorMapStringString");
    qDBusRegisterMetaType<VectorMapStringString>();
    qRegisterMetaType<MapStringMapStringVectorString>("MapStringMapStringVectorString");
    qDBusRegisterMetaType<MapStringMapStringVectorString>();
    qRegisterMetaType<VectorInt>("VectorInt");
    qDBusRegisterMetaType<VectorInt>();
    qRegisterMetaType<VectorUInt>("VectorUInt");
    qDBusRegisterMetaType<VectorUInt>();
    qRegisterMetaType<VectorULongLong>("VectorULongLong");
    qDBusRegisterMetaType<VectorULongLong>();
    qRegisterMetaType<VectorString>("VectorString");
    qDBusRegisterMetaType<VectorString>();
    qRegisterMetaType<MapStringVectorString>("MapStringVectorString");
    qDBusRegisterMetaType<MapStringVectorString>();
    qRegisterMetaType<VectorVectorByte>("VectorVectorByte");
    qDBusRegisterMetaType<VectorVectorByte>();
    qRegisterMetaType<DataTransferInfo>("DataTransferInfo");
    qDBusRegisterMetaType<DataTransferInfo>();
    qRegisterMetaType<SwarmMessage>("SwarmMessage");
    qDBusRegisterMetaType<SwarmMessage>();
    qRegisterMetaType<VectorSwarmMessage>("VectorSwarmMessage");
    qDBusRegisterMetaType<VectorSwarmMessage>();
    qRegisterMetaType<Message>("Message");
    qDBusRegisterMetaType<Message>();
    qRegisterMetaType<QVector<Message>>("QVector<Message>");
    qDBusRegisterMetaType<QVector<Message>>();
    dbus_metaTypeInit = true;
#endif
}

#pragma GCC diagnostic pop
