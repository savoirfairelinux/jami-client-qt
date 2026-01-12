/*!
 * Copyright (C) 2024-2026 Savoir-faire Linux Inc.
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

#include <QString>
#include <cstdint>
#include <gio/gio.h>
#include <gio/gunixfdlist.h>

enum class PortalCaptureType {
    SCREEN = 1,
    WINDOW = 2,
};

struct DbusCallData;

class ScreenCastPortal
{
public:
    ScreenCastPortal(PortalCaptureType captureType);
    ~ScreenCastPortal();
    int getPipewireFd();
    int pipewireFd;
    uint32_t pipewireNode = 0;
    QString videoInputId;

private:
    void createSession();
    void selectSources();
    void start();
    void openPipewireRemote();
    void abort(int error, const char* message);

    static void onCreateSessionResponseReceivedCallback(GDBusConnection* connection,
                                                        const char* sender_name,
                                                        const char* object_path,
                                                        const char* interface_name,
                                                        const char* signal_name,
                                                        GVariant* parameters,
                                                        gpointer user_data);
    static void onSelectSourcesResponseReceivedCallback(GDBusConnection* connection,
                                                        const char* sender_name,
                                                        const char* object_path,
                                                        const char* interface_name,
                                                        const char* signal_name,
                                                        GVariant* parameters,
                                                        gpointer user_data);
    static void onStartResponseReceivedCallback(GDBusConnection* connection,
                                                const char* sender_name,
                                                const char* object_path,
                                                const char* interface_name,
                                                const char* signal_name,
                                                GVariant* parameters,
                                                gpointer user_data);

    int callDBusMethod(const gchar* method_name, GVariant* parameters);
    int createDBusProxy();
    int createDBusConnection();
    void updateAvailableCursorModes();
    DbusCallData* subscribeToSignal(const char* path, GDBusSignalCallback callback);
    static void dbusCallDataFree(DbusCallData* ptr_dbus_call_data);

    GDBusConnection* connection = nullptr;
    GDBusProxy* proxy = nullptr;

    char* sender_name = nullptr;
    char* session_handle = nullptr;

    uint32_t available_cursor_modes = 0;

    GMainLoop* glib_main_loop = nullptr;
    struct pw_thread_loop* thread_loop = nullptr;
    struct pw_context* context = nullptr;

    guint32 capture_type;

    bool draw_mouse;

    int portal_error = 0;
};

struct DbusCallData
{
    ScreenCastPortal* portal;
    char* request_path;
    guint signal_id;
};
