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

// Windows implementation of CallControlDevice.
//
// It uses the SetupAPI to enumerate HID devices, keeps the ones that expose the
// HID Telephony page (Hook Switch / Phone Mute inputs), reads their input
// reports with an overlapped ReadFile loop, and writes HID output reports to
// drive the call-state LEDs. This mirrors the Linux hidraw implementation.
// Hotplug is handled by periodically re-enumerating the present HID devices.

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif

#include "callcontroldevice.h"

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QHash>
#include <QSet>
#include <QStringList>
#include <QTextStream>
#include <QTimer>
#include <QLoggingCategory>
#include <QWinEventNotifier>

#include <windows.h>
#include <setupapi.h>

extern "C" {
#include <hidsdi.h>
#include <hidpi.h>
}

#include <algorithm>
#include <chrono>
#include <cstdint>
#include <vector>

#pragma comment(lib, "hid.lib")
#pragma comment(lib, "setupapi.lib")

namespace {

// HID usage pages and usages we care about.
constexpr USAGE kPageTelephony = 0x0b;
constexpr USAGE kPageLed = 0x08;

constexpr USAGE kTelHookSwitch = 0x20;
constexpr USAGE kTelRingEnable = 0x2d;
constexpr USAGE kTelPhoneMute = 0x2f;

constexpr USAGE kLedOffHook = 0x17; // active call
constexpr USAGE kLedMute = 0x09;    // microphone muted
constexpr USAGE kLedRing = 0x18;    // incoming call

// Re-enumeration interval used to pick up device hotplug events.
constexpr int kPollIntervalMs = 2000;

// Does a HID button capability cover the given (page, usage)?
bool
buttonMatches(const HIDP_BUTTON_CAPS& cap, USAGE page, USAGE usage)
{
    if (cap.UsagePage != page)
        return false;
    if (cap.IsRange)
        return usage >= cap.Range.UsageMin && usage <= cap.Range.UsageMax;
    return cap.NotRange.Usage == usage;
}

QString
bytesToHex(const uint8_t* data, DWORD size)
{
    QString text;
    for (DWORD i = 0; i < size; ++i) {
        if (!text.isEmpty())
            text += ' ';
        text += QString("%1").arg(data[i], 2, 16, QChar('0'));
    }
    return text;
}

} // namespace

Q_LOGGING_CATEGORY(LOG_CALLCTL, "jami.callcontroldevice")

void
logMessage(const QString& message)
{
    qCInfo(LOG_CALLCTL).noquote() << message;

    QFile file(QDir::temp().filePath("jami-callcontrol.log"));
    if (!file.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text))
        return;
    QTextStream stream(&file);
    stream << QDateTime::currentDateTime().toString(Qt::ISODateWithMs) << " " << message << '\n';
}

class CallControlDevice::Impl : public QObject
{
    Q_OBJECT
public:
    explicit Impl(CallControlDevice* parent)
        : QObject(parent)
        , parent_(*parent)
    {
        pollTimer_ = new QTimer(this);
        pollTimer_->setInterval(kPollIntervalMs);
        connect(pollTimer_, &QTimer::timeout, this, &Impl::enumerate);
        pollTimer_->start();
        diagnostic("Windows HID call-control starting");
        enumerate();
    }

    ~Impl() override
    {
        const auto paths = devices_.keys();
        for (const auto& path : paths)
            removeDevice(path);
    }

    void applyLeds()
    {
        if (devices_.isEmpty()) {
            diagnostic("LED request ignored: no HID telephony device is tracked");
            return;
        }
        for (auto it = devices_.begin(); it != devices_.end(); ++it)
            applyLeds(it.value());
    }

    QStringList diagnosticMessages() const { return diagnosticMessages_; }

    void diagnostic(const QString& message)
    {
        diagnosticMessages_.append(message);
        if (diagnosticMessages_.size() > 300)
            diagnosticMessages_.removeFirst();
        logMessage(message);
        Q_EMIT parent_.diagnosticMessage(message);
    }

    bool ringing_ {false};
    bool inCall_ {false};
    bool muted_ {false};

private:
    // A single LED output control we drive.
    struct Led
    {
        bool valid {false};
        UCHAR reportId {0};
        USAGE page {0};
        USAGE usage {0};
    };

    struct DeviceCtx
    {
        QString path;
        HANDLE handle {INVALID_HANDLE_VALUE};
        PHIDP_PREPARSED_DATA preparsed {nullptr};
        USHORT inputLen {0};
        USHORT outputLen {0};
        bool canWrite {false};

