/****************************************************************************
 *   Copyright (C) 2015-2025 Savoir-faire Linux Inc.                        *
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

#include "interfaces/dbuserrorhandleri.h"

namespace Interfaces {

/**
 * This implementation of the DBusErrorHandler interface throws an exception with the given message.
 */
class DBusErrorHandlerDefault : public DBusErrorHandlerI
{
public:
    [[noreturn]] void connectionError(const QString& error) override;
    [[noreturn]] void invalidInterfaceError(const QString& error) override;
};

} // namespace Interfaces
