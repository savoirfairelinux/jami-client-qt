/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
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

    // SwarmDetailsPanel
    property string about: qsTr("About")
    property string aboutJami: qsTr("About Jami")

    // Misc
    property string accept: qsTr("Accept")
    property string acceptAudio: qsTr("Accept in audio")
    property string acceptContactRequest: qsTr("Accept contact request")
    property string acceptTransferBelow: qsTr("Accept transfer limit (in Mb)")
    property string acceptTransferTooltip: qsTr("in MB, 0 = unlimited")
    property string acceptVideo: qsTr("Accept in video")

    // Account QR
    property string accountQr: qsTr("Account QR")
    property string accountSettingsMenuTitle: qsTr("Account")
    property string accountSettingsTitle: qsTr("Account Settings")
    property string addADescription: qsTr("Add a description")
    property string addAccount: qsTr("Add Account")
    property string addCustomRingtone: qsTr("Add a custom ringtone")
    property string addDefaultModerator: qsTr("Add default moderator")
    property string addDevice: qsTr("Add Device")

    // Message view
    property string addEmoji: qsTr("Add emoji")
    property string addModerator: qsTr("Add")
    property string addNewPlugin: qsTr("Add new plugin")
    property string addParticipant: qsTr("Add participant")
    property string addParticipants: qsTr("Add participants")
    property string addSIPAccount: qsTr("Configure a SIP account")
    property string addSip: qsTr("Add SIP account")

    // ContactPicker
    property string addToConference: qsTr("Add to conference")
    property string addToConversation: qsTr("Add to conversation")
    property string addToConversations: qsTr("Add to conversations")
    property string address: qsTr("Address")
    property string administrator: qsTr("Administrator")
    property string advancedAccountSettings: qsTr("Advanced account settings")
    property string advancedFeatures: qsTr("Advanced features")
    property string advancedInformation: qsTr("Advanced information")
    property string advancedSettingsTitle: qsTr("Advanced settings")
    property string alias: qsTr("Alias")
    property string allFiles: qsTr("All files (*)")
    property string allScreens: qsTr("All Screens")

    // AdvancedCallSettings
    property string allowCallsUnknownContacs: qsTr("Allow incoming calls from unknown contacts")

    // AdvancedPublicAddressSettings
    property string allowIPAutoRewrite: qsTr("Allow IP Auto Rewrite")
    property string alreadyHaveAccount: qsTr("I already have an account")
    property string alwaysRecordCalls: qsTr("Always record calls")
    property string answerIncoming: qsTr("Answer an incoming call")
    readonly property string appTitle: "Jami"

    //General
    property string appearence: qsTr("Appearence")
    property string applicationTheme: qsTr("Application theme")

    // ImportFromBackupPage
    property string archive: qsTr("Archive")
    property string areRecording: qsTr("are recording")

    // AudioSettings
    property string audio: qsTr("Audio")
    property string audioCodec: qsTr("Audio codec")
    property string audioCodecs: qsTr("Audio codecs")
    property string audioDeviceSelector: qsTr("Audio input device selector")
    property string audioFile: qsTr("Audio File (*.wav *.ogg *.opus *.mp3 *.aiff *.wma)")
    property string audioManager: qsTr("Audio manager")
    property string audioRTPMaxPort: qsTr("Audio RTP maximum Port")
    property string audioRTPMinPort: qsTr("Audio RTP minimum Port")
    property string audioVideoSettingsTitle: qsTr("Audio and Video")
    property string authenticate: qsTr("Authenticate")
    property string authenticationFailed: qsTr("Authentication failed")

    // AccountMigrationDialog
    property string authenticationRequired: qsTr("Authentication required")
    property string autoAcceptFiles: qsTr("Automatically accept incoming files")
    property string autoAnswerCalls: qsTr("Automatically answer calls")
    property string autoRegistration: qsTr("Auto Registration After Expired")

    // SettingsHeader
    property string back: qsTr("Back")
    property string backCall: qsTr("Back to Call")
    property string backToWelcome: qsTr("Back to welcome page")
    property string backendError: qsTr("This is the error from the backend: %0")
    property string backupAccountBtn: qsTr("Back up account")
    property string backupAccountHere: qsTr("Back up account here")
    property string backupAccountInfos: qsTr("Your account only exists on this device. " + "If you lose your device or uninstall the application, " + "your account will be deleted and CANNOT be recovered. " + "You can back up your account now or later (in the Account Settings).")
    property string backupFailed: qsTr("Backup failed")

    // CurrentAccountSettings && AdvancedSettings
    property string backupSuccessful: qsTr("Backup successful")
    property string banned: qsTr("Banned")
    property string bannedContacts: qsTr("Banned contacts")
    property string becomeDefaultHost: qsTr("Make me the default host for future calls")
    property string becomeHostOneCall: qsTr("Host only this call")

    // Updates
    property string betaInstall: qsTr("Install beta version")
    property string blockContact: qsTr("Block contact")
    property string blockSwarm: qsTr("Block swarm")
    property string bootstrap: qsTr("Bootstrap")
    property string bothMuted: qsTr("Local and Moderator muted")
    property string caCertificate: qsTr("CA certificate")
    property string callId: qsTr("Call id")
    property string callInformation: qsTr("Call information")
    property string callKeyboardShortcuts: qsTr("Call")
    property string callRecording: qsTr("Call recording")
    property string callSettingsTitle: qsTr("Call settings")
    property string cancel: qsTr("Cancel")
    property string centerMapTooltip: qsTr("Center")
    property string certificateFile: qsTr("Certificate File (*.crt)")
    property string change: qsTr("Change")
    property string changeCurrentPassword: qsTr("Change current password")
    property string changePassword: qsTr("Change password")
    property string changePasswordFailed: qsTr("Password change failed")
    property string changePasswordSuccess: qsTr("Password changed successfully")
    property string changeTextSize: qsTr("Change text size (%)")
    property string chat: qsTr("Chat")
    property string chatSettingsTitle: qsTr("Chat")
    property string checkForUpdates: qsTr("Check for updates now")
    property string chooseAColor: qsTr("Choose a color")
    property string chooseAName: qsTr("Choose a name")
    property string chooseAUsername: qsTr("Choose a username")

    // PhotoBoothView
    property string chooseAvatarImage: qsTr("Choose a picture as your avatar")
    property string chooseAvatarPicture: qsTr("Choose a picture")
    property string chooseHoster: qsTr("Choose a dedicated device for hosting future calls in this swarm. If not set, the device starting a call will host it.")
    property string chooseIdentifier: qsTr("Choose an identifier")
    property string chooseImageFile: qsTr("Choose image file")

    // CreateAccountPage
    property string chooseName: qsTr("Choose name")
    property string choosePlugin: qsTr("Choose Plugin")
    property string chooseThisDevice: qsTr("Choose this device")
    property string chooseUsername: qsTr("Choose username")
    property string chooseUsernameForAccount: qsTr("You can choose a username to help others more easily find and reach you on Jami.")
    property string chooseUsernameForRV: qsTr("Choose a name for your rendezvous point")
    property string clearAvatar: qsTr("Clear avatar image")
    property string clearConversation: qsTr("Clear conversation")
    property string clearHistory: qsTr("Clear history")

    // SmartList
    property string clearText: qsTr("Clear Text")
    property string close: qsTr("Close")
    property string closeMapTooltip: qsTr("Close")
    property string closeSettings: qsTr("Close settings")
    property string companyDeclarationYear: declarationYear + " " + companyName
    property string companyName: "Savoir-faire Linux Inc."

    // Settings moderation
    property string conferenceModeration: qsTr("Conference moderation")
    property string configureExistingSIP: qsTr("Configure an existing SIP account")
    property string confirm: qsTr("Confirm")
    property string confirmAction: qsTr("Confirm action")
    property string confirmBeta: qsTr("This will uninstall your current Release version and you can always download the latest Release version on our website")
    property string confirmBlockConversation: qsTr("Would you really like to block this conversation?")

    // DeleteAccountDialog
    property string confirmDeleteQuestion: qsTr("Would you really like to delete this account?")
    property string confirmNewPassword: qsTr("Confirm new password")
    property string confirmPassword: qsTr("Confirm password")
    property string confirmRemoval: qsTr("Enter this account's password to confirm the removal of this device")

    // RevokeDevicePasswordDialog
    property string confirmRemovalRequest: qsTr("Enter the account password to confirm the removal of this device")
    property string confirmRmConversation: qsTr("Would you really like to remove this conversation?")
    property string connect: qsTr("Connect")
    property string connectFromAnotherDevice: qsTr("Link device")
    property string connectFromBackup: qsTr("Restore account from backup")
    property string connectJAMSServer: qsTr("Connect to a JAMS server")

    // AdvancedConnectivitySettings
    property string connectivity: qsTr("Connectivity")
    property string contactDetails: qsTr("Contact details")
    property string convDetails: qsTr("Conversation details")
    property string conversation: qsTr("Conversation")
    property string conversationKeyboardShortcuts: qsTr("Conversation")
    property string conversations: qsTr("Conversations")

    // LineEditContextMenu
    property string copy: qsTr("Copy")
    property string createAJamiAccount: qsTr("Create a Jami account")
    property string createAccount: qsTr("Create account")
    property string createFromJAMS: qsTr("Create account from Jami Account Management Server (JAMS)")
    property string createNewJamiAccount: qsTr("Create new Jami account")
    property string createNewRV: qsTr("Create a rendezvous point")
    property string createNewSipAccount: qsTr("Create new SIP account")
    property string createPassword: qsTr("Encrypt account with password")
    property string createSIPAccount: qsTr("Create SIP account")
    property string createSwarm: qsTr("Create swarm")
    property string createTheSwarm: qsTr("Create the swarm")
    property string creatingAccount: qsTr("Creating account…")
    property string credits: qsTr("Credits")
    property string customizationDescription: qsTr("This profile is only shared with this account's contacts")
    property string customizationDescription2: qsTr("Your profile is only shared with your contacts")

    //TipBox
    property string customize: qsTr("Customize")

    // accountSettingsPages
    property string customizeAccountDescription: qsTr("Your profile is only shared with your contacts.\nYour picture and your nickname can be changed at all time in the settings of your account.")
    property string customizeOptional: qsTr("Setting a profile picture and nickname is optional, and can also be changed later in the settings.")
    property string customizeProfile: qsTr("Customize profile")
    property string customizeProfileDescription: qsTr("This profile is only shared with this account's contacts.\nThe profile can be changed at all times from the account's settings.")
    property string customizeText: qsTr("Add a profile picture and nickname to complete your profile")
    property string cut: qsTr("Cut")
    property string dark: qsTr("Dark")
    property string declaration: qsTr("Jami is a free universal communication software that respects the freedom and privacy of its users.")
    property string declarationYear: "© 2015-2023"
    property string declineCallRequest: qsTr("Decline the call request")

    // SmartList context menu
    property string declineContactRequest: qsTr("Decline contact request")
    property string defaultCallHost: qsTr("Default host (calls)")
    property string defaultModerators: qsTr("Default moderators")
    property string defaultSettings: qsTr("Default settings")
    property string deleteAccount: qsTr("Delete account")
    property string deleteAccountDescription: qsTr("If your account has not been backed up or added to another device, your account and registered name will be irrevocably lost.")
    property string deleteAccountInfos: qsTr("If your account has not been backed up or added to another device, your account and registered username will be IRREVOCABLY LOST.")
    property string deleteAccountTitle: qsTr("Delete your account")

    //message options
    property string deleteMessage: qsTr("Delete message")
    property string deleteReplyMessage: qsTr("*(Deleted Message)*")
    property string deletedMessage: qsTr("Deleted message")
    property string description: qsTr("Jami is a universal communication platform, with privacy as its foundation, that relies on a free distributed network for everyone.")
    property string details: qsTr("Details")
    property string device: qsTr("Device")
    property string deviceId: qsTr("Device Id")
    property string disableSecureDlgCheck: qsTr("Disable secure dialog check for incoming TLS data")
    property string disabledAccount: qsTr("The account is disabled")
    property string dismiss: qsTr("Dismiss")
    property string displayHyperlinkPreviews: qsTr("Show link preview in conversations")
    property string displayHyperlinkPreviewsDescription: qsTr("Preview require to download content from this third-party servers.")
    property string displayName: qsTr("Display Name")

    // AccountComboBox
    property string displayQRCode: qsTr("Display QR code")
    property string documents: qsTr("Documents")
    property string downloadFolder: qsTr("Choose download directory")
    property string dragMapTooltip: qsTr("Drag")
    property string ecryptAccountDescription: qsTr("Your Jami account is registered only on this device as an archive containing the keys of your account. Access to this archive can be protected by a password.")
    property string edit: qsTr("Edit")
    property string editDeviceName: qsTr("Edit device name")
    property string editMessage: qsTr("Edit message")
    property string editPreference: qsTr("Edit preference")
    property string edited: qsTr("Edited")

    // Plugins
    property string enable: qsTr("Enable")

    //New settings
    //ManageAccount
    property string enableAccountDescription: qsTr("Enabling your account allows you to be contacted on Jami")
    property string enableAccountSettingsTitle: qsTr("Enable account")
    property string enableAllModerators: qsTr("Make all participants moderators")
    property string enableAutoUpdates: qsTr("Enable/Disable automatic updates")
    property string enableCustomRingtone: qsTr("Enable custom ringtone")
    property string enableHWAccel: qsTr("Enable hardware acceleration")
    property string enableLocalModerators: qsTr("Enable local moderators")
    property string enableNotifications: qsTr("Enable notifications")

    // AdvancedOpenDHTSettings
    property string enablePeerDiscovery: qsTr("Enable local peer discovery")
    property string enableProxy: qsTr("Enable proxy")

    // AdvancedChatSettings
    property string enableReadReceipts: qsTr("Enable read receipts")
    property string enableReadReceiptsTooltip: qsTr("Send and receive receipts indicating that a message have been displayed")
    property string enableSDES: qsTr("Enable SDES key exchange")

    // ChatviewSettings
    property string enableTypingIndicator: qsTr("Enable typing indicators")
    property string enableTypingIndicatorDescription: qsTr("Send and receive typing indicators showing that a message is being typed.")
    property string enableVideo: qsTr("Enable video")
    property string encrypt: qsTr("Encrypt")
    property string encryptAccount: qsTr("Encrypt account with password")
    property string encryptDescription: qsTr("A Jami account is created and stored locally only on this device, as an archive containing your account keys. Access to this archive can optionally be protected by a password.")
    property string encryptNegotiation: qsTr("Encrypt negotiation (TLS)")
    property string encryptTitle: qsTr("Encrypt account with a password")
    property string encryptWarning: qsTr("Please note that if you lose your password, it CANNOT be recovered!")
    property string endCall: qsTr("End call")
    property string enterAccountPassword: qsTr("Enter account's password")
    property string enterCurrentPassword: qsTr("Enter current password")

    // ConnectToAccountManager
    property string enterJAMSURL: qsTr("Enter the Jami Account Management Server (JAMS) URL")
    property string enterNewPassword: qsTr("Enter new password")
    property string enterNickname: qsTr("Enter a nickname, surname...")
    property string enterPIN: qsTr("Enter the PIN from another configured Jami account. " + "Use the \"Link Another Device\" feature to obtain a PIN.")

    // PasswordDialog
    property string enterPassword: qsTr("Enter the password")
    property string enterRVName: qsTr("Enter the rendezvous point's name")
    property string enterYourName: qsTr("Enter your name")
    property string error: qsTr("Error")
    property string errorCreateAccount: qsTr("Error while creating your account. Check your credentials.")
    property string exitFullScreen: qsTr("Exit full screen")

    //system
    property string experimental: qsTr("Experimental")
    property string experimentalCallSwarm: qsTr("Enable small swarm groups support for Swarm")
    property string experimentalCallSwarmTooltip: qsTr("This feature will enable call buttons in swarms with multiple participants.")
    property string exportAccount: qsTr("Export")
    property string extendMapTooltip: qsTr("Extend")
    property string fallbackRTP: qsTr("Allow fallback on RTP")
    property string falseStr: qsTr("False")

    // File transfer settings
    property string fileTransfer: qsTr("File transfer")
    property string files: qsTr("Files")
    property string focusConversationsList: qsTr("Focus conversations list")
    property string fps: qsTr("Frames per second")
    property string fps_short: qsTr("Fps")
    property string fullScreen: qsTr("Full screen")
    property string generalSettings: qsTr("General settings")
    property string generalSettingsTitle: qsTr("General")
    property string generatingAccount: qsTr("Generating account…")
    property string generatingRV: qsTr("Creating rendezvous point…")
    property string genericError: qsTr("Something went wrong")
    property string goBackToPluginsList: qsTr("Go back to plugins list")
    property string goToConversation: qsTr("Go to conversation")

    // Good to know
    property string goodToKnow: qsTr("Good to know")
    property string hangupParticipant: qsTr("Hangup")
    property string hardwareAcceleration: qsTr("Hardware acceleration")
    property string hereIsIdentifier: qsTr("Here is your Jami identifier, don't hesitate to share it in order to be contacted more easily!")
    property string hideAdvancedFeatures: qsTr("Hide advanced features")

    // Chatview header
    property string hideChat: qsTr("Hide chat")
    property string hideSelf: qsTr("Hide self")
    property string hideSpectators: qsTr("Hide spectators")

    // CallViewContextMenu
    property string hold: qsTr("Hold")
    property string horizontalViewOpt: qsTr("Horizontal view")
    property string host: qsTr("Host")
    property string hostThisCall: qsTr("Host this call")
    readonly property string httpUserAgentName: "jami"
    property string identifier: qsTr("Identifier")

    //Jami identifier
    property string identifierDescription: qsTr("Share this Jami identifier to be contacted on this account!")
    property string identifierNotAvailable: qsTr("The identifier is not available")
    property string identity: qsTr("Identity")
    property string ignoreNotificationsTooltip: qsTr("Ignore all notifications from this conversation")
    property string imageFiles: qsTr("Image Files (*.png *.jpg *.jpeg *.JPG *.JPEG *.PNG)")
    property string importAccountArchive: qsTr("Create account from backup")
    property string importAccountExplanation: qsTr("You can obtain an archive by clicking on \"Back up account\" " + "in the Account Settings. " + "This will create a .gz file on your device.")
    property string importAccountFromAnotherDevice: qsTr("Import from another device")
    property string importAccountFromBackup: qsTr("Import from an archive backup")
    property string importButton: qsTr("Import")
    property string importFromArchiveBackup: qsTr("Import from archive backup")
    property string importFromArchiveBackupDescription: qsTr("Import Jami account from local archive file.")
    property string importFromBackup: qsTr("Import from backup")
    property string importFromDeviceDescription: qsTr("A PIN is required to use an existing Jami account on this device.")
    property string importFromFile: qsTr("Import avatar from image file")
    property string importPasswordDesc: qsTr("Fill if the account is password-encrypted.")
    property string importStep1: qsTr("Step 01")
    property string importStep1Desc: qsTr("Go to the account management settings of a previous device")
    property string importStep2: qsTr("Step 02")
    property string importStep2Desc: qsTr("Choose the account to link")
    property string importStep3: qsTr("Step 03")
    property string importStep3Desc: qsTr("Select \"Link another device\"")
    property string importStep4: qsTr("Step 04")
    property string importStep4Desc: qsTr("The PIN code will be available for 10 minutes")
    property string inProgress: qsTr("In progress…")
    property string inReplyTo: qsTr("In reply to")
    property string inReplyToMe: qsTr("Me")
    property string includeLocalVideo: qsTr("Include local video in recording")
    property string incomingAudioCallFrom: qsTr("Incoming audio call from {}")
    property string incomingVideoCallFrom: qsTr("Incoming video call from {}")
    property string incorrectPassword: qsTr("Incorrect password")
    property string information: qsTr("Information")
    property string installPlugin: qsTr("Install plugin")
    property string installedPlugins: qsTr("Installed plugins")
    property string introductionJami: qsTr("Share freely and privately with Jami")
    property string invalidName: qsTr("Invalid name")
    property string invalidUsername: qsTr("Invalid username")
    property string invitationViewAcceptedConversation: qsTr("You have accepted\nthe conversation request")
    property string invitationViewJoinConversation: qsTr("Hello,\nWould you like to join the conversation?")

    // Invitation View
    property string invitationViewSentRequest: qsTr("%1 has sent you a request for a conversation.")
    property string invitationViewWaitingForSync: qsTr("Waiting until %1\nconnects to synchronize the conversation.")
    property string invitations: qsTr("Invitations")
    property string invited: qsTr("Invited")
    property string isCallingYou: qsTr("is calling you")

    // CallOverlay
    property string isRecording: qsTr("is recording")

    // Is Swarm
    property string isSwarm: qsTr("Is swarm:")
    property string jamiArchiveFiles: qsTr("Jami archive files (*.gz)")
    property string jamiIdentity: qsTr("Jami identity")
    property string jamiManagementServerURL: qsTr("Jami Account Management Server URL")
    property string jamsCredentials: qsTr("Enter JAMS credentials")
    property string jamsServer: qsTr("JAMS server")
    property string joinCall: qsTr("Join call")
    property string joinJami: qsTr("Join Jami")
    property string joinJamiNoPassword: qsTr("Are you sure you would like to join Jami without a username?\nIf yes, only a randomly generated 40-character identifier will be assigned to this account.")

    //MessagesResearch
    property string jumpTo: qsTr("Jump to")
    property string keepMinimized: qsTr("Minimize on close")
    property string keyFile: qsTr("Key File (*.key)")

    // KeyboardShortCutTable
    property string keyboardShortcutTableWindowTitle: qsTr("Keyboard Shortcut Table")
    property string keyboardShortcuts: qsTr("Keyboard Shortcuts")
    property string kickMember: qsTr("Kick member")
    property string language: qsTr("User interface language")
    property string layout: qsTr("Layout")
    property string layoutSettings: qsTr("Layout settings")
    property string leave: qsTr("Leave")
    property string leaveAudioMessage: qsTr("Leave audio message")
    property string leaveConversation: qsTr("Leave conversation")
    property string leaveVideoMessage: qsTr("Leave video message")
    property string light: qsTr("Light")
    property string linkAnotherDevice: qsTr("Link a new device")
    property string linkDeviceNetWorkError: qsTr("Error connecting to the network.\nPlease try again later.")
    property string linkFromAnotherDevice: qsTr("Link this device to an existing account")
    property string linkNewDevice: qsTr("Exporting account…")
    property string linkedAccountDescription: qsTr("You can link your account to an other device to be able to use it on the other device.")
    property string linkedAccountList: qsTr("List of the devices that are linked to this account:")
    property string linkedDevicesSettingsTitle: qsTr("Linked devices")
    property string linkedOtherDevices: qsTr("Other linked devices")
    property string linkedThisDevice: qsTr("This device")
    property string loadUnload: qsTr("Load/Unload")
    property string local: qsTr("Local")
    property string localAccount: qsTr("Your account will be created and stored locally.")
    property string localMuted: qsTr("Local muted")
    property string locationServicesClosedError: qsTr("Your precise location could not be determined. Please check your Internet connection.")
    property string locationServicesError: qsTr("Your precise location could not be determined.\nIn Device Settings, please turn on \"Location Services\".\nOther participants' location can still be received.")
    property string locationSharingLabel: qsTr("Location sharing")
    property string logsViewClear: qsTr("Clear")
    property string logsViewCopied: qsTr("Copied to clipboard!")
    property string logsViewCopy: qsTr("Copy")
    property string logsViewDisplay: qsTr("Receive Logs")
    property string logsViewReport: qsTr("Report Bug")
    property string logsViewShowStats: qsTr("Show Stats")
    property string logsViewStart: qsTr("Start")
    property string logsViewStop: qsTr("Stop")

    // View Logs
    property string logsViewTitle: qsTr("Debug")
    property string longSharing: qsTr("One hour")
    property string lowerHand: qsTr("Lower hand")

    // ImportFromDevicePage
    property string mainAccountPassword: qsTr("Enter Jami account password")
    property string manageAccountSettingsTitle: qsTr("Manage account")
    property string maxLocationDuration: qsTr("Unlimited")
    property string maximizeMapTooltip: qsTr("Maximize")
    property string maximizeParticipant: qsTr("Maximize")
    property string me: qsTr("Me")

    // AdvancedMediaSettings
    property string media: qsTr("Media")
    property string mediaSettings: qsTr("Media settings")
    property string member: qsTr("Member")
    property string members: qsTr("%1 Members")
    property string messages: qsTr("Messages")
    property string microphone: qsTr("Microphone")
    property string migrateConversation: qsTr("Migrate conversation")
    property string migrationReason: qsTr("Your session has expired or been revoked on this device. Please enter your password.")
    property string minLocationDuration: qsTr("1 min")
    property string minimizeMapTooltip: qsTr("Minimize")
    property string minimizeParticipant: qsTr("Minimize")
    property string minuteLeft: qsTr("%1 minute left")
    property string minutesLeft: qsTr("%1 minutes left")
    property string mirrorLocalVideo: qsTr("Mirror local video")

    //moderation
    property string moderation: qsTr("Moderation")
    property string moderator: qsTr("Moderator")
    property string moderatorMuted: qsTr("Moderator muted")
    property string moreEmojis: qsTr("more emojis")
    property string moreOptions: qsTr("More options")
    property string mosaic: qsTr("Mosaic")
    property string mute: qsTr("Mute")
    property string muteCamera: qsTr("Mute camera")
    property string muteConversation: qsTr("Mute conversation")
    property string muteParticipant: qsTr("Mute")
    property string mutedByModerator: qsTr("You are muted by a moderator")
    property string mutedLocally: qsTr("You are still muted on your device")
    property string name: qsTr("name")
    property string nameAlreadyTaken: qsTr("Name already taken")

    // AdvancedNameServerSettings
    property string nameServer: qsTr("Name server")
    property string needsHost: qsTr("Current host for this swarm seems unreachable. Do you want to host the call?")
    property string negotiationTimeOut: qsTr("Negotiation timeout (seconds)")
    property string networkDisconnected: qsTr("Network disconnected")
    property string networkError: qsTr("Network error")
    property string networkInterface: qsTr("Network interface")
    property string neverShowAgain: qsTr("Never show me this again")
    property string nextConversation: qsTr("Next conversation")
    property string noNetworkConnectivity: qsTr("No network connectivity")
    property string noVideo: qsTr("no video")
    property string noVideoDevice: qsTr("No video device")
    property string none: qsTr("None")
    property string notAvailable: qsTr("Unavailable")
    property string notMuted: qsTr("Not muted")
    property string notePasswordRecovery: qsTr("Choose a password to encrypt your account on this device. Note that the password CANNOT be recovered.")
    property string onOff: qsTr("On/Off")
    property string openAccountCreationWizard: qsTr("Open account creation wizard")
    property string openAccountList: qsTr("Open account list")
    property string openDHTConfig: qsTr("OpenDHT configuration")
    property string openFile: qsTr("Open file")
    property string openKeyboardShortcutTable: qsTr("Open keyboard shortcut table")
    property string openLocation: qsTr("Open location")
    property string openSettings: qsTr("Open settings")
    property string optionBlock: qsTr("Block")
    property string optionCancel: qsTr("Cancel")
    property string optionDelete: qsTr("Delete")
    property string optionLater: qsTr("Later")

    // Generic dialog options
    property string optionOk: qsTr("Ok")
    property string optionRemove: qsTr("Remove")
    property string optionSave: qsTr("Save")
    property string optionUnban: qsTr("Unban")
    property string optionUpgrade: qsTr("Upgrade")
    property string optional: qsTr("Optional")
    property string outputDevice: qsTr("Output device")
    property string participantMicIsStillMuted: qsTr("Participant is still muted on their device")
    property string participantModIsStillMuted: qsTr("You are still muted by moderator")
    property string participantsSide: qsTr("On the side")
    property string participantsTop: qsTr("On the top")
    property string password: qsTr("Password")
    property string passwordArchive: qsTr("If the account is encrypted with a password, please fill the following field.")
    property string passwordOptional: qsTr("Encrypting your account with a password is optional, and if the password is lost it CANNOT be recovered later.")
    property string paste: qsTr("Paste")
    property string pauseCall: qsTr("Pause call")
    property string peerNumber: qsTr("Peer number")
    property string peerStoppedRecording: qsTr("Peer stopped recording")
    property string personalizeAccount: qsTr("Personalize account")
    property string pin: qsTr("Enter the PIN code")

    // LinkDevicesDialog
    property string pinTimerInfos: qsTr("The PIN and the account password should be entered in your device within 10 minutes.")
    property string pinWindow: qsTr("Pin")
    property string placeAudioCall: qsTr("Place audio call")
    property string placeVideoCall: qsTr("Place video call")
    property string pluginFiles: qsTr("Plugin Files (*.jpl)")
    property string pluginPreferences: qsTr("Preferences")
    property string pluginResetConfirmation: qsTr("Are you sure you wish to reset %1 preferences?")
    property string pluginSettings: qsTr("Plugin settings")
    property string pluginSettingsTitle: qsTr("Plugins")
    property string pluginUninstallConfirmation: qsTr("Are you sure you wish to uninstall %1?")
    property string port: qsTr("Port")
    property string positionShareDuration: qsTr("Position share duration")
    property string positionShareLimit: qsTr("Limit the duration of location sharing")
    property string previewUnavailable: qsTr("Preview unavailable")
    property string previousConversation: qsTr("Previous conversation")
    property string privateKey: qsTr("Private key")
    property string privateKeyPassword: qsTr("Private key password")
    property string profile: qsTr("Profile")

    // ProfilePage
    property string profileSharedWithContacts: qsTr("Profile is only shared with contacts")
    property string promoteAdministrator: qsTr("Promote to administrator")
    property string proxy: qsTr("Proxy")
    property string proxyAddress: qsTr("Proxy address")
    property string publicAddress: qsTr("Public address")

    // UserProfile
    property string qrCode: qsTr("QR code")
    property string quality: qsTr("Quality")
    property string raiseHand: qsTr("Raise hand")
    property string recommended: qsTr("Recommended")

    // Daemon reconnection
    property string reconnectDaemon: qsTr("Trying to reconnect to the Jami daemon (jamid)…")
    property string reconnectTry: qsTr("Trying to reconnect to the Jami daemon (jamid)…")

    // DaemonReconnectWindow
    property string reconnectWarn: qsTr("Could not re-connect to the Jami daemon (jamid).\nJami will now quit.")
    property string reconnectionFailed: qsTr("Could not re-connect to the Jami daemon (jamid).\nJami will now quit.")
    property string reduceMapTooltip: qsTr("Reduce")
    property string refuse: qsTr("Refuse")

    // JamiUserIdentity settings
    property string register: qsTr("Register")

    // JamiUserIdentity
    property string registerAUsername: qsTr("Register a username")
    property string registerUsername: qsTr("Register username")
    property string registeringName: qsTr("Registering name")
    property string registrationExpirationTime: qsTr("Registration expiration time (seconds)")

    // BannedItemDelegate
    property string reinstateContact: qsTr("Reinstate as contact")
    property string reinstateMember: qsTr("Reinstate member")
    property string remove: qsTr("Remove")
    property string removeContact: qsTr("Remove contact")
    property string removeConversation: qsTr("Remove conversation")
    property string removeCurrentDevice: qsTr("Remove current device")
    property string removeDefaultModerator: qsTr("Remove default moderator")
    property string removeDevice: qsTr("Remove Device")
    property string removeMember: qsTr("Remove member")
    property string rendererId: qsTr("Renderer id")

    //advanced information
    property string renderersInformation: qsTr("Renderers information")
    property string rendezVous: qsTr("Convert your account into a rendezvous point")

    //rdv
    property string rendezVousPoint: qsTr("Rendezvous point")
    property string repliedTo: qsTr(" replied to")
    property string reply: qsTr("Reply")
    property string replyTo: qsTr("Reply to")
    property string requestsList: qsTr("Requests list")
    property string required: qsTr("Required")
    property string reset: qsTr("Reset")
    property string resetPreferences: qsTr("Reset Preferences")
    property string resolution: qsTr("Resolution")
    property string resumeCall: qsTr("Resume call")

    //ringtone
    property string ringtone: qsTr("Ringtone")
    property string ringtoneDevice: qsTr("Ringtone device")
    property string runStartup: qsTr("Launch at startup")
    property string saveAccountDescription: qsTr("Your Jami account exists only on this device.\nIf you lose your device or uninstall the application, your account will be lost. We recommend to back up it.")
    property string saveAccountTitle: qsTr("Backup account")

    // Context Menu
    property string saveFile: qsTr("Save file")

    // DeviceItemDelegate
    property string saveNewDeviceName: qsTr("Save new device name")
    property string saveProfile: qsTr("Save profile")
    property string saveRecordingsTo: qsTr("Save recordings to")
    property string saveScreenshotsTo: qsTr("Save screenshots to")
    property string screen: qsTr("Screen %1")
    property string screenSharing: qsTr("Screen Sharing")
    property string screens: qsTr("Screens")
    property string screenshotTaken: qsTr("Screenshot saved to %1")

    // Chatview footer
    property string scrollToEnd: qsTr("Scroll to end of conversation")
    property string sdpSettingsSubtitle: qsTr("Only used during negotiation in case ICE is not supported")

    // AdvancedSDPSettings
    property string sdpSettingsTitle: qsTr("SDP Session Negotiation (ICE Fallback)")
    property string search: qsTr("Search")
    property string searchBar: qsTr("Search bar")
    property string searchResults: qsTr("Search Results")

    // AdvancedSIPSecuritySettings && AdvancedJamiSecuritySettings
    property string security: qsTr("Security")
    property string select: qsTr("Select")
    property string selectAnImage: qsTr("Select An Image to %1")
    property string selectArchiveFile: qsTr("Select archive file")
    property string selectAudioInputDevice: qsTr("Select audio input device")
    property string selectAudioOutputDevice: qsTr("Select audio output device")
    property string selectCACert: qsTr("Select a CA certificate")
    property string selectCACertDefault: qsTr("Select")
    property string selectCustomRingtone: qsTr("Select custom ringtone")
    property string selectFPS: qsTr("Select video frame rate (frames per second)")
    property string selectFile: qsTr("Select a file")
    property string selectFolder: qsTr("Select a folder")
    property string selectNewRingtone: qsTr("Select a new ringtone")
    property string selectPluginInstall: qsTr("Select a plugin to install")
    property string selectPrivateKey: qsTr("Select a private key")
    property string selectRingtoneOutputDevice: qsTr("Select ringtone output device")

    // SelectScreen
    property string selectScreen: qsTr("Select a screen to share")
    property string selectScreenSharingFPS: qsTr("Select screen sharing frame rate (frames per second)")
    property string selectShareMethod: qsTr("Select sharing method")
    property string selectUserCert: qsTr("Select a user certificate")
    property string selectVideoDevice: qsTr("Select video device")
    property string selectVideoResolution: qsTr("Select video resolution")
    property string selectWindow: qsTr("Select a window to share")
    property string send: qsTr("Send")
    property string sendFile: qsTr("Send file")
    property string server: qsTr("Server")
    property string setAPassword: qsTr("Set a password")

    // Conference moderation
    property string setModerator: qsTr("Set moderator")
    property string setPassword: qsTr("Encrypt account")
    property string setPasswordFailed: qsTr("Password set failed")
    property string setPasswordSuccess: qsTr("Password set successfully")

    // NameRegistrationDialog
    property string setUsername: qsTr("Set username")
    property string settings: qsTr("Settings")
    property string share: qsTr("Share")
    property string shareFile: qsTr("Share file")

    // WelcomePage
    property string shareInvite: qsTr("This is your Jami username.\nCopy and share it with your friends!")

    // Share location/position
    property string shareLocation: qsTr("Share location")
    property string shareLocationToolTip: qsTr("Share location to participants of this conversation (%1)")
    property string shareScreen: qsTr("Share screen")
    property string shareScreenArea: qsTr("Share screen area")
    property string shareWindow: qsTr("Share window")
    property string shortSharing: qsTr("10 minutes")
    property string shortStopAllSharings: qsTr("Turn off sharing")
    property string showAdvancedFeatures: qsTr("Show advanced features")
    property string showHidePrefs: qsTr("Display or hide preferences")
    property string showInvitations: qsTr("Show invitations")
    property string showNotifications: qsTr("Show notifications")
    property string showPlugins: qsTr("Show available plugins")

    // CreateSIPAccountPage
    property string sipAccount: qsTr("SIP account")
    property string sipInputPanel: qsTr("Sip input panel")
    property string skip: qsTr("Skip")
    property string slogan: "Világfa"
    property string sockets: qsTr("Sockets")
    property string somethingWentWrong: qsTr("Something went wrong")
    property string soundTest: qsTr("Sound test")
    property string startAudioCall: qsTr("Start audio call")
    property string startRec: qsTr("Start recording")
    property string startSwarm: qsTr("Start swarm")

    // ConversationContextMenu
    property string startVideoCall: qsTr("Start video call")
    property string stopAllSharings: qsTr("Turn off location sharing")
    property string stopConvSharing: qsTr("Stop location sharing in this conversation (%1)")
    property string stopRec: qsTr("Stop recording")
    property string stopSharing: qsTr("Stop sharing screen or file")
    property string stopSharingLocation: qsTr("Stop sharing")
    property string stopSharingPopupBody: qsTr("Location is shared in several conversations")
    property string stopSharingSeveralConversationTooltip: qsTr("Location is shared in several conversations, click to choose how to turn off location sharing")
    property string stopTakingPhoto: qsTr("Stop taking photo")
    property string stunAdress: qsTr("STUN address")
    property string success: qsTr("Success")
    property string sureToRemoveDevice: qsTr("Are you sure you wish to remove this device?")
    property string swarmName: qsTr("Swarm's name")

    // SystemSettings
    property string system: qsTr("System")
    property string takePhoto: qsTr("Take photo")
    property string textZoom: qsTr("Text zoom")

    //Appearence
    property string theme: qsTr("Theme")
    property string tileScreenshot: qsTr("Take tile screenshot")
    property string tip: qsTr("Tip")
    property string tipAccountPluginSettingsDisplay: qsTr("Display or hide Account plugin settings")
    property string tipAdvancedSettingsDisplay: qsTr("Display advanced settings")
    property string tipAdvancedSettingsHide: qsTr("Hide advanced settings")
    property string tipAutoUpdate: qsTr("Toggle automatic updates")
    property string tipBackupAccount: qsTr("Back up account to a .gz file")

    // BannedContacts
    property string tipBannedContactsDisplay: qsTr("Display banned contacts")
    property string tipBannedContactsHide: qsTr("Hide banned contacts")
    property string tipChooseDownloadFolder: qsTr("Choose download directory")
    property string tipGeneralPluginSettingsDisplay: qsTr("Display or hide General plugin settings")

    // LinkedDevices
    property string tipLinkNewDevice: qsTr("Link a new device to this account")

    // Recording Settings
    property string tipRecordFolder: qsTr("Select a record directory")
    property string tipRunStartup: qsTr("Run at system startup")
    property string tls: qsTr("TLS")
    property string tlsProtocol: qsTr("TLS protocol method")
    property string tlsRequireConnections: qsTr("Require certificate for incoming TLS connections")
    property string tlsServerName: qsTr("TLS server name")
    property string to: qsTr("To:")
    property string tooltipPeerDiscovery: qsTr("Connect to other DHT nodes advertising on your local network.")
    property string transferCall: qsTr("Transfer call")
    property string transferThisCall: qsTr("Transfer this call")
    property string transferTo: qsTr("Transfer to")
    property string troubleshootButton: qsTr("Open logs")
    property string troubleshootText: qsTr("Get logs")

    //Troubleshoot Settings
    property string troubleshootTitle: qsTr("Troubleshoot")
    property string trueStr: qsTr("True")
    property string turnAdress: qsTr("TURN address")
    property string turnPassword: qsTr("TURN password")
    property string turnRealm: qsTr("TURN Realm")
    property string turnUsername: qsTr("TURN username")
    property string typeIndicatorAnd: qsTr(" and ")
    property string typeIndicatorMax: qsTr("Several people are typing…")
    property string typeIndicatorPlural: qsTr("{} are typing…")
    property string typeIndicatorSingle: qsTr("{} is typing…")
    property string typeOfSwarm: qsTr("Type of swarm")
    property string udp: qsTr("UDP")
    property string uninstall: qsTr("Uninstall")
    property string uninstallPlugin: qsTr("Uninstall plugin")
    property string unlinkDevice: qsTr("Unlink device from account")
    property string unmute: qsTr("Unmute")
    property string unmuteCamera: qsTr("Unmute camera")
    property string unmuteParticipant: qsTr("Unmute")
    property string unpin: qsTr("Unpin")
    property string unpinStopSharingTooltip: qsTr("Pin map to be able to share location or to turn off location in specific conversations")
    property string unsetModerator: qsTr("Unset moderator")

    // Update settings
    property string update: qsTr("Automatically check for updates")
    property string updateCheckError: qsTr("An error occured when checking for a new version")
    property string updateDialogTitle: qsTr("Update")
    property string updateDownloadCanceled: qsTr("Installer download canceled")
    property string updateDownloading: "Downloading"
    property string updateFound: qsTr("A new version of Jami was found\nWould you like to update now?")
    property string updateNetworkError: qsTr("Network error")
    property string updateNotFound: qsTr("No new version of Jami was found")
    property string updateSSLError: qsTr("SSL error")
    property string updateToSwarm: qsTr("Migrating to the Swarm technology will enable synchronizing this conversation across multiple devices and improve reliability. The legacy conversation history will be cleared in the process.")
    property string updatesTitle: qsTr("Updates")
    property string useCustomAddress: qsTr("Use custom address and port")
    property string useExistingAccount: qsTr("Use existing Jami account")
    property string useSTUN: qsTr("Use STUN")
    property string useTURN: qsTr("Use TURN")
    property string useUPnP: qsTr("Use UPnP")
    property string userCertificate: qsTr("User certificate")
    property string username: qsTr("Username")
    property string usernameAccountDescription: qsTr("Your username help you to be easily found and reach on Jami.\nIf you don’t choose one, the serial identifier (a randomly generated word of 40 characters) of your account will be your username. It’s more difficult to be found and reach with this number.")
    property string usernameAlreadyTaken: qsTr("Username already taken")
    property string usernameRecommened: qsTr("Choosing a username is recommended, and a chosen username CANNOT be changed later.")
    property string usernameToolTip: qsTr("- 32 characters maximum\n- Alphabetical characters (A to Z and a to z)\n- Numeric characters (0 to 9)\n- Special characters allowed: dash (-)")
    property string verifyCertificatesClient: qsTr("Verify server TLS certificates")
    property string verifyCertificatesServer: qsTr("Verify certificates for incoming TLS connections")

    // AboutPopUp
    property string version: qsTr("Version") + (UpdateManager.isCurrentVersionBeta() ? " (Beta)" : "")
    property string verticalViewOpt: qsTr("Vertical view")

    // VideoSettings
    property string video: qsTr("Video")
    property string videoBitrate: qsTr("Video bitrate")
    property string videoCodec: qsTr("Video codec")
    property string videoCodecs: qsTr("Video codecs")
    property string videoRTPMaxPort: qsTr("Video RTP maximum port")
    property string videoRTPMinPort: qsTr("Video RTP minimum Port")
    property string viewFullScreen: qsTr("View full screen")
    property string viewPlugin: qsTr("View plugin")

    // AdvancedVoiceMailSettings
    property string voiceMail: qsTr("Voicemail")
    property string voiceMailDialCode: qsTr("Voicemail dial code")
    property string wantToJoin: qsTr("A call is in progress. Do you want to join the call?")
    property string welcomeTo: qsTr("Welcome to")
    property string welcomeToJami: qsTr("Welcome to Jami")

    // BackupKeyPage
    property string whyBackupAccount: qsTr("Why should I back-up this account?")
    property string whySaveAccount: qsTr("Why should I save my account?")
    property string windows: qsTr("Windows")
    property string writeTo: qsTr("Write to %1")

    // NewSwarmPage
    property string youCanAdd7: qsTr("You can add 7 people in the swarm")
    property string youCanAddMore: qsTr("You can add %1 more people in the swarm")
    property string yourPinIs: qsTr("Your PIN is:")
    property string zoomLevel: qsTr("Text zoom level")
}
