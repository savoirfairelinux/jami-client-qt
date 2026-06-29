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

// Linux implementation of CallControlDevice.
//
// It uses libudev to enumerate and hotplug-monitor "hidraw" devices, keeps the
// ones that expose the HID Telephony page (Hook Switch / Phone Mute inputs), and
// reads their input reports to surface button presses. The current call state is
// reflected back onto the device LEDs (HID LED page output reports). Everything
// runs on the owner thread through QSocketNotifier, so no extra thread is needed.

#include "callcontroldevice.h"

#include <QSocketNotifier>
#include <QHash>
#include <QPointer>
#include <QLoggingCategory>

#include <libudev.h>
#include <linux/hidraw.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <unistd.h>

#include <algorithm>
#include <array>
#include <chrono>
#include <cstdint>
#include <vector>

namespace {

// HID usage pages and usages we care about.
constexpr uint16_t kPageTelephony = 0x0b;
constexpr uint16_t kPageLed = 0x08;

constexpr uint16_t kTelHookSwitch = 0x20;
constexpr uint16_t kTelPhoneMute = 0x2f;

constexpr uint16_t kLedOffHook = 0x17; // active call
constexpr uint16_t kLedMute = 0x09;    // microphone muted
constexpr uint16_t kLedRing = 0x18;    // incoming call

// HID item prefixes (tag|type, size bits masked out).
constexpr uint8_t kItemUsagePage = 0x04;   // global
constexpr uint8_t kItemReportId = 0x84;    // global
constexpr uint8_t kItemReportSize = 0x74;  // global
constexpr uint8_t kItemReportCount = 0x94; // global
constexpr uint8_t kItemUsage = 0x08;       // local
constexpr uint8_t kItemUsageMin = 0x18;    // local
constexpr uint8_t kItemUsageMax = 0x28;    // local
constexpr uint8_t kItemInput = 0x80;       // main
constexpr uint8_t kItemOutput = 0x90;      // main
constexpr uint8_t kItemFeature = 0xb0;     // main
constexpr uint8_t kItemCollection = 0xa0;
constexpr uint8_t kItemEndCollection = 0xc0;

// Location of a single-bit control inside a HID report.
struct BitLocation
{
    bool valid {false};
    uint8_t reportId {0};
    uint16_t bitOffset {0}; // bit offset within the report payload (after the id)
};

// Result of parsing a report descriptor for the controls we use.
struct DeviceLayout
{
    BitLocation hook;       // Telephony input
    BitLocation mute;       // Telephony input
    BitLocation ledOffHook; // LED output
    BitLocation ledMute;    // LED output
    BitLocation ledRing;    // LED output
    bool numbered {false};  // whether the descriptor declares Report IDs

    bool hasInputs() const
    {
        return hook.valid || mute.valid;
    }
};

// Minimal HID report-descriptor walker. It tracks the global/local item state
// required to compute the bit offset of each control, and records the offsets of
// the Telephony inputs and LED outputs we drive.
class DescriptorParser
{
public:
    DeviceLayout parse(const uint8_t* data, size_t size)
    {
        DeviceLayout layout;
        size_t i = 0;
        while (i < size) {
            const uint8_t prefix = data[i++];
            uint8_t len = prefix & 0x03;
            if (len == 3)
                len = 4;
            uint32_t value = 0;
            for (uint8_t b = 0; b < len && i < size; ++b)
                value |= static_cast<uint32_t>(data[i++]) << (8 * b);
            handleItem(prefix & 0xfc, value, len, layout);
        }
        return layout;
    }

private:
    struct Usage
    {
        uint16_t page;
        uint16_t usage;
    };

