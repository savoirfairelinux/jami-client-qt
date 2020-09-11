/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Aline Gondim Santos <aline.gondimsantos@savoirfairelinux.com>
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

// JamiTheme as a singleton is to provide global strings entries.
pragma Singleton

import QtQuick 2.14

Item {
    // Misc
    property string contactSearchConversation: qsTr("Search a contact or a conversation")
    property string contactSearchInvitations: qsTr("Search your invitations")

    // AboutPopUp
    property string version: qsTr("Version")
    property string slogan: qsTr("Together")
    property string declaration: qsTr("Jami is a free software for universal communication which respects the freedom and privacy of its users.")
    property string changelog: qsTr("Changelog")
    property string credits: qsTr("Credits")

    // AccountComboBox
    property string displayQRCode: qsTr("Display QR code")
    property string openSettings: qsTr("Open settings")
    property string closeSettings: qsTr("Close settings")

    // AccountMigrationDialog
    property string authenticationRequired: qsTr("Authentication required")
    property string migrationReason: qsTr("Your session has expired or been revoked on this device. Please enter your password.")
    property string jamsServer: qsTr("JAMS server")
    property string authenticate: qsTr("Authenticate")
    property string deleteAccount: qsTr("Delete account")
    property string inProgress: qsTr("In progress...")
    property string authenticationFailed: qsTr("Authentication failed")
    property string password: qsTr("Password")
    property string username: qsTr("Username")
    property string alias: qsTr("Alias")

    // AdvancedCallSettings
    property string callSettings: qsTr("Call Settings")
    property string allowCallsUnknownContacs: qsTr("Allow incoming calls from unknown contacts")
    property string rendezVous: qsTr("Rendezvous point: turn your account into a meeting point")
    property string autoAnswerCalls: qsTr("Automatically answer calls")
    property string enableCustomRingtone: qsTr("Enable custom ringtone")
    property string selectCustomRingtone: qsTr("Select custom ringtone")
    property string addCustomRingtone: qsTr("Add a custom ringtone")
    property string selectNewRingtone: qsTr("Select a new ringtone")

    // AdvancedVoiceMailSettings
    property string voiceMail: qsTr("Voicemail")
    property string voiceMailDialCode: qsTr("Voicemail dial code")

    // AdvancedSIPSecuritySettings && AdvancedJamiSecuritySettings
    property string security: qsTr("Security")
    property string encryptMediaStream: qsTr("Encrypt media streams (SRTP)")
    property string enableSDES: qsTr("Enable SDES key exchange")
    property string fallbackRTP: qsTr("Allow fallback on RTP")
    property string encryptNegotiation: qsTr("Encrypt negotiation (TLS)")
    property string caCertificate: qsTr("CA certificate")
    property string userCertificate: qsTr("User certificate")
    property string privateKey: qsTr("Private key")
    property string privateKeyPassword: qsTr("Private key password")
    property string verifyCertificatesServer: qsTr("Verify certificates for incoming TLS connections")
    property string verifyCertificatesClient: qsTr("Verify server TLS certificates")
    property string tlsRequireConnections: qsTr("Require certificate for incoming TLS connections")
    property string tlsProtocol: qsTr("TLS protocol method")
    property string audioDeviceSelector: qsTr("Audio input device selector")
    property string tlsServerName: qsTr("TLS server name")
    property string negotiationTimeOut: qsTr("Negotiation timeout (seconds)")
    property string selectPrivateKey: qsTr("Select a private key")
    property string selectUserCert: qsTr("Select an user certificate")
    property string selectCACert: qsTr("Select a CA certificate")

    // AdvancedConnectivitySettings
    property string connectivity: qsTr("Connectivity")
    property string registrationTimeOut: qsTr("Registration expire timeout (seconds)")
    property string networkInterface: qsTr("Network interface")
    property string useUPnP: qsTr("Use UPnP")
    property string useTURN: qsTr("Use TURN")
    property string turnAdress: qsTr("TURN address")
    property string turnUsername: qsTr("TURN username")
    property string turnPassword: qsTr("TURN password")
    property string turnRealm: qsTr("TURN Realm")
    property string useSTUN: qsTr("Use STUN")
    property string stunAdress: qsTr("STUN address")

    // AdvancedPublicAddressSettings
    property string publicAddress: qsTr("Public address")
    property string useCustomAddress: qsTr("Use custom address/port")
    property string address: qsTr("Address")
    property string port: qsTr("Port")

    // AdvancedMediaSettings
    property string media: qsTr("Media")
    property string enableVideo: qsTr("Enable video")

    // AdvancedSDPSettings
    property string sdpSettingsTitle: qsTr("SDP Session Negotiation (ICE Fallback)")
    property string sdpSettingsSubtitle: qsTr("Only used during negotiation in case ICE is not supported")
    property string audioRTPMinPort: qsTr("Audio RTP minimum Port")
    property string audioRTPMaxPort: qsTr("Audio RTP maximum Port")
    property string videoRTPMinPort: qsTr("Video RTP minimum Port")
    property string videoRTPMaxPort: qsTr("Video RTP maximum port")

    // AdvancedOpenDHTSettings
    property string enablePeerDiscovery: qsTr("Enable local peer discovery.")
    property string tooltipPeerDiscovery: qsTr("Connect to other DHT nodes advertising on your local network.")
    property string openDHTConfig: qsTr("OpenDHT Configuration")
    property string enableProxy: qsTr("Enable proxy")
    property string proxyAddress: qsTr("Proxy address")
    property string bootstrap: qsTr("Bootstrap")

    // SettingsHeader
    property string back: qsTr("Back")

    // AVSettingsPage
    property string avSettingsTitle: qsTr("Audio & Video Settings")

    // AudioSettings
    property string audio: qsTr("Audio")
    property string microphone: qsTr("Microphone")
    property string selectAudioInputDevice: qsTr("Select audio input device")
    property string outputDevice: qsTr("Output device")
    property string selectAudioOutputDevice: qsTr("Select audio output device")
    property string ringtoneDevice: qsTr("Ringtone device")
    property string selectRingtoneOutputDevice: qsTr("Select ringtone output device")
    property string audioManager: qsTr("Audio manager")

    // VideoSettings
    property string video: qsTr("Video")
    property string selectVideoDevice: qsTr("Select video device")
    property string device: qsTr("Device")
    property string resolution: qsTr("Resolution")
    property string selectVideoResolution: qsTr("Select video resolution")
    property string fps: qsTr("Frame per second")
    property string selectFPS: qsTr("Select video frame per second (fps)")
    property string enableHWAccel: qsTr("Enable hardware acceleration")
    property string previewUnavailable: qsTr("Preview unavailable")

    // BackupKeyPage
    property string  backupAccountInfos: qsTr("Your account only exists on this device. " +
                                            "If you lost your device or uninstall the application, " +
                                            "your account will be deleted and can not be recovered. " +
                                            "You can backup your account now or later.")
    property string backupAccountHere: qsTr("Backup account here")
    property string backupAccount: qsTr("Backup your account!")
    property string backupAccountBtn: qsTr("Backup account")
    property string skip: qsTr("Skip")
    property string neverShowAgain: qsTr("Never show me this again")
    property string recommended: qsTr("Recommended")

    // BannedItemDelegate
    property string reinstateContact: qsTr("Reinstate as contact")
    property string name: qsTr("name")
    property string id: qsTr("id")

    // CallOverlayButtonGroup
    property string mute: qsTr("Mute")
    property string unmute: qsTr("Unmute")
    property string hanguUp: qsTr("Hang-up")
    property string pause: qsTr("Pause")
    property string resume: qsTr("Resume")
    property string addParticipants: qsTr("Add participants")
    property string chat: qsTr("Chat")
    property string moreOptions: qsTr("More options")

    // CallViewContextMenu
    property string hold: qsTr("Hold")
    property string sipInputPanel: qsTr("Sip input panel")
    property string transferCall: qsTr("Transfer call")
    property string stopRec: qsTr("Stop recording")
    property string startRec: qsTr("Start recording")
    property string exitFullScreen: qsTr("Exit full screen")
    property string fullScreen: qsTr("Full screen")
    property string shareScreen: qsTr("Share screen")
    property string shareScreenArea: qsTr("Share screen area")
    property string shareFile: qsTr("Share file")
    property string viewPlugin: qsTr("View plugin")
    property string noVideoDevice: qsTr("No video device")

    // ConnectToAccountManager
    property string enterJAMSURL: qsTr("Enter Jami Account Management Server (JAMS) URL")
    property string required: qsTr("Required")
    property string jamiManagementServerURL: qsTr("Jami Account Management Server URL")
    property string jamsCredentials: qsTr("Enter your JAMS credentials")
    property string connect: qsTr("Connect")
    property string generatingAccount: qsTr("Generating account…")
    property string backToWelcome: qsTr("Back to welcome page")
    
}