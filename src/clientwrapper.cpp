/*!
 * Copyright (C) 2019-2020 by Savoir-faire Linux
 * Author: Yang Wang   <yang.wang@savoirfairelinux.com>
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "clientwrapper.h"

ClientWrapper::ClientWrapper(QObject *parent)
    : QObject(parent)
{}

lrc::api::NewAccountModel *
ClientWrapper::getAccountModel()
{
    return &(LRCInstance::accountModel());
}

lrc::api::DataTransferModel *
ClientWrapper::getDataTransferModel()
{
    return &(LRCInstance::dataTransferModel());
}

lrc::api::AVModel *
ClientWrapper::getAvModel()
{
    return &(LRCInstance::avModel());
}