        bool hasHook {false};
        UCHAR hookReportId {0};
        bool hasMute {false};
        UCHAR muteReportId {0};

        Led ledOffHook;
        Led ledMute;
        Led ledRing;
        Led ledRingEnable;

        HANDLE readEvent {nullptr};
        QWinEventNotifier* readNotifier {nullptr};
        OVERLAPPED readOverlapped {};
        std::vector<char> readBuffer;
        bool readPending {false};

        // Button state tracking.
        std::vector<uint8_t> lastReport;
        bool hookKnown {false};
        bool lastHook {false};
        bool lastMute {false};
        std::chrono::steady_clock::time_point lastHookEvent {};
        // Off-hook and mute are bidirectional in HID Telephony: writing those
        // LEDs drives the state, which the device echoes back as an input
        // report. Track what we last drove and ignore input briefly after a
        // write so the echo is not mistaken for a physical button press.
        bool lastOffHookWritten {false};
        bool lastMuteWritten {false};
        std::chrono::steady_clock::time_point suppressInputUntil {};

        bool hasInputs() const { return hasHook || hasMute; }
    };

    void startRead(const QString& path)
    {
        auto it = devices_.find(path);
        if (it == devices_.end())
            return;
        DeviceCtx& ctx = it.value();
        if (ctx.handle == INVALID_HANDLE_VALUE || ctx.inputLen == 0 || ctx.readPending)
            return;

        if (!ctx.readEvent) {
            ctx.readEvent = CreateEventW(nullptr, TRUE, FALSE, nullptr);
            if (!ctx.readEvent) {
                diagnostic(QString("CreateEventW for HID read failed error=%1 path=%2")
                               .arg(GetLastError())
                               .arg(ctx.path));
                return;
            }
            ctx.readNotifier = new QWinEventNotifier(ctx.readEvent, this);
            connect(ctx.readNotifier, &QWinEventNotifier::activated, this, [this, path] {
                finishRead(path);
            });
        }

        ResetEvent(ctx.readEvent);
        ctx.readOverlapped = {};
        ctx.readOverlapped.hEvent = ctx.readEvent;
        ctx.readBuffer.assign(ctx.inputLen, 0);

        DWORD bytesRead = 0;
        const BOOL ok = ReadFile(ctx.handle,
                                 ctx.readBuffer.data(),
                                 ctx.readBuffer.size(),
                                 &bytesRead,
                                 &ctx.readOverlapped);
        if (ok) {
            if (bytesRead > 0)
                handleReport(ctx, reinterpret_cast<const uint8_t*>(ctx.readBuffer.data()), bytesRead);
            QTimer::singleShot(0, this, [this, path] { startRead(path); });
            return;
        }

        const DWORD error = GetLastError();
        if (error == ERROR_IO_PENDING) {
            ctx.readPending = true;
            return;
        }

        diagnostic(QString("ReadFile for HID input failed error=%1 path=%2").arg(error).arg(ctx.path));
    }

    void finishRead(const QString& path)
    {
        auto it = devices_.find(path);
        if (it == devices_.end())
            return;
        DeviceCtx& ctx = it.value();
        if (!ctx.readPending)
            return;

        DWORD bytesRead = 0;
        const BOOL ok = GetOverlappedResult(ctx.handle, &ctx.readOverlapped, &bytesRead, FALSE);
        ctx.readPending = false;
        if (ok && bytesRead > 0) {
            handleReport(ctx, reinterpret_cast<const uint8_t*>(ctx.readBuffer.data()), bytesRead);
        } else if (!ok) {
            const DWORD error = GetLastError();
            if (error != ERROR_OPERATION_ABORTED)
                diagnostic(QString("GetOverlappedResult for HID input failed error=%1 path=%2")
                               .arg(error)
                               .arg(ctx.path));
        }
        startRead(path);
    }

