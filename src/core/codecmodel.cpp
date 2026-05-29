/****************************************************************************
 *   Copyright (C) 2017-2026 Savoir-faire Linux Inc.                        *
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
    CodecModelPimpl(CodecModel& linked, const CallbacksHandler& callbacksHandler);
    ~CodecModelPimpl();

    void loadFromDaemon();
    void emitDataChanged(int row);

    QVector<unsigned int> codecsList_;
    QList<Codec> codecs_;
    std::mutex codecsMtx_;

    const CallbacksHandler& callbacksHandler;
    CodecModel& linked;

    void setActiveCodecs();
    void setCodecDetails(const Codec& codec);

private:
    void addCodec(const unsigned int& id, const QVector<unsigned int>& activeCodecs);
};

CodecModel::CodecModel(const account::Info& owner, const CallbacksHandler& callbacksHandler)
    : owner(owner)
    , pimpl_(std::make_unique<CodecModelPimpl>(*this, callbacksHandler))
{}

CodecModel::~CodecModel() {}

int
CodecModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid())
        return 0;
    return pimpl_->codecs_.size();
}

QVariant
CodecModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= pimpl_->codecs_.size())
        return {};

    const auto& codec = pimpl_->codecs_.at(index.row());
    using Role = CodecList::Role;
    switch (role) {
    case Role::MediaCodecName:
        return codec.name;
    case Role::IsEnabled:
        return codec.enabled;
    case Role::MediaCodecID:
        return codec.id;
    case Role::Samplerate:
        return codec.samplerate;
    case Role::Type:
        return codec.type;
    }
    return {};
}

QHash<int, QByteArray>
CodecModel::roleNames() const
{
    using namespace CodecList;
    QHash<int, QByteArray> roles;
    roles[MediaCodecName] = "MediaCodecName";
    roles[IsEnabled] = "IsEnabled";
    roles[MediaCodecID] = "MediaCodecID";
    roles[Samplerate] = "Samplerate";
    roles[Type] = "Type";
    return roles;
}

QList<Codec>
CodecModel::getAudioCodecs() const
{
    QList<Codec> result;
    for (const auto& codec : pimpl_->codecs_)
        if (codec.type == "AUDIO")
            result.append(codec);
    return result;
}

QList<Codec>
CodecModel::getVideoCodecs() const
{
    QList<Codec> result;
    for (const auto& codec : pimpl_->codecs_)
        if (codec.type == "VIDEO")
            result.append(codec);
    return result;
}

void
CodecModel::increasePriority(const unsigned int& codecId, bool isVideo)
{
    QString targetType = isVideo ? "VIDEO" : "AUDIO";
    {
        std::unique_lock<std::mutex> lock(pimpl_->codecsMtx_);
        int prevSameTypeIdx = -1;
        for (int i = 0; i < pimpl_->codecs_.size(); ++i) {
            if (pimpl_->codecs_[i].type == targetType) {
                if (pimpl_->codecs_[i].id == codecId) {
                    if (prevSameTypeIdx < 0)
                        return;
                    pimpl_->codecs_.swapItemsAt(i, prevSameTypeIdx);
                    break;
                }
                prevSameTypeIdx = i;
            }
        }
    }
    pimpl_->setActiveCodecs();
}

void
CodecModel::decreasePriority(const unsigned int& codecId, bool isVideo)
{
    QString targetType = isVideo ? "VIDEO" : "AUDIO";
    {
        std::unique_lock<std::mutex> lock(pimpl_->codecsMtx_);
        bool found = false;
        int targetIdx = -1;
        for (int i = 0; i < pimpl_->codecs_.size(); ++i) {
            if (pimpl_->codecs_[i].type == targetType) {
                if (found) {
                    pimpl_->codecs_.swapItemsAt(targetIdx, i);
                    break;
                }
                if (pimpl_->codecs_[i].id == codecId) {
                    targetIdx = i;
                    found = true;
                }
            }
        }
    }
    pimpl_->setActiveCodecs();
}

bool
CodecModel::enable(const unsigned int& codecId, bool enabled)
{
    std::unique_lock<std::mutex> lock(pimpl_->codecsMtx_);
    auto it = std::find_if(pimpl_->codecs_.begin(),
                           pimpl_->codecs_.end(),
                           [&](const Codec& c) { return c.id == codecId; });
    if (it == pimpl_->codecs_.end() || it->enabled == enabled)
        return false;

    it->enabled = enabled;
    QString modifiedType = it->type;

    bool allDisabled = std::none_of(pimpl_->codecs_.begin(),
                                    pimpl_->codecs_.end(),
                                    [&](const Codec& c) {
                                        return c.type == modifiedType && c.enabled;
                                    });
    lock.unlock();
    pimpl_->setActiveCodecs();
    return allDisabled;
}

void
CodecModel::autoQuality(const unsigned int& codecId, bool on)
{
    int row = -1;
    Codec finalCodec;
    {
        std::unique_lock<std::mutex> lock(pimpl_->codecsMtx_);
        for (int i = 0; i < pimpl_->codecs_.size(); ++i) {
            if (pimpl_->codecs_[i].id == codecId) {
                if (pimpl_->codecs_[i].auto_quality_enabled == on)
                    return;
                pimpl_->codecs_[i].auto_quality_enabled = on;
                finalCodec = pimpl_->codecs_[i];
                row = i;
                break;
            }
        }
    }
    if (row >= 0) {
        pimpl_->setCodecDetails(finalCodec);
        pimpl_->emitDataChanged(row);
    }
}

void
CodecModel::quality(const unsigned int& codecId, double quality)
{
    int row = -1;
    auto qualityStr = toQString(static_cast<int>(quality));
    Codec finalCodec;
    {
        std::unique_lock<std::mutex> lock(pimpl_->codecsMtx_);
        for (int i = 0; i < pimpl_->codecs_.size(); ++i) {
            if (pimpl_->codecs_[i].id == codecId) {
                if (pimpl_->codecs_[i].quality == qualityStr)
                    return;
                pimpl_->codecs_[i].quality = qualityStr;
                finalCodec = pimpl_->codecs_[i];
                row = i;
                break;
            }
        }
    }
    if (row >= 0) {
        pimpl_->setCodecDetails(finalCodec);
        pimpl_->emitDataChanged(row);
    }
}

void
CodecModel::bitrate(const unsigned int& codecId, double bitrate)
{
    int row = -1;
    auto bitrateStr = toQString(static_cast<int>(bitrate));
    Codec finalCodec;
    {
        std::unique_lock<std::mutex> lock(pimpl_->codecsMtx_);
        for (int i = 0; i < pimpl_->codecs_.size(); ++i) {
            if (pimpl_->codecs_[i].id == codecId) {
                if (pimpl_->codecs_[i].bitrate == bitrateStr)
                    return;
                pimpl_->codecs_[i].bitrate = bitrateStr;
                finalCodec = pimpl_->codecs_[i];
                row = i;
                break;
            }
        }
    }
    if (row >= 0) {
        pimpl_->setCodecDetails(finalCodec);
        pimpl_->emitDataChanged(row);
    }
}

CodecModelPimpl::CodecModelPimpl(CodecModel& linked, const CallbacksHandler& callbacksHandler)
    : linked(linked)
    , callbacksHandler(callbacksHandler)
{
    codecsList_ = ConfigurationManager::instance().getCodecList();
    loadFromDaemon();
}

CodecModelPimpl::~CodecModelPimpl() {}

void
CodecModelPimpl::emitDataChanged(int row)
{
    auto idx = linked.index(row);
    Q_EMIT linked.dataChanged(idx, idx);
}

void
CodecModelPimpl::loadFromDaemon()
{
    linked.beginResetModel();
    {
        std::unique_lock<std::mutex> lock(codecsMtx_);
        codecs_.clear();
    }
    QVector<unsigned int> activeCodecs = ConfigurationManager::instance().getActiveCodecList(linked.owner.id);
    for (const auto& id : activeCodecs) {
        addCodec(id, activeCodecs);
    }
    for (const auto& id : codecsList_) {
        if (activeCodecs.indexOf(id) != -1)
            continue;
        addCodec(id, activeCodecs);
    }
    linked.endResetModel();
}

void
CodecModelPimpl::setActiveCodecs()
{
    QVector<unsigned int> enabledCodecs;
    {
        std::unique_lock<std::mutex> lock(codecsMtx_);
        for (const auto& codec : codecs_) {
            if (codec.enabled) {
                enabledCodecs.push_back(codec.id);
            }
        }
    }
    ConfigurationManager::instance().setActiveCodecList(linked.owner.id, enabledCodecs);
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
    codec.auto_quality_enabled = details[libjami::Account::ConfProperties::CodecInfo::AUTO_QUALITY_ENABLED] == "true";
    {
        std::unique_lock<std::mutex> lock(codecsMtx_);
        codecs_.push_back(codec);
    }
}

void
CodecModelPimpl::setCodecDetails(const Codec& codec)
{
    MapStringString details;
    details[libjami::Account::ConfProperties::CodecInfo::NAME] = codec.name;
    details[libjami::Account::ConfProperties::CodecInfo::SAMPLE_RATE] = codec.samplerate;
    details[libjami::Account::ConfProperties::CodecInfo::BITRATE] = codec.bitrate;
    details[libjami::Account::ConfProperties::CodecInfo::MIN_BITRATE] = codec.min_bitrate;
    details[libjami::Account::ConfProperties::CodecInfo::MAX_BITRATE] = codec.max_bitrate;
    details[libjami::Account::ConfProperties::CodecInfo::TYPE] = codec.type;
    details[libjami::Account::ConfProperties::CodecInfo::QUALITY] = codec.quality;
    details[libjami::Account::ConfProperties::CodecInfo::MIN_QUALITY] = codec.min_quality;
    details[libjami::Account::ConfProperties::CodecInfo::MAX_QUALITY] = codec.max_quality;
    details[libjami::Account::ConfProperties::CodecInfo::AUTO_QUALITY_ENABLED] = codec.auto_quality_enabled ? "true"
                                                                                                            : "false";
    ConfigurationManager::instance().setCodecDetails(linked.owner.id, codec.id, details);
}

} // namespace lrc

#include "codecmodel.moc"
#include "api/moc_codecmodel.cpp"
