# **Add device feature**

This document describes the architecture of the feature allowing users to link their account to a new device, referred to as the `Add a New Device` process.

## **Terminology**

To understand this document, here are some key terms:

- **`import side`**: The device importing the account.
- **`export side`**: The device exporting its account.
- **`token`**: A URI that identifies a device on the Distributed Hash Table (DHT).

---

## **State Machine**

The `daemon` manages this functionality using a state machine.

The state evolution is communicated to clients, enabling the appropriate interface display.

Currently, the state machine is symmetrical for both `import side` and `export side`, though certain states are inaccessible depending on the side.

### **State Overview**

| **Number** | **Name**        | **Usage (Side)** | **Description**                                              |
| ---------- | --------------- | ---------------- | ------------------------------------------------------------ |
| 0          | Init            | None             | Initial state.                                               |
| 1          | Token available | Import only      | The `token` is available. This is the URI identifying the new device on the DHT, displayed as text or a QR code. |
| 2          | Connecting      | Export/Import    | A peer-to-peer connection is being established.              |
| 3          | Authenticating  | Export/Import    | The identity of the account and device address are being confirmed. |
| 4          | In progress     | Export/Import    | The account archive is being transferred.                    |
| 5          | Done            | Export/Import    | Final state. Represents success or failure.                  |

---

### **Details**

The state machine can include supplementary information for display purposes, passed as a `map<String, String>` called `details`.

#### **Details for `import side`**

| **Number** | **Name**        | **Details**                                                  |
| ---------- | --------------- | ------------------------------------------------------------ |
| 0          | Init            | Not applicable.                                              |
| 1          | Token available | `token`: A 59-character URI with the prefix `jami-auth://`.  |
| 2          | Connecting      | No details.                                                  |
| 3          | Authenticating  | `peer_id`: Jami ID of the imported account.<br>`auth_scheme`: `{"", "none", "password"}` (empty if unprotected).<br>`auth_error`: `{"bad_password"}`. |
| 4          | In progress     | No details.                                                  |
| 5          | Done            | `error`: `{"", "none", "network", "authentication"}` (empty if no error). |

#### **Details for `export side`**

| **Number** | **Name**        | **Details**                                                  |
| ---------- | --------------- | ------------------------------------------------------------ |
| 0          | Init            | Not applicable.                                              |
| 1          | Token available | Not applicable.                                              |
| 2          | Connecting      | No details.                                                  |
| 3          | Authenticating  | `peer_address`: IP address of the exporting device.          |
| 4          | In progress     | No details.                                                  |
| 5          | Done            | `error`: `{"", "none", "network", "authentication"}` (empty if no error). |

---

## **API Between Daemon and Client**

### **API for `import side`**

| **Signal Name**                | **Direction** | **Purpose**                                                  |
| ------------------------------ | ------------- | ------------------------------------------------------------ |
| `addAccount`                   | Outbound      | Announces the intent to import an account. Must include the key `Account.archiveURL="jami-auth"`. |
| `provideAccountAuthentication` | Outbound      | Provides a password if needed and confirms the identity of the imported account. |
| `removeAccount`                | Outbound      | Cancels the operation.                                       |
| `deviceAuthStateChanged`       | Inbound       | Indicates the new state and provides details.                |

---

### **API for `export side`**

| **Signal Name**         | **Direction** | **Purpose**                                   |
| ----------------------- | ------------- | --------------------------------------------- |
| `addDevice`             | Outbound      | Announces the intent to export an account.    |
| `confirmAddDevice`      | Outbound      | Confirms the address of the exporting device. |
| `cancelAddDevice`       | Outbound      | Cancels the operation.                        |
| `addDeviceStateChanged` | Inbound       | Indicates the new state and provides details. |

# Daemon state machine
```mermaid
stateDiagram-v2
    state "Import Side" as Import {
        [*] --> Import_Init
        Import_Init --> Import_TokenAvailable: Generate token
        Import_TokenAvailable --> Import_Connecting: Peer detected
        Import_Connecting --> Import_Authenticating: Connection established
        Import_Authenticating --> Import_InProgress: Auth success
        Import_InProgress --> Import_Done: Transfer complete

        note right of Import_TokenAvailable
            Provides:
            - Authentication code
            - QR data
        end note

        note right of Import_Authenticating
            May require password
            auth_scheme: "", "none", "password"
        end note

        note right of Import_Done
            error: "", "none", "network", "authentication"
        end note
    }

    state "Export Side" as Export {
        [*] --> Export_Init
        Export_Init --> Export_Connecting: Token validated
        Export_Connecting --> Export_Authenticating: Connection established
        Export_Authenticating --> Export_InProgress: Auth success
        Export_InProgress --> Export_Done: Transfer complete

        note right of Export_Init
            Accepts:
            - Authentication code
            - QR data
        end note
        note right of Export_Authenticating
            Confirms peer address
        end note
    }
```

