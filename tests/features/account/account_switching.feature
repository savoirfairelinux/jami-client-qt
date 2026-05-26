@account
Feature: Account Switching
  As a user of a Jami client
  I want to switch between multiple accounts seamlessly
  So that I can manage separate identities in the same client session

  Background:
    Given the client has at least two accounts in the account list
    And all accounts are enabled

  # ---------------------------------------------------------------------------
  # Basic switching
  # ---------------------------------------------------------------------------

  @smoke
  Scenario: Switch from one account to another
    Given the active account is "Alice"
    When the user selects the account "Bob" from the account list
    Then the active account becomes "Bob"
    And the client emits an "accountStatusChanged" signal for "Bob"

  @smoke
  Scenario: Conversation list updates when switching accounts
    Given the active account is "Alice" with conversations from her contacts
    When the user switches to the account "Bob"
    Then the conversation list displays only conversations belonging to "Bob"
    And no conversations from "Alice" are shown

  # ---------------------------------------------------------------------------
  # Startup behaviour
  # ---------------------------------------------------------------------------

  @smoke
  Scenario: The client auto-selects the first account on startup
    Given the client has accounts "Alice" and "Bob" in the account list
    When the client starts up
    Then the active account is the first account in the list
    And the conversation list reflects that account's data

  # ---------------------------------------------------------------------------
  # Account ordering
  # ---------------------------------------------------------------------------

  @regression
  Scenario: Reorder accounts in the account list
    Given the account list order is "Alice", "Bob", "Carol"
    When the user moves "Carol" to the top of the account list
    Then the account list order becomes "Carol", "Alice", "Bob"
    And the reordered list is persisted after the client restarts

  # ---------------------------------------------------------------------------
  # Enable / disable
  # ---------------------------------------------------------------------------

  @smoke
  Scenario: Disable an account
    Given the active account is "Alice"
    When the user disables the account "Bob"
    Then the client emits an "accountStatusChanged" signal for "Bob" with status "DISABLED"
    And the account "Bob" is shown as disabled in the account list

  @regression
  Scenario: A disabled account does not receive messages
    Given the account "Bob" is disabled
    When a peer sends a message to "Bob"
    Then "Bob" does not receive the message
    And no notification is shown for the incoming message

  @regression
  Scenario: A disabled account does not receive incoming calls
    Given the account "Bob" is disabled
    When a peer calls "Bob"
    Then "Bob" does not receive the incoming call
    And no call notification is shown for "Bob"

  @smoke
  Scenario: Re-enable a disabled account
    Given the account "Bob" is currently disabled
    When the user enables the account "Bob"
    Then the client emits an "accountStatusChanged" signal for "Bob" with status "ENABLED"
    And the account "Bob" is shown as enabled in the account list
    And "Bob" is reachable by peers again

  # ---------------------------------------------------------------------------
  # Edge cases
  # ---------------------------------------------------------------------------

  @regression
  Scenario: Switching to a disabled account shows a disabled-state indicator
    Given the account list contains accounts "Alice" (enabled) and "Bob" (disabled)
    When the user selects the account "Bob"
    Then the client indicates that "Bob" is currently disabled
    And the user is offered an option to re-enable "Bob"

  @regression
  Scenario: Switching accounts does not interrupt an active call on the current account
    Given the active account is "Alice"
    And "Alice" is currently in an active call
    When the user switches the active view to "Bob"
    Then "Alice"'s active call continues uninterrupted
    And the conversation list shows "Bob"'s conversations