    void handleItem(uint8_t item, uint32_t value, uint8_t len, DeviceLayout& layout)
    {
        switch (item) {
        case kItemUsagePage:
            usagePage_ = static_cast<uint16_t>(value);
            break;
        case kItemReportId:
            reportId_ = static_cast<uint8_t>(value);
            layout.numbered = true;
            break;
        case kItemReportSize:
            reportSize_ = value;
            break;
        case kItemReportCount:
            reportCount_ = value;
            break;
        case kItemUsage:
            // A 4-byte usage carries its page in the high word.
            if (len == 4)
                usages_.push_back({static_cast<uint16_t>(value >> 16), static_cast<uint16_t>(value & 0xffff)});
            else
                usages_.push_back({usagePage_, static_cast<uint16_t>(value)});
            break;
        case kItemUsageMin:
            usageMin_ = {len == 4 ? static_cast<uint16_t>(value >> 16) : usagePage_,
                         static_cast<uint16_t>(value & 0xffff)};
            usageMinSet_ = true;
            break;
        case kItemUsageMax:
            usageMax_ = {len == 4 ? static_cast<uint16_t>(value >> 16) : usagePage_,
                         static_cast<uint16_t>(value & 0xffff)};
            usageMaxSet_ = true;
            break;
        case kItemInput:
            consumeMain(true, value, layout);
            resetLocals();
            break;
        case kItemOutput:
            consumeMain(false, value, layout);
            resetLocals();
            break;
        case kItemFeature:
            featureBits_[reportId_] = static_cast<uint16_t>(featureBits_[reportId_] + reportCount_ * reportSize_);
            resetLocals();
            break;
        case kItemCollection:
        case kItemEndCollection:
            resetLocals();
            break;
        default:
            break;
        }
    }

    void consumeMain(bool isInput, uint32_t mainFlags, DeviceLayout& layout)
    {
        const bool constant = (mainFlags & 0x01) != 0; // constant => padding, no usage
        uint16_t& cursor = isInput ? inputBits_[reportId_] : outputBits_[reportId_];
        if (!constant) {
            // The fields of this item take their usages from the explicit Usage
            // items, then from the Usage Minimum/Maximum range. The last usage
            // repeats if there are more fields than usages.
            std::vector<Usage> usages = usages_;
            if (usageMinSet_ && usageMaxSet_ && usageMax_.usage >= usageMin_.usage) {
                for (uint16_t u = usageMin_.usage;; ++u) {
                    usages.push_back({usageMin_.page, u});
                    if (u == usageMax_.usage)
                        break;
                }
            }
            for (uint32_t f = 0; f < reportCount_ && !usages.empty(); ++f) {
                const Usage u = usages[std::min<size_t>(f, usages.size() - 1)];
                record(isInput, u, static_cast<uint16_t>(cursor + f * reportSize_), layout);
            }
        }
        cursor = static_cast<uint16_t>(cursor + reportCount_ * reportSize_);
    }

    void resetLocals()
    {
        usages_.clear();
        usageMinSet_ = false;
        usageMaxSet_ = false;
    }

    void record(bool isInput, const Usage& u, uint16_t bitOffset, DeviceLayout& layout)
    {
        if (isInput && u.page == kPageTelephony) {
            if (u.usage == kTelHookSwitch)
                layout.hook = {true, reportId_, bitOffset};
            else if (u.usage == kTelPhoneMute)
                layout.mute = {true, reportId_, bitOffset};
        } else if (!isInput && u.page == kPageLed) {
            if (u.usage == kLedOffHook)
                layout.ledOffHook = {true, reportId_, bitOffset};
            else if (u.usage == kLedMute)
                layout.ledMute = {true, reportId_, bitOffset};
            else if (u.usage == kLedRing)
                layout.ledRing = {true, reportId_, bitOffset};
        }
    }

    uint16_t usagePage_ {0};
    uint8_t reportId_ {0};
    uint32_t reportSize_ {0};
    uint32_t reportCount_ {0};
    std::vector<Usage> usages_;
    Usage usageMin_ {0, 0};
    Usage usageMax_ {0, 0};
    bool usageMinSet_ {false};
    bool usageMaxSet_ {false};
    std::array<uint16_t, 256> inputBits_ {};
    std::array<uint16_t, 256> outputBits_ {};
    std::array<uint16_t, 256> featureBits_ {};
};

} // namespace

Q_LOGGING_CATEGORY(LOG_CALLCTL, "jami.callcontroldevice")

class CallControlDevice::Impl : public QObject
{
    Q_OBJECT
public:
    explicit Impl(CallControlDevice* parent)
        : QObject(parent)
        , parent_(*parent)
    {
        udev_ = udev_new();
        if (!udev_)
            return;
        monitor_ = udev_monitor_new_from_netlink(udev_, "udev");
        if (monitor_) {
            udev_monitor_filter_add_match_subsystem_devtype(monitor_, "hidraw", nullptr);
            udev_monitor_enable_receiving(monitor_);
            monitorNotifier_ = new QSocketNotifier(udev_monitor_get_fd(monitor_), QSocketNotifier::Read, this);
            connect(monitorNotifier_, &QSocketNotifier::activated, this, &Impl::onMonitorEvent);
        }
        enumerate();
    }

