@account
Feature: Account Migration
  As a user of a Jami client
  I want outdated accounts to be migrated automatically
  So that they remain functional after client or protocol upgrades

  # ---------------------------------------------------------------------------
  # Detection at startup
  # ---------------------------------------------------------------------------

  @smoke
  Scenario: Detect a single account needing migration at startup
    Given the client stores an account in a legacy format
    When the client starts up
    Then the client detects that the account requires migration
    And the client presents the migration prompt to the user

  @regression
  Scenario: No migration prompt when all accounts are up to date
    Given all accounts stored by the client are in the current format
    When the client starts up
    Then no migration prompt is displayed
    And the client proceeds directly to the main screen

  # ---------------------------------------------------------------------------
  # Successful migration
  # ---------------------------------------------------------------------------

  @smoke
  Scenario: Successfully migrate an account that requires migration
    Given the client has detected an account "Alice" that needs migration
    And the user is presented with the migration prompt for "Alice"
    When the user provides the account password if required
    And the user confirms the migration
    Then the client emits a "migrationEnded" signal with status "success" for "Alice"
    And the account "Alice" is updated to the current format
    And the account "Alice" remains in the account list and is functional

  @smoke
  Scenario: Migrate an account protected by a password
    Given the client has detected a password-protected account "Bob" that needs migration
    When the user enters the correct account password for "Bob"
    And the user confirms the migration
    Then the client emits a "migrationEnded" signal with status "success" for "Bob"
    And the account "Bob" is accessible after migration

  @regression
  Scenario: Migration fails when the wrong password is provided
    Given the client has detected a password-protected account "Bob" that needs migration
    When the user enters an incorrect account password for "Bob"
    And the user confirms the migration
    Then the client emits a "migrationEnded" signal with status "failure" for "Bob"
    And the client displays a migration failure error
    And the user is offered a chance to retry with the correct password

  # ---------------------------------------------------------------------------
  # Failure handling
  # ---------------------------------------------------------------------------

  @regression
  Scenario: Migration failure leaves the account intact and reports an error
    Given the client has detected an account "Carol" that needs migration
    When a migration error occurs during the migration of "Carol"
    Then the client emits a "migrationEnded" signal with status "failure" for "Carol"
    And the client displays a descriptive migration failure message
    And the original account data for "Carol" is not corrupted

  # ---------------------------------------------------------------------------
  # Multiple accounts
  # ---------------------------------------------------------------------------

  @regression
  Scenario: Multiple accounts needing migration are queued and processed in order
    Given the client stores accounts "Alice", "Bob", and "Carol" all in a legacy format
    When the client starts up
    Then the client detects all three accounts as requiring migration
    And the client presents a migration prompt for the first account "Alice"
    When the migration for "Alice" completes successfully
    Then the client presents a migration prompt for the next account "Bob"
    When the migration for "Bob" completes successfully
    Then the client presents a migration prompt for the next account "Carol"

  @regression
  Scenario: Migrating one account does not affect accounts that do not need migration
    Given the client has account "Alice" (legacy format) and account "Bob" (current format)
    When the client migrates account "Alice" successfully
    Then the account "Bob" is unaffected and remains functional

  # ---------------------------------------------------------------------------
  # Skip / dismiss
  # ---------------------------------------------------------------------------

  @regression
  Scenario: User dismisses the migration prompt — account remains in legacy state
    Given the client has detected an account "Dave" that needs migration
    When the user dismisses the migration prompt for "Dave"
    Then no "migrationEnded" signal is emitted for "Dave"
    And the account "Dave" remains in the account list in its legacy state
    And the client displays a warning that the account may not function correctly

  # ---------------------------------------------------------------------------
  # Completion notification
  # ---------------------------------------------------------------------------

  @smoke
  Scenario: Client notifies the user when all pending migrations are finished
    Given the client has detected accounts "Alice" and "Bob" as requiring migration
    When both "Alice" and "Bob" are migrated successfully
    Then the client displays a notification that all account migrations are complete
    And the client navigates to the main screen
