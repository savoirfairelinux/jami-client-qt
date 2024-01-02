/****************************************************************************
 *    Copyright (C) 2018-2024 Savoir-faire Linux Inc.                       *
 *   Author: Guillaume Roguez <guillaume.roguez@savoirfairelinux.com>       *
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

// LRC
#include "api/datatransfermodel.h"

// Dbus
#include "dbus/configurationmanager.h"

// libjami
#include <datatransfer_interface.h>

// Std
#include <map>
#include <stdexcept>
#include <type_traits>

// Qt
#include <QDir>
#include <QFileInfo>
#include <QtCore/QStandardPaths>
#include <QUuid>

namespace lrc {
namespace api {

// LIBJAMI to LRC event code conversion
static inline datatransfer::Status
convertDataTransferEvent(libjami::DataTransferEventCode event)
{
    switch (event) {
    case libjami::DataTransferEventCode::invalid:
        return datatransfer::Status::INVALID;
    case libjami::DataTransferEventCode::created:
        return datatransfer::Status::on_connection;
    case libjami::DataTransferEventCode::unsupported:
        return datatransfer::Status::unsupported;
    case libjami::DataTransferEventCode::wait_peer_acceptance:
        return datatransfer::Status::on_connection;
    case libjami::DataTransferEventCode::wait_host_acceptance:
        return datatransfer::Status::on_connection;
    case libjami::DataTransferEventCode::ongoing:
        return datatransfer::Status::on_progress;
    case libjami::DataTransferEventCode::finished:
        return datatransfer::Status::success;
    case libjami::DataTransferEventCode::closed_by_host:
        return datatransfer::Status::stop_by_host;
    case libjami::DataTransferEventCode::closed_by_peer:
        return datatransfer::Status::stop_by_peer;
    case libjami::DataTransferEventCode::invalid_pathname:
        return datatransfer::Status::invalid_pathname;
    case libjami::DataTransferEventCode::unjoinable_peer:
        return datatransfer::Status::unjoinable_peer;
    case libjami::DataTransferEventCode::timeout_expired:
        return datatransfer::Status::timeout_expired;
    }
    throw std::runtime_error("BUG: broken convertDataTransferEvent() switch");
}

class DataTransferModel::Impl : public QObject
{
    Q_OBJECT

public:
    Impl(DataTransferModel& up_link);

    QString getUniqueFilePath(const QString& filename, const QString& path = "");

    DataTransferModel& upLink;
    MapStringString file2InteractionId;
    MapStringString interactionToFileId; // stricly the reverse map of file2InteractionId
};

DataTransferModel::Impl::Impl(DataTransferModel& up_link)
    : QObject {}
    , upLink {up_link}
{}

QString
DataTransferModel::Impl::getUniqueFilePath(const QString& filename, const QString& path)
{
    auto base = filename;
    QString ext = QFileInfo(base).completeSuffix();
    if (!ext.isEmpty())
        ext = ext.prepend(".");

    QFileInfo fi(filename);
    auto p = !path.isEmpty() ? path : fi.dir().path();
    base = QDir(p).filePath(fi.baseName() + ext);
    if (!QFile::exists(base))
        return base;

    base.chop(ext.size());
    QString ret;
    for (int suffix = 1;; suffix++) {
        ret = QString("%1 (%2)%3").arg(base).arg(suffix).arg(ext);
        if (!QFile::exists(ret)) {
            return ret;
        }
    }
}

void
DataTransferModel::registerTransferId(const QString& fileId, const QString& interactionId)
{
    pimpl_->file2InteractionId[fileId] = interactionId;
    pimpl_->interactionToFileId.remove(interactionId); // Because a file transfer can be retried
    pimpl_->interactionToFileId[interactionId] = fileId;
}

DataTransferModel::DataTransferModel()
    : QObject(nullptr)
    , pimpl_ {std::make_unique<Impl>(*this)}
{}

DataTransferModel::~DataTransferModel() = default;

void
DataTransferModel::sendFile(const QString& accountId,
                            const QString& conversationId,
                            const QString& filePath,
                            const QString& displayName,
                            const QString& parent)
{
    ConfigurationManager::instance().sendFile(accountId,
                                              conversationId,
                                              filePath,
                                              displayName,
                                              parent);
}

void
DataTransferModel::fileTransferInfo(const QString& accountId,
                                    const QString& conversationId,
                                    const QString& fileId,
                                    QString& path,
                                    qlonglong& total,
                                    qlonglong& progress)
{
    ConfigurationManager::instance()
        .fileTransferInfo(accountId, conversationId, fileId, path, total, progress);
}

void
DataTransferModel::download(const QString& accountId,
                            const QString& convId,
                            const QString& interactionId,
                            const QString& fileId,
                            const QString& path)
{
    ConfigurationManager::instance().downloadFile(accountId, convId, interactionId, fileId, path);
}

QString
DataTransferModel::copyTo(const QString& accountId,
                          const QString& convId,
                          const QString& interactionId,
                          const QString& destPath,
                          const QString& displayName)
{
    auto fileId = getFileIdFromInteractionId(interactionId);
    if (fileId.isEmpty()) {
        qWarning() << "Cannot find any file for " << interactionId;
        return {};
    }
    QString path;
    qlonglong total, progress;

    fileTransferInfo(accountId, convId, fileId, path, total, progress);

    auto src = QFile(path);
    auto srcfi = QFileInfo(path);
    if (!src.exists())
        return {};

    auto filename = displayName;
    if (displayName.isEmpty())
        filename = srcfi.isSymLink() ? srcfi.symLinkTarget() : path;
    auto dest = pimpl_->getUniqueFilePath(filename, destPath);
    qDebug() << "Copy to " << dest;
    // create directory if it does not exist
    QDir dir(destPath);
    if (!dir.exists())
        dir.mkpath(".");
    src.copy(dest);
    return dest;
}

void
DataTransferModel::cancel(const QString& accountId,
                          const QString& conversationId,
                          const QString& interactionId)
{
    ConfigurationManager::instance().cancelDataTransfer(accountId,
                                                        conversationId,
                                                        getFileIdFromInteractionId(interactionId));
}

QString
DataTransferModel::getInteractionIdFromFileId(const QString& fileId)
{
    return pimpl_->file2InteractionId[fileId];
}

QString
DataTransferModel::getFileIdFromInteractionId(const QString& interactionId)
{
    return pimpl_->interactionToFileId[interactionId];
}

QString
DataTransferModel::createDefaultDirectory()
{
    auto defaultDirectory = QStandardPaths::writableLocation(QStandardPaths::DownloadLocation)
                            + "/Jami";
    QDir dir(defaultDirectory);
    if (!dir.exists())
        dir.mkpath(".");
    return defaultDirectory;
}

} // namespace api
} // namespace lrc

#include "api/moc_datatransfermodel.cpp"
#include "datatransfermodel.moc"
