/*
 *  Copyright (C) 2018-2025 Savoir-faire Linux Inc.
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "vcard.h"

namespace lrc {
namespace vCard {
namespace utils {

QHash<QByteArray, QByteArray>
toHashMap(const QByteArray& content)
{
    QHash<QByteArray, QByteArray> vCard;
    QByteArray previousKey, previousValue;
    const QList<QByteArray> lines = content.split('\n');

    Q_FOREACH (const QByteArray& property, lines) {
        // Ignore empty lines
        if (!property.size())
            continue;

        // Some properties are over multiple lines
        if (property[0] == ' ' && previousKey.size()) {
            previousValue += property.right(property.size() - 1);
        }

        // Do not use split, URIs can have : in them
        const int separatorPos = property.indexOf(':');
        const QByteArray key(property.left(separatorPos));
        const QByteArray value(property.right(property.size() - separatorPos - 1));
        vCard[key] = value;
    }
    return vCard;
}

} // namespace utils
} // namespace vCard
} // namespace lrc
