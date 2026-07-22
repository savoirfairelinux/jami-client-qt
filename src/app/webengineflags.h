/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
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

#include <QByteArray>

namespace jami::webengine {

inline constexpr auto kDisableWebSecurity = "--disable-web-security";
inline constexpr auto kDisableGpu = "--disable-gpu";
inline constexpr auto kDisableHandleVerifier = "--disable-handle-verifier";

inline bool
hasChromiumFlag(const QByteArray& flags, const char* expected)
{
    const auto flagList = flags.split(' ');
    for (const auto& flag : flagList) {
        if (flag == expected)
            return true;
    }
    return false;
}

inline void
appendChromiumFlag(QByteArray& flags, const char* flag)
{
    if (hasChromiumFlag(flags, flag))
        return;

    if (!flags.isEmpty() && !flags.endsWith(' '))
        flags.append(' ');
    flags.append(flag);
}

inline QByteArray
buildChromiumFlags(QByteArray flags, bool disableWindowsHandleVerifier)
{
    // These flags must be present before QtWebEngine initializes Chromium.
    appendChromiumFlag(flags, kDisableWebSecurity);
    appendChromiumFlag(flags, kDisableGpu);
    if (disableWindowsHandleVerifier)
        appendChromiumFlag(flags, kDisableHandleVerifier);
    return flags;
}

inline void
configureChromiumFlags()
{
#ifdef Q_OS_WIN
    constexpr auto disableWindowsHandleVerifier = true;
#else
    constexpr auto disableWindowsHandleVerifier = false;
#endif
    qputenv("QTWEBENGINE_CHROMIUM_FLAGS",
            buildChromiumFlags(qgetenv("QTWEBENGINE_CHROMIUM_FLAGS"),
                               disableWindowsHandleVerifier));
}

} // namespace jami::webengine
