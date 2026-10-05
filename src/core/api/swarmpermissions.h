/****************************************************************************
 *   Copyright (C) 2026 Savoir-faire Linux Inc.                             *
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

#include <QSet>
#include <QString>
#include <QStringList>

#include <array>
#include <string_view>
#include <utility>

/**
 * Swarm permissions granted by the daemon to the local account. Mirrors the
 * daemon's Permission enum; the daemon is the authority on what is allowed.
 */
namespace lrc {
namespace api {
namespace permissions {

enum class Permission {
    Text,
    TextReply,
    File,
    FileReply,
    Reaction,
    Call,
    HostConference,
    Edit,
    Delete,
    DeleteFile,
    CreateDocument,
    DeleteDocument,
    UpdateDocument,
    AddDocumentAttachment,
    AddMember,
    BanUnbanMember,
    UpdateProfile,
};

using PermissionSet = QSet<Permission>;

// Names used by the daemon in SwarmLoaded and getConversationPermissions
constexpr std::array<std::pair<Permission, std::string_view>, 17> PERMISSION_NAME_TABLE {{
    {Permission::Text, "text"},
    {Permission::TextReply, "textReply"},
    {Permission::File, "file"},
    {Permission::FileReply, "fileReply"},
    {Permission::Reaction, "reaction"},
    {Permission::Call, "call"},
    {Permission::HostConference, "hostConference"},
    {Permission::Edit, "edit"},
    {Permission::Delete, "delete"},
    {Permission::DeleteFile, "deleteFile"},
    {Permission::CreateDocument, "createDocument"},
    {Permission::DeleteDocument, "deleteDocument"},
    {Permission::UpdateDocument, "updateDocument"},
    {Permission::AddDocumentAttachment, "addDocumentAttachment"},
    {Permission::AddMember, "addMember"},
    {Permission::BanUnbanMember, "banUnbanMember"},
    {Permission::UpdateProfile, "updateProfile"},
}};

/**
 * Convert the permission names sent by the daemon. Unknown names are ignored.
 */
inline PermissionSet
fromNames(const QStringList& names)
{
    PermissionSet permissions;
    for (const auto& name : names) {
        const auto utf8Name = name.toUtf8();
        const std::string_view view(utf8Name.constData(), utf8Name.size());
        for (const auto& [permission, knownName] : PERMISSION_NAME_TABLE) {
            if (knownName == view) {
                permissions.insert(permission);
                break;
            }
        }
    }
    return permissions;
}

} // namespace permissions
} // namespace api
} // namespace lrc
