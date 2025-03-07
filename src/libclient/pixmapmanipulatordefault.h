/****************************************************************************
 *   Copyright (C) 2013-2025 Savoir-faire Linux Inc.                        *
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
#pragma once

#include "interfaces/pixmapmanipulatori.h"

namespace Interfaces {

/// Default implementation of the PixmapManipulator interface which simply returns empty
/// QVariants/QByteArrays
class LIB_EXPORT PixmapManipulatorDefault : public PixmapManipulatorI
{
public:
    QVariant conversationPhoto(const lrc::api::conversation::Info& conversation,
                               const lrc::api::account::Info& accountInfo,
                               const QSize& size,
                               int presence = 0) override;
    QVariant numberCategoryIcon(const QVariant& p,
                                const QSize& size,
                                bool displayPresence = false,
                                int presence = 0) override;
    QByteArray toByteArray(const QVariant& pxm) override;
    QVariant personPhoto(const QByteArray& data, const QString& type = "PNG") override;
    QVariant decorationRole(const QModelIndex& index) override;
    QVariant decorationRole(const lrc::api::conversation::Info& conversation,
                            const lrc::api::account::Info& accountInfo) override;
    /**
     * Return the icons associated with the action and its state
     */
    QVariant userActionIcon(const UserActionElement& state) const override;
};

} // namespace Interfaces
