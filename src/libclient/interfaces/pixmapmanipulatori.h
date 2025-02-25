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

#include <typedefs.h>

// Qt
class QVariant;
class QModelIndex;
class QByteArray;

// Ring
struct UserActionElement;

namespace lrc {
namespace api {
namespace account {
struct Info;
}
namespace conversation {
struct Info;
}
} // namespace api
} // namespace lrc

namespace Interfaces {

/**
 * Different clients can have multiple way of displaying images. Some may
 * add borders, other add corner radius (see Ubuntu-SDK HIG). This
 * abstract class define many operations that can be defined by each clients.
 *
 * Most methods return QVariants as this library doesn't link against QtGui
 *
 * This interface is not frozen, more methods may be added later.
 */
class PixmapManipulatorI
{
public:
    // Implementation can use random values to extend this
    enum CollectionIconHint {
        NONE,
        HISTORY,
        CONTACT,
        BOOKMARK,
        PHONE_NUMBER,
        RINGTONE,
        PROFILE,
        CERTIFICATE,
        ACCOUNT,
        RECORDING,
        MACRO,
    };

    virtual ~PixmapManipulatorI() = default;

    virtual QVariant conversationPhoto(const lrc::api::conversation::Info& conversation,
                                       const lrc::api::account::Info& accountInfo,
                                       const QSize& size,
                                       int presence = 0)
    {
        Q_UNUSED(conversation);
        Q_UNUSED(accountInfo);
        Q_UNUSED(size);
        Q_UNUSED(presence);
        return {};
    }
    virtual QVariant numberCategoryIcon(const QVariant& p,
                                        const QSize& size,
                                        bool displayPresence = false,
                                        int presence = 0)
        = 0;
    virtual QByteArray toByteArray(const QVariant& pxm) = 0;
    virtual QVariant personPhoto(const QByteArray& data, const QString& type = "PNG") = 0;
    virtual QVariant decorationRole(const QModelIndex& index) = 0;
    virtual QVariant decorationRole(const lrc::api::conversation::Info& conversation,
                                    const lrc::api::account::Info& accountInfo)
    {
        Q_UNUSED(conversation);
        Q_UNUSED(accountInfo);
        return {};
    }

    /**
     * Return the icons associated with the action and its state
     */
    virtual QVariant userActionIcon(const UserActionElement& state) const = 0;
};

} // namespace Interfaces
