/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "webenginebootstrap.h"

#include <QOperatingSystemVersion>
#include <QtGlobal>

namespace WebEngineBootstrap {
namespace {

void
appendFlag(QByteArray& flags, const QByteArray& flag)
{
    if (flags.split(' ').contains(flag))
        return;
    if (!flags.isEmpty())
        flags.append(' ');
    flags.append(flag);
}

}

bool
isWindowsVersionSupported(int majorVersion)
{
    return majorVersion >= 10;
}

bool
isSupportedPlatform()
{
#if defined(Q_OS_WIN)
    return isWindowsVersionSupported(QOperatingSystemVersion::current().majorVersion());
#else
    return true;
#endif
}

QByteArray
chromiumFlagsWithRequiredOptions(const QByteArray& currentFlags)
{
    auto flags = currentFlags.trimmed();
    appendFlag(flags, "--disable-web-security");
    appendFlag(flags, "--disable-gpu");
    return flags;
}

void
configureChromiumFlags()
{
    qputenv("QTWEBENGINE_CHROMIUM_FLAGS",
            chromiumFlagsWithRequiredOptions(qgetenv("QTWEBENGINE_CHROMIUM_FLAGS")));
}

}
