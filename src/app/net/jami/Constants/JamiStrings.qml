/*
 * Copyright (C) 2020-2026 Savoir-faire Linux Inc.
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

// JamiStrings as a singleton is to provide global strings entries.
pragma Singleton
import QtQuick
import net.jami.Helpers 1.1

Item {
    readonly property string appTitle: "Jami"
    readonly property string httpUserAgentName: "jami"

    // Misc
    property string accept: qsTr("Accept")
    property string acceptAudio: qsTr("Accept with audio")
    property string acceptVideo: qsTr("Accept with video")
    property string decline: qsTr("Decline")
    property string endCall: qsTr("End call")
    property string incomingAudioCallFrom: qsTr("Incoming audio call from %1")
    property string incomingVideoCallFrom: qsTr("Incoming video call from %1")
    property string newGroup: qsTr("Create new group")
    property string invitations: qsTr("Invitations")
    property string description: qsTr("Jami is a universal communication platform, with privacy as its foundation, that relies on a free distributed network for everyone.")
    property string updateToSwarm: qsTr("Migrating to the Swarm technology will enable synchronizing this conversation across multiple devices and improve reliability. The legacy conversation history will be cleared in the process.")
    property string migrateConversation: qsTr("Migrate conversation")

    // DaemonReconnectWindow
    property string reconnectWarn: qsTr("An error occurred while reconnecting to the Jami daemon (jamid).\nThe application will now exit.")
    property string reconnectAttempt: qsTr("Jami daemon (jamid) reconnection is in progress. Please wait…")

    // AboutPopUp
    property string buildID: qsTr("Build ID")
    property string version: qsTr("Version")
    property string declarationYear: "Copyright © 2015–2025"
    property string slogan: "Atlas"
    property string declaration: qsTr('Jami, a GNU package, is software for universal and distributed peer-to-peer communication that respects the freedom and privacy of its users. Visit <a href="https://jami.net" style="color: ' + JamiTheme.buttonTintedBlue + '">jami.net</a>' + ' to learn more.')
    property string noWarranty: qsTr('This program comes with absolutely no warranty. See the <a href="https://www.gnu.org/licenses/gpl-3.0.html" style="color: ' + JamiTheme.buttonTintedBlue + '">GNU General Public License</a>, version 3 or later for details.')
    property string contribute: qsTr('Contribute')
    property string feedback: qsTr('Feedback')

    // Crash report popup
    property string crashReportTitle: qsTr("Application Recovery")
    property string crashReportMessage: qsTr("Jami has recovered from a crash. Do you want to send a crash report to help fix the issue?")
    property string crashReportMessageExtra: qsTr("Only essential data, including the app version, platform information, and a snapshot of the program's state at the time of the crash, will be shared.")

    // AccountComboBox
    property string displayQRCode: qsTr("Display QR code")
    property string openSettings: qsTr("Open settings")
    property string closeSettings: qsTr("Close settings")
    property string addAccount: qsTr("Add another account")
    property string manageAccount: qsTr("Manage account")

    // ContactPicker
    property string addToConference: qsTr("Add to conference")
    property string addToConversation: qsTr("Add to conversation")
    property string transferThisCall: qsTr("Transfer this call")
    property string transferTo: qsTr("Transfer to")

    // Device import/linking
    property string scanToImportAccount: qsTr("To continue the import account operation, scan the following QR code on the source device.")
    property string waitingForToken: qsTr("Please wait…")
    property string scanQRCode: qsTr("Scan QR code")
    property string connectingToDevice: qsTr("Action required. Please confirm account on the source device.")
    property string confirmAccountImport: qsTr("Authenticating device")
    property string transferringAccount: qsTr("Transferring account…")
    property string cantScanQRCode: qsTr("If you are unable to scan the QR code, enter the following token on the source device.")
    property string optionConfirm: qsTr("Confirm")
    property string optionTryAgain: qsTr("Try again")
    property string importFailed: qsTr("An error occurred while importing the account.")
    property string importFromAnotherAccount: qsTr("Import from another account")
    property string connectToAccount: qsTr("Connect to account")
    property string authenticationError: qsTr("An authentication error occurred while linking the device. Please check credentials and try again.")

    // AccountMigrationDialog
    property string authenticationRequired: qsTr("Authentication required")
    property string migrationReason: qsTr("Your session has expired or been revoked on this device. Please enter your password.")
    property string jamsServer: qsTr("JAMS server")
    property string authenticate: qsTr("Authenticate")
    property string deleteAccount: qsTr("Delete account")
    property string inProgress: qsTr("In progress…")
    property string authenticationFailed: qsTr("An error occurred while authenticating the account.")
    property string password: qsTr("Password")
    property string username: qsTr("Username")
    property string alias: qsTr("Alias")

    // AdvancedCallSettings
    property string allowCallsUnknownContacs: qsTr("Allow incoming calls from unknown contacts")
    property string rendezVous: qsTr("Convert your account into a rendezvous point")
    property string autoAcceptCalls: qsTr("Automatically accept calls")
    property string enableCustomRingtone: qsTr("Enable custom ringtone")
    property string selectCustomRingtone: qsTr("Select custom ringtone")
    property string selectNewRingtone: qsTr("Select a new ringtone")
    property string certificateFile: qsTr("Certificate file (*.crt)")
    property string audioFile: qsTr("Audio file (*.wav *.ogg *.opus *.mp3 *.aiff *.wma)")
    property string pushToTalk: qsTr("Push-to-talk")
    property string enablePTT: qsTr("Enable push-to-talk")
    property string keyboardShortcut: qsTr("Keyboard shortcut")
    property string changeKeyboardShortcut: qsTr("Change keyboard shortcut")
    property string raiseWhenCalled: qsTr("Bring the application to the front for incoming calls")
    property string denySecondCall: qsTr("Decline incoming calls when already in a call")

    // ChangePttKeyPopup
    property string changeShortcut: qsTr("Change shortcut")
    property string assignmentIndication: qsTr("Press the key to be assigned to push-to-talk shortcut")
    property string assign: qsTr("Assign")

    // AdvancedVoiceMailSettings
    property string voiceMail: qsTr("Voicemail")
    property string voiceMailDialCode: qsTr("Voicemail dial code")

    // AdvancedSIPSecuritySettings && AdvancedJamiSecuritySettings
    property string security: qsTr("Security")
    property string enableSDES: qsTr("Enable SDES key exchange")
    property string encryptNegotiation: qsTr("Encrypt negotiation (TLS)")
    property string caCertificate: qsTr("CA certificate")
    property string userCertificate: qsTr("User certificate")
    property string privateKey: qsTr("Private key")
    property string privateKeyPassword: qsTr("Private key password")
    property string verifyCertificatesServer: qsTr("Verify certificates for incoming TLS connections")
    property string verifyCertificatesClient: qsTr("Verify server TLS certificates")
    property string tlsRequireConnections: qsTr("Require certificate for incoming TLS connections")
    property string disableSecureDlgCheck: qsTr("Disable secure dialog check for incoming TLS data")
    property string selectPrivateKey: qsTr("Select private key")
    property string selectUserCert: qsTr("Select user certificate")
    property string selectCACert: qsTr("Select CA certificate")
    property string selectCACertDefault: qsTr("Select")
    property string keyFile: qsTr("Key file (*.key)")

    // AdvancedConnectivitySettings
    property string connectivity: qsTr("Connectivity")
    property string autoRegistration: qsTr("Auto Registration After Expired")
    property string registrationExpirationTime: qsTr("Registration expiration time (seconds)")
    property string networkInterface: qsTr("Network interface")
    property string useUPnP: qsTr("Use UPnP")
    property string useTURN: qsTr("Use TURN")
    property string turnAdress: qsTr("TURN address")
    property string turnUsername: qsTr("TURN username")
    property string turnPassword: qsTr("TURN password")
    property string turnRealm: qsTr("TURN realm")
    property string useSTUN: qsTr("Use STUN")
    property string stunAdress: qsTr("STUN address")

    // AdvancedPublicAddressSettings
    property string allowIPAutoRewrite: qsTr("Allow IP Auto Rewrite")
    property string publicAddress: qsTr("Public address")
    property string useCustomAddress: qsTr("Use custom address and port")
    property string address: qsTr("Address")
    property string port: qsTr("Port")

    // AdvancedMediaSettings
    property string media: qsTr("Media")
    property string enableVideo: qsTr("Enable video")
    property string videoCodecs: qsTr("Video codecs")
    property string audioCodecs: qsTr("Audio codecs")

    // AdvancedNameServerSettings
    property string nameServer: qsTr("Name server")

    // AdvancedSDPSettings
    property string sdpSettingsTitle: qsTr("SDP Session Negotiation (ICE Fallback)")
    property string sdpSettingsSubtitle: qsTr("Only used during negotiation in case ICE is not supported")
    property string audioRTPMinPort: qsTr("Audio RTP minimum Port")
    property string audioRTPMaxPort: qsTr("Audio RTP maximum Port")
    property string videoRTPMinPort: qsTr("Video RTP minimum Port")
    property string videoRTPMaxPort: qsTr("Video RTP maximum port")

    // AdvancedOpenDHTSettings
    property string dhtPortUsed: qsTr("Current DHT port used")
    property string enablePeerDiscovery: qsTr("Enable local peer discovery")
    property string tooltipPeerDiscovery: qsTr("Connect to other DHT nodes advertising on your local network.")
    property string openDHTConfig: qsTr("OpenDHT configuration")
    property string enableProxy: qsTr("Enable proxy")
    property string proxyAddress: qsTr("Proxy address")
    property string proxyListURL: qsTr("Proxy list URL")
    property string bootstrap: qsTr("Bootstrap")
    property string usingProxy: qsTr("Using proxy:")
    property string proxyDisabled: qsTr("Proxy disabled")

    // SettingsHeader
    property string back: qsTr("Back")
    property string accountSettingsMenuTitle: qsTr("Account")
    property string generalSettingsTitle: qsTr("General")
    property string extensionSettingsTitle: qsTr("Extensions")
    property string enableAccountSettingsTitle: qsTr("Enable account")
    property string manageAccountSettingsTitle: qsTr("Manage account")
    property string linkedDevicesSettingsTitle: qsTr("Linked devices")
    property string callSettingsTitle: qsTr("Call settings")
    property string chatSettingsTitle: qsTr("Chat")
    property string advancedSettingsTitle: qsTr("Advanced settings")
    property string mediaSettingsTitle: qsTr("Media")

    // AudioSettings
    property string audio: qsTr("Audio")
    property string devices: qsTr("Devices")
    property string microphone: qsTr("Microphone")
    property string selectAudioInputDevice: qsTr("Select audio input device")
    property string outputDevice: qsTr("Output device")
    property string selectAudioOutputDevice: qsTr("Select audio output device")
    property string ringtoneDevice: qsTr("Ringtone device")
    property string selectRingtoneOutputDevice: qsTr("Select ringtone output device")
    property string audioManager: qsTr("Audio manager")
    property string soundTest: qsTr("Sound test")
    property string noiseReduction: qsTr("Noise reduction")
    property string echoSuppression: qsTr("Echo suppression")
    property string voiceActivityDetection: qsTr("Voice activity detection")

    // VideoSettings
    property string video: qsTr("Video")
    property string selectVideoDevice: qsTr("Select video device")
    property string device: qsTr("Device")
    property string resolution: qsTr("Resolution")
    property string selectVideoResolution: qsTr("Select video resolution")
    property string fps: qsTr("Frames per second")
    property string selectFPS: qsTr("Select video frame rate (frames per second)")
    property string enableHWAccel: qsTr("Hardware acceleration")
    property string mirrorLocalVideo: qsTr("Mirror local video")
    property string screenSharing: qsTr("Screen sharing")
    property string selectScreenSharingFPS: qsTr("Select screen sharing frame rate (frames per second)")
    property string noCamera: qsTr("No camera available")

    // BackupKeyPage
    property string whyBackupAccount: qsTr("Why should I back-up this account?")
    property string backupAccountInfos: qsTr("Your account only exists on this device. " + "If you lose your device or uninstall the application, " + "your account will be deleted and CANNOT be recovered. " + "You can <a href='blank'> back up your account </a> now or later (in the Account Settings).")
    property string backupAccountHere: qsTr("Back up account here")
    property string backupAccountBtn: qsTr("Back up account")
    property string success: qsTr("Success")
    property string error: qsTr("Error")
    property string jamiAccountFiles: qsTr("Jami account (*.jac)")
    property string allFiles: qsTr("All files (*)")

    // ContactItemDelegate
    property string name: qsTr("name")
    property string identifier: qsTr("Identifier")

    // CallOverlay
    property string isRecording: qsTr("%1 is recording")
    property string areRecording: qsTr("%1 are recording")
    property string mute: qsTr("Mute microphone")
    property string unmute: qsTr("Unmute microphone")
    property string pauseCall: qsTr("Pause call")
    property string resumeCall: qsTr("Resume call")
    property string stopCamera: qsTr("Stop camera")
    property string startCamera: qsTr("Start camera")
    property string inviteMember: qsTr("Invite member")
    property string inviteMembers: qsTr("Invite members")
    property string details: qsTr("Details")
    property string chat: qsTr("Chat")
    property string moreOptions: qsTr("More options")
    property string mosaic: qsTr("Mosaic")
    property string participantMicIsStillMuted: qsTr("Participant microphone is still muted.")
    property string mutedLocally: qsTr("Device microphone is still muted.")
    property string participantModIsStillMuted: qsTr("You are still muted by moderator")
    property string mutedByModerator: qsTr("You are muted by a moderator")
    property string moderator: qsTr("Moderator")
    property string host: qsTr("Host")
    property string bothMuted: qsTr("Local and Moderator muted")
    property string moderatorMuted: qsTr("Moderator muted")
    property string notMuted: qsTr("Not muted")
    property string participantsSide: qsTr("On the side")
    property string participantsTop: qsTr("On the top")
    property string hideSelf: qsTr("Hide self")
    property string hideSpectators: qsTr("Hide spectators")
    property string privateConversation: qsTr("Private")
    property string privateRestrictedGroup: qsTr("Private group (restricted invites)")
    property string privateGroup: qsTr("Private group")
    property string publicGroup: qsTr("Public Group")

    // LineEditContextMenu
    property string share: qsTr("Share")
    property string cut: qsTr("Cut")
    property string copy: qsTr("Copy")
    property string paste: qsTr("Paste")

    // ConversationContextMenu
    property string startAudioCall: qsTr("Start audio call")
    property string startVideoCall: qsTr("Start video call")
    property string deleteConversation: qsTr("Delete conversation")
    property string confirmAction: qsTr("Confirm action")
    property string removeConversation: qsTr("Remove conversation")
    property string confirmRemoveConversation: qsTr("Do you want to leave this conversation?")
    property string leaveGroup: qsTr("Leave group")
    property string confirmLeaveGroup: qsTr("Are you sure you want to leave this group?")
    property string confirmRemoveContact: qsTr("Do you want to remove this contact? The existing conversation will be deleted.")
    property string confirmBlockContact: qsTr("Do you want to block this contact?")
    property string confirmRemoveOneToOneConversation: qsTr("Are you sure you want to remove this conversation? The contact will not be removed.")
    property string removeContact: qsTr("Remove contact")
    property string blockContact: qsTr("Block contact")
    property string convDetails: qsTr("Conversation details")
    property string contactDetails: qsTr("Contact details")

    // CallViewContextMenu
    property string sipInputPanel: qsTr("DTMF input panel")
    property string openKeypad: qsTr("Open keypad")
    property string transferCall: qsTr("Transfer call")
    property string stopRec: qsTr("Stop recording")
    property string startRec: qsTr("Start recording")
    property string viewFullScreen: qsTr("View full screen")
    property string shareScreen: qsTr("Share screen")
    property string shareWindow: qsTr("Share window")
    property string stopSharing: qsTr("Stop sharing screen or file")
    property string shareScreenArea: qsTr("Share screen area")
    property string shareFile: qsTr("Share file")
    property string selectShareMethod: qsTr("Select sharing method")
    property string viewExtension: qsTr("View extension")
    property string advancedInformation: qsTr("Advanced information")
    property string noVideoDevice: qsTr("No video device")
    property string notAvailable: qsTr("Unavailable")
    property string lowerHand: qsTr("Lower hand")
    property string raiseHand: qsTr("Raise hand")
    property string layoutSettings: qsTr("Layout settings")
    property string tileScreenshot: qsTr("Take tile screenshot")
    property string screenshotTaken: qsTr("Screenshot saved to %1")
    property string fileSaved: qsTr("File saved to %1")

    // Advanced information
    property string renderersInformation: qsTr("Renderers information")
    property string callInformation: qsTr("Call information")
    property string peerNumber: qsTr("Peer number")
    property string callId: qsTr("Call id")
    property string sockets: qsTr("Sockets")
    property string videoCodec: qsTr("Video codec")
    property string hardwareAcceleration: qsTr("Hardware acceleration")
    property string videoBitrate: qsTr("Video bitrate")
    property string audioCodec: qsTr("Audio codec")
    property string rendererId: qsTr("Renderer id")
    property string fps_short: qsTr("Fps")

    // Share location/position
    property string shareLocation: qsTr("Share location")
    property string stopSharingLocation: qsTr("Stop sharing")
    property string locationServicesError: qsTr("An error occurred while sharing the device location.\nEnable “Location Services” in device settings in order to use this feature.\nThe location of other members can still be received.")
    property string locationServicesClosedError: qsTr("An error occurred while sharing the device location. Please check your Internet connection and try again.")
    property string stopAllSharings: qsTr("Turn off location sharing")
    property string shortStopAllSharings: qsTr("Turn off sharing")
    property string stopConvSharing: qsTr("Stop location sharing in this conversation (%1)")
    property string stopSharingPopupBody: qsTr("Location is shared in several conversations")
    property string unpinStopSharingTooltip: qsTr("Pin map to be able to share location or to turn off location in specific conversations")
    property string stopSharingSeveralConversationTooltip: qsTr("Location is shared in several conversations, click to choose how to turn off location sharing")
    property string shareLocationToolTip: qsTr("Share location to participants of this conversation (%1)")
    property string maximizeMapTooltip: qsTr("Maximize")
    property string reduceMapTooltip: qsTr("Reduce")
    property string dragMapTooltip: qsTr("Drag")
    property string centerMapTooltip: qsTr("Center")
    property string closeMapTooltip: qsTr("Close")
    property string unpin: qsTr("Unpin")
    property string pinWindow: qsTr("Pin")
    property string positionShareDuration: qsTr("Position share duration")
    property string locationSharingLabel: qsTr("Location sharing")
    property string minLocationDuration: qsTr("1m")
    property string maxLocationDuration: qsTr("Unlimited")
    property string xsec: qsTr("%L1s")
    property string xmin: qsTr("%L1m")
    property string xminxsec: qsTr("%L1m %L2s")
    property string xhour: qsTr("%L1h")
    property string xhourxmin: qsTr("%L1h %L2m")

    // Chatview header
    property string hideChat: qsTr("Hide chat")
    property string showExtensions: qsTr("Show available extensions")
    property string addToConversations: qsTr("Add to conversations")
    property string backendError: qsTr("A backend system error occurred: %0")
    property string disabledAccount: qsTr("The account is disabled")
    property string noNetworkConnectivity: qsTr("No network connectivity")
    property string deletedMessage: qsTr("%1 deleted a message")
    property string deletedMedia: qsTr("%1 deleted a media")
    property string returnToCall: qsTr("Return to call")

    // Conversation ended banner
    property string conversationEnded: qsTr("This conversation has ended.")

    // MessagesResearch
    property string jumpTo: qsTr("Jump to")
    property string messages: qsTr("Messages")
    property string files: qsTr("Files")
    property string search: qsTr("Search")

    // Chatview footer
    property string typeIndicatorSingle: qsTr("%1 is typing…")
    property string typeIndicatorPlural: qsTr("%1 are typing…")
    property string typeIndicatorMax: qsTr("Several people are typing…")
    property string typeIndicatorAnd: qsTr("%1 and %2")

    // ConnectToAccountManager
    property string enterJAMSURL: qsTr("Enter the Jami Account Management Server (JAMS) URL")
    property string jamiManagementServerURL: qsTr("Jami Account Management Server URL")
    property string jamsCredentials: qsTr("Enter JAMS credentials")
    property string connect: qsTr("Connect")
    property string creatingAccount: qsTr("Creating account…")

    // CreateAccountPage
    property string chooseName: qsTr("Choose name")
    property string chooseUsername: qsTr("Choose username")
    property string chooseAUsername: qsTr("Choose a username")
    property string confirmPassword: qsTr("Confirm password")
    property string chooseUsernameForAccount: qsTr("You can choose a username to help others more easily find and reach you on Jami.")
    property string chooseUsernameForRV: qsTr("Choose a name for your rendezvous point")
    property string chooseAName: qsTr("Choose a name")
    property string invalidName: qsTr("Invalid name")
    property string invalidUsername: qsTr("Invalid username")
    property string nameAlreadyTaken: qsTr("Name already taken")
    property string usernameAlreadyTaken: qsTr("Username already taken")
    property string joinJamiNoPassword: qsTr("Do you want to create a Jami account without a username?\nIf yes, only a randomly generated 40-character identifier will be assigned to the account.")
    property string usernameToolTip: qsTr("- 32 characters maximum\n- Special characters allowed: dash (-)")
    property string customizeProfileOptional: qsTr("Customize your profile (optional)")
    property string skip: qsTr("Skip")
    property string skipProfile: qsTr("Skip profile configuration")
    property string saveProfile: qsTr("Save profile")
    // Good to know
    property string goodToKnow: qsTr("Good to know")
    property string local: qsTr("Local")
    property string encrypt: qsTr("Encrypt")
    property string localAccount: qsTr("Your account will be created and stored locally.")
    property string usernameRecommened: qsTr("Choosing a username is recommended, and a chosen username CANNOT be changed later.")
    property string passwordOptional: qsTr("Encrypting your account with a password is optional, and if the password is lost it CANNOT be recovered later.")
    property string customizeOptional: qsTr("Setting a profile picture and display name is optional, and can also be changed later in the settings.")

    // CreateSIPAccountPage
    property string sipAccount: qsTr("SIP account")
    property string proxy: qsTr("Proxy")
    property string server: qsTr("Server")
    property string configureExistingSIP: qsTr("Configure existing SIP account")
    property string personalizeAccount: qsTr("Personalize account")
    property string addSip: qsTr("Add SIP account")
    property string tls: qsTr("TLS")
    property string udp: qsTr("UDP")
    property string displayName: qsTr("Display name")

    // accountSettingsPages
    property string customizeAccountDescription: qsTr("Your profile is only shared with your contacts. You can customize your profile at any time.")
    property string usernameAccountDescription: qsTr("A chosen username can help to be found more easily on Jami. If a username is not chosen, a randomly generated 40-character identifier will be assigned to this account as a username. It is more difficult to be found and reached with this identifier.")
    property string encryptAccountDescription: qsTr("Your Jami account is registered only on this device as an archive containing the keys of your account. Access to this archive can be protected with a password.")
    property string saveAccountTitle: qsTr("Backup account")
    property string saveAccountDescription: qsTr("This Jami account exists only on this device. The account will be lost if this device is lost or the application is uninstalled. It is recommended to make a backup of this account.")
    property string deleteAccountTitle: qsTr("Delete account")
    property string linkedAccountList: qsTr("List of the devices that are linked to this account:")
    property string linkedThisDevice: qsTr("This device")
    property string linkedOtherDevices: qsTr("Other linked devices")

    // CurrentAccountSettings && AdvancedSettings
    property string backupSuccessful: qsTr("Backup completed successfully.")
    property string backupFailed: qsTr("An error occurred while backing up the account.")
    property string changePasswordSuccess: qsTr("Password changed successfully.")
    property string changePasswordFailed: qsTr("An error occurred while changing the account password.")
    property string setPasswordSuccess: qsTr("Password set successfully.")
    property string setPasswordFailed: qsTr("An error occurred while setting the account password.")
    property string changePassword: qsTr("Change password")
    property string setPassword: qsTr("Encrypt account")
    property string setAPassword: qsTr("Set a password")
    property string changeCurrentPassword: qsTr("Change current password")
    property string tipBackupAccount: qsTr("Back up account to a .gz file")
    property string tipAdvancedSettingsDisplay: qsTr("Display advanced settings")
    property string tipAdvancedSettingsHide: qsTr("Hide advanced settings")
    property string advancedAccountSettings: qsTr("Advanced account settings")
    property string encryptAccount: qsTr("Encrypt account with password")
    property string customizeProfile: qsTr("Customize profile")
    property string encryptTitle: qsTr("Encrypt account with password")
    property string encryptDescription: qsTr("A Jami account is created and stored locally only on this device, as an archive containing your account keys. Access to this archive can optionally be protected with a password.")
    property string encryptWarning: qsTr("Please note that if you lose your password, it CANNOT be recovered!")
    property string enterNickname: qsTr("Enter a nickname, surname…")
    property string linkTitle: qsTr("Use this account on other devices")
    property string linkDescription: qsTr("This account is created and stored locally, if you want to use it on another device you have to link the new device to this account.")
    property string linkAnotherDevice: qsTr("Link device")

    // NameRegistrationDialog
    property string setUsername: qsTr("Set username")
    property string registeringName: qsTr("Registering name")

    // JamiUserIdentity
    property string identity: qsTr("Identity")

    // LinkedDevices
    property string tipLinkNewDevice: qsTr("Link a new device to this account")
    property string linkDevice: qsTr("Exporting account…")
    property string removeDevice: qsTr("Remove device")
    property string confirmRemoveDevice: qsTr("Do you want to unlink the selected device? To continue, enter account password and click Unlink.")
    property string yourPinIs: qsTr("Account PIN code is:")
    property string linkDeviceNetWorkError: qsTr("A network error occurred while linking the device. Please try again later.")

    // BannedContacts
    property string reinstateContact: qsTr("Unblock contact")
    property string blocked: qsTr("Blocked")
    property string blockedContacts: qsTr("Blocked contacts")

    // DeleteAccountDialog
    property string confirmDeleteAccount: qsTr("Do you want to delete this account? To continue, click Delete.")
    property string deleteAccountInfo: qsTr("If the account has not been backed up or added to another device, the account and registered username will be IRREVOCABLY LOST.")

    // DeviceItemDelegate
    property string saveNewDeviceName: qsTr("Save")
    property string editDeviceName: qsTr("Edit")
    property string deviceName: qsTr("Device name:")
    property string unlinkDevice: qsTr("Remove")
    property string deviceId: qsTr("Device Id")

    // SystemSettings
    property string system: qsTr("System")
    property string dark: qsTr("Dark")
    property string light: qsTr("Light")
    property string selectFolder: qsTr("Select a folder")
    property string enableNotifications: qsTr("Enable notifications")
    property string showNotifications: qsTr("Show notifications")
    property string keepMinimized: qsTr("Minimize on close")
    property string useNativeWindowFrame: qsTr("Use native window frame (requires restart)")
    property string tipRunStartup: qsTr("Run at system startup")
    property string runStartup: qsTr("Launch at startup")
    property string downloadFolder: qsTr("Choose download directory")
    property string includeLocalVideo: qsTr("Include local video in recording")
    property string defaultSettings: qsTr("Default settings")

    // ChatviewSettings
    property string enableTypingIndicator: qsTr("Typing indicator")
    property string enableTypingIndicatorDescription: qsTr("Send and receive typing indicators showing when messages are being typed.")
    property string enableReadReceipts: qsTr("Read receipts")
    property string enableReadReceiptsTooltip: qsTr("Send and request delivery and read receipts to be sent when messages are delivered or read.")
    property string displayHyperlinkPreviews: qsTr("Web link previews")
    property string displayHyperlinkPreviewsDescription: qsTr("Preview requires downloading content from third-party servers.")

    property string userInterfaceLanguage: qsTr("User interface language")
    property string verticalViewOpt: qsTr("Vertical view")
    property string horizontalViewOpt: qsTr("Horizontal view")

    // File transfer settings
    property string fileTransfer: qsTr("File transfer")
    property string autoAcceptFiles: qsTr("Automatically accept incoming files")
    property string acceptTransferBelow: qsTr("Accept transfer limit (MB)")
    property string acceptTransferTooltip: qsTr("MB, 0 = unlimited")

    // JamiUserIdentity settings
    property string register: qsTr("Register")
    property string incorrectPassword: qsTr("Incorrect password.")
    property string networkError: qsTr("A network error occurred.")
    property string somethingWentWrong: qsTr("An unexpected error occurred.")

    // Context Menu
    property string saveFile: qsTr("Save file")
    property string openLocation: qsTr("Open location")
    property string removeLocally: qsTr("Delete file from device")

    // Updates
    property string betaInstall: qsTr("Install beta version")
    property string checkForUpdates: qsTr("Check for updates now")
    property string enableAutoUpdates: qsTr("Enable/Disable automatic updates")
    property string updatesTitle: qsTr("Updates")
    property string updateDialogTitle: qsTr("Update")
    property string updateFound: qsTr("A new version of the Jami application is available. Do you want to update now? To continue, click Update.")
    property string updateNotFound: qsTr("The application is up to date.")
    property string updateCheckError: qsTr("An error occurred while checking for updates.")
    property string updateNetworkError: qsTr("A network error occurred while checking for updates.")
    property string updateSSLError: qsTr("An SSL error occurred.")
    property string updateDownloadCanceled: qsTr("Installer download was canceled by user.")
    property string updateDownloading: "Downloading"
    property string confirmBeta: qsTr("This will replace the Release version with the Beta version on this device. The latest Release version can always be downloaded from the Jami website.")
    property string networkDisconnected: qsTr("Network disconnected")
    property string accessError: qsTr("An error occurred while accessing the contents.")
    property string contentNotFoundError: qsTr("Content not found.")
    property string genericError: qsTr("An unexpected error occurred.")

    // Troubleshoot Settings
    property string troubleshootTitle: qsTr("Troubleshoot")
    property string troubleshootButton: qsTr("Open logs")
    property string troubleshootText: qsTr("Get logs")

    // Recording Settings
    property string quality: qsTr("Quality")
    property string saveRecordingsTo: qsTr("Save recordings to")
    property string saveScreenshotsTo: qsTr("Save screenshots to")
    property string callRecording: qsTr("Call recording")
    property string alwaysRecordCalls: qsTr("Always record calls")

    // Keyboard shortcuts
    property string keyboardShortcutTableWindowTitle: qsTr("Keyboard shortcuts")
    property string keyboardShortcuts: qsTr("Keyboard shortcuts")
    property string conversationKeyboardShortcuts: qsTr("Conversation")
    property string callKeyboardShortcuts: qsTr("Call")
    property string settings: qsTr("Settings")
    property string markdownKeyboardShortcuts: qsTr("Markdown")

    // View Logs
    property string logsViewTitle: qsTr("Debug")
    property string logsViewCopy: qsTr("Copy")
    property string logsViewReport: qsTr("Submit issue")
    property string logsViewClear: qsTr("Clear")
    property string cancel: qsTr("Cancel")
    property string logsViewCopied: qsTr("Copied to clipboard.")
    property string logsViewDisplay: qsTr("View logs")

    // ImportFromBackupPage
    property string archive: qsTr("Archive")
    property string openFile: qsTr("Open file")
    property string importAccountArchive: qsTr("Create account from backup")
    property string connectFromBackup: qsTr("Restore account from backup")
    property string generatingAccount: qsTr("Generating account…")
    property string importFromArchiveBackup: qsTr("Import from archive backup")
    property string importFromArchiveBackupDescription: qsTr("Import Jami account from local archive file.")
    property string selectArchiveFile: qsTr("Select archive file")
    property string passwordArchive: qsTr("If the account is encrypted with a password, please fill the following field.")

    // ImportFromDevicePage
    property string importButton: qsTr("Import")
    property string pin: qsTr("Enter the PIN code")

    // LinkDevicesDialog
    property string close: qsTr("Close")
    property string enterAccountPassword: qsTr("Enter account password")
    property string enterPasswordPinCode: qsTr("This account is password encrypted, enter the password to generate a PIN code.")
    property string addDevice: qsTr("Add Device")
    property string linkNewDevice: qsTr("Link new device")
    property string linkDeviceConnecting: qsTr("Connecting to the new device…")
    property string linkDeviceInProgress: qsTr("The export account operation to the new device is in progress.\nPlease confirm the import on the new device.")
    property string linkDeviceScanQR: qsTr("On the new device, initiate a new account.\nSelect Add account → Connect from another device.\nWhen ready, scan the QR code.")
    property string linkDeviceEnterManually: qsTr("Alternatively, enter the authentication code manually.")
    property string linkDeviceEnterCodePlaceholder: qsTr("Enter authentication code")
    property string linkDeviceAllSet: qsTr("The account was imported successfully.")
    property string linkDeviceFoundAddress: qsTr("New device connected at the following IP address. Is that you? To continue the export account operation, click Confirm.")
    property string linkDeviceNewDeviceIP: qsTr("New device IP address: %1")
    property string linkDeviceCloseWarningTitle: qsTr("Do you want to exit?")
    property string linkDeviceCloseWarningMessage: qsTr("Exiting will cancel the import account operation.")

    // PasswordDialog
    property string enterPassword: qsTr("Enter password")
    property string enterCurrentPassword: qsTr("Enter current password")
    property string confirmRemoval: qsTr("Enter account password to confirm the removal of this device")
    property string enterNewPassword: qsTr("Enter new password")
    property string confirmNewPassword: qsTr("Confirm new password")
    property string change: qsTr("Change")
    property string exportAccount: qsTr("Export")

    // PhotoBoothView
    property string selectProfilePicture: qsTr("Select image as profile picture")
    property string selectImage: qsTr("How do you want to set the profile picture?")
    property string importFromFile: qsTr("Import profile picture from image file")
    property string removeImage: qsTr("Remove profile picture")
    property string takePhoto: qsTr("Take photo")
    property string imageFiles: qsTr("Image files (*.jpeg *.jpg *.png *.JPEG* .JPG *.PNG)")
    property string editProfilePicture: qsTr("Edit profile picture")

    // Extensions
    property string autoUpdate: qsTr("Auto update")
    property string disableAll: qsTr("Disable all")
    property string installed: qsTr("Installed")
    property string install: qsTr("Install")
    property string installing: qsTr("Installing")
    property string installManually: qsTr("Install manually")
    property string installMannuallyDescription: qsTr("Install an extension directly from your device.")
    property string extensionStoreTitle: qsTr("Available")
    property string extensionStoreNotAvailable: qsTr("The Jami Extension Store is currently unavailable. Please try again later.")
    property string storeNotSupportedPlatform: qsTr("There are no extensions for the platform to display in the Jami Extension Store. Please try again later.")
    property string extensionPreferences: qsTr("Preferences")
    property string installationFailed: qsTr("Installation error")
    property string extensionInstallationFailed: qsTr("An error occurred while installing the extension.")
    property string reset: qsTr("Reset")
    property string uninstall: qsTr("Uninstall")
    property string resetPreferences: qsTr("Reset preferences")
    property string selectExtensionInstall: qsTr("Select extension to install")
    property string uninstallExtension: qsTr("Uninstall extension")
    property string confirmExtensionReset: qsTr("Do you want to reset the preferences for the %1 extension? To continue, click Reset.")
    property string confirmExtensionUninstall: qsTr("Do you want to uninstall the %1 extension? To continue, click Uninstall.")
    property string goBackToExtensionsList: qsTr("Go back to extensions list")
    property string selectFile: qsTr("Select file")
    property string select: qsTr("Select")
    property string chooseImageFile: qsTr("Choose image file")
    property string extensionFiles: qsTr("Extension files (*.jpl)")
    property string loadUnload: qsTr("Load/Unload")
    property string selectAnImage: qsTr("Select An Image to %1")
    property string editPreference: qsTr("Edit preference")
    property string onOff: qsTr("On/Off")
    property string chooseExtension: qsTr("Choose extension")
    property string versionExtension: qsTr("Version %1")
    property string lastUpdate: qsTr("Last update %1")
    property string by: qsTr("By %1")
    property string proposedBy: qsTr("Proposed by %1")

    // ProfilePage
    property string information: qsTr("Information")
    property string moreInformation: qsTr("More information")
    property string profile: qsTr("Profile")

    // RevokeDevicePasswordDialog
    property string confirmRemovalRequest: qsTr("Enter the account password to confirm the removal of this device")

    // SelectScreen
    property string selectScreen: qsTr("Select screen to share")
    property string selectWindow: qsTr("Select window to share")
    property string allScreens: qsTr("All screens")
    property string screens: qsTr("Screens")
    property string windows: qsTr("Windows")
    property string screen: qsTr("Screen %1")

    // UserProfile
    property string qrCode: qsTr("QR code")

    // WelcomePage
    property string linkFromAnotherDevice: qsTr("Link this device to an existing account")
    property string importAccountFromAnotherDevice: qsTr("Import from another device")
    property string importAccountFromBackup: qsTr("Import from an archive backup")
    property string advancedFeatures: qsTr("Advanced features")
    property string showAdvancedFeatures: qsTr("Show advanced features")
    property string hideAdvancedFeatures: qsTr("Hide advanced features")
    property string connectJAMSServer: qsTr("Connect to a JAMS server")
    property string createFromJAMS: qsTr("Create account from Jami Account Management Server (JAMS)")
    property string addSIPAccount: qsTr("Configure a SIP account")
    property string errorCreateAccount: qsTr("An error occurred while creating the account. Check credentials and try again.")
    property string createNewRV: qsTr("Create a rendezvous point")
    property string joinJami: qsTr("Create Jami account")
    property string createNewJamiAccount: qsTr("Create new Jami account")
    property string createNewSipAccount: qsTr("Create new SIP account")
    property string aboutJami: qsTr("About Jami")
    property string introductionJami: qsTr("Share freely and privately with Jami")
    property string alreadyHaveAccount: qsTr("I already have an account")
    property string useExistingAccount: qsTr("Use existing Jami account")
    property string welcomeToJami: qsTr("Welcome to Jami")

    // SmartList
    property string clearText: qsTr("Clear text")
    property string conversations: qsTr("Conversations")
    property string searchResults: qsTr("Search results")

    // SmartList context menu
    property string declineContactRequest: qsTr("Decline invitation")
    property string acceptContactRequest: qsTr("Accept invitation")

    // Update settings
    property string update: qsTr("Automatically check for updates")

    // Generic dialog options
    property string optionOk: qsTr("OK")
    property string optionSave: qsTr("Save")
    property string optionCancel: qsTr("Cancel")
    property string optionUpgrade: qsTr("Upgrade")
    property string optionLater: qsTr("Later")
    property string optionDelete: qsTr("Delete")
    property string optionRemove: qsTr("Remove")
    property string optionLeave: qsTr("Leave")
    property string optionBlock: qsTr("Block")
    property string optionUnblock: qsTr("Unblock")
    property string optionReset: qsTr("Reset")
    property string optionUninstall: qsTr("Uninstall")

    // Conference moderation
    property string setModerator: qsTr("Set moderator")
    property string unsetModerator: qsTr("Unset moderator")
    property string muteParticipant: qsTr("Mute participant")
    property string unmuteParticipant: qsTr("Unmute participant")
    property string maximizeParticipant: qsTr("Maximize participant")
    property string minimizeParticipant: qsTr("Minimize participant")
    property string disconnectParticipant: qsTr("Disconnect participant")
    property string localMuted: qsTr("Local muted")

    // Settings moderation
    property string defaultModerators: qsTr("Default moderators")
    property string enableLocalModerators: qsTr("Enable local moderators")
    property string enableAllModerators: qsTr("Make all participants moderators")
    property string addDefaultModerator: qsTr("Add default moderator")
    property string addModerator: qsTr("Add")
    property string removeDefaultModerator: qsTr("Remove default moderator")

    // Daemon reconnection
    property string reconnectDaemon: qsTr("Jami daemon (jamid) reconnection is in progress. Please wait…")
    property string reconnectionFailed: qsTr("An error occurred while reconnecting to the Jami daemon (jamid).\nThe application will now exit.")

    // Message view
    property string addEmoji: qsTr("Add emoji")
    property string moreEmojis: qsTr("more emojis")
    property string sendFile: qsTr("Send file")
    property string leaveAudioMessage: qsTr("Audio message")
    property string leaveVideoMessage: qsTr("Video message")
    property string discardRestart: qsTr("Discard and restart")
    property string showMore: qsTr("Show more")
    property string showLess: qsTr("Show less")

    property string showPreview: qsTr("Show preview")
    property string continueEditing: qsTr("Continue editing")
    property string bold: qsTr("Bold")
    property string italic: qsTr("Italic")
    property string strikethrough: qsTr("Strikethrough")
    property string title: qsTr("Title")
    property string heading: qsTr("Heading")
    property string link: qsTr("Link")
    property string code: qsTr("Code")
    property string quote: qsTr("Quote")
    property string unorderedList: qsTr("Unordered list")
    property string orderedList: qsTr("Ordered list")
    property string showFormatting: qsTr("Show formatting")
    property string hideFormatting: qsTr("Hide formatting")
    property string shiftEnterNewLine: qsTr("Press Shift+Enter to insert a new line")
    property string enterNewLine: qsTr("Press Enter to insert a new line")
    property string send: qsTr("Send")
    property string dontSend: qsTr("Don't send")
    property string replyTo: qsTr("Reply to")
    property string inReplyTo: qsTr("In reply to")
    property string repliedTo: qsTr("%1 replied to")
    property string inReplyToYou: qsTr("you")
    property string reply: qsTr("Reply")
    property string writeTo: qsTr("Write to %1")
    property string writeToNewContact: qsTr("Send a message to %1 in order to add them as a contact")
    property string edit: qsTr("Edit")
    property string edited: qsTr("Edited")
    property string joinCall: qsTr("Join call")
    property string joinWithAudio: qsTr("Join with audio")
    property string joinWithVideo: qsTr("Join with video")
    property string callStarted: qsTr("Call started")
    property string wantToJoin: qsTr("A call is in progress. Do you want to join the call?")
    property string needsHost: qsTr("Current host for this group conversation seems unreachable. Do you want to host the call?")
    property string selectHost: qsTr("Select dedicated device for hosting future calls in this group conversation. If not set, the host will be the device starting a call.")
    property string selectThisDevice: qsTr("Select this device")
    property string selectDevice: qsTr("Select device")
    property string removeCurrentDevice: qsTr("Remove current device")
    property string becomeHostOneCall: qsTr("Host only this call")
    property string hostThisCall: qsTr("Host this call")
    property string becomeDefaultHost: qsTr("Make me the default host for future calls")
    property string showLocalVideo: qsTr("Show local video")
    property string hideLocalVideo: qsTr("Hide local video")

    // Invitation View
    property string invitationViewSentRequest: qsTr("%1 sent you a conversation invitation.")
    property string invitationViewJoinConversation: qsTr("Hello,\nDo you want to join the conversation?")
    property string invitationViewAcceptedConversation: qsTr("You have accepted\nthe conversation invitation.")
    property string invitationViewWaitingForSync: qsTr("Waiting for %1\nto connect to synchronize the conversation…")

    // SwarmDetailsPanel (group conversation panel)
    property string members: qsTr("%L1 members")
    property string member: qsTr("Member")
    property string groupName: qsTr("Group name")
    property string contactName: qsTr("Contact name")
    property string addDescription: qsTr("Add description")
    property string groupMembers: qsTr("Members")
    property string conversationType: qsTr("Conversation type")

    property string muteConversation: qsTr("Mute conversation")
    property string unmuteConversation: qsTr("Unmute conversation")
    property string ignoreNotificationsTooltip: qsTr("Ignore all notifications from this conversation")
    property string chooseAColor: qsTr("Choose a color")
    property string color: qsTr("Color")
    property string defaultCallHost: qsTr("Default host (calls)")
    property string selectDefaultHost: qsTr("Select default host")
    property string changeDefaultHost: qsTr("Change default host")
    property string typeOfSwarm: qsTr("Conversation type")
    property string none: qsTr("None")

    // NewSwarmPage (new group conversation page)
    property string goToConversation: qsTr("Go to conversation")
    property string kickMember: qsTr("Block member")
    property string reinstateMember: qsTr("Unblock member")
    property string administrator: qsTr("Administrator")
    property string invited: qsTr("Invited")
    property string removeMember: qsTr("Remove member")
    property string to: qsTr("To:")

    // TipBox
    property string customize: qsTr("Customize")
    property string tip: qsTr("Tip")
    property string dismiss: qsTr("Dismiss")
    property string customizeText: qsTr("Add a profile picture and nickname to complete your profile")
    property string customizationDescription: qsTr("Your profile is only shared with your contacts")

    // Message options
    property string deleteMessage: qsTr("Delete message")
    property string deleteReplyMessage: qsTr("*(Deleted Message)*")
    property string editMessage: qsTr("Edit message")

    // Jami identifier
    property string hereIsIdentifier: qsTr("Share your Jami identifier in order to be contacted more easily!")
    property string jamiIdentity: qsTr("Jami identity")
    property string identifierURI: qsTr("Show fingerprint")
    property string identifierRegisterName: qsTr("Show registered name")

    // ManageAccount
    property string enableAccountDescription: qsTr("Enabling your account allows you to be contacted on Jami")

    // CreateAccount
    property string encryptWithPassword: qsTr("Encrypt your account with a password")
    property string customizeYourProfile: qsTr("Customize your profile")

    // General
    property string appearance: qsTr("Appearance")

    // System
    property string experimental: qsTr("Experimental")

    // Ringtone
    property string ringtone: qsTr("Ringtone")

    // Rdv
    property string rendezVousPoint: qsTr("Rendezvous point")

    // Moderation
    property string moderation: qsTr("Moderation")

    // Appearence
    property string theme: qsTr("Theme")
    property string zoomLevel: qsTr("Text zoom level")
    property string backgroundImage: qsTr("Background image")
    property string selectBackgroundImage: qsTr("Select background image")
    property string defaultImage: qsTr("Default")
    property string blurBackgroundImage: qsTr("Blur background image")
    property string applyOverlayBackgroundImage: qsTr("Normalize background image contrast")

    // Donation campaign
    property string donationTipBoxText: qsTr("Free and private sharing. <a href=\"https://jami.net/donate/\">Donate</a> to expand it.")
    property string donation: qsTr("Donate")
    property string donationText: qsTr("If you enjoy using Jami and believe in our mission, do you want to make a donation?")
    property string notNow: qsTr("Not now")
    property string enableDonation: qsTr("Enable donation campaign")

    // Chat setting page
    property string enter: qsTr("Enter")
    property string shiftEnter: qsTr("Shift+Enter")
    property string textFormattingDescription: qsTr("Enter or Shift+Enter to insert a new line")
    property string textFormatting: qsTr("Text formatting")

    // Connection monitoring
    property string connected: qsTr("Connected")
    property string connectingTLS: qsTr("Connecting TLS")
    property string connectingICE: qsTr("Connecting ICE")
    property string connecting: qsTr("Connecting")
    property string waiting: qsTr("Waiting")
    property string contact: qsTr("Contact")
    property string connection: qsTr("Connection")
    property string channels: qsTr("Channels")
    property string copyAllData: qsTr("Copy all data")
    property string remote: qsTr("Remote: %1")
    property string view: qsTr("View")

    // Spell checker
    property string checkSpelling: qsTr("Check spelling while typing")
    property string systemDictionary: qsTr("System")
    property string textLanguage: qsTr("Text language")
    property string spellChecker: qsTr("Spell checker")
    property string searchTextLanguages: qsTr("Search text languages")
    property string searchAvailableTextLanguages: qsTr("Search for available text languages")
    property string noDictionariesFoundFor: qsTr("No dictionary found for %1.")
    property string noDictionariesAvailable: qsTr("No dictionary is available.")
    property string dictionaryManager: qsTr("Dictionary manager")
    property string spellCheckDownloadFailed: qsTr("An error occurred while downloading the %1 dictionary.")
    property string showInstalledDictionaries: qsTr("Show installed dictionaries")
    property string showInstalledDictionariesDescription: qsTr("Only show dictionaries that are currently installed")

    // Search bar
    property string searchOrAdd: qsTr("Search/add")

    // Files
    property string noFilesInConversation: qsTr("This conversation has no files.")

    // Share message menu
    property string addAComment: qsTr("Add a comment")
    property string shareWith: qsTr("Share with...")

    // Side panel
    property string addAContact: qsTr("Add a contact")
    property string noConversations: qsTr("It's a ghost town here!")
    property string noContactsToChooseFrom: qsTr("No contacts to choose from!")

    // Accessibility
    property string switchToAccount: qsTr("Press enter to switch to this account")
    property string qrCodeExplanation: qsTr("Display your QR code to allow other users to scan it and add you as a contact")
    property string accountList: qsTr("Account list")
    property string accountListDescription: qsTr("Use arrows to switch between available account")
    property string languageComboBoxExplanation: qsTr("Select the user interface language")
    property string backButtonExplanation: qsTr("Go back to the previous page")
    property string adviceBox: qsTr("Advice Box")
    property string backButton: qsTr("Back button")
    property string adviceBoxExplanation: qsTr("Open the advice popup that contains information about Jami")
    property string more: qsTr("More")
    property string pressToAction: qsTr("Press to %1")
    property string pressToToggle: qsTr("Press to toggle %1 (%2)")
    property string active: qsTr("active")
    property string inactive: qsTr("inactive")
    property string minimize: qsTr("Minimize application")
    property string maximize: qsTr("Maximize application")
    property string closeApplication: qsTr("Close application")
    property string dismissTip: qsTr("Dismiss this tip")
    property string tipDescription: qsTr("Tips to help you use Jami more effectively")
    property string showMoreMessagingOptions: qsTr("Show more messaging options")
    property string showMoreMessagingOptionsDescription: qsTr("Open a menu that allows you to send voice and video messages as well as sharing your location")
    property string conversationMessages: qsTr("Conversation messages list. Use arrow keys to navigate through messages.")
    property string dataTransfer: qsTr("Data transfer")
    property string status: qsTr("Status")
    property string readBy: qsTr("Read by")
    property string selectedDescription: qsTr("Currently selected: %1")
    property string hasBeenSelectedDescription: qsTr("%1 has been selected for %2")
    property string availableOptionDescription: qsTr("Available option for %1")
}