    void enumerate()
    {
        GUID hidGuid;
        HidD_GetHidGuid(&hidGuid);

        HDEVINFO info = SetupDiGetClassDevsW(&hidGuid,
                                             nullptr,
                                             nullptr,
                                             DIGCF_PRESENT | DIGCF_DEVICEINTERFACE);
        if (info == INVALID_HANDLE_VALUE)
            return;

        QSet<QString> seen;
        SP_DEVICE_INTERFACE_DATA ifData {};
        ifData.cbSize = sizeof(ifData);
        for (DWORD index = 0;
             SetupDiEnumDeviceInterfaces(info, nullptr, &hidGuid, index, &ifData);
             ++index) {
            DWORD required = 0;
            SetupDiGetDeviceInterfaceDetailW(info, &ifData, nullptr, 0, &required, nullptr);
            if (required == 0)
                continue;
            std::vector<BYTE> buffer(required);
            auto detail = reinterpret_cast<SP_DEVICE_INTERFACE_DETAIL_DATA_W*>(buffer.data());
            detail->cbSize = sizeof(SP_DEVICE_INTERFACE_DETAIL_DATA_W);
            if (!SetupDiGetDeviceInterfaceDetailW(info, &ifData, detail, required, nullptr, nullptr))
                continue;
            const QString path = QString::fromWCharArray(detail->DevicePath);
            seen.insert(path);
            if (!devices_.contains(path))
                tryAddDevice(path);
        }
        SetupDiDestroyDeviceInfoList(info);

        // Drop devices that are no longer present.
        const auto known = devices_.keys();
        for (const auto& path : known)
            if (!seen.contains(path))
                removeDevice(path);
    }

    void tryAddDevice(const QString& path)
    {
        const std::wstring wpath = path.toStdWString();
        DWORD desiredAccess = 0;
        HANDLE handle = CreateFileW(wpath.c_str(),
                                    desiredAccess,
                                    FILE_SHARE_READ | FILE_SHARE_WRITE,
                                    nullptr,
                                    OPEN_EXISTING,
                                    0,
                                    nullptr);
        if (handle == INVALID_HANDLE_VALUE)
            return;

        PHIDP_PREPARSED_DATA preparsed = nullptr;
        if (!HidD_GetPreparsedData(handle, &preparsed)) {
            CloseHandle(handle);
            return;
        }
        HIDP_CAPS caps {};
        if (HidP_GetCaps(preparsed, &caps) != HIDP_STATUS_SUCCESS) {
            HidD_FreePreparsedData(preparsed);
            CloseHandle(handle);
            return;
        }

        DeviceCtx ctx;
        ctx.path = path;
        ctx.inputLen = caps.InputReportByteLength;
        ctx.outputLen = caps.OutputReportByteLength;

        parseInputs(caps, preparsed, ctx);
        parseLeds(caps, preparsed, ctx);

        if (!ctx.hasInputs() || ctx.inputLen == 0) {
            HidD_FreePreparsedData(preparsed);
            CloseHandle(handle);
            return;
        }

        HidD_FreePreparsedData(preparsed);
        CloseHandle(handle);

        desiredAccess = GENERIC_READ | GENERIC_WRITE;
        handle = CreateFileW(wpath.c_str(),
                             desiredAccess,
                             FILE_SHARE_READ | FILE_SHARE_WRITE,
                             nullptr,
                             OPEN_EXISTING,
                             FILE_FLAG_OVERLAPPED,
                             nullptr);
        if (handle == INVALID_HANDLE_VALUE) {
            diagnostic(QString("Open HID telephony device read/write failed error=%1 path=%2")
                           .arg(GetLastError())
                           .arg(path));
            desiredAccess = 0;
            handle = CreateFileW(wpath.c_str(),
                                 desiredAccess,
                                 FILE_SHARE_READ | FILE_SHARE_WRITE,
                                 nullptr,
                                 OPEN_EXISTING,
                                 FILE_FLAG_OVERLAPPED,
                                 nullptr);
        }
        if (handle == INVALID_HANDLE_VALUE) {
            diagnostic(QString("Open HID telephony device metadata-only failed error=%1 path=%2")
                           .arg(GetLastError())
                           .arg(path));
            return;
        }

        preparsed = nullptr;
        if (!HidD_GetPreparsedData(handle, &preparsed)) {
            CloseHandle(handle);
            return;
        }
        caps = {};
        if (HidP_GetCaps(preparsed, &caps) != HIDP_STATUS_SUCCESS) {
            HidD_FreePreparsedData(preparsed);
            CloseHandle(handle);
            return;
        }

        ctx = {};
        ctx.path = path;
        ctx.handle = handle;
        ctx.preparsed = preparsed;
        ctx.inputLen = caps.InputReportByteLength;
        ctx.outputLen = caps.OutputReportByteLength;
        ctx.canWrite = (desiredAccess & GENERIC_WRITE) != 0;
        parseInputs(caps, preparsed, ctx);
        parseLeds(caps, preparsed, ctx);

        devices_.insert(path, ctx);
        DeviceCtx& stored = devices_[path];

        applyLeds(stored);
        startRead(path);

        qCInfo(LOG_CALLCTL).nospace()
            << "Using HID telephony device " << qUtf8Printable(path) << " (hook=" << stored.hasHook
            << " mute=" << stored.hasMute << " leds: ring=" << (stored.ledRing.valid || stored.ledRingEnable.valid)
            << " offhook=" << stored.ledOffHook.valid << " mute=" << stored.ledMute.valid << ")";
        diagnostic(QString("Using HID telephony device %1 hook=%2 mute=%3 leds(ring/offhook/mute)=%4/%5/%6 writable=%7")
                       .arg(path)
                       .arg(stored.hasHook)
                       .arg(stored.hasMute)
                       .arg(stored.ledRing.valid || stored.ledRingEnable.valid)
                       .arg(stored.ledOffHook.valid)
                   .arg(stored.ledMute.valid)
                   .arg(stored.canWrite));
        diagnostic(QString("HID caps inputLen=%1 outputLen=%2 hookReportId=0x%3 muteReportId=0x%4")
                   .arg(stored.inputLen)
                   .arg(stored.outputLen)
                   .arg(stored.hookReportId, 2, 16, QChar('0'))
                   .arg(stored.muteReportId, 2, 16, QChar('0')));
        diagnostic(QString("HID output pages ringLed=0x%1 ringEnable=0x%2 offhook=0x%3 mute=0x%4")
                   .arg(stored.ledRing.page, 2, 16, QChar('0'))
               .arg(stored.ledRingEnable.page, 2, 16, QChar('0'))
                   .arg(stored.ledOffHook.page, 2, 16, QChar('0'))
                   .arg(stored.ledMute.page, 2, 16, QChar('0')));
        diagnostic(QString("HID descriptor handle access=0x%1").arg(desiredAccess, 0, 16));
    }

