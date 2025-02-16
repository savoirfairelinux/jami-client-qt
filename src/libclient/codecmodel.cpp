/****************************************************************************
 *   Copyright (C) 2017-2025 Savoir-faire Linux Inc.                        *
 *                                                                          *
 *   This library is free software; you can redistribute it and/or          *
 *   modify it under the terms of the GNU Lesser General Public             *
 *   License as published by the Free Software Foundation; either           *
 *   version 2.1 of the License, or (at your option) any later version.     *
 *                                                                          *
 *   This library is distributed in the hope that it will be useful,        *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of         *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU      *
 *   Lesser General Public License for more details.                        *
 *                                                                          *
 *   You should have received a copy of the GNU General Public License      *
 *   along with this program.  If not, see <http://www.gnu.org/licenses/>.  *
 ***************************************************************************/
#include "api/codecmodel.h"

// LRC
#include "callbackshandler.h"
#include "dbus/configurationmanager.h"

// Daemon
#include <account_const.h>

// Qt
#include <QObject>
#include <QList>

// std
#include <mutex>

namespace lrc {

using namespace api;

class CodecModelPimpl : public QObject
{
    Q_OBJECT
public:
    CodecModelPimpl(const CodecModel& linked, const CallbacksHandler& callbacksHandler);
    ~CodecModelPimpl();

    void loadFromDaemon();

    QVector<unsigned int> codecsList_;
    QList<Codec> videoCodecs;
    std::mutex audioCodecsMtx;
    QList<Codec> audioCodecs;
    std::mutex videoCodecsMtx;

    const CallbacksHandler& callbacksHandler;
    const CodecModel& linked;