    ~Impl() override
    {
        for (auto it = devices_.begin(); it != devices_.end(); ++it)
            closeDevice(it.value());
        devices_.clear();
        if (monitor_)
            udev_monitor_unref(monitor_);
        if (udev_)
            udev_unref(udev_);
    }

    void applyLeds()
    {
        for (auto it = devices_.begin(); it != devices_.end(); ++it)
            applyLeds(it.value());
    }

    bool ringing_ {false};
    bool inCall_ {false};
    bool muted_ {false};

private:
    struct DeviceCtx
    {
        QString syspath;
        int fd {-1};
        QPointer<QSocketNotifier> notifier;
        DeviceLayout layout;
        bool hookKnown {false};
        bool lastHook {false};
        bool lastMute {false};
        std::chrono::steady_clock::time_point lastHookEvent {};
    };

    void enumerate()
    {
        udev_enumerate* en = udev_enumerate_new(udev_);
        if (!en)
            return;
        udev_enumerate_add_match_subsystem(en, "hidraw");
        udev_enumerate_scan_devices(en);
        udev_list_entry* entry;
        udev_list_entry_foreach(entry, udev_enumerate_get_list_entry(en))
        {
            const char* path = udev_list_entry_get_name(entry);
            udev_device* dev = udev_device_new_from_syspath(udev_, path);
            if (dev) {
                tryAddDevice(dev);
                udev_device_unref(dev);
            }
        }
        udev_enumerate_unref(en);
    }

    void onMonitorEvent()
    {
        udev_device* dev = udev_monitor_receive_device(monitor_);
        if (!dev)
            return;
        const char* action = udev_device_get_action(dev);
        if (action && qstrcmp(action, "add") == 0)
            tryAddDevice(dev);
        else if (action && qstrcmp(action, "remove") == 0)
            removeDevice(QString::fromUtf8(udev_device_get_syspath(dev)));
        udev_device_unref(dev);
    }

    void tryAddDevice(udev_device* dev)
    {
        const char* node = udev_device_get_devnode(dev);
        const char* syspath = udev_device_get_syspath(dev);
        if (!node || !syspath)
            return;
        const QString sys = QString::fromUtf8(syspath);
        if (devices_.contains(sys))
            return;

        const int fd = ::open(node, O_RDWR | O_NONBLOCK);
        if (fd < 0)
            return;

        DeviceLayout layout;
        if (!readLayout(fd, layout) || !layout.hasInputs()) {
            ::close(fd);
            return;
        }

        DeviceCtx ctx;
        ctx.syspath = sys;
        ctx.fd = fd;
        ctx.layout = layout;
        ctx.notifier = new QSocketNotifier(fd, QSocketNotifier::Read, this);
        connect(ctx.notifier, &QSocketNotifier::activated, this, [this, sys] { onReadable(sys); });
        devices_.insert(sys, ctx);
        applyLeds(devices_[sys]);
        qCInfo(LOG_CALLCTL).nospace() << "Using HID telephony device " << node << " (hook=" << layout.hook.valid
                                      << " mute=" << layout.mute.valid << " leds: ring=" << layout.ledRing.valid
                                      << " offhook=" << layout.ledOffHook.valid << " mute=" << layout.ledMute.valid
                                      << ")";
    }

    static bool readLayout(int fd, DeviceLayout& layout)
    {
        int descSize = 0;
        if (ioctl(fd, HIDIOCGRDESCSIZE, &descSize) < 0 || descSize <= 0)
            return false;
        hidraw_report_descriptor desc {};
        desc.size = static_cast<uint32_t>(descSize);
        if (ioctl(fd, HIDIOCGRDESC, &desc) < 0)
            return false;
        DescriptorParser parser;
        layout = parser.parse(desc.value, desc.size);
        return true;
    }

    void onReadable(const QString& sys)
    {
        auto it = devices_.find(sys);
        if (it == devices_.end())
            return;
        DeviceCtx& ctx = it.value();
        uint8_t buf[64];
        for (;;) {
            const ssize_t n = ::read(ctx.fd, buf, sizeof(buf));
            if (n <= 0)
                break;
            handleReport(ctx, buf, static_cast<size_t>(n));
        }
    }

