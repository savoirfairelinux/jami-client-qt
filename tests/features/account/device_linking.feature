@account
Feature: Device Linking
  As a user of a Jami client
  I want to link new devices to my existing Jami account
  So that I can access my account on multiple devices

  Background:
    Given the user has an existing Jami account on a primary device
    And the account is enabled and connected to the network

  # ---------------------------------------------------------------------------
  # Token generation
  # ---------------------------------------------------------------------------

  @smoke
  Scenario: Generate a device link token on the primary device
    Given the user is on the device management screen
    When the user initiates "Link a new device"
    Then the device auth state transitions from "INIT" to "TOKEN_AVAILABLE"
    And a device link token is generated
    And the client emits a "deviceAuthStateChanged" signal with state "TOKEN_AVAILABLE"

  @smoke
  Scenario: The generated token is displayed to the user for sharing
    Given the user has initiated device linking
    And the device auth state is "TOKEN_AVAILABLE"
    Then the client displays the link token clearly to the user
    And the token can be copied or shared with the secondary device

  # ---------------------------------------------------------------------------
  # State machine transitions
  # ---------------------------------------------------------------------------

  @smoke
  Scenario: Full device auth state machine transitions during a successful linking
    Given the user has initiated device linking on the primary device
    And the device auth state is "TOKEN_AVAILABLE"
    When the secondary device submits the token to start linking
    Then the device auth state transitions to "CONNECTING"
    And the client emits a "deviceAuthStateChanged" signal with state "CONNECTING"
    When the secondary device establishes a secure channel
    Then the device auth state transitions to "AUTHENTICATING"
    And the client emits a "deviceAuthStateChanged" signal with state "AUTHENTICATING"
    When authentication succeeds
    Then the device auth state transitions to "IN_PROGRESS"
    And the client emits a "deviceAuthStateChanged" signal with state "IN_PROGRESS"
    When the account data transfer completes
    Then the device auth state transitions to "DONE"
    And the client emits a "deviceAuthStateChanged" signal with state "DONE"

  @regression
  Scenario Outline: Device auth state is reported correctly at each transition
    Given the device linking flow is at state "<previous_state>"
    When the linking flow advances to the next stage
    Then the device auth state becomes "<next_state>"
    And the client emits a "deviceAuthStateChanged" signal with state "<next_state>"

    Examples:
      | previous_state  | next_state      |
      | INIT            | TOKEN_AVAILABLE |
      | TOKEN_AVAILABLE | CONNECTING      |
      | CONNECTING      | AUTHENTICATING  |
      | AUTHENTICATING  | IN_PROGRESS     |
      | IN_PROGRESS     | DONE            |

  # ---------------------------------------------------------------------------
  # Linking on the secondary device
  # ---------------------------------------------------------------------------

  @smoke
  Scenario: Link a new device by entering the token on the secondary device
    Given the primary device displays a link token
    When the user opens the account linking wizard on the secondary device
    And the user selects "Link this device to an existing account"
    And the user enters the link token displayed on the primary device
    And the user confirms the linking request
    Then the secondary device connects to the primary device
    And the device auth state on the primary device progresses through the linking states
    And the secondary device receives the account data upon completion

  # ---------------------------------------------------------------------------
  # Confirmation on the primary device
  # ---------------------------------------------------------------------------

  @smoke
  Scenario: Primary device confirms the addition of a new device
    Given the device auth state is "AUTHENTICATING" on the primary device
    When the primary device prompts the user to approve the new device
    And the user approves the new device on the primary device
    Then the device auth state advances to "IN_PROGRESS" and then "DONE"
    And the new device appears in the device list on the primary device

  @regression
  Scenario: Primary device rejects the addition of a new device
    Given the device auth state is "AUTHENTICATING" on the primary device
    When the primary device prompts the user to approve the new device
    And the user rejects the new device on the primary device
    Then the device auth state returns to an idle state
    And the new device does not appear in the device list
    And the client displays a message that the device was rejected

  # ---------------------------------------------------------------------------
  # Post-linking state
  # ---------------------------------------------------------------------------

  @smoke
  Scenario: New device appears in the device list after successful linking
    Given a device linking flow has reached state "DONE"
    When the user views the device list on the primary device
    Then the newly linked device is listed
    And the device entry shows the device name or identifier

  # ---------------------------------------------------------------------------
  # Cancellation and error paths
  # ---------------------------------------------------------------------------

  @regression
  Scenario: Cancel device linking mid-flow on the primary device
    Given the device auth state is "TOKEN_AVAILABLE" on the primary device
    When the user cancels the device linking operation on the primary device
    Then the device auth state returns to an idle state
    And no new device is added to the device list
    And the generated token is invalidated

  @regression
  Scenario: Device linking times out because the token is not used
    Given the primary device has generated a link token
    And the token expires without being used on any secondary device
    Then the device auth state returns to an idle state
    And the client informs the user that the linking attempt has timed out
    And the user can initiate a new linking attempt

  @regression
  Scenario: Device linking fails due to an invalid token on the secondary device
    Given the primary device displays a link token
    When the user enters an incorrect or expired token on the secondary device
    Then the secondary device displays a token validation error
    And no linking state advances on the primary device
    And the primary device is not affected

  @regression
  Scenario: Device linking fails due to a network error
    Given the primary device has generated a link token
    When the network becomes unavailable during the linking flow
    Then the device auth state does not advance past the last connected state
    And the client displays a network error on both devices
    And the user can retry the linking once the network is restored
