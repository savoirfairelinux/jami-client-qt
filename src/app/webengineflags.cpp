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

#include "webengineflags.h"

#include <QtGlobal>

#if defined(Q_OS_WIN) \
    && (defined(_M_IX86) || defined(_M_X64) || defined(__i386__) || defined(__x86_64__))
#if defined(_MSC_VER)
#include <intrin.h>
#elif defined(__GNUC__)
#include <cpuid.h>
#endif
#endif

namespace {

void
appendFlag(QByteArray& flags, const QByteArray& flag)
{
    if (!flags.isEmpty())
        flags.append(' ');
    flags.append(flag);
}

#if defined(Q_OS_WIN) \
    && (defined(_M_IX86) || defined(_M_X64) || defined(__i386__) || defined(__x86_64__))
bool
readCpuInfo(int leaf, int subLeaf, int (&registers)[4])
{
#if defined(_MSC_VER)
    __cpuidex(registers, leaf, subLeaf);
    return true;
#elif defined(__GNUC__)
    unsigned int eax = 0;
    unsigned int ebx = 0;
    unsigned int ecx = 0;
    unsigned int edx = 0;
    if (!__get_cpuid_count(leaf, subLeaf, &eax, &ebx, &ecx, &edx))
        return false;
    registers[0] = static_cast<int>(eax);
    registers[1] = static_cast<int>(ebx);
    registers[2] = static_cast<int>(ecx);
    registers[3] = static_cast<int>(edx);
    return true;
#else
    Q_UNUSED(leaf);
    Q_UNUSED(subLeaf);
    Q_UNUSED(registers);
    return false;
#endif
}

quint64
readExtendedControlRegister(unsigned int index)
{
#if defined(_MSC_VER)
    return _xgetbv(index);
#elif defined(__GNUC__)
    unsigned int eax = 0;
    unsigned int edx = 0;
    __asm__ volatile("xgetbv" : "=a"(eax), "=d"(edx) : "c"(index));
    return (static_cast<quint64>(edx) << 32) | eax;
#else
    Q_UNUSED(index);
    return 0;
#endif
}
#endif

} // namespace

bool
currentCpuSupportsAvxInstructions()
{
#if defined(Q_OS_WIN) \
    && (defined(_M_IX86) || defined(_M_X64) || defined(__i386__) || defined(__x86_64__))
    int registers[4] = {};
    if (!readCpuInfo(1, 0, registers))
        return false;

    constexpr auto osxsaveBit = 1 << 27;
    constexpr auto avxBit = 1 << 28;
    if ((registers[2] & (osxsaveBit | avxBit)) != (osxsaveBit | avxBit))
        return false;

    constexpr quint64 xmmStateBit = 1 << 1;
    constexpr quint64 ymmStateBit = 1 << 2;
    const auto xcr0 = readExtendedControlRegister(0);
    return (xcr0 & (xmmStateBit | ymmStateBit)) == (xmmStateBit | ymmStateBit);
#else
    return true;
#endif
}

bool
shouldDisableWebEngineJavascriptJit(bool isWindows, bool hasAvxInstructions)
{
    return isWindows && !hasAvxInstructions;
}

QByteArray
makeWebEngineFlags(const QByteArray& existingFlags, bool disableJavascriptJit)
{
    auto flags = existingFlags;
    appendFlag(flags, "--disable-web-security");
    appendFlag(flags, "--single-process");
    appendFlag(flags, "--disable-gpu");
    if (disableJavascriptJit)
        appendFlag(flags, "--js-flags=--jitless");
    return flags;
}
