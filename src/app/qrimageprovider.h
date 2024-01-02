/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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

#pragma once

#include "quickimageproviderbase.h"
#include "accountlistmodel.h"

#include <QPair>
#include <QString>

class QrImageProvider : public QuickImageProviderBase
{
public:
    QrImageProvider(LRCInstance* instance = nullptr)
        : QuickImageProviderBase(QQuickImageProvider::Image,
                                 QQmlImageProviderBase::ForceAsynchronousImageLoading,
                                 instance)
    {}

    enum class QrType { Account, Contact, Raw };

    /*
     * Id should be string like account_0 (account index),
     * or contact_xxx (uid).
     * Cannot use getCurrentAccId to replace account index,
     * since we need to keep each image id unique.
     */
    QPair<QrType, QString> getIndexFromID(const QString& id)
    {
        auto list = id.split('_', Qt::SkipEmptyParts);
        if (list.size() < 2)
            return {QrType::Account, {}};
        if (list.contains("account") && list.size() > 1) {
            return {QrType::Account, list[1]};
        } else if (list.contains("contact") && list.size() > 1) {
            // For contact_xxx, xxx is "" initially
            try {
                const auto& convInfo = lrcInstance_->getConversationFromConvUid(list[1]);
                if (convInfo.uid.isEmpty())
                    return {QrType::Contact, list[1]};
                if (convInfo.mode == conversation::Mode::ONE_TO_ONE
                    || convInfo.mode == conversation::Mode::NON_SWARM) {
                    auto peerUri = lrcInstance_->getCurrentAccountInfo()
                                       .conversationModel->peersForConversation(convInfo.uid)
                                       .at(0);
                    return {QrType::Contact, peerUri};
                }
            } catch (...) {
            }
            return {QrType::Contact, {}};
        } else if (list.contains("raw") && list.size() > 1) {
            return {QrType::Raw, list[1]};
        }
        return {QrType::Account, {}};
    }

    QImage requestImage(const QString& id, QSize* size, const QSize& requestedSize) override
    {
        Q_UNUSED(size);

        QString uri;
        auto [type, identifier] = getIndexFromID(id);

        if (type == QrType::Account) {
            if (identifier.isEmpty())
                return QImage();
            try {
                auto& accountInfo = lrcInstance_->getAccountInfo(identifier);
                uri = accountInfo.profileInfo.uri;
            } catch (const std::out_of_range&) {
                qWarning() << "Couldn't get account info for id:" << identifier;
                return QImage();
            }
        } else
            uri = identifier;

        if (!requestedSize.isEmpty())
            return Utils::getQRCodeImage(uri, 0).scaled(requestedSize, Qt::KeepAspectRatio);
        else
            return Utils::getQRCodeImage(uri, 0);
    }
};
