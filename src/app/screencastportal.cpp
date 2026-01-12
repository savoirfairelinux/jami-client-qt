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

#include "screencastportal.h"

#include <QDebug>
#include <unistd.h>

#define REQUEST_PATH "/org/freedesktop/portal/desktop/request/%s/%s"

/*
 * PipeWire supported cursor modes
 */
enum PortalCursorMode {
    PORTAL_CURSOR_MODE_HIDDEN = 1 << 0,
    PORTAL_CURSOR_MODE_EMBEDDED = 1 << 1,
    PORTAL_CURSOR_MODE_METADATA = 1 << 2,
};

/*
 * Helper function to allow getPipewireFd to stop and return an error
 * code if a DBus operation/callback fails.
 */
void
ScreenCastPortal::abort(int error, const char* message)
{
    portal_error = error;
    qWarning() << "Aborting:" << message;

    if (glib_main_loop && g_main_loop_is_running(glib_main_loop)) {
        g_main_loop_quit(glib_main_loop);
    }
}

/*
 * Callback to free a DbusCallData object's memory and unsubscribe from the
 * associated dbus signal.
 */
void
ScreenCastPortal::dbusCallDataFree(DbusCallData* ptr_dbus_call_data)
{
    if (!ptr_dbus_call_data)
        return;

    if (ptr_dbus_call_data->signal_id)
        g_dbus_connection_signal_unsubscribe(ptr_dbus_call_data->portal->connection, ptr_dbus_call_data->signal_id);

    g_clear_pointer(&ptr_dbus_call_data->request_path, g_free);
}

DbusCallData*
ScreenCastPortal::subscribeToSignal(const char* path, GDBusSignalCallback callback)
{
    DbusCallData* ptr_dbus_call_data = new DbusCallData;

    ptr_dbus_call_data->portal = this;
    ptr_dbus_call_data->request_path = g_strdup(path);
    ptr_dbus_call_data->signal_id
        = g_dbus_connection_signal_subscribe(connection,
                                             "org.freedesktop.portal.Desktop" /*sender*/,
                                             "org.freedesktop.portal.Request" /*interface_name*/,
                                             "Response" /*member: dbus signal name*/,
                                             ptr_dbus_call_data->request_path /*object_path*/,
                                             NULL,
                                             G_DBUS_SIGNAL_FLAGS_NO_MATCH_RULE,
                                             callback,
                                             ptr_dbus_call_data,
                                             NULL);
    return ptr_dbus_call_data;
}

void
ScreenCastPortal::openPipewireRemote()
{
    GUnixFDList* fd_list = NULL;
    GVariant* result = NULL;
    GError* error = NULL;
    int fd_index;
    GVariantBuilder builder;

    g_variant_builder_init(&builder, G_VARIANT_TYPE_VARDICT);

    result = g_dbus_proxy_call_with_unix_fd_list_sync(proxy,
                                                      "OpenPipeWireRemote",
                                                      g_variant_new("(oa{sv})", session_handle, &builder),
                                                      G_DBUS_CALL_FLAGS_NONE,
                                                      -1,
                                                      NULL,
                                                      &fd_list,
                                                      NULL,
                                                      &error);
    if (error)
        goto fail;

    g_variant_get(result, "(h)", &fd_index);
    g_variant_unref(result);

    pipewireFd = g_unix_fd_list_get(fd_list, fd_index, &error);
    g_object_unref(fd_list);
    if (error)
        goto fail;

    g_main_loop_quit(glib_main_loop);
    return;

fail:
    qWarning() << "Error retrieving PipeWire fd:" << error->message;
    g_error_free(error);
    abort(EIO, "Failed to open PipeWire remote");
}

