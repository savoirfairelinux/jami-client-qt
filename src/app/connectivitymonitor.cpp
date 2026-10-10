/*
 * Copyright (C) 2019-2026 Savoir-faire Linux Inc.
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

#include "global.h"

#ifndef _WIN32
#include <glib.h>
#include <gio/gio.h>
#ifdef USE_LIBNM
#include <NetworkManager.h>
#endif
#endif
#include "connectivitymonitor.h"
#include <QDebug>
#include <QPointer>
#include <memory>

#ifdef Q_OS_WIN
#include <atlbase.h>
#include <netlistmgr.h>

class NetworkEventHandler : public INetworkListManagerEvents
{
public:
    NetworkEventHandler()
        : m_lRefCnt(1) {};
    virtual ~NetworkEventHandler() {};

    HRESULT STDMETHODCALLTYPE QueryInterface(REFIID riid, void** ppvObject)
    {
        HRESULT hr = S_OK;
        if (IsEqualIID(riid, IID_IUnknown)) {
            *ppvObject = (IUnknown*) this;
        } else if (IsEqualIID(riid, IID_INetworkListManagerEvents)) {
            *ppvObject = (INetworkListManagerEvents*) this;
        } else {
            hr = E_NOINTERFACE;
        }

        return hr;
    };
    ULONG STDMETHODCALLTYPE AddRef()
    {
        return (ULONG) InterlockedIncrement(&m_lRefCnt);
    };
    ULONG STDMETHODCALLTYPE Release()
    {
        LONG res = InterlockedDecrement(&m_lRefCnt);
        if (res == 0) {
            delete this;
        }
        return (ULONG) res;
    };

    virtual HRESULT STDMETHODCALLTYPE ConnectivityChanged(NLM_CONNECTIVITY newConnectivity)
    {
        qDebug() << "connectivity changed: " << newConnectivity;
        if (connectivityChangedCb_) {
            connectivityChangedCb_(newConnectivity != NLM_CONNECTIVITY_DISCONNECTED);
        }
        return S_OK;
    };

    void setOnConnectivityChangedCallBack(std::function<void(bool)>&& cb)
    {
        connectivityChangedCb_ = cb;
    };

private:
    LONG m_lRefCnt;

    std::function<void(bool)> connectivityChangedCb_;
};

ConnectivityMonitor::ConnectivityMonitor(QObject* parent)
    : QObject(parent)
{
    CoInitialize(NULL);

    IUnknown* pUnknown = NULL;

    HRESULT hr = CoCreateInstance(CLSID_NetworkListManager, NULL, CLSCTX_ALL, IID_IUnknown, (void**) &pUnknown);
    if (FAILED(hr)) {
        return;
    }

    pNetworkListManager_ = NULL;
    hr = pUnknown->QueryInterface(IID_INetworkListManager, (void**) &pNetworkListManager_);
    if (FAILED(hr)) {
        destroy();
        pUnknown->Release();
        return;
    }

    pCPContainer_ = NULL;
    hr = pNetworkListManager_->QueryInterface(IID_IConnectionPointContainer, (void**) &pCPContainer_);
    if (FAILED(hr)) {
        destroy();
        pUnknown->Release();
        return;
    }

    pConnectPoint_ = NULL;
    hr = pCPContainer_->FindConnectionPoint(IID_INetworkListManagerEvents, &pConnectPoint_);
    if (SUCCEEDED(hr)) {
        cookie_ = NULL;
        netEventHandler_ = new NetworkEventHandler;
        netEventHandler_->setOnConnectivityChangedCallBack([this](bool connected) {
            Q_EMIT connectivityChanged();
            if (connected)
                Q_EMIT networkChanged();
            else
                Q_EMIT networkLost();
        });
        hr = pConnectPoint_->Advise((IUnknown*) netEventHandler_, &cookie_);
    } else {
        destroy();
    }

    pUnknown->Release();
}

bool
ConnectivityMonitor::isOnline()
{
    if (!pNetworkListManager_) {
        return false;
    }
    VARIANT_BOOL IsConnect = VARIANT_FALSE;
    HRESULT hr = pNetworkListManager_->get_IsConnectedToInternet(&IsConnect);
    if (SUCCEEDED(hr)) {
        return IsConnect == VARIANT_TRUE;
    }
    return false;
}

void
ConnectivityMonitor::destroy()
{
    if (pConnectPoint_) {
        pConnectPoint_->Unadvise(cookie_);
        pConnectPoint_->Release();
    }
    if (pCPContainer_) {
        pCPContainer_->Release();
    }
    if (pNetworkListManager_) {
        pNetworkListManager_->Release();
        pNetworkListManager_ = NULL;
    }
}

ConnectivityMonitor::~ConnectivityMonitor()
{
    destroy();
    CoUninitialize();
}
#else
#ifdef USE_LIBNM
static void
logConnectionInfo(NMActiveConnection* connection)
{
    if (connection) {
        C_INFO << "Primary network connection:" << nm_active_connection_get_uuid(connection)
               << "default:" << (nm_active_connection_get_default(connection) ? "yes" : "no");
    } else {
        C_WARN << "No primary network connection detected, check network settings";
    }
}

static void
activeConnectionsChanged(NMClient* nm, GParamSpec*, ConnectivityMonitor* cm)
{
    auto connection = nm_client_get_primary_connection(nm);
    logConnectionInfo(connection);
    Q_EMIT cm->connectivityChanged();
}

// D-Bus path of the last primary connection, unique to each activation.
static constexpr auto PRIMARY_CONNECTION_KEY = "jami-primary-connection";

static bool
updatePrimaryConnection(NMClient* nm)
{
    auto connection = nm_client_get_primary_connection(nm);
    // Losing the network is not a move to a new one: wait for the next.
    if (not connection)
        return false;
    auto path = nm_object_get_path(NM_OBJECT(connection));
    if (g_strcmp0(path, static_cast<const char*>(g_object_get_data(G_OBJECT(nm), PRIMARY_CONNECTION_KEY))) == 0)
        return false;
    g_object_set_data_full(G_OBJECT(nm), PRIMARY_CONNECTION_KEY, g_strdup(path), g_free);
    return true;
}

static void
primaryConnectionChanged(NMClient* nm, GParamSpec*, ConnectivityMonitor* cm)
{
    if (not nm_client_get_primary_connection(nm)) {
        logConnectionInfo(nullptr);
        Q_EMIT cm->networkLost();
    } else if (updatePrimaryConnection(nm)) {
        logConnectionInfo(nm_client_get_primary_connection(nm));
        Q_EMIT cm->networkChanged();
    }
}

static void
vpnConnectionChanged(NMClient* nm, NMActiveConnection* connection, ConnectivityMonitor* cm)
{
    if (nm_active_connection_get_vpn(connection)
        and (nm_active_connection_get_default(connection) or nm_active_connection_get_default6(connection))
        and nm_client_get_primary_connection(nm))
        Q_EMIT cm->networkChanged();
}

void
ConnectivityMonitor::onNetworkManagerReady(NMClient* nm)
{
    nmClient_ = nm;
    C_INFO << "NetworkManager client initialized, version:" << nm_client_get_version(nm)
           << ", daemon running:" << (nm_client_get_nm_running(nm) ? "yes" : "no")
           << ", networking enabled:" << (nm_client_networking_get_enabled(nm) ? "yes" : "no");

    auto connection = nm_client_get_primary_connection(nm);
    logConnectionInfo(connection);
    updatePrimaryConnection(nm);
    g_signal_connect(nm, "notify::active-connections", G_CALLBACK(activeConnectionsChanged), this);
    g_signal_connect(nm, "notify::primary-connection", G_CALLBACK(primaryConnectionChanged), this);

    const auto* connections = nm_client_get_active_connections(nm);
    for (guint i = 0; i < connections->len; ++i)
        watchVpnConnection(NM_ACTIVE_CONNECTION(g_ptr_array_index(connections, i)));

    g_signal_connect(nm,
                     "active-connection-added",
                     G_CALLBACK(+[](NMClient* client, NMActiveConnection* connection, ConnectivityMonitor* cm) {
                         cm->watchVpnConnection(connection);
                         vpnConnectionChanged(client, connection, cm);
                     }),
                     this);
    g_signal_connect(nm,
                     "active-connection-removed",
                     G_CALLBACK(+[](NMClient* client, NMActiveConnection* connection, ConnectivityMonitor* cm) {
                         g_signal_handlers_disconnect_by_data(connection, cm);
                         vpnConnectionChanged(client, connection, cm);
                     }),
                     this);
}

void
ConnectivityMonitor::watchVpnConnection(NMActiveConnection* connection)
{
    if (not nm_active_connection_get_vpn(connection))
        return;

    // PrimaryConnection stays on the underlay when a VPN takes the default route.
    auto callback = G_CALLBACK(+[](NMActiveConnection*, GParamSpec*, ConnectivityMonitor* cm) {
        if (nm_client_get_primary_connection(cm->nmClient_))
            Q_EMIT cm->networkChanged();
    });
    g_signal_connect(connection, "notify::default", callback, this);
    g_signal_connect(connection, "notify::default6", callback, this);
}
#endif

ConnectivityMonitor::ConnectivityMonitor(QObject* parent)
    : QObject(parent)
{
#ifdef USE_LIBNM
    auto* monitor = new QPointer<ConnectivityMonitor>(this);
    nm_client_new_async(
        nullptr,
        +[](GObject*, GAsyncResult* result, gpointer data) {
            std::unique_ptr<QPointer<ConnectivityMonitor>> monitor(static_cast<QPointer<ConnectivityMonitor>*>(data));
            GError* error = nullptr;
            auto* client = nm_client_new_finish(result, &error);
            if (not client) {
                C_WARN << "Error initializing NetworkManager client:" << error->message;
                g_clear_error(&error);
            } else if (auto* instance = monitor->data()) {
                instance->onNetworkManagerReady(client);
            } else {
                g_object_unref(client);
            }
        },
        monitor);
#endif
}

ConnectivityMonitor::~ConnectivityMonitor()
{
#ifdef USE_LIBNM
    if (nmClient_) {
        g_signal_handlers_disconnect_by_data(nmClient_, this);
        const auto* connections = nm_client_get_active_connections(nmClient_);
        for (guint i = 0; i < connections->len; ++i)
            g_signal_handlers_disconnect_by_data(g_ptr_array_index(connections, i), this);
        g_object_unref(nmClient_);
    }
#endif
    C_DBG << "Destroying connectivity monitor";
}

bool
ConnectivityMonitor::isOnline()
{
    return false;
}

#endif // Q_OS_WIN
