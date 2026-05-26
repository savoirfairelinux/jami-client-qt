@account
Feature: Account Creation
  As a user of a Jami client
  I want to create and register accounts of different types
  So that I can communicate securely with others

  # ---------------------------------------------------------------------------
  # Jami (DHT) account creation
  # ---------------------------------------------------------------------------

  @smoke
  Scenario: Create a Jami account with a display name only
    Given the client is on the account creation wizard
    When the user selects "Jami" as the account type
    And the user enters the display name "Alice"
    And the user confirms account creation
    Then the client emits an "accountAdded" signal
    And the new account appears in the account list with the name "Alice"
    And no username is registered for the account

  @smoke
  Scenario: Create a Jami account with a display name and password
    Given the client is on the account creation wizard
    When the user selects "Jami" as the account type
    And the user enters the display name "Bob"
    And the user sets the account password "S3cur3P@ss!"
    And the user confirms account creation
    Then the client emits an "accountAdded" signal
    And the new account appears in the account list with the name "Bob"
    And the account is protected by a password

  @smoke
  Scenario: Create a Jami account and register a username
    Given the client is on the account creation wizard
    When the user selects "Jami" as the account type
    And the user enters the display name "Carol"
    And the user enters the desired username "carol_jami"
    And the username "carol_jami" is available on the nameserver
    And the user confirms account creation
    Then the client emits an "accountAdded" signal
    And the client emits a "nameRegistrationEnded" signal with status "success"
    And the account's registered username is "carol_jami"

  # ---------------------------------------------------------------------------
  # Username validation
  # ---------------------------------------------------------------------------

  @regression
  Scenario Outline: Username validation during account creation
    Given the client is on the account creation wizard
    And the user selects "Jami" as the account type
    When the user enters the desired username "<username>"
    Then the client displays the validation error "<error_message>"
    And the user cannot proceed with account creation

    Examples:
      | username       | error_message                              |
      | ab             | Username must be at least 3 characters     |
      | hi             | Username must be at least 3 characters     |
      | bad name       | Username contains invalid characters       |
      | inv@lid!       | Username contains invalid characters       |
      | carol_jami     | Username is already taken                  |

  @regression
  Scenario: Username already taken on nameserver
    Given the client is on the account creation wizard
    And the user selects "Jami" as the account type
    And the user enters the display name "Dave"
    When the user enters the desired username "taken_username"
    And the nameserver reports "taken_username" as already registered
    Then the client displays the message "Username is already taken"
    And the user cannot proceed with account creation

  # ---------------------------------------------------------------------------
  # SIP account creation
  # ---------------------------------------------------------------------------

  @smoke
  Scenario: Create a SIP account with valid credentials
    Given the client is on the account creation wizard
    When the user selects "SIP" as the account type
    And the user enters the SIP host "sip.example.org"
    And the user enters the SIP username "alice"
    And the user enters the SIP password "sip_pass_123"
    And the user confirms account creation
    Then the client emits an "accountAdded" signal
    And the new account appears in the account list
    And the account type is recorded as "SIP"

  @regression
  Scenario: Create a SIP account with invalid server credentials
    Given the client is on the account creation wizard
    When the user selects "SIP" as the account type
    And the user enters the SIP host "sip.example.org"
    And the user enters the SIP username "wronguser"
    And the user enters the SIP password "wrongpass"
    And the user confirms account creation
    And the SIP server rejects the credentials
    Then the client emits an "accountCreationFailed" signal
    And the client displays an authentication error
    And no new account is added to the account list

  # ---------------------------------------------------------------------------
  # JAMS account creation
  # ---------------------------------------------------------------------------

  @smoke
  Scenario: Create a JAMS account via an account manager URL
    Given the client is on the account creation wizard
    When the user selects "JAMS" as the account type
    And the user enters the account manager URL "https://jams.example.org"
    And the user enters the JAMS username "alice@example.org"
    And the user enters the JAMS password "jams_secure_pass"
    And the user confirms account creation
    Then the client emits an "accountAdded" signal
    And the new account appears in the account list
    And the account type is recorded as "JAMS"

  @regression
  Scenario: Create a JAMS account with an unreachable account manager
    Given the client is on the account creation wizard
    When the user selects "JAMS" as the account type
    And the user enters the account manager URL "https://unreachable.example.org"
    And the user enters the JAMS username "user@example.org"
    And the user enters the JAMS password "anypass"
    And the user confirms account creation
    And the account manager server is not reachable
    Then the client emits an "accountCreationFailed" signal
    And the client displays a network error message
    And no new account is added to the account list

  # ---------------------------------------------------------------------------
  # General failure handling
  # ---------------------------------------------------------------------------

  @regression
  Scenario: Account creation fails due to a network error
    Given the client is on the account creation wizard
    And the network is unavailable
    When the user selects "Jami" as the account type
    And the user enters the display name "Eve"
    And the user confirms account creation
    Then the client emits an "accountCreationFailed" signal
    And the client displays a network error message

  # ---------------------------------------------------------------------------
  # Multiple accounts
  # ---------------------------------------------------------------------------

  @regression
  Scenario: Create multiple accounts of different types
    Given the client already has a Jami account in the account list
    When the user opens the account creation wizard
    And the user selects "SIP" as the account type
    And the user enters valid SIP credentials
    And the user confirms account creation
    Then the client emits an "accountAdded" signal
    And both accounts appear in the account list
    And each account displays its correct type

  # ---------------------------------------------------------------------------
  # Parameterised creation across account types
  # ---------------------------------------------------------------------------

  @smoke
  Scenario Outline: Account appears in the account list after successful creation
    Given the client is on the account creation wizard
    When the user creates a "<account_type>" account with valid parameters
    Then the client emits an "accountAdded" signal
    And the account list contains an entry for the newly created account
    And the account status is "<initial_status>"

    Examples:
      | account_type | initial_status |
      | Jami         | ENABLED        |
      | SIP          | ENABLED        |
      | JAMS         | ENABLED        |
