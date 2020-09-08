/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Edouard Denommee <edouard.denommee@savoirfairelinux.com>
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
pragma Singleton

import QtQuick 2.14

QtObject {
    readonly property string id: "Account.id"
    readonly property string type: "Account.type"
    readonly property string alias: "Account.alias"
    readonly property string displayname: "Account.displayName"
    readonly property string enabled: "Account.enable"
    readonly property string mailbox: "Account.mailbox"
    readonly property string dtmf_type: "Account.dtmfType"
    readonly property string autoanswer: "Account.autoAnswer"
    readonly property string isrendezvous: "Account.rendezVous"
    readonly property string active_call_limit: "Account.activeCallLimit"
    readonly property string hostname: "Account.hostname"
    readonly property string username: "Account.username"
    readonly property string bind_address: "Account.bindAddress"
    readonly property string route: "Account.routeset"
    readonly property string password: "Account.password"
    readonly property string realm: "Account.realm"
    readonly property string local_interface: "Account.localInterface"
    readonly property string published_sameas_local: "Account.publishedSameAsLocal"
    readonly property string local_port: "Account.localPort"
    readonly property string published_port: "Account.publishedPort"
    readonly property string published_address: "Account.publishedAddress"
    readonly property string user_agent: "Account.useragent"
    readonly property string upnp_enabled: "Account.upnpEnabled"
    readonly property string has_custom_user_agent: "Account.hasCustomUserAgent"
    readonly property string allow_cert_from_history: "Account.allowCertFromHistory"
    readonly property string allow_cert_from_contact: "Account.allowCertFromContact"
    readonly property string allow_cert_from_trusted: "Account.allowCertFromTrusted"
    readonly property string archive_password: "Account.archivePassword"
    readonly property string archive_has_password: "Account.archiveHasPassword"
    readonly property string archive_path: "Account.archivePath"
    readonly property string archive_pin: "Account.archivePIN"
    readonly property string ring_device_id: "Account.deviceID"
    readonly property string ring_device_name: "Account.deviceName"
    readonly property string proxy_enabled: "Account.proxyEnabled"
    readonly property string proxy_server: "Account.proxyServer"
    readonly property string proxy_push_token: "Account.proxyPushToken"
    readonly property string dht_peer_discovery: "Account.peerDiscovery"
    readonly property string account_peer_discovery: "Account.accountDiscovery"
    readonly property string account_publish: "Account.accountPublish"
    readonly property string manager_uri: "Account.managerUri"
    readonly property string manager_username: "Account.managerUsername"
    readonly property string bootstrap_list_url: "Account.bootstrapListUrl"
    readonly property string dht_proxy_list_url: "Account.dhtProxyListUrl"

    readonly property QtObject audio: QtObject{
        readonly property string port_max: "Account.audioPortMax"
        readonly property string port_min: "Account.audioPortMin"
    }

    readonly property QtObject video: QtObject {
        readonly property string enabled: "Account.videoEnabled"
        readonly property string port_max: "Account.videoPortMax"
        readonly property string port_min: "Account.videoPortMin"
    }

    readonly property QtObject stun: QtObject {
        readonly property string server: "STUN.server"
        readonly property string enabled: "STUN.enable"
    }

    readonly property QtObject turn: QtObject {
        readonly property string server: "TURN.server"
        readonly property string enabled: "TURN.enable"
        readonly property string server_uname: "TURN.username"
        readonly property string server_pwd: "TURN.password"
        readonly property string server_realm: "TURN.realm"
    }

    readonly property QtObject presence: QtObject {
        readonly property string support_publish: "Account.presencePublishSupported"
        readonly property string support_subscribe: "Account.presenceSubscribeSupported"
        readonly property string enabled: "Account.presenceEnabled"
    }

    readonly property QtObject registration: QtObject {
        readonly property string expire: "Account.registrationExpire"
        readonly property string status: "Account.registrationStatus"
    }

    readonly property QtObject ringtone: QtObject {
        readonly property string path: "Account.ringtonePath"
        readonly property string enabled: "Account.ringtoneEnabled"
    }

    readonly property QtObject srtp: QtObject {
        readonly property string key_exchange: "SRTP.keyExchange"
        readonly property string enabled: "SRTP.enable"
        readonly property string rtp_fallback: "SRTP.rtpFallback"
    }

    readonly property QtObject tls: QtObject {
        readonly property string listener_port: "TLS.listenerPort"
        readonly property string enabled: "TLS.enable"
        readonly property string port: "TLS.port"
        readonly property string ca_list_file: "TLS.certificateListFile"
        readonly property string certificate_file: "TLS.certificateFile"
        readonly property string private_key_file: "TLS.privateKeyFile"
        readonly property string password: "TLS.password"
        readonly property string method: "TLS.method"
        readonly property string ciphers: "TLS.ciphers"
        readonly property string server_name: "TLS.serverName"
        readonly property string verify_server: "TLS.verifyServer"
        readonly property string verify_client: "TLS.verifyClient"
        readonly property string require_client_certificate: "TLS.requireClientCertificate"
        readonly property string negotiation_timeout_sec: "TLS.negotiationTimeoutSec"
    }

    readonly property QtObject dht: QtObject {
        readonly property string port: "DHT.port"
        readonly property string public_in_calls: "DHT.PublicInCalls"
        readonly property string allow_from_trusted: "DHT.AllowFromTrusted"
    }

    readonly property QtObject ringns: QtObject {
        readonly property string uri: "RingNS.uri"
        readonly property string account: "RingNS.account"
    }

    readonly property QtObject codecinfo: QtObject {
        readonly property string name: "CodecInfo.name"
        readonly property string type: "CodecInfo.type"
        readonly property string sample_rate: "CodecInfo.sampleRate"
        readonly property string frame_rate: "CodecInfo.frameRate"
        readonly property string bitrate: "CodecInfo.bitrate"
        readonly property string min_bitrate: "CodecInfo.min_bitrate"
        readonly property string max_bitrate: "CodecInfo.max_bitrate"
        readonly property string quality: "CodecInfo.quality"
        readonly property string min_quality: "CodecInfo.min_quality"
        readonly property string max_quality: "CodecInfo.max_quality"
        readonly property string channel_number: "CodecInfo.channelNumber"
        readonly property string auto_quality_enabled: "CodecInfo.autoQualityEnabled"
    }
}