    static void parseInputs(const HIDP_CAPS& caps, PHIDP_PREPARSED_DATA preparsed, DeviceCtx& ctx)
    {
        if (caps.NumberInputButtonCaps == 0)
            return;
        USHORT count = caps.NumberInputButtonCaps;
        std::vector<HIDP_BUTTON_CAPS> buttons(count);
        if (HidP_GetButtonCaps(HidP_Input, buttons.data(), &count, preparsed) != HIDP_STATUS_SUCCESS)
            return;
        for (USHORT i = 0; i < count; ++i) {
            const HIDP_BUTTON_CAPS& cap = buttons[i];
            if (!ctx.hasHook && buttonMatches(cap, kPageTelephony, kTelHookSwitch)) {
                ctx.hasHook = true;
                ctx.hookReportId = cap.ReportID;
            }
            if (!ctx.hasMute && buttonMatches(cap, kPageTelephony, kTelPhoneMute)) {
                ctx.hasMute = true;
                ctx.muteReportId = cap.ReportID;
            }
        }
    }

    static void parseLeds(const HIDP_CAPS& caps, PHIDP_PREPARSED_DATA preparsed, DeviceCtx& ctx)
    {
        if (caps.NumberOutputButtonCaps == 0)
            return;
        USHORT count = caps.NumberOutputButtonCaps;
        std::vector<HIDP_BUTTON_CAPS> buttons(count);
        if (HidP_GetButtonCaps(HidP_Output, buttons.data(), &count, preparsed) != HIDP_STATUS_SUCCESS)
            return;
        const struct
        {
            USAGE usage;
            USAGE page;
            Led& led;
        } targets[] = {
            {kLedOffHook, kPageLed, ctx.ledOffHook},
            {kLedMute, kPageLed, ctx.ledMute},
            {kLedRing, kPageLed, ctx.ledRing},
            {kTelRingEnable, kPageTelephony, ctx.ledRingEnable},
        };
        for (USHORT i = 0; i < count; ++i) {
            const HIDP_BUTTON_CAPS& cap = buttons[i];
            for (const auto& t : targets) {
                if (!t.led.valid && buttonMatches(cap, t.page, t.usage)) {
                    t.led.valid = true;
                    t.led.reportId = cap.ReportID;
                    t.led.page = t.page;
                    t.led.usage = t.usage;
                }
            }
        }
    }

