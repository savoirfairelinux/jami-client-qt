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

#include <QJSEngine>
#include <QQmlEngine>
#include <QObject>

#define NS_MODELS    "net.jami.Models"
#define NS_ADAPTERS  "net.jami.Adapters"
#define NS_CONSTANTS "net.jami.Constants"
#define NS_HELPERS   "net.jami.Helpers"
#define NS_ENUMS     "net.jami.Enums"
#define VER_MAJ      1
#define VER_MIN      0

#include <string>

#ifndef _WIN32
#include <cxxabi.h>
#endif

#ifdef _WIN32
template<typename T>
const std::string
demang() noexcept
{
    return std::string {typeid(T).name()}.substr(6);
}
#else
template<typename T>
std::string
demang() noexcept
{
    int err = 0;
    std::string ret {};
    char* tname = abi::__cxa_demangle(typeid(T).name(), 0, 0, &err);
    ret = err == 0 ? tname : "error";
    std::free(tname);
    return ret;
}
#endif

namespace Utils {
void registerTypes();
}