# Client state machine
```mermaid
stateDiagram-v2
    [*] --> Initial
    Initial --> ImportDevice: ImportFromDevice selected
    Initial --> ExportDevice: ExportToDevice selected

    state "Import Device" as ImportDevice {
        [*] --> Import_Init
        Import_Init --> Import_TokenAvailable: Token received
        Import_TokenAvailable --> Import_Connecting: Peer detected
        Import_Connecting --> Import_Authenticating: Connection established
        Import_Authenticating --> Import_InProgress: Auth success
        Import_InProgress --> Import_Done: Transfer complete

        Import_Authenticating --> Import_Error: Bad password
        Import_Connecting --> Import_Error: Connection failed
        Import_InProgress --> Import_Error: Transfer failed

        Import_Error --> [*]: Reset
        Import_Done --> [*]: Account ready

        note right of Import_TokenAvailable
            Display:
            - QR code
            - Authentication code
            - Copy button
        end note
        note right of Import_Authenticating
            Show password input if needed
        end note
    }

    state "Export Device" as ExportDevice {
        [*] --> Export_Init

        state Export_Init {
            [*] --> ShowInputOptions
            ShowInputOptions --> ScanQR: Camera selected
            ShowInputOptions --> ManualEntry: Manual selected

            ScanQR --> QRScanning: Start camera
            QRScanning --> TokenObtained: QR detected
            QRScanning --> ShowInputOptions: Cancel scan

            ManualEntry --> TokenObtained: Valid code entered
            ManualEntry --> ShowInputOptions: Cancel entry
        }

        Export_Init --> Export_Connecting: Token validated
        Export_Connecting --> Export_Authenticating: Connection established
        Export_Authenticating --> Export_InProgress: Auth provided
        Export_InProgress --> Export_Done: Transfer complete

        Export_Connecting --> Export_Error: Invalid token
        Export_Authenticating --> Export_Error: Auth failed
        Export_InProgress --> Export_Error: Transfer failed

        Export_Error --> [*]: Reset
        Export_Done --> [*]: Device added

        note right of Export_Init
            Input options:
            - QR scanner
            - Manual code entry
        end note
        note right of Export_Authenticating
            Confirm peer device
        end note
    }

    ImportDevice --> Initial: Back/Cancel
    ExportDevice --> Initial: Back/Cancel
```

# Full sequence diagram
```mermaid
sequenceDiagram
    box white Import Side
    participant IC as New Client
    participant ID as New Daemon
    end
    box white Export Side
    participant ED as Old Daemon
    participant EC as Old Client
    end

    %% Initial Setup
    IC->>ID: addAccount(archiveURL="jami-auth")
    activate ID
    ID-->>IC: deviceAuthStateChanged(state=TOKEN_AVAILABLE)
    Note over IC: Display QR code<br/>and auth token

    %% Export Side Initiation
    EC->>EC: User chooses to export
    EC->>EC: Scan QR/Enter token
    EC->>ED: addDevice(token)
    activate ED

    %% Connection Establishment
    ED->>ID: DHT connection request
    ID-->>IC: deviceAuthStateChanged(state=CONNECTING)
    ED-->>EC: addDeviceStateChanged(state=CONNECTING)

    %% Authentication Phase
    ID-->>IC: deviceAuthStateChanged(state=AUTHENTICATING,<br/>peer_id, auth_scheme)
    ED-->>EC: addDeviceStateChanged(state=AUTHENTICATING,<br/>peer_address)

    alt Account is password protected
        IC->>IC: Show password prompt
        IC->>ID: provideAccountAuthentication(password)
    end

    EC->>ED: confirmAddDevice()

    %% Transfer Phase
    ID-->>IC: deviceAuthStateChanged(state=IN_PROGRESS)
    ED-->>EC: addDeviceStateChanged(state=IN_PROGRESS)

    ED->>ID: Transfer account archive

    %% Completion
    ID-->>IC: deviceAuthStateChanged(state=DONE, error="")
    ED-->>EC: addDeviceStateChanged(state=DONE, error="")

    deactivate ID
    deactivate ED

    Note over IC,EC: Account successfully linked

    alt Error Scenarios
        ID-->>IC: deviceAuthStateChanged(state=DONE, error="network")
        ED-->>EC: addDeviceStateChanged(state=DONE, error="network")
        Note over IC,EC: Network error during transfer

        ID-->>IC: deviceAuthStateChanged(state=DONE, error="authentication")
        ED-->>EC: addDeviceStateChanged(state=DONE, error="authentication")
        Note over IC,EC: Authentication failed
    end

    %% Cancellation Scenarios
    rect rgb(240, 240, 240)
        Note over IC,EC: Optional Cancellation Flows
        IC->>ID: removeAccount()
        EC->>ED: cancelAddDevice()
    end
```