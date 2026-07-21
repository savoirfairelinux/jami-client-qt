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

#include "webengineconfig.h"

#include <QDebug>
#include <QtGlobal>

#if defined(Q_OS_WIN) && (defined(Q_PROCESSOR_X86_64) || defined(Q_PROCESSOR_X86))
#if defined(_MSC_VER)
#include <intrin.h>
#elif defined(__GNUC__)
#include <cpuid.h>
#include <immintrin.h>
#endif
#endif

namespace jami {
namespace {

constexpr auto kDisableWebEngineEnv = "JAMI_DISABLE_WEBENGINE";
constexpr auto kChromiumFlagsEnv = "QTWEBENGINE_CHROMIUM_FLAGS";
constexpr auto kRequiredChromiumFlags = "--disable-web-security --single-process --disable-gpu";

#if defined(Q_OS_WIN) && (defined(Q_PROCESSOR_X86_64) || defined(Q_PROCESSOR_X86))
bool
cpuid(int leaf, int subleaf, int registers[4])
{
#if defined(_MSC_VER)
    int highestLeaf[4] = {};
    __cpuidex(highestLeaf, 0, 0);
    if (highestLeaf[0] < leaf)
        return false;
    __cpuidex(registers, leaf, subleaf);
    return true;
#elif defined(__GNUC__)
    unsigned int eax = 0;
    unsigned int ebx = 0;
    unsigned int ecx = 0;
    unsigned int edx = 0;
    if (!__get_cpuid_count(leaf, subleaf, &eax, &ebx, &ecx, &edx))
        return false;
    registers[0] = static_cast<int>(eax);
    registers[1] = static_cast<int>(ebx);
    registers[2] = static_cast<int>(ecx);
    registers[3] = static_cast<int>(edx);
    return true;
#else
    Q_UNUSED(leaf)
    Q_UNUSED(subleaf)
    Q_UNUSED(registers)
    return false;
#endif
}

quint64
xgetbv0()
{
#if defined(_MSC_VER)
    return _xgetbv(0);
#elif defined(__GNUC__)
    unsigned int eax = 0;
    unsigned int edx = 0;
    __asm__ volatile("xgetbv" : "=a"(eax), "=d"(edx) : "c"(0));
    return (static_cast<quint64>(edx) << 32) | eax;
#else
    return 0;
#endif
}
#endif

} // namespace

QByteArray
webEngineChromiumFlags(const QByteArray& existingFlags)
{
    // Keep these flags together: WebEngine must see them before initialize().
    auto flags = existingFlags.trimmed();
    if (!flags.isEmpty())
        flags.append(' ');
    flags.append(kRequiredChromiumFlags);
    return flags;
}

bool
webEngineCpuSupported()
{
#if defined(Q_OS_WIN) && (defined(Q_PROCESSOR_X86_64) || defined(Q_PROCESSOR_X86))
    int leaf1[4] = {};
    if (!cpuid(1, 0, leaf1))
        return false;

    constexpr auto kOsXsave = 1 << 27;
    constexpr auto kAvx = 1 << 28;
    const auto ecx = leaf1[2];
    if ((ecx & kOsXsave) == 0 || (ecx & kAvx) == 0)
        return false;

    constexpr quint64 kXmmYmmState = 0x6;
    if ((xgetbv0() & kXmmYmmState) != kXmmYmmState)
        return false;

    int leaf7[4] = {};
    if (!cpuid(7, 0, leaf7))
        return false;

    constexpr auto kAvx2 = 1 << 5;
    return (leaf7[1] & kAvx2) != 0;
#else
    return true;
#endif
}

bool
webEngineRuntimeAvailable()
{
    return qEnvironmentVariableIsEmpty(kDisableWebEngineEnv);
}

void
disableWebEngineRuntime()
{
    qputenv(kDisableWebEngineEnv, "1");
}

void
configureWebEngineRuntime()
{
    if (!webEngineRuntimeAvailable())
        return;

    if (!webEngineCpuSupported()) {
        qWarning() << "Disabling Qt WebEngine: CPU does not support the AVX2"
                      " instruction set required by the bundled Chromium.";
        disableWebEngineRuntime();
        return;
    }

    qputenv(kChromiumFlagsEnv, webEngineChromiumFlags(qgetenv(kChromiumFlagsEnv)));
}

} // namespace jami