void
ScreenCastPortal::onStartResponseReceivedCallback(GDBusConnection* connection,
                                                  const char* sender_name,
                                                  const char* object_path,
                                                  const char* interface_name,
                                                  const char* signal_name,
                                                  GVariant* parameters,
                                                  gpointer user_data)
{
    GVariant* stream_properties = NULL;
    GVariant* streams = NULL;
    GVariant* result = NULL;
    GVariantIter iter;
    uint32_t response;

    DbusCallData* ptr_dbus_call_data = (DbusCallData*) user_data;
    ScreenCastPortal* portal = ptr_dbus_call_data->portal;

    g_clear_pointer(&ptr_dbus_call_data, dbusCallDataFree);

    g_variant_get(parameters, "(u@a{sv})", &response, &result);

    if (response) {
        g_variant_unref(result);
        portal->abort(EACCES, "Failed to start screencast, denied or canceled by user");
        return;
    }

    streams = g_variant_lookup_value(result, "streams", G_VARIANT_TYPE_ARRAY);

    g_variant_iter_init(&iter, streams);

    g_variant_iter_loop(&iter, "(u@a{sv})", &portal->pipewireNode, &stream_properties);

    qInfo() << "Monitor selected, setting up screencast\n";

    g_variant_unref(result);
    g_variant_unref(streams);
    g_variant_unref(stream_properties);

    portal->openPipewireRemote();
}

int
ScreenCastPortal::callDBusMethod(const gchar* method_name, GVariant* parameters)
{
    GVariant* result;
    GError* error = NULL;

    result = g_dbus_proxy_call_sync(proxy, method_name, parameters, G_DBUS_CALL_FLAGS_NONE, -1, NULL, &error);
    if (error) {
        qWarning() << "Call to DBus method" << method_name << "failed:" << error->message;
        g_error_free(error);
        return EIO;
    }
    g_variant_unref(result);
    return 0;
}

void
ScreenCastPortal::start()
{
    int ret;
    const char* request_token;
    g_autofree char* request_path;
    GVariantBuilder builder;
    GVariant* parameters;
    struct DbusCallData* ptr_dbus_call_data;

    request_token = "pipewiregrabStart";
    request_path = g_strdup_printf(REQUEST_PATH, sender_name, request_token);

    qInfo() << "Asking for monitor…";

    ptr_dbus_call_data = subscribeToSignal(request_path, onStartResponseReceivedCallback);
    if (!ptr_dbus_call_data) {
        abort(ENOMEM, "Failed to allocate DBus call data");
        return;
    }

    g_variant_builder_init(&builder, G_VARIANT_TYPE_VARDICT);
    g_variant_builder_add(&builder, "{sv}", "handle_token", g_variant_new_string(request_token));
    parameters = g_variant_new("(osa{sv})", session_handle, "", &builder);

    ret = callDBusMethod("Start", parameters);
    if (ret != 0)
        abort(ret, "Failed to start screen cast session");
}

void
ScreenCastPortal::onSelectSourcesResponseReceivedCallback(GDBusConnection* connection,
                                                          const char* sender_name,
                                                          const char* object_path,
                                                          const char* interface_name,
                                                          const char* signal_name,
                                                          GVariant* parameters,
                                                          gpointer user_data)
{
    GVariant* ret = NULL;
    uint32_t response;
    struct DbusCallData* ptr_dbus_call_data = (DbusCallData*) user_data;
    ScreenCastPortal* portal = ptr_dbus_call_data->portal;

    g_clear_pointer(&ptr_dbus_call_data, dbusCallDataFree);

    g_variant_get(parameters, "(u@a{sv})", &response, &ret);
    g_variant_unref(ret);
    if (response) {
        portal->abort(EACCES, "Failed to select screencast sources, denied or canceled by user");
        return;
    }

    portal->start();
}

