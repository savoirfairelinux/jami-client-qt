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
#pragma once

// Lrc
#include "api/account.h"
#include "api/contact.h"
#include "dbus/configurationmanager.h"

namespace lrc {

namespace authority {

namespace daemon {
/**
 * Ask the daemon to add contact to the daemon.
 * @param owner
 * @param contactUri
 */
void addContact(const api::account::Info& owner, const QString& contactUri);
/**
 * Ask the daemon to add contact to the daemon.
 * @param owner
 * @param contactInfo
 */
void addContact(const api::account::Info& owner, const api::contact::Info& contactInfo);
/**
 * Ask the daemon to remove a contact and may ban it.
 * @param owner
 * @param contactInfo
 * @param banned
 */
void removeContact(const api::account::Info& owner, const QString& contactUri, bool banned);

} // namespace daemon

} // namespace authority

} // namespace lrc
