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

#include "webengineutils.h"

#include <QCoreApplication>
#include <QVariant>

#if defined(Q_OS_WIN) && (defined(Q_PROCESSOR_X86_32) || defined(Q_PROCESSOR_X86_64))
#ifdef Q_CC_MSVC
#include <intrin.h>
#else
#include <cpuid.h>
#endif
#endif

namespace Utils {
namespace {

bool
x86CpuHasSse3()
{
#if defined(Q_OS_WIN) && (defined(Q_PROCESSOR_X86_32) || defined(Q_PROCESSOR_X86_64))
#ifdef Q_CC_MSVC
    int cpuInfo[4] = {};
    __cpuid(cpuInfo, 1);
    return (cpuInfo[2] & 0x1) != 0;
#else
    unsigned int eax = 0;
    unsigned int ebx = 0;
    unsigned int ecx = 0;
    unsigned int edx = 0;
    if (!__get_cpuid(1, &eax, &ebx, &ecx, &edx))
        return false;
    return (ecx & bit_SSE3) != 0;
#endif
#else
    return true;
#endif
}

} // namespace

QByteArray
chromiumFlagsForWebEngine(QByteArray flags)
{
    if (!flags.isEmpty())
        flags.append(' ');
    // Keep user-provided Chromium flags, then add Jami's crash workarounds.
    flags.append("--disable-web-security --single-process --disable-gpu");
    return flags;
}

bool
webEngineRuntimeAvailable(bool cpuSupported)
{
    return WITH_WEBENGINE && cpuSupported;
}

bool
isWebEngineCpuSupported()
{
    return x86CpuHasSse3();
}

bool
isWebEngineRuntimeAvailable()
{
    return webEngineRuntimeAvailable(isWebEngineCpuSupported());
}

void
configureWebEngineEnvironment()
{
    // --single-process avoids spawning a QtWebEngineProcess per message webview.
    // --disable-gpu keeps Chromium's in-process GPU crashes from taking Jami down.
    qputenv("QTWEBENGINE_CHROMIUM_FLAGS",
            chromiumFlagsForWebEngine(qgetenv("QTWEBENGINE_CHROMIUM_FLAGS")));
}

bool
isWebEngineEnabledForQml()
{
    if (qApp) {
        const auto runtimeAvailable = qApp->property(WebEngineRuntimeAvailableProperty);
        if (runtimeAvailable.isValid())
            return webEngineRuntimeAvailable(runtimeAvailable.toBool());
    }
    return isWebEngineRuntimeAvailable();
}

} // namespace Utils
