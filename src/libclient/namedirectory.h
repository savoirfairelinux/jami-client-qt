/****************************************************************************
 *   Copyright (C) 2016-2026 Savoir-faire Linux Inc.                        *
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

#include "typedefs.h"

class NameDirectoryPrivate;
class Account;

class LIB_EXPORT NameDirectory : public QObject
{
    Q_OBJECT
    Q_CLASSINFO("RegisterEnumClassesUnscoped", "false")
public:
    // Register name status
    enum class RegisterNameStatus {
        SUCCESS = 0,
        WRONG_PASSWORD = 1,
        INVALID_NAME = 2,
        ALREADY_TAKEN = 3,
        NETWORK_ERROR = 4
    };
    Q_ENUM(RegisterNameStatus)

    // Lookup name status
    enum class LookupStatus { SUCCESS = 0, INVALID_NAME = 1, NOT_FOUND = 2, ERROR = 3 };
    Q_ENUM(LookupStatus)

    // Singleton
    static NameDirectory& instance();

    // Lookup
    Q_INVOKABLE bool lookupName(const QString& accountId, const QString& name, const QString& nameServiceURL = "") const;
    Q_INVOKABLE bool lookupAddress(const QString& accountId,
                                   const QString& address,
                                   const QString& nameServiceURL = "") const;

private:
    // Constructors & Destructors
    explicit NameDirectory();
    virtual ~NameDirectory();

    NameDirectoryPrivate* d_ptr;
    Q_DECLARE_PRIVATE(NameDirectory)
    Q_DISABLE_COPY(NameDirectory)

Q_SIGNALS:
    /// RegisterName has ended
    void nameRegistrationEnded(NameDirectory::RegisterNameStatus status, const QString& name);

    /// Name or address lookup has completed
    /// requestedName - name for what lookup was requested
    /// registeredName - name found in the lookup, have same normalized form as requestedName
    void registeredNameFound(NameDirectory::LookupStatus status,
                             const QString& address,
                             const QString& registeredName,
                             const QString& requestedName);
};
Q_DECLARE_METATYPE(NameDirectory*)