    void handleReport(DeviceCtx& ctx, const uint8_t* buf, DWORD n)
    {
        // The device streams its current input report continuously; only act on
        // an actual change so we do not flood the log or re-fire button events.
        std::vector<uint8_t> bytes(buf, buf + n);
        if (bytes == ctx.lastReport)
            return;
        ctx.lastReport = std::move(bytes);

        const UCHAR reportId = static_cast<UCHAR>(buf[0]);
        diagnostic(QString("report id=0x%1 bytes=%2")
                       .arg(reportId, 2, 16, QChar('0'))
                       .arg(bytesToHex(buf, n)));

        if (ctx.hasHook && reportId == ctx.hookReportId) {
            const bool hook = usagePresent(ctx, kTelHookSwitch, buf, n);
            diagnostic(QString("hook usage=%1 known=%2 last=%3")
                           .arg(hook)
                           .arg(ctx.hookKnown)
                           .arg(ctx.lastHook));
            const auto now = std::chrono::steady_clock::now();
            const bool echo = now < ctx.suppressInputUntil;
            if (!ctx.hookKnown) {
                ctx.hookKnown = true;
                ctx.lastHook = hook;
                if (hook && !echo) {
                    ctx.lastHookEvent = now;
                    qCDebug(LOG_CALLCTL) << "hook switch pressed";
                    diagnostic("hook switch pressed");
                    Q_EMIT parent_.hookSwitchPressed();
                }
            } else if (hook != ctx.lastHook) {
                ctx.lastHook = hook;
                if (echo) {
                    diagnostic("hook change ignored (LED echo)");
                } else if (now - ctx.lastHookEvent >= std::chrono::milliseconds(300)) {
                    // The hook switch may latch (one transition per press) or be
                    // momentary (a quick 0->1->0 pulse); coalesce transitions
                    // that are close in time so each physical press yields a
                    // single intent, then let the app map it to answer/hang up
                    // based on the current call state.
                    ctx.lastHookEvent = now;
                    qCDebug(LOG_CALLCTL) << "hook switch pressed";
                    diagnostic("hook switch pressed");
                    Q_EMIT parent_.hookSwitchPressed();
                }
            }
        }

        if (ctx.hasMute && reportId == ctx.muteReportId) {
            const bool mute = usagePresent(ctx, kTelPhoneMute, buf, n);
            diagnostic(QString("mute usage=%1 last=%2").arg(mute).arg(ctx.lastMute));
            if (mute && !ctx.lastMute) {
                if (std::chrono::steady_clock::now() < ctx.suppressInputUntil) {
                    diagnostic("mute change ignored (LED echo)");
                } else {
                    qCDebug(LOG_CALLCTL) << "mute button pressed";
                    diagnostic("mute button pressed");
                    Q_EMIT parent_.muteToggleRequested();
                }
            }
            ctx.lastMute = mute;
        }
    }

    static bool usagePresent(DeviceCtx& ctx, USAGE usage, const uint8_t* buf, DWORD n)
    {
        USAGE usages[64];
        ULONG length = static_cast<ULONG>(std::size(usages));
        const NTSTATUS status = HidP_GetUsages(HidP_Input,
                                               kPageTelephony,
                                               0,
                                               usages,
                                               &length,
                                               ctx.preparsed,
                                               const_cast<PCHAR>(reinterpret_cast<const char*>(buf)),
                                               n);
        if (status != HIDP_STATUS_SUCCESS)
            return false;
        for (ULONG i = 0; i < length; ++i)
            if (usages[i] == usage)
                return true;
        return false;
    }