    void handleReport(DeviceCtx& ctx, const uint8_t* buf, size_t n)
    {
        const bool numbered = ctx.layout.numbered;
        if (ctx.layout.hook.valid && reportMatches(ctx.layout.hook, numbered, buf, n)) {
            const bool hook = bitValue(ctx.layout.hook, numbered, buf, n);
            if (!ctx.hookKnown) {
                ctx.hookKnown = true;
                ctx.lastHook = hook;
            } else if (hook != ctx.lastHook) {
                ctx.lastHook = hook;
                // The hook switch may be a latching toggle (one transition per
                // press) or a momentary button (a press is a quick 0->1->0
                // pulse). Coalesce transitions that are close in time so each
                // physical press yields a single intent, then let the app map it
                // to answer/hang up based on the current call state.
                const auto now = std::chrono::steady_clock::now();
                if (now - ctx.lastHookEvent >= std::chrono::milliseconds(300)) {
                    ctx.lastHookEvent = now;
                    qCDebug(LOG_CALLCTL) << "hook switch pressed";
                    Q_EMIT parent_.hookSwitchPressed();
                }
            }
        }
        if (ctx.layout.mute.valid && reportMatches(ctx.layout.mute, numbered, buf, n)) {
            const bool mute = bitValue(ctx.layout.mute, numbered, buf, n);
            if (mute && !ctx.lastMute) {
                qCDebug(LOG_CALLCTL) << "mute button pressed";
                Q_EMIT parent_.muteToggleRequested();
            }
            ctx.lastMute = mute;
        }
    }

    static bool reportMatches(const BitLocation& loc, bool numbered, const uint8_t* buf, size_t n)
    {
        if (!numbered)
            return n >= 1; // unnumbered: a single report type, no id byte to match
        return n >= 1 && buf[0] == loc.reportId;
    }

    static bool bitValue(const BitLocation& loc, bool numbered, const uint8_t* buf, size_t n)
    {
        const size_t byteIndex = (numbered ? 1 : 0) + loc.bitOffset / 8; // skip id byte only if numbered
        if (byteIndex >= n)
            return false;
        return (buf[byteIndex] >> (loc.bitOffset % 8)) & 0x01;
    }

    void applyLeds(DeviceCtx& ctx)
    {
        if (ctx.fd < 0)
            return;
        const struct
        {
            const BitLocation& loc;
            bool on;
        } leds[] = {
            {ctx.layout.ledRing, ringing_},
            {ctx.layout.ledOffHook, inCall_},
            {ctx.layout.ledMute, muted_},
        };
        // Several LED usages can live in the same output report, so build one
        // report per report id with all of its bits set, then write it once;
        // writing them separately would clear the bits set by previous writes.
        std::array<bool, 256> handled {};
        for (const auto& led : leds) {
            if (!led.loc.valid || handled[led.loc.reportId])
                continue;
            const uint8_t reportId = led.loc.reportId;
            handled[reportId] = true;

            uint16_t maxBit = 0;
            for (const auto& other : leds)
                if (other.loc.valid && other.loc.reportId == reportId)
                    maxBit = std::max(maxBit, other.loc.bitOffset);

            const size_t base = ctx.layout.numbered ? 1 : 0;
            std::vector<uint8_t> report(base + maxBit / 8 + 1, 0);
            if (ctx.layout.numbered)
                report[0] = reportId;
            for (const auto& other : leds)
                if (other.loc.valid && other.loc.reportId == reportId && other.on)
                    report[base + other.loc.bitOffset / 8] |= (1u << (other.loc.bitOffset % 8));

            const ssize_t res = ::write(ctx.fd, report.data(), report.size());
            Q_UNUSED(res)
        }
    }

    void removeDevice(const QString& sys)
    {
        auto it = devices_.find(sys);
        if (it == devices_.end())
            return;
        closeDevice(it.value());
        devices_.erase(it);
    }

    void closeDevice(DeviceCtx& ctx)
    {
        if (ctx.notifier) {
            ctx.notifier->setEnabled(false);
            ctx.notifier->deleteLater();
            ctx.notifier.clear();
        }
        if (ctx.fd >= 0) {
            ::close(ctx.fd);
            ctx.fd = -1;
        }
    }

    CallControlDevice& parent_;
    udev* udev_ {nullptr};
    udev_monitor* monitor_ {nullptr};
    QSocketNotifier* monitorNotifier_ {nullptr};
    QHash<QString, DeviceCtx> devices_;
};

CallControlDevice::CallControlDevice(QObject* parent)
    : QObject(parent)
    , pimpl_(std::make_unique<Impl>(this))
{}

CallControlDevice::~CallControlDevice() = default;

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
