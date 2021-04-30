/*
 * Copyright (C) 2021 by Savoir-faire Linux
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

#include "utils.h"

#include <configurationmanager_interface.h>

extern bool muteDring;

void initDirectDaemonConnection() {
#ifdef ENABLE_CLIENT_QT_TESTS
    std::map<std::string, std::shared_ptr<DRing::CallbackWrapperBase>> confHandlers;
    confHandlers.insert(DRing::exportable_callback<DRing::ConfigurationSignal::GetAppDataPath>(
        [&](const std::string& name, std::vector<std::string>* paths) {
            paths->emplace_back(std::string(Utils::WinGetEnv("TEMP")) + "\\jami_tests");
        }));
    DRing::registerSignalHandlers(confHandlers);
#endif
}