    void applyLeds(DeviceCtx& ctx)
    {
        if (ctx.handle == INVALID_HANDLE_VALUE || ctx.outputLen == 0) {
            diagnostic(QString("LED write skipped for %1: invalid handle or outputLen=0").arg(ctx.path));
            return;
        }
        if (!ctx.canWrite) {
            diagnostic(QString("LED write skipped for %1: HID handle is not writable").arg(ctx.path));
            return;
        }

        // Setting the off-hook or mute LED also drives that telephony state, and
        // the device echoes it back as an input report. Suppress input briefly
        // after such a write so the echo is not mistaken for a button press
        // (which would, e.g., hang up the call we just answered).
        bool driveChanged = false;
        if (ctx.ledOffHook.valid && inCall_ != ctx.lastOffHookWritten) {
            ctx.lastOffHookWritten = inCall_;
            driveChanged = true;
        }
        if (ctx.ledMute.valid && muted_ != ctx.lastMuteWritten) {
            ctx.lastMuteWritten = muted_;
            driveChanged = true;
        }
        if (driveChanged)
            ctx.suppressInputUntil = std::chrono::steady_clock::now() + std::chrono::milliseconds(750);

        const struct
        {
            const Led& led;
            bool on;
        } leds[] = {
            {ctx.ledRing, ringing_},
            {ctx.ledRingEnable, ringing_},
            {ctx.ledOffHook, inCall_},
            {ctx.ledMute, muted_},
        };
        // Several LED usages can live in the same output report, so build one
        // report per report id with all of its bits set, then write it once;
        // writing them separately would clear the bits set by previous writes.
        QSet<UCHAR> handled;
        for (const auto& led : leds) {
            if (!led.led.valid)
                continue;
            if (handled.contains(led.led.reportId))
                continue;
            const UCHAR reportId = led.led.reportId;
            handled.insert(reportId);

            std::vector<char> report(ctx.outputLen, 0);
            report[0] = static_cast<char>(reportId);

            QStringList pageSummaries;
            for (const USAGE page : {kPageLed, kPageTelephony}) {
                USAGE onUsages[8];
                ULONG onCount = 0;
                for (const auto& other : leds)
                    if (other.led.valid && other.led.reportId == reportId && other.led.page == page && other.on
                        && onCount < std::size(onUsages))
                        onUsages[onCount++] = other.led.usage;

                if (onCount == 0)
                    continue;

                ULONG length = onCount;
                const NTSTATUS status = HidP_SetUsages(HidP_Output,
                                                       page,
                                                       0,
                                                       onUsages,
                                                       &length,
                                                       ctx.preparsed,
                                                       report.data(),
                                                       ctx.outputLen);
                pageSummaries.append(QString("page=0x%1 count=%2 status=0x%3")
                                         .arg(page, 2, 16, QChar('0'))
                                         .arg(onCount)
                                         .arg(static_cast<unsigned long>(status), 0, 16));
            }

            const BOOLEAN ok = HidD_SetOutputReport(ctx.handle, report.data(), ctx.outputLen);
            diagnostic(QString("LED output report id=0x%1 usages=[%2] bytes=%3 result=%4 error=%5")
                           .arg(reportId, 2, 16, QChar('0'))
                           .arg(pageSummaries.join(", "))
                           .arg(bytesToHex(reinterpret_cast<const uint8_t*>(report.data()), ctx.outputLen))
                           .arg(ok ? 1 : 0)
                           .arg(ok ? 0 : GetLastError()));
        }
    }

    void removeDevice(const QString& path)
    {
        auto it = devices_.find(path);
        if (it == devices_.end())
            return;
        DeviceCtx& ctx = it.value();
        diagnostic(QString("Removing HID telephony device %1").arg(path));
        if (ctx.readPending) {
            CancelIoEx(ctx.handle, &ctx.readOverlapped);
            ctx.readPending = false;
        }
        if (ctx.readNotifier) {
            ctx.readNotifier->setEnabled(false);
            ctx.readNotifier->deleteLater();
            ctx.readNotifier = nullptr;
        }
        if (ctx.readEvent) {
            CloseHandle(ctx.readEvent);
            ctx.readEvent = nullptr;
        }
        if (ctx.handle != INVALID_HANDLE_VALUE) {
            CloseHandle(ctx.handle);
            ctx.handle = INVALID_HANDLE_VALUE;
        }
        if (ctx.preparsed) {
            HidD_FreePreparsedData(ctx.preparsed);
            ctx.preparsed = nullptr;
        }
        devices_.erase(it);
    }

    CallControlDevice& parent_;
    QTimer* pollTimer_ {nullptr};
    QHash<QString, DeviceCtx> devices_;
    QStringList diagnosticMessages_;
};

CallControlDevice::CallControlDevice(QObject* parent)
    : QObject(parent)
    , pimpl_(std::make_unique<Impl>(this))
{}

CallControlDevice::~CallControlDevice() = default;

QStringList
CallControlDevice::diagnosticMessages() const
{
    return pimpl_->diagnosticMessages();
}

void
CallControlDevice::setRinging(bool ringing)
{
    if (pimpl_->ringing_ == ringing)
        return;
    pimpl_->ringing_ = ringing;
    pimpl_->applyLeds();
}

void
CallControlDevice::setInCall(bool inCall)
{
    if (pimpl_->inCall_ == inCall)
        return;
    pimpl_->inCall_ = inCall;
    pimpl_->applyLeds();
}

void
CallControlDevice::setMuted(bool muted)
{
    if (pimpl_->muted_ == muted)
        return;
    pimpl_->muted_ = muted;
    pimpl_->applyLeds();
}

#include "callcontroldevice.moc"
