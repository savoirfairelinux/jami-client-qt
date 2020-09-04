/*!
 * Copyright (C) 2019-2020 by Savoir-faire Linux
 * Author: Yang Wang   <yang.wang@savoirfairelinux.com>
 * Author: Aline Gondim Santos   <aline.gondimsantos@savoirfairelinux.com>
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

#pragma once

#include "accountadapter.h"
#include "accountlistmodel.h"
#include "audiocodeclistmodel.h"
#include "avadapter.h"
#include "bannedlistmodel.h"
#include "calladapter.h"
#include "contactadapter.h"
#include "pluginadapter.h"
#include "conversationsadapter.h"
#include "deviceitemlistmodel.h"
#include "pluginitemlistmodel.h"
#include "mediahandleritemlistmodel.h"
#include "preferenceitemlistmodel.h"
#include "distantrenderer.h"
#include "globalinstances.h"
#include "globalsystemtray.h"
#include "messagesadapter.h"
#include "namedirectory.h"
#include "pixbufmanipulator.h"
#include "previewrenderer.h"
#include "qrimageprovider.h"
#include "settingsadapter.h"
#include "version.h"
#include "videocodeclistmodel.h"

#include <QObject>

class ClientWrapper final : public QObject
{
    Q_OBJECT

    Q_PROPERTY(lrc::api::NewAccountModel *accountModel READ getAccountModel NOTIFY accountModelChanged)
    Q_PROPERTY(lrc::api::DataTransferModel *dataTransferModel READ getDataTransferModel)
    Q_PROPERTY(lrc::api::AVModel *avmodel READ getAvModel NOTIFY avModelChanged)

public:
    explicit ClientWrapper(QObject *parent = nullptr);
    ~ClientWrapper() = default;

    lrc::api::NewAccountModel *getAccountModel();
    lrc::api::DataTransferModel *getDataTransferModel();
    lrc::api::AVModel *getAvModel();

signals:
    void accountModelChanged();
    void avModelChanged();

};
Q_DECLARE_METATYPE(ClientWrapper *)
