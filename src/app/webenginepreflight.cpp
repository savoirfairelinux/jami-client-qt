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

#include "webenginepreflight.h"

#include <QByteArray>
#include <QtGlobal>

#if defined(Q_OS_WIN) && (defined(Q_PROCESSOR_X86_64) || defined(Q_PROCESSOR_X86_32))
#ifdef Q_CC_MSVC
#include <intrin.h>
#else
#include <cpuid.h>
#endif
#endif

namespace {

constexpr auto disableEnv = "JAMI_DISABLE_WEBENGINE";

#if defined(Q_OS_WIN) && (defined(Q_PROCESSOR_X86_64) || defined(Q_PROCESSOR_X86_32))
void
cpuid(int leaf, int subleaf, int cpuInfo[4])
{
#ifdef Q_CC_MSVC
    __cpuidex(cpuInfo, leaf, subleaf);
#else
    __cpuid_count(leaf, subleaf, cpuInfo[0], cpuInfo[1], cpuInfo[2], cpuInfo[3]);
#endif
}

bool
hasRequiredCpuFeatures()
{
    int info[4] = {};
    cpuid(1, 0, info);
    constexpr int sse3 = 1 << 0;
    return (info[2] & sse3) != 0;
}
#endif

} // namespace

namespace WebEnginePreflight {

bool
isRuntimeAvailable()
{
#if WITH_WEBENGINE
    return qEnvironmentVariableIsEmpty(disableEnv);
#else
    return false;
#endif
}

void
disableForUnsupportedCpu()
{
    qputenv(disableEnv, QByteArrayLiteral("unsupported-cpu"));
}

void
disableIfUnsupportedCpu()
{
#if WITH_WEBENGINE && defined(Q_OS_WIN) && (defined(Q_PROCESSOR_X86_64) || defined(Q_PROCESSOR_X86_32))
    if (!hasRequiredCpuFeatures())
        disableForUnsupportedCpu();
#endif
}

} // namespace WebEnginePreflight