    void setActiveCodecs();
    void setCodecDetails(const Codec& codec, bool isAudio);

private:
    void addCodec(const unsigned int& id, const QVector<unsigned int>& activeCodecs);
};

CodecModel::CodecModel(const account::Info& owner, const CallbacksHandler& callbacksHandler)
    : owner(owner)
    , pimpl_(std::make_unique<CodecModelPimpl>(*this, callbacksHandler))
{}

CodecModel::~CodecModel() {}

QList<Codec>
CodecModel::getAudioCodecs() const
{
    return pimpl_->audioCodecs;
}

QList<Codec>
CodecModel::getVideoCodecs() const
{
    return pimpl_->videoCodecs;
}

void
CodecModel::increasePriority(const unsigned int& codecId, bool isVideo)
{
    auto& codecs = isVideo ? pimpl_->videoCodecs : pimpl_->audioCodecs;
    auto& mutex = isVideo ? pimpl_->videoCodecsMtx : pimpl_->audioCodecsMtx;
    {
        std::unique_lock<std::mutex> lock(mutex);
        auto it = codecs.begin();
        if (codecs.begin()->id == codecId) {
            // Already at top, abort
            return;
        }
        while (it != codecs.end()) {
            if (it->id == codecId) {
                std::iter_swap(it, std::prev(it));
                break;
            }
            it++;
        }
    }
    pimpl_->setActiveCodecs();
}

void
CodecModel::decreasePriority(const unsigned int& codecId, bool isVideo)
{
    auto& codecs = isVideo ? pimpl_->videoCodecs : pimpl_->audioCodecs;
    auto& mutex = isVideo ? pimpl_->videoCodecsMtx : pimpl_->audioCodecsMtx;
    {
        std::unique_lock<std::mutex> lock(mutex);
        auto it = codecs.begin();
        if (codecs.size() > 0 && (codecs.end() - 1)->id == codecId) {
            // Already at bottom, abort
            return;
        }
        while (it != codecs.end()) {
            if (it->id == codecId) {
                std::iter_swap(it, std::next(it));
                break;
            }
            it++;
        }
    }
    pimpl_->setActiveCodecs();
}

bool
CodecModel::enable(const unsigned int& codecId, bool enabled)
{
    auto redraw = false;
    auto isAudio = true;
    {
        std::unique_lock<std::mutex> lock(pimpl_->videoCodecsMtx);
        auto allDisabled = true;
        for (auto& codec : pimpl_->videoCodecs) {
            if (codec.id == codecId) {
                if (codec.enabled == enabled)
                    return redraw;
                codec.enabled = enabled;
                isAudio = false;
            }
            if (codec.enabled) {
                allDisabled = false;
            }
        }
        if (allDisabled) {
            redraw = true;
        }
    }
    if (isAudio) {
        std::unique_lock<std::mutex> lock(pimpl_->audioCodecsMtx);
        auto allDisabled = true;
        for (auto& codec : pimpl_->audioCodecs) {
            if (codec.id == codecId) {
                if (codec.enabled == enabled)
                    return redraw;
                codec.enabled = enabled;
            }
            if (codec.enabled) {
                allDisabled = false;
            }
        }
        if (allDisabled) {
            redraw = true;
        }
    }
    pimpl_->setActiveCodecs();
    return redraw;
}

void
CodecModel::autoQuality(const unsigned int& codecId, bool on)
{
    auto isAudio = true;
    Codec finalCodec;
    {
        std::unique_lock<std::mutex> lock(pimpl_->videoCodecsMtx);
        for (auto& codec : pimpl_->videoCodecs) {
            if (codec.id == codecId) {
                if (codec.auto_quality_enabled == on)
                    return;
                codec.auto_quality_enabled = on;
                isAudio = false;
                finalCodec = codec;
                break;
            }
        }
    }
    if (isAudio) {
        std::unique_lock<std::mutex> lock(pimpl_->audioCodecsMtx);
        for (auto& codec : pimpl_->audioCodecs) {
            if (codec.id == codecId) {
                if (codec.auto_quality_enabled == on)
                    return;
                codec.auto_quality_enabled = on;
                finalCodec = codec;
                break;
            }
        }
    }
    pimpl_->setCodecDetails(finalCodec, isAudio);
}

void
CodecModel::quality(const unsigned int& codecId, double quality)
{
    auto isAudio = true;
    auto qualityStr = toQString(static_cast<int>(quality));
    Codec finalCodec;
    {
        std::unique_lock<std::mutex> lock(pimpl_->videoCodecsMtx);
        for (auto& codec : pimpl_->videoCodecs) {
            if (codec.id == codecId) {
                if (codec.quality == qualityStr)
                    return;
                codec.quality = qualityStr;
                isAudio = false;
                finalCodec = codec;
                break;
            }
        }
    }
    if (isAudio) {
        std::unique_lock<std::mutex> lock(pimpl_->audioCodecsMtx);
        for (auto& codec : pimpl_->audioCodecs) {
            if (codec.id == codecId) {
                if (codec.quality == qualityStr)
                    return;
                codec.quality = qualityStr;
                finalCodec = codec;
                break;
            }
        }
    }
    pimpl_->setCodecDetails(finalCodec, isAudio);
}

void
CodecModel::bitrate(const unsigned int& codecId, double bitrate)
{
    auto isAudio = true;
    auto bitrateStr = toQString(static_cast<int>(bitrate));
    Codec finalCodec;
    {
        std::unique_lock<std::mutex> lock(pimpl_->videoCodecsMtx);
        for (auto& codec : pimpl_->videoCodecs) {
            if (codec.id == codecId) {
                if (codec.bitrate == bitrateStr)
                    return;
                codec.bitrate = bitrateStr;
                isAudio = false;
                finalCodec = codec;
                break;
            }
        }
    }
    if (isAudio) {
        std::unique_lock<std::mutex> lock(pimpl_->audioCodecsMtx);
        for (auto& codec : pimpl_->audioCodecs) {
            if (codec.id == codecId) {
                if (codec.bitrate == bitrateStr)
                    return;
                codec.bitrate = bitrateStr;
                finalCodec = codec;
                break;
            }
        }
    }
    pimpl_->setCodecDetails(finalCodec, isAudio);
}

CodecModelPimpl::CodecModelPimpl(const CodecModel& linked, const CallbacksHandler& callbacksHandler)
    : linked(linked)
    , callbacksHandler(callbacksHandler)
{
    codecsList_ = ConfigurationManager::instance().getCodecList();
    loadFromDaemon();
}

CodecModelPimpl::~CodecModelPimpl() {}

void
CodecModelPimpl::loadFromDaemon()
{
    {
        std::unique_lock<std::mutex> lock(audioCodecsMtx);
        audioCodecs.clear();
    }
    {
        std::unique_lock<std::mutex> lock(videoCodecsMtx);
        videoCodecs.clear();
    }
    QVector<unsigned int> activeCodecs = ConfigurationManager::instance().getActiveCodecList(
        linked.owner.id);
    for (const auto& id : activeCodecs) {
        addCodec(id, activeCodecs);
    }
    for (const auto& id : codecsList_) {
        if (activeCodecs.indexOf(id) != -1)
            continue;
        addCodec(id, activeCodecs);
    }
}

void
CodecModelPimpl::setActiveCodecs()
{
    QVector<unsigned int> enabledCodecs;
    {
        std::unique_lock<std::mutex> lock(videoCodecsMtx);
        for (auto& codec : videoCodecs) {
            if (codec.enabled) {
                enabledCodecs.push_back(codec.id);
            }
        }
    }
    {
        std::unique_lock<std::mutex> lock(audioCodecsMtx);
        for (auto& codec : audioCodecs) {
            if (codec.enabled) {
                enabledCodecs.push_back(codec.id);
            }
        }
    }
    ConfigurationManager::instance().setActiveCodecList(linked.owner.id, enabledCodecs);
    // Refresh list from daemon
    loadFromDaemon();
}

void
CodecModelPimpl::addCodec(const unsigned int& id, const QVector<unsigned int>& activeCodecs)
{
    MapStringString details = ConfigurationManager::instance().getCodecDetails(linked.owner.id, id);
    Codec codec;
    codec.id = id;
    codec.enabled = activeCodecs.indexOf(id) != -1;
    codec.name = details[libjami::Account::ConfProperties::CodecInfo::NAME];
    codec.samplerate = details[libjami::Account::ConfProperties::CodecInfo::SAMPLE_RATE];
    codec.bitrate = details[libjami::Account::ConfProperties::CodecInfo::BITRATE];
    codec.min_bitrate = details[libjami::Account::ConfProperties::CodecInfo::MIN_BITRATE];
    codec.max_bitrate = details[libjami::Account::ConfProperties::CodecInfo::MAX_BITRATE];
    codec.type = details[libjami::Account::ConfProperties::CodecInfo::TYPE];
    codec.quality = details[libjami::Account::ConfProperties::CodecInfo::QUALITY];
    codec.min_quality = details[libjami::Account::ConfProperties::CodecInfo::MIN_QUALITY];
    codec.max_quality = details[libjami::Account::ConfProperties::CodecInfo::MAX_QUALITY];
    codec.auto_quality_enabled
        = details[libjami::Account::ConfProperties::CodecInfo::AUTO_QUALITY_ENABLED] == "true";
    if (codec.type == "AUDIO") {
        std::unique_lock<std::mutex> lock(audioCodecsMtx);
        audioCodecs.push_back(codec);
    } else {
        std::unique_lock<std::mutex> lock(videoCodecsMtx);
        videoCodecs.push_back(codec);
    }
}

void
CodecModelPimpl::setCodecDetails(const Codec& codec, bool isAudio)
{
    MapStringString details;
    details[libjami::Account::ConfProperties::CodecInfo::NAME] = codec.name;
    details[libjami::Account::ConfProperties::CodecInfo::SAMPLE_RATE] = codec.samplerate;
    details[libjami::Account::ConfProperties::CodecInfo::BITRATE] = codec.bitrate;
    details[libjami::Account::ConfProperties::CodecInfo::MIN_BITRATE] = codec.min_bitrate;
    details[libjami::Account::ConfProperties::CodecInfo::MAX_BITRATE] = codec.max_bitrate;
    details[libjami::Account::ConfProperties::CodecInfo::TYPE] = isAudio ? "AUDIO" : "VIDEO";
    details[libjami::Account::ConfProperties::CodecInfo::QUALITY] = codec.quality;
    details[libjami::Account::ConfProperties::CodecInfo::MIN_QUALITY] = codec.min_quality;
    details[libjami::Account::ConfProperties::CodecInfo::MAX_QUALITY] = codec.max_quality;
    details[libjami::Account::ConfProperties::CodecInfo::AUTO_QUALITY_ENABLED]
        = codec.auto_quality_enabled ? "true" : "false";
    ConfigurationManager::instance().setCodecDetails(linked.owner.id, codec.id, details);
}

} // namespace lrc

#include "codecmodel.moc"
#include "api/moc_codecmodel.cpp"