void
ScreenCastPortal::selectSources()
{
    int ret;
    const char* request_token;
    g_autofree char* request_path;
    GVariantBuilder builder;
    GVariant* parameters;
    struct DbusCallData* ptr_dbus_call_data;

    request_token = "pipewiregrabSelectSources";
    request_path = g_strdup_printf(REQUEST_PATH, sender_name, request_token);

    ptr_dbus_call_data = subscribeToSignal(request_path, onSelectSourcesResponseReceivedCallback);
    if (!ptr_dbus_call_data) {
        abort(ENOMEM, "Failed to allocate DBus call data");
        return;
    }

    g_variant_builder_init(&builder, G_VARIANT_TYPE_VARDICT);
    g_variant_builder_add(&builder, "{sv}", "types", g_variant_new_uint32(capture_type));
    g_variant_builder_add(&builder, "{sv}", "multiple", g_variant_new_boolean(FALSE));
    g_variant_builder_add(&builder, "{sv}", "handle_token", g_variant_new_string(request_token));

    if ((available_cursor_modes & PORTAL_CURSOR_MODE_EMBEDDED) && draw_mouse)
        g_variant_builder_add(&builder, "{sv}", "cursor_mode", g_variant_new_uint32(PORTAL_CURSOR_MODE_EMBEDDED));
    else
        g_variant_builder_add(&builder, "{sv}", "cursor_mode", g_variant_new_uint32(PORTAL_CURSOR_MODE_HIDDEN));
    parameters = g_variant_new("(oa{sv})", session_handle, &builder);

    ret = callDBusMethod("SelectSources", parameters);
    if (ret != 0)
        abort(ret, "Failed to select sources for screen cast session");
}

void
ScreenCastPortal::onCreateSessionResponseReceivedCallback(GDBusConnection* connection,
                                                          const char* sender_name,
                                                          const char* object_path,
                                                          const char* interface_name,
                                                          const char* signal_name,
                                                          GVariant* parameters,
                                                          gpointer user_data)
{
    uint32_t response;
    GVariant* result = NULL;
    DbusCallData* ptr_dbus_call_data = (DbusCallData*) user_data;
    ScreenCastPortal* portal = ptr_dbus_call_data->portal;

    g_clear_pointer(&ptr_dbus_call_data, dbusCallDataFree);

    g_variant_get(parameters, "(u@a{sv})", &response, &result);

    if (response != 0) {
        g_variant_unref(result);
        portal->abort(EACCES, "Failed to create screencast session, denied or canceled by user");
        return;
    }

    qDebug() << "Screencast session created";

    g_variant_lookup(result, "session_handle", "s", &portal->session_handle);
    g_variant_unref(result);

    portal->selectSources();
}

void
ScreenCastPortal::createSession()
{
    int ret;
    GVariantBuilder builder;
    GVariant* parameters;
    const char* request_token;
    g_autofree char* request_path;
    DbusCallData* ptr_dbus_call_data;

    request_token = "pipewiregrabCreateSession";
    request_path = g_strdup_printf(REQUEST_PATH, sender_name, request_token);

    ptr_dbus_call_data = subscribeToSignal(request_path, onCreateSessionResponseReceivedCallback);
    if (!ptr_dbus_call_data) {
        abort(ENOMEM, "Failed to allocate DBus call data");
        return;
    }

    g_variant_builder_init(&builder, G_VARIANT_TYPE_VARDICT);
    g_variant_builder_add(&builder, "{sv}", "handle_token", g_variant_new_string(request_token));
    g_variant_builder_add(&builder, "{sv}", "session_handle_token", g_variant_new_string("pipewiregrab"));
    parameters = g_variant_new("(a{sv})", &builder);

    ret = callDBusMethod("CreateSession", parameters);
    if (ret != 0)
        abort(ret, "Failed to create screen cast session");
}

/*
 * Helper function: get available cursor modes and update the
 *                  PipewireGrabContext accordingly
 */
void
ScreenCastPortal::updateAvailableCursorModes()
{
    GVariant* cached_cursor_modes = NULL;

    cached_cursor_modes = g_dbus_proxy_get_cached_property(proxy, "AvailableCursorModes");
    available_cursor_modes = cached_cursor_modes ? g_variant_get_uint32(cached_cursor_modes) : 0;

    // Only use embedded or hidden mode for now
    available_cursor_modes &= PORTAL_CURSOR_MODE_EMBEDDED | PORTAL_CURSOR_MODE_HIDDEN;

    g_variant_unref(cached_cursor_modes);
}

int
ScreenCastPortal::createDBusProxy()
{
    GError* error = NULL;

    proxy = g_dbus_proxy_new_sync(connection,
                                  G_DBUS_PROXY_FLAGS_NONE,
                                  NULL,
                                  "org.freedesktop.portal.Desktop",
                                  "/org/freedesktop/portal/desktop",
                                  "org.freedesktop.portal.ScreenCast",
                                  NULL,
                                  &error);
    if (error) {
        qWarning() << "Error creating proxy:" << error->message;
        g_error_free(error);
        return EPERM;
    }
    return 0;
}

