/*
 * Copyright (C) 2020-2022 Savoir-faire Linux Inc.
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

// JamiStrings as a singleton is to provide global strings entries.
pragma Singleton

import QtQuick

import net.jami.Helpers 1.1

Item {
    readonly property string appTitle: "Jami"
    readonly property string httpUserAgentName: "jami"

    // Misc
    property string accept: qsTr("Accept")
    property string acceptAudio: qsTr("Accept in audio")
    property string acceptVideo: qsTr("Accept in video")
    property string refuse: qsTr("Refuse")
    property string endCall: qsTr("End call")
    property string incomingAudioCallFrom: qsTr("Incoming audio call from {}")
    property string incomingVideoCallFrom: qsTr("Incoming video call from {}")
    property string contactSearchConversation: qsTr("Find users and conversations")
    property string startSwarm: qsTr("Start swarm")
    property string createSwarm: qsTr("Create swarm")
    property string showInvitations: qsTr("Show invitations")
    property string invitations: qsTr("Invitations")
    property string description: qsTr("Jami is a universal communication platform, with privacy as its foundation, that relies on a free distributed network for everyone.")
    property string updateToSwarm: qsTr("Migrating to the Swarm technology will enable synchronizing this conversation across multiple devices and improve reliability. The legacy conversation history will be cleared in the process.")
    property string migrateConversation: qsTr("Migrate conversation")

    // DaemonReconnectWindow
    property string reconnectWarn: qsTr("Could not re-connect to the Jami daemon (jamid).\nJami will now quit.")
    property string reconnectTry: qsTr("Trying to reconnect to the Jami daemon (jamid)…")

    // AboutPopUp
    property string version: qsTr("Version") + (UpdateManager.isCurrentVersionBeta() ? " (Beta)" : "")
    property string companyDeclarationYear: declarationYear + " " + companyName
    property string declarationYear: "© 2015-2022"
    property string companyName: "Savoir-faire Linux Inc."
    property string slogan: "Taranis"
    property string declaration: qsTr("Jami is a free universal communication software that respects the freedom and privacy of its users.")
    property string credits: qsTr("Credits")

    // AccountComboBox
    property string displayQRCode: qsTr("Display QR code")
    property string openSettings: qsTr("Open settings")
    property string closeSettings: qsTr("Close settings")
    property string addAccount: qsTr("Add Account")

    // ContactPicker
    property string addToConference: qsTr("Add to conference")
    property string addToConversation: qsTr("Add to conversation")
    property string transferThisCall: qsTr("Transfer this call")
    property string transferTo: qsTr("Transfer to")

    // AccountMigrationDialog
    property string authenticationRequired: qsTr("Authentication required")
    property string migrationReason: qsTr("Your session has expired or been revoked on this device. Please enter your password.")
    property string jamsServer: qsTr("JAMS server")
    property string authenticate: qsTr("Authenticate")
    property string deleteAccount: qsTr("Delete account")
    property string inProgress: qsTr("In progress…")
    property string authenticationFailed: qsTr("Authentication failed")
    property string password: qsTr("Password")
    property string username: qsTr("Username")
    property string alias: qsTr("Alias")

    // AdvancedCallSettings
    property string callSettings: qsTr("Call Settings")
    property string allowCallsUnknownContacs: qsTr("Allow incoming calls from unknown contacts")
    property string rendezVous: qsTr("Convert your account into a rendezvous point")
    property string autoAnswerCalls: qsTr("Automatically answer calls")
    property string enableCustomRingtone: qsTr("Enable custom ringtone")
    property string selectCustomRingtone: qsTr("Select custom ringtone")
    property string addCustomRingtone: qsTr("Add a custom ringtone")
    property string selectNewRingtone: qsTr("Select a new ringtone")
    property string certificateFile: qsTr("Certificate File (*.crt)")
    property string audioFile: qsTr("Audio File (*.wav *.ogg *.opus *.mp3 *.aiff *.wma)")

    // AdvancedChatSettings
    property string chatSettings: qsTr("Chat Settings")
    property string enableReadReceipts: qsTr("Enable read receipts")
    property string enableReadReceiptsTooltip: qsTr("Send and receive receipts indicating that a message have been displayed")

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
    property string selectUserCert: qsTr("Select a user certificate")
    property string selectCACert: qsTr("Select a CA certificate")
    property string keyFile: qsTr("Key File (*.key)")

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
    property string turnRealm: qsTr("TURN Realm")
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
    property string videoCodecs: qsTr("Video Codecs")
    property string audioCodecs: qsTr("Audio Codecs")

    // AdvancedNameServerSettings
    property string nameServer: qsTr("Name Server")

    // AdvancedSDPSettings
    property string sdpSettingsTitle: qsTr("SDP Session Negotiation (ICE Fallback)")
    property string sdpSettingsSubtitle: qsTr("Only used during negotiation in case ICE is not supported")
    property string audioRTPMinPort: qsTr("Audio RTP minimum Port")
    property string audioRTPMaxPort: qsTr("Audio RTP maximum Port")
    property string videoRTPMinPort: qsTr("Video RTP minimum Port")
    property string videoRTPMaxPort: qsTr("Video RTP maximum port")

    // AdvancedOpenDHTSettings
    property string enablePeerDiscovery: qsTr("Enable local peer discovery")
    property string tooltipPeerDiscovery: qsTr("Connect to other DHT nodes advertising on your local network.")
    property string openDHTConfig: qsTr("OpenDHT Configuration")
    property string enableProxy: qsTr("Enable proxy")
    property string proxyAddress: qsTr("Proxy address")
    property string bootstrap: qsTr("Bootstrap")

    // SettingsHeader
    property string back: qsTr("Back")
    property string accountSettingsTitle: qsTr("Account Settings")
    property string accountSettingsMenuTitle: qsTr("Account")
    property string generalSettingsTitle: qsTr("General")
    property string pluginSettingsTitle: qsTr("Plugin")
    property string avSettingsTitle: qsTr("Audio and Video Settings")
    property string avSettingsMenuTitle: qsTr("Audio/Video")

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
    property string fps: qsTr("Frames per second")
    property string selectFPS: qsTr("Select video frame rate (frames per second)")
    property string enableHWAccel: qsTr("Enable hardware acceleration")
    property string previewUnavailable: qsTr("Preview unavailable")
    property string screenSharing: qsTr("Screen Sharing")
    property string selectScreenSharingFPS: qsTr("Select screen sharing frame rate (frames per second)")
    property string noVideo: qsTr("no video")

    // BackupKeyPage
    property string whyBackupAccount: qsTr("Why should I back-up this account?")
    property string  backupAccountInfos: qsTr("Your account only exists on this device. " +
                                              "If you lose your device or uninstall the application, " +
                                              "your account will be deleted and CANNOT be recovered. " +
                                              "You can back up your account now or later (in the Account Settings).")
    property string backupAccountHere: qsTr("Back up account here")
    property string backupAccountBtn: qsTr("Back up account")
    property string skip: qsTr("Skip")
    property string success: qsTr("Success")
    property string error: qsTr("Error")
    property string neverShowAgain: qsTr("Never show me this again")
    property string recommended: qsTr("Recommended")
    property string jamiArchiveFiles: qsTr("Jami archive files (*.gz)")
    property string allFiles: qsTr("All files (*)")

    // BannedItemDelegate
    property string reinstateContact: qsTr("Reinstate as contact")
    property string name: qsTr("name")
    property string identifier: qsTr("Identifier")

    // CallOverlay
    property string isRecording: qsTr("is recording")
    property string areRecording: qsTr("are recording")
    property string peerStoppedRecording: qsTr("Peer stopped recording")
    property string isCallingYou: qsTr("is calling you")
    property string mute: qsTr("Mute")
    property string unmute: qsTr("Unmute")
    property string hangup: qsTr("End call")
    property string pauseCall: qsTr("Pause call")
    property string resumeCall: qsTr("Resume call")
    property string muteCamera: qsTr("Mute camera")
    property string unmuteCamera: qsTr("Unmute camera")
    property string addParticipant: qsTr("Add participant")
    property string addParticipants: qsTr("Add participants")
    property string details: qsTr("Details")
    property string chat: qsTr("Chat")
    property string moreOptions: qsTr("More options")
    property string mosaic: qsTr("Mosaic")
    property string participantMicIsStillMuted: qsTr("Participant is still muted on their device")
    property string mutedLocally: qsTr("You are still muted on your device")
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
    property string hideAudioOnly: qsTr("Hide audio-only participants")

    // LineEditContextMenu
    property string copy: qsTr("Copy")
    property string share: qsTr("Share")
    property string cut: qsTr("Cut")
    property string paste: qsTr("Paste")

    // ConversationContextMenu
    property string startVideoCall: qsTr("Start video call")
    property string startAudioCall: qsTr("Start audio call")
    property string clearConversation: qsTr("Clear conversation")
    property string confirmAction: qsTr("Confirm action")
    property string removeConversation: qsTr("Remove conversation")
    property string confirmRmConversation: qsTr("Would you really like to remove this conversation?")
    property string confirmBlockConversation: qsTr("Would you really like to block this conversation?")
    property string removeContact: qsTr("Remove contact")
    property string blockContact: qsTr("Block contact")
    property string blockSwarm: qsTr("Block swarm")
    property string convDetails: qsTr("Conversation details")

    // CallViewContextMenu
    property string hold: qsTr("Hold")
    property string sipInputPanel: qsTr("Sip input panel")
    property string transferCall: qsTr("Transfer call")
    property string stopRec: qsTr("Stop recording")
    property string startRec: qsTr("Start recording")
    property string exitFullScreen: qsTr("Exit full screen")
    property string viewFullScreen: qsTr("View full screen")
    property string shareScreen: qsTr("Share screen")
    property string shareWindow: qsTr("Share window")
    property string stopSharing: qsTr("Stop sharing screen or file")
    property string shareScreenArea: qsTr("Share screen area")
    property string shareFile: qsTr("Share file")
    property string selectShareMethod: qsTr("Select sharing method")
    property string viewPlugin: qsTr("View plugin")
    property string noVideoDevice: qsTr("No video device")
    property string notAvailable: qsTr("Unavailable")
    property string lowerHand: qsTr("Lower hand")
    property string raiseHand: qsTr("Raise hand")
    property string layoutSettings: qsTr("Layout settings")

    // Chatview header
    property string hideChat: qsTr("Hide chat")
    property string placeAudioCall: qsTr("Place audio call")
    property string placeVideoCall: qsTr("Place video call")
    property string showPlugins: qsTr("Show available plugins")
    property string addToConversations: qsTr("Add to conversations")
    property string backendError: qsTr("This is the error from the backend: %0")

    // Chatview footer
    property string jumpToLatest: qsTr("Jump to latest")
    property string typeIndicatorSingle: qsTr("{} is typing…")
    property string typeIndicatorPlural: qsTr("{} are typing…")
    property string typeIndicatorMax: qsTr("Several people are typing…")
    property string typeIndicatorAnd: qsTr(" and ")

    // ConnectToAccountManager
    property string enterJAMSURL: qsTr("Enter the Jami Account Management Server (JAMS) URL")
    property string required: qsTr("Required")
    property string jamiManagementServerURL: qsTr("Jami Account Management Server URL")
    property string jamsCredentials: qsTr("Enter JAMS credentials")
    property string connect: qsTr("Connect")
    property string creatingAccount: qsTr("Creating account…")
    property string backToWelcome: qsTr("Back to welcome page")

    // CreateAccountPage
    property string chooseName: qsTr("Choose name")
    property string chooseUsername: qsTr("Choose username")
    property string chooseAUsername: qsTr("Choose a username")
    property string chooseIdentifier: qsTr("Choose an identifier")
    property string identifierNotAvailable: qsTr("The identifier is not available")
    property string createPassword: qsTr("Encrypt account with password")
    property string createAccount: qsTr("Create account")
    property string confirmPassword: qsTr("Confirm password")
    property string notePasswordRecovery: qsTr("Choose a password to encrypt your account on this device. Note that the password CANNOT be recovered.")
    property string optional: qsTr("Optional")
    property string chooseUsernameForAccount: qsTr("You can choose a username to help others more easily find and reach you on Jami.")
    property string chooseUsernameForRV: qsTr("Choose a name for your rendezvous point")
    property string chooseAName: qsTr("Choose a name")
    property string chooseYourUserName: qsTr("Choose username")
    property string invalidName: qsTr("Invalid name")
    property string invalidUsername: qsTr("Invalid username")
    property string nameAlreadyTaken: qsTr("Name already taken")
    property string usernameAlreadyTaken: qsTr("Username already taken")
    property string joinJamiNoPassword: qsTr("Are you sure you would like to join Jami without a username?\nIf yes, only a randomly generated 40-character identifier will be assigned to this account.")
    property string usernameToolTip: qsTr("- 32 characters maximum\n- Alphabetical characters (A to Z and a to z)\n- Numeric characters (0 to 9)\n- Special characters allowed: dash (-)")

    // Good to know

    property string goodToKnow: qsTr("Good to know")
    property string local: qsTr("Local")
    property string encrypt: qsTr("Encrypt")
    property string localAccount: qsTr("Your account will be created and stored locally.")
    property string usernameRecommened: qsTr("Choosing a username is recommended, and a chosen username CANNOT be changed later.")
    property string passwordOptional: qsTr("Encrypting your account with a password is optional, and if the password is lost it CANNOT be recovered later.")
    property string customizeOptional: qsTr("Setting a profile picture and nickname is optional, and can also be changed later in the settings.")


    // CreateSIPAccountPage
    property string sipAccount: qsTr("SIP account")
    property string proxy: qsTr("Proxy")
    property string server: qsTr("Server")
    property string createSIPAccount: qsTr("Create SIP account")
    property string configureExistingSIP: qsTr("Configure an existing SIP account")
    property string personalizeAccount: qsTr("Personalize account")
    property string addSip: qsTr("Add SIP account")

    // CurrentAccountSettings && AdvancedSettings
    property string backupSuccessful: qsTr("Backup successful")
    property string backupFailed: qsTr("Backup failed")
    property string changePasswordSuccess: qsTr("Password changed successfully")
    property string changePasswordFailed: qsTr("Password change failed")
    property string setPasswordSuccess: qsTr("Password set successfully")
    property string setPasswordFailed: qsTr("Password set failed")
    property string changePassword: qsTr("Change password")
    property string setPassword: qsTr("Set password")
    property string setAPassword: qsTr("Set a password")
    property string changeCurrentPassword: qsTr("Change current password")
    property string tipBackupAccount: qsTr("Back up account to a .gz file")
    property string tipAdvancedSettingsDisplay: qsTr("Display advanced settings")
    property string tipAdvancedSettingsHide: qsTr("Hide advanced settings")
    property string enableAccount: qsTr("Enable account")
    property string advancedAccountSettings: qsTr("Advanced account settings")
    property string encryptAccount: qsTr("Encrypt account with password")
    property string customizeProfile: qsTr("Customize profile")
    property string customizeProfileDescription: qsTr("This profile is only shared with this account's contacts.\nThe profile can be changed at all times from the account's settings.")
    property string encryptTitle: qsTr("Encrypt your account with a password")
    property string encryptDescription: qsTr("A Jami account is created and stored locally only on this device, as an archive containing your account keys. Access to this archive can optionally be protected by a password.")
    property string encryptWarning: qsTr("Please note that if you lose your password, it CANNOT be recovered!")
    property string enterNickname: qsTr("Enter a nickname, surname...")

    // NameRegistrationDialog
    property string setUsername: qsTr("Set username")
    property string registeringName: qsTr("Registering name")

    // JamiUserIdentity
    property string registerAUsername: qsTr("Register a username")
    property string registerUsername: qsTr("Register username")
    property string identity: qsTr("Identity")

    // LinkedDevices
    property string tipLinkNewDevice: qsTr("Link a new device to this account")
    property string linkAnotherDevice: qsTr("Link another device")
    property string linkNewDevice: qsTr("Exporting account…")
    property string removeDevice: qsTr("Remove Device")
    property string sureToRemoveDevice: qsTr("Are you sure you wish to remove this device?")
    property string linkedDevices: qsTr("Linked Devices")
    property string yourPinIs: qsTr("Your PIN is:")
    property string linkDeviceNetWorkError: qsTr("Error connecting to the network.\nPlease try again later.")

    // BannedContacts
    property string tipBannedContactsDisplay: qsTr("Display banned contacts")
    property string banned: qsTr("Banned")
    property string tipBannedContactsHide: qsTr("Hide banned contacts")
    property string bannedContacts: qsTr("Banned contacts")

    // DeleteAccountDialog
    property string confirmDeleteQuestion: qsTr("Would you really like to delete this account?")
    property string deleteAccountInfos: qsTr("If your account has not been backed up or added to another device, your account and registered username will be IRREVOCABLY LOST.")

    // DeviceItemDelegate
    property string saveNewDeviceName: qsTr("Save new device name")
    property string editDeviceName: qsTr("Edit device name")
    property string unlinkDevice: qsTr("Unlink device from account")
    property string deviceId: qsTr("Device Id")

    // SystemSettings
    property string system: qsTr("System")
    property string dark: qsTr("Dark")
    property string light: qsTr("Light")
    property string selectFolder: qsTr("Select a folder")
    property string enableNotifications: qsTr("Enable notifications")
    property string applicationTheme: qsTr("Application theme")
    property string showNotifications: qsTr("Show notifications")
    property string keepMinimized: qsTr("Minimize on close")
    property string tipRunStartup: qsTr("Run at system startup")
    property string runStartup: qsTr("Launch at startup")
    property string downloadFolder: qsTr("Download directory")
    property string tipChooseDownloadFolder: qsTr("Choose download directory")
    property string recordCall: qsTr("Record call")
    property string textZoom: qsTr("Text zoom")
    property string changeTextSize: qsTr("Change text size (%)")

    // ChatviewSettings
    property string enableTypingIndicator: qsTr("Typing indicators")
    property string displayHyperlinkPreviews: qsTr("Show link previews")
    property string layout: qsTr("Layout")
    property string language: qsTr("User interface language")
    property string verticalViewOpt: qsTr("Vertical view")
    property string horizontalViewOpt: qsTr("Horizontal view")

    // File transfer settings
    property string fileTransfer: qsTr("File transfer")
    property string autoAcceptFiles: qsTr("Automatically accept incoming files")
    property string acceptTransferBelow: qsTr("Accept transfer limit")
    property string acceptTransferTooltip: qsTr("in MB, 0 = unlimited")

    // JamiUserIdentity settings
    property string register: qsTr("Register")
    property string incorrectPassword: qsTr("Incorrect password")
    property string networkError: qsTr("Network error")
    property string somethingWentWrong: qsTr("Something went wrong")

    // Context Menu
    property string saveFile: qsTr("Save file")
    property string openLocation: qsTr("Open location")

    // Updates
    property string betaInstall: qsTr("Install beta version")
    property string checkForUpdates: qsTr("Check for updates now")
    property string enableAutoUpdates: qsTr("Enable/Disable automatic updates")
    property string tipAutoUpdate: qsTr("toggle automatic updates")
    property string updatesTitle: qsTr("Updates")
    property string updateDialogTitle: qsTr("Update")
    property string updateFound: qsTr("A new version of Jami was found\n Would you like to update now?")
    property string updateNotFound: qsTr("No new version of Jami was found")
    property string updateCheckError: qsTr("An error occured when checking for a new version")
    property string updateNetworkError: qsTr("Network error")
    property string updateSSLError: qsTr("SSL error")
    property string updateDownloadCanceled: qsTr("Installer download canceled")
    property string updateDownloading: "Downloading"
    property string confirmBeta: qsTr("This will uninstall your current Release version and you can always download the latest Release version on our website")
    property string networkDisconnected: qsTr("Network disconnected")
    property string genericError: qsTr("Something went wrong")

    //Troubleshoot Settings
    property string troubleshootTitle: qsTr("Troubleshoot")
    property string troubleshootButton: qsTr("Open logs")
    property string troubleshootText: qsTr("Get logs")
    property string experimentalSwarm: qsTr("(Experimental) Enable small groups support for Swarm")
    property string experimentalSwarmTooltip: qsTr("This feature is in development.")

    // Recording Settings
    property string tipRecordFolder: qsTr("Select a record directory")
    property string quality: qsTr("Quality")
    property string saveIn: qsTr("Save in")
    property string callRecording: qsTr("Call Recording")
    property string alwaysRecordCalls: qsTr("Always record calls")

    // KeyboardShortCutTable
    property string keyboardShortcutTableWindowTitle: qsTr("Keyboard Shortcut Table")
    property string keyboardShortcuts: qsTr("Keyboard Shortcuts")
    property string generalKeyboardShortcuts: qsTr("General")
    property string conversationKeyboardShortcuts: qsTr("Conversation")
    property string callKeyboardShortcuts: qsTr("Call")
    property string settingsKeyboardShortcuts: qsTr("Settings")
    property string openAccountList: qsTr("Open account list")
    property string focusConversationsList: qsTr("Focus conversations list")
    property string requestsList: qsTr("Requests list")
    property string previousConversation: qsTr("Previous conversation")
    property string nextConversation: qsTr("Next conversation")
    property string searchBar: qsTr("Search bar")
    property string fullScreen: qsTr("Full screen")
    property string clearHistory: qsTr("Clear history")
    property string mediaSettings: qsTr("Media settings")
    property string generalSettings: qsTr("General settings")
    property string accountSettings: qsTr("Account settings")
    property string pluginSettings: qsTr("Plugin settings")
    property string answerIncoming: qsTr("Answer an incoming call")
    property string declineCallRequest: qsTr("Decline the call request")
    property string openAccountCreationWizard: qsTr("Open account creation wizard")
    property string openKeyboardShortcutTable: qsTr("Open keyboard shortcut table")

    // View Logs
    property string logsViewTitle: qsTr("Debug")
    property string logsViewShowStats: qsTr("Show Stats")
    property string logsViewStart: qsTr("Start")
    property string logsViewStop: qsTr("Stop")
    property string logsViewCopy: qsTr("Copy")
    property string logsViewReport: qsTr("Report Bug")
    property string logsViewClear: qsTr("Clear")
    property string cancel: qsTr("Cancel")
    property string logsViewCopied: qsTr("Copied to clipboard!")
    property string logsViewDisplay: qsTr("Receive Logs")

    // ImportFromBackupPage
    property string archive: qsTr("Archive")
    property string openFile: qsTr("Open file")
    property string importAccountArchive: qsTr("Create account from backup")
    property string importAccountExplanation: qsTr("You can obtain an archive by clicking on \"Back up account\" " +
                                                   "in the Account Settings. " +
                                                   "This will create a .gz file on your device.")
    property string connectFromBackup: qsTr("Restore account from backup")
    property string generatingAccount: qsTr("Generating account…")
    property string importFromBackup: qsTr("Import from backup")
    property string importFromArchiveBackup: qsTr("Import from archive backup")
    property string importFromArchiveBackupDescription: qsTr("Import Jami account from local archive file.")
    property string selectArchiveFile: qsTr("Select archive file")

    // ImportFromDevicePage
    property string mainAccountPassword: qsTr("Enter Jami account password")
    property string enterPIN: qsTr("Enter the PIN from another configured Jami account. " +
                                   "Use the \"Link Another Device\" feature to obtain a PIN.")
    property string connectFromAnotherDevice: qsTr("Link device")
    property string importButton: qsTr("Import")
    property string pin: qsTr("PIN")
    property string importFromDeviceDescription: qsTr("A PIN is required to use an existing Jami account on this device.")
    property string importStep1: qsTr("Step 1")
    property string importStep2: qsTr("Step 2")
    property string importStep3: qsTr("Step 3")
    property string importStep4: qsTr("Step 4")
    property string importStep1Desc: qsTr("Go to the Account Settings of a previous device")
    property string importStep2Desc: qsTr("Choose the account to link")
    property string importStep3Desc: qsTr("Select \"Link another device\"")
    property string importStep4Desc: qsTr("The PIN code will be valid for 10 minutes.")


    // LinkDevicesDialog
    property string pinTimerInfos: qsTr("The PIN and the account password should be entered in your device within 10 minutes.")
    property string close: qsTr("Close")
    property string enterAccountPassword: qsTr("Enter account's password")
    property string addDevice: qsTr("Add Device")

    // PasswordDialog
    property string enterPassword: qsTr("Enter the password")
    property string enterCurrentPassword: qsTr("Enter current password")
    property string confirmRemoval: qsTr("Enter this account's password to confirm the removal of this device")
    property string enterNewPassword: qsTr("Enter new password")
    property string confirmNewPassword: qsTr("Confirm new password")
    property string change: qsTr("Change")
    property string confirm: qsTr("Confirm")
    property string exportAccount: qsTr("Export")

    // PhotoBoothView
    property string chooseAvatarImage: qsTr("Choose a picture as your avatar")
    property string importFromFile: qsTr("Import avatar from image file")
    property string stopTakingPhoto: qsTr("Stop taking photo")
    property string clearAvatar: qsTr("Clear avatar image")
    property string takePhoto: qsTr("Take photo")
    property string imageFiles: qsTr("Image Files (*.png *.jpg *.jpeg *.JPG *.JPEG *.PNG)")

    // Plugins
    property string enable: qsTr("Enable")
    property string pluginPreferences: qsTr("Preferences")
    property string reset: qsTr("Reset")
    property string uninstall: qsTr("Uninstall")
    property string resetPreferences: qsTr("Reset Preferences")
    property string selectPluginInstall: qsTr("Select a plugin to install")
    property string installPlugin: qsTr("Install plugin")
    property string uninstallPlugin: qsTr("Uninstall plugin")
    property string pluginResetConfirmation: qsTr("Are you sure you wish to reset %1 preferences?")
    property string pluginUninstallConfirmation: qsTr("Are you sure you wish to uninstall %1?")
    property string showHidePrefs: qsTr("Display or hide preferences")
    property string addNewPlugin: qsTr("Add new plugin")
    property string goBackToPluginsList: qsTr("Go back to plugins list")
    property string selectFile: qsTr("Select a file")
    property string select: qsTr("Select")
    property string chooseImageFile: qsTr("Choose image file")
    property string tipGeneralPluginSettingsDisplay: qsTr("Display or hide General plugin settings")
    property string tipAccountPluginSettingsDisplay: qsTr("Display or hide Account plugin settings")
    property string installedPlugins: qsTr("Installed plugins")
    property string pluginFiles: qsTr("Plugin Files (*.jpl)")
    property string loadUnload: qsTr("Load/Unload")
    property string selectAnImage: qsTr("Select An Image to %1")
    property string editPreference: qsTr("Edit preference")
    property string onOff: qsTr("On/Off")
    property string choosePlugin: qsTr("Choose Plugin")

    // ProfilePage
    property string profileSharedWithContacts: qsTr("Profile is only shared with contacts")
    property string saveProfile: qsTr("Save profile")
    property string enterYourName: qsTr("Enter your name")
    property string enterRVName: qsTr("Enter the rendezvous point's name")
    property string generatingRV: qsTr("Creating rendezvous point…")
    property string information: qsTr("Information")
    property string profile: qsTr("Profile")

    // RevokeDevicePasswordDialog
    property string confirmRemovalRequest: qsTr("Enter the account password to confirm the removal of this device")

    // SelectScreen
    property string selectScreen: qsTr("Select a screen to share")
    property string selectWindow: qsTr("Select a window to share")
    property string allScreens: qsTr("All Screens")
    property string screens: qsTr("Screens")
    property string windows: qsTr("Windows")
    property string screen: qsTr("Screen %1")

    // UserProfile
    property string qrCode: qsTr("QR code")

    // Account QR
    property string accountQr: qsTr("Account QR")

    // WelcomePage
    property string shareInvite: qsTr("This is your Jami username.\nCopy and share it with your friends!")
    property string linkFromAnotherDevice: qsTr("Link this device to an existing account")
    property string importAccountFromAnotherDevice: qsTr("Import from another device")
    property string importAccountFromBackup: qsTr("Import from an archive backup")
    property string advancedFeatures: qsTr("Advanced features")
    property string showAdvancedFeatures: qsTr("Show advanced features")
    property string hideAdvancedFeatures: qsTr("Hide advanced features")
    property string connectJAMSServer: qsTr("Connect to a JAMS server")
    property string createFromJAMS: qsTr("Create account from Jami Account Management Server (JAMS)")
    property string addSIPAccount: qsTr("Configure a SIP account")
    property string errorCreateAccount: qsTr("Error while creating your account. Check your credentials.")
    property string createNewRV: qsTr("Create a rendezvous point")
    property string createAJamiAccount: qsTr("Create a Jami account")
    property string joinJami: qsTr("Join Jami")
    property string createNewJamiAccount: qsTr("Create new Jami account")
    property string createNewSipAccount: qsTr("Create new SIP account")
    property string aboutJami: qsTr("About Jami")
    property string welcomeTo: qsTr("Welcome to")
    property string introductionJami: qsTr("Share freely and privately with Jami")
    property string alreadyHaveAccount: qsTr("I already have an account")
    property string useExistingAccount: qsTr("Use existing Jami account")
    property string welcomeToJami: qsTr("Welcome to Jami")
    property string identifierDescription: qsTr("Share this Jami identifier to be contacted on this account!")
    property string hereIsIdentifier: qsTr("Here is your Jami identifier, don't hesitate to share it in order to be contacted more easily!")

    // SmartList
    property string clearText: qsTr("Clear Text")
    property string conversations: qsTr("Conversations")
    property string searchResults: qsTr("Search Results")

    // SmartList context menu
    property string declineContactRequest: qsTr("Decline contact request")
    property string acceptContactRequest: qsTr("Accept contact request")

    // Update settings
    property string update: qsTr("Automatically check for updates")

    // Generic dialog options
    property string optionOk: qsTr("Ok")
    property string optionSave: qsTr("Save")
    property string optionCancel: qsTr("Cancel")
    property string optionUpgrade: qsTr("Upgrade")
    property string optionLater: qsTr("Later")
    property string optionDelete: qsTr("Delete")
    property string optionRemove: qsTr("Remove")
    property string optionBlock: qsTr("Block")

    // Conference moderation
    property string setModerator: qsTr("Set moderator")
    property string unsetModerator: qsTr("Unset moderator")
    property string muteParticipant: qsTr("Mute")
    property string unmuteParticipant: qsTr("Unmute")
    property string maximizeParticipant: qsTr("Maximize")
    property string minimizeParticipant: qsTr("Minimize")
    property string hangupParticipant: qsTr("Hangup")
    property string localMuted: qsTr("Local muted")

    // Settings moderation
    property string conferenceModeration: qsTr("Conference moderation")
    property string defaultModerators: qsTr("Default moderators")
    property string enableLocalModerators: qsTr("Enable local moderators")
    property string enableAllModerators: qsTr("Make all participants moderators")
    property string addDefaultModerator: qsTr("Add default moderator")
    property string removeDefaultModerator: qsTr("Remove default moderator")

    // Daemon reconnection
    property string reconnectDaemon: qsTr("Trying to reconnect to the Jami daemon (jamid)…")
    property string reconnectionFailed: qsTr("Could not re-connect to the Jami daemon (jamid).\nJami will now quit.")

    // Is Swarm
    property string isSwarm: qsTr("Is swarm:")
    property string trueStr: qsTr("True")
    property string falseStr: qsTr("False")

    // Message view
    property string addEmoji: qsTr("Add emoji")
    property string sendFile: qsTr("Send file")
    property string leaveAudioMessage: qsTr("Leave audio message")
    property string leaveVideoMessage: qsTr("Leave video message")
    property string send: qsTr("Send")
    property string remove: qsTr("Remove")
    property string replyTo: qsTr("Reply to")
    property string inReplyTo: qsTr("In reply to")
    property string reply: qsTr("Reply")
    property string writeTo: qsTr("Write to %1")
    property string joinCall: qsTr("Join call")
    property string wantToJoin: qsTr("A call is in progress. Do you want to join the call?")
    property string needsHoster: qsTr("Current host for this swarm seems unreachable. Do you want to host the call?")
    property string chooseHoster: qsTr("Choose a dedicated device for hosting future calls in this swarm. If not set, the device starting a call will host it.")
    property string chooseThisDevice: qsTr("Choose this device")
    property string becomeHostOneCall: qsTr("Host only this call")
    property string hostThisCall: qsTr("Host this call")
    property string becomeDefaultHost: qsTr("Make me the default host for future calls")

    // Invitation View
    property string invitationViewSentRequest: qsTr("%1 has sent you a request for a conversation.")
    property string invitationViewJoinConversation: qsTr("Hello,\nWould you like to join the conversation?")
    property string invitationViewAcceptedConversation: qsTr("You have accepted\nthe conversation request")
    property string invitationViewWaitingForSync: qsTr("Waiting until %1\nconnects to synchronize the conversation.")

    // SwarmDetailsPanel
    property string about: qsTr("About")
    property string members: qsTr("%1 Members")
    property string member: qsTr("Member")
    property string documents: qsTr("Documents")
    property string swarmName: qsTr("Swarm's name")
    property string addADescription: qsTr("Add a description")

    property string muteConversation: qsTr("Mute conversation")
    property string ignoreNotificationsTooltip: qsTr("Ignore all notifications from this conversation")
    property string chooseAColor: qsTr("Choose a color")
    property string defaultCallHost: qsTr("Default host (calls)")
    property string leaveTheSwarm: qsTr("Leave the swarm")
    property string leave: qsTr("Leave")
    property string typeOfSwarm: qsTr("Type of swarm")
    property string none: qsTr("None")

    // NewSwarmPage
    property string youCanAdd8: qsTr("You can add 8 people in the swarm")
    property string youCanAddMore: qsTr("You can add %1 more people in the swarm")
    property string createTheSwarm: qsTr("Create the swarm")
    property string goToConversation: qsTr("Go to conversation")
    property string promoteAdministrator: qsTr("Promote to administrator")
    property string kickMember: qsTr("Kick member")
    property string administrator: qsTr("Administrator")
    property string invited: qsTr("Invited")
    property string removeMember: qsTr("Remove member")
    property string to: qsTr("To:")

    //TipBox
    property string customize: qsTr("Customize")
    property string tip: qsTr("Tip")
    property string dismiss: qsTr("Dismiss")
    property string customizeText: qsTr("Add a profile picture and nickname to complete your profile")
    property string customizationDescription: qsTr("This profile is only shared with this account's contacts")
    property string customizationDescription2: qsTr("Your profile is only shared with your contacts")
    property string whySaveAccount: qsTr("Why should I save my account?")
}
