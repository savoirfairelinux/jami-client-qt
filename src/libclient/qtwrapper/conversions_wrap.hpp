/******************************************************************************
 *   Copyright (C) 2014-2023 by Savoir-faire Linux Inc.                       *
 *   Author : Philippe Groarke <philippe.groarke@savoirfairelinux.com>        *
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
#ifndef CONVERSIONS_WRAP_H
#define CONVERSIONS_WRAP_H

#include <map>
#include <string>
#include <vector>
#include <ctime>

#include "../typedefs.h"

#define Q_NOREPLY

// Print all call to some signals
#ifdef VERBOSE_IPC
#define LOG_LIBJAMI_SIGNAL(name, arg) qDebug() << "\033[22;34m >>>>>> \033[0m" << name << arg;
#define LOG_LIBJAMI_SIGNAL2(name, arg, arg2) \
    qDebug() << "\033[22;34m >>>>>> \033[0m" << name << arg << arg2;
#define LOG_LIBJAMI_SIGNAL3(name, arg, arg2, arg3) \
    qDebug() << "\033[22;34m >>>>>> \033[0m" << name << arg << arg2 << arg3;
#define LOG_LIBJAMI_SIGNAL4(name, arg, arg2, arg3, arg4) \
    qDebug() << "\033[22;34m >>>>>> \033[0m" << name << arg << arg2 << arg3 << arg4;
#else
#define LOG_LIBJAMI_SIGNAL(name, args) // Nothing
#define LOG_LIBJAMI_SIGNAL2(name, arg, arg2)
#define LOG_LIBJAMI_SIGNAL3(name, arg, arg2, arg3)
#define LOG_LIBJAMI_SIGNAL4(name, arg, arg2, arg3, arg4)
#endif

inline QVariantMap
mapStringStringToQVariantMap(const MapStringString& map)
{
    QVariantMap convertedMap;
    for (auto i = map.begin(); i != map.end(); i++) {
        convertedMap.insert(i.key(), i.value());
    }
    return convertedMap;
}

inline QVariantMap
mapStringIntToQVariantMap(const MapStringInt& map)
{
    QVariantMap convertedMap;
    for (auto i = map.begin(); i != map.end(); i++) {
        convertedMap.insert(i.key(), i.value());
    }
    return convertedMap;
}

inline MapStringString
convertMap(const std::map<std::string, std::string>& m)
{
    MapStringString temp;
    for (const auto& [key, value] : m) {
        temp[QString(key.c_str())] = QString(value.c_str());
    }
    return temp;
}

inline std::map<std::string, std::string>
convertMap(const MapStringString& m)
{
    std::map<std::string, std::string> temp;
    for (const auto& [key, value] : m.toStdMap()) {
        temp[key.toStdString()] = value.toStdString();
    }
    return temp;
}

inline MapStringInt
convertMap(const std::map<std::string, int32_t>& m)
{
    MapStringInt temp;
    for (const auto& [key, value] : m) {
        temp[QString(key.c_str())] = value;
    }
    return temp;
}

inline std::map<std::string, int32_t>
convertMap(const MapStringInt& m)
{
    std::map<std::string, int32_t> temp;
    for (const auto& [key, value] : m.toStdMap()) {
        temp[key.toStdString()] = value;
    }
    return temp;
}

inline VectorMapStringString
convertVecMap(const std::vector<std::map<std::string, std::string>>& m)
{
    VectorMapStringString temp;
    for (const auto& x : m) {
        temp.push_back(convertMap(x));
    }
    return temp;
}

inline std::vector<std::map<std::string, std::string>>
convertVecMap(const VectorMapStringString& m)
{
    std::vector<std::map<std::string, std::string>> temp;
    for (const auto& x : m) {
        temp.push_back(convertMap(x));
    }
    return temp;
}

inline QStringList
convertStringList(const std::vector<std::string>& v)
{
    QStringList temp;
    for (const auto& x : v) {
        temp.push_back(QString(x.c_str()));
    }
    return temp;
}

inline VectorString
convertVectorString(const std::vector<std::string>& v)
{
    VectorString temp;
    for (const auto& x : v) {
        temp.push_back(QString(x.c_str()));
    }
    return temp;
}

inline std::vector<std::string>
convertVectorString(const VectorString& v)
{
    std::vector<std::string> temp;
    for (const auto& x : v) {
        temp.emplace_back(x.toStdString());
    }
    return temp;
}

inline std::map<std::string, std::vector<std::string>>
convertMap(const MapStringVectorString& m)
{
    std::map<std::string, std::vector<std::string>> temp;
    for (const auto& [key, value] : m.toStdMap()) {
        temp[key.toStdString()] = convertVectorString(value);
    }
    return temp;
}

inline MapStringVectorString
convertMap(const std::map<std::string, std::vector<std::string>>& m)
{
    MapStringVectorString temp;
    for (const auto& [key, value] : m) {
        temp[QString(key.c_str())] = convertVectorString(value);
    }
    return temp;
}

inline VectorULongLong
convertVectorULongLong(const std::vector<uint64_t>& v)
{
    VectorULongLong temp;
    for (const auto& x : v) {
        temp.push_back(x);
    }
    return temp;
}

inline VectorUInt
convertVectorUnsignedInt(const std::vector<unsigned int>& v)
{
    VectorUInt temp;
    for (const auto& x : v) {
        temp.push_back(x);
    }
    return temp;
}

inline std::vector<unsigned int>
convertStdVectorUnsignedInt(const VectorUInt& v)
{
    std::vector<unsigned int> temp;
    for (const auto& x : v) {
        temp.push_back(x);
    }
    return temp;
}

inline std::vector<std::string>
convertStringList(const QStringList& v)
{
    std::vector<std::string> temp;
    for (const auto& x : v) {
        temp.push_back(x.toStdString());
    }
    return temp;
}

inline MapStringInt
convertStringInt(const std::map<std::string, int>& m)
{
    MapStringInt temp;
    for (const auto& [key, value] : m) {
        temp[QString(key.c_str())] = value;
    }
    return temp;
}

static inline QString
toQString(bool b) noexcept
{
    return b ? TRUE_STR : FALSE_STR;
}

static inline QString
toQString(const std::string& str) noexcept
{
    return QString::fromStdString(str);
}

static inline QString
toQString(int i) noexcept
{
    return QString::number(i);
}

static inline QString
toQString(unsigned int i) noexcept
{
    return QString::number(i);
}

static inline QString
toQString(uint64_t i) noexcept
{
    return QString::number(i);
}

static inline bool
toBool(QString qs) noexcept
{
    return qs == TRUE_STR ? true : false;
}

static inline int
toInt(QString qs) noexcept
{
    return qs.toInt();
}

static inline std::string
toStdString(QString qs) noexcept
{
    return qs.toStdString();
}

static inline QString
toQString(const std::time_t& t) noexcept
{
    return QString::fromStdString(std::to_string(t));
}

#endif // CONVERSIONS_WRAP_H