/*
 * Create DBus connection and related objects
 */
int
ScreenCastPortal::createDBusConnection()
{
    char* aux;
    GError* error = NULL;

    connection = g_bus_get_sync(G_BUS_TYPE_SESSION, NULL, &error);
    if (error) {
        qWarning() << "Error getting session bus:" << error->message;
        g_error_free(error);
        return EPERM;
    }

    sender_name = g_strdup(g_dbus_connection_get_unique_name(connection) + 1);
    while ((aux = g_strstr_len(sender_name, -1, ".")) != NULL)
        *aux = '_';

    return 0;
}

/*
 * Use XDG Desktop Portal's ScreenCast interface to open a file descriptor that
 * can be used by PipeWire to access the screen cast streams.
 * (https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.portal.ScreenCast.html)
 */
int
ScreenCastPortal::getPipewireFd()
{
    int ret = 0;
    GMainContext* glib_main_context;

    // Create a new GLib context and set it as the default for the current thread.
    // This ensures that the callbacks from DBus operations started in this thread are
    // handled by the GLib main loop defined below, even if pipewiregrab_init was
    // called by a program which also uses GLib and already had its own main loop running.
    glib_main_context = g_main_context_new();
    g_main_context_push_thread_default(glib_main_context);
    glib_main_loop = g_main_loop_new(glib_main_context, FALSE);
    if (!glib_main_loop) {
        qWarning() << "g_main_loop_new failed!";
        ret = ENOMEM;
    }

    ret = createDBusConnection();
    if (ret != 0)
        goto exit_glib_loop;

    ret = createDBusProxy();
    if (ret != 0)
        goto exit_glib_loop;

    updateAvailableCursorModes();
    createSession();
    if (portal_error) {
        ret = portal_error;
        goto exit_glib_loop;
    }

    g_main_loop_run(glib_main_loop);
    // The main loop will run until it's stopped by openPipewireRemote (if
    // all DBus method calls were successful), abort (in case of error) or
    // on_cancelled_callback (if a DBus request is canceled).
    // In the latter two cases, pw_ctx->portal_error gets set to a nonzero value.
    if (portal_error)
        ret = portal_error;

exit_glib_loop:
    g_main_loop_unref(glib_main_loop);
    glib_main_loop = NULL;
    g_main_context_pop_thread_default(glib_main_context);
    g_main_context_unref(glib_main_context);

    return ret;
}

ScreenCastPortal::ScreenCastPortal(PortalCaptureType captureType)
    : draw_mouse(true)
    , pipewireFd(0)
{
    switch (captureType) {
    case PortalCaptureType::SCREEN:
        capture_type = 1;
        break;
    case PortalCaptureType::WINDOW:
        capture_type = 2;
        break;
    }
}

ScreenCastPortal::~ScreenCastPortal()
{
    if (session_handle) {
        g_dbus_connection_call(connection,
                               "org.freedesktop.portal.Desktop",
                               session_handle,
                               "org.freedesktop.portal.Session",
                               "Close",
                               NULL,
                               NULL,
                               G_DBUS_CALL_FLAGS_NONE,
                               -1,
                               NULL,
                               NULL,
                               NULL);

        g_clear_pointer(&session_handle, g_free);
    }
    g_clear_object(&connection);
    g_clear_object(&proxy);
    g_clear_pointer(&sender_name, g_free);

#ifndef ENABLE_LIBWRAP
    // If the daemon is running as a separate process, then it is unable to directly use the
    // PipeWire file descriptor opened by the client, so it will have to duplicate it.
    // The duplicated file descriptor will be closed by the daemon, but the original
    // file descriptor needs to be closed by the client.
    if (close(pipewireFd) != 0) {
        int err = errno;
        qWarning() << "Error while attempting to close PipeWire file descriptor: errno =" << err;
    } else {
        qInfo() << "PipeWire file descriptor closed successfully.";
    }
#endif
}