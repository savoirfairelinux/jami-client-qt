/****************************************************************************
 *   Copyright (C) 2016-2025 Savoir-faire Linux Inc.                        *
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

#include <QCoreApplication>

#include "namedirectory.h"
#include "private/namedirectory_p.h"
#include "dbus/configurationmanager.h"

NameDirectoryPrivate::NameDirectoryPrivate(NameDirectory* q)
    : q_ptr(q)
{
    ConfigurationManagerInterface& configurationManager = ConfigurationManager::instance();

    connect(&configurationManager,
            &ConfigurationManagerInterface::nameRegistrationEnded,
            this,
            &NameDirectoryPrivate::slotNameRegistrationEnded,
            Qt::QueuedConnection);
    connect(&configurationManager,
            &ConfigurationManagerInterface::registeredNameFound,
            this,
            &NameDirectoryPrivate::slotRegisteredNameFound,
            Qt::QueuedConnection);
}

NameDirectory::NameDirectory()
    : QObject(QCoreApplication::instance())
    , d_ptr(new NameDirectoryPrivate(this))
{}

/// Singleton
NameDirectory&
NameDirectory::instance()
{
    static auto instance = new NameDirectory;
    return *instance;
}

// Name registration ended
void
NameDirectoryPrivate::slotNameRegistrationEnded(const QString& accountId,
                                                int status,
                                                const QString& name)
{
    LC_DBG << "Name registration ended. Account:" << accountId << "status:" << status
           << "name:" << name;

    Q_EMIT q_ptr->nameRegistrationEnded(static_cast<NameDirectory::RegisterNameStatus>(status),
                                        name);
}

// Registered Name found
void
NameDirectoryPrivate::slotRegisteredNameFound(const QString& accountId,
                                              const QString& requestedName,
                                              int status,
                                              const QString& address,
                                              const QString& registeredName)
{
    switch (static_cast<NameDirectory::LookupStatus>(status)) {
    case NameDirectory::LookupStatus::INVALID_NAME:
        LC_DBG << "lookup name is INVALID: address: " << address << " name: " << requestedName
               << " accountId: " << accountId;
        break;
    case NameDirectory::LookupStatus::NOT_FOUND:
        LC_DBG << "lookup name NOT FOUND: address: " << address << " name: " << requestedName
               << " accountId: " << accountId;
        break;
    case NameDirectory::LookupStatus::ERROR:
        LC_DBG << "lookup name ERROR: address: " << address << " name: " << requestedName
               << " accountId: " << accountId;
        break;
    case NameDirectory::LookupStatus::SUCCESS:
        break;
    }

    Q_EMIT q_ptr->registeredNameFound(static_cast<NameDirectory::LookupStatus>(status),
                                      address,
                                      registeredName,
                                      requestedName);
}

// Lookup a name
bool
NameDirectory::lookupName(const QString& accountId,
                          const QString& name,
                          const QString& nameServiceURL) const
{
    return ConfigurationManager::instance().lookupName(accountId, nameServiceURL, name);
}

// Lookup an address
bool
NameDirectory::lookupAddress(const QString& accountId,
                             const QString& address,
                             const QString& nameServiceURL) const
{
    return ConfigurationManager::instance().lookupAddress(accountId, nameServiceURL, address);
}

NameDirectory::~NameDirectory()
{
    delete d_ptr;
}
