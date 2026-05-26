@account
Feature: Account Import and Export
  As a user of a Jami client
  I want to export my account to an archive and import it on another device
  So that I can back up and restore my identity

  # ---------------------------------------------------------------------------
  # Export
  # ---------------------------------------------------------------------------

  @smoke
  Scenario: Export a Jami account to an archive file
    Given the client has an active Jami account "Alice"
    And the user is on the account settings screen for "Alice"
    When the user initiates an account export
    And the user selects a destination path for the archive
    And the user confirms the export without setting a password
    Then an archive file is created at the specified destination
    And the archive file is a valid Jami account archive

  @smoke
  Scenario: Export a Jami account with password protection
    Given the client has an active Jami account "Alice"
    And the user is on the account settings screen for "Alice"
    When the user initiates an account export
    And the user sets the export password "ExportP@ss1"
    And the user confirms the export
    Then an archive file is created at the specified destination
    And the archive file is encrypted with the password "ExportP@ss1"

  @regression
  Scenario: Export is cancelled — no archive file is created
    Given the client has an active Jami account "Alice"
    When the user initiates an account export
    And the user cancels the export dialog
    Then no archive file is written to disk

  # ---------------------------------------------------------------------------
  # Import
  # ---------------------------------------------------------------------------

  @smoke
  Scenario: Import a Jami account from an unprotected archive file
    Given a valid Jami archive file exists at a known path
    And the archive is not password-protected
    When the user opens the account import wizard
    And the user selects the archive file
    And the user confirms the import without entering a password
    Then the client emits an "accountAdded" signal
    And the imported account appears in the account list
    And the account details match the original exported account

  @smoke
  Scenario: Import a Jami account from a password-protected archive with the correct password
    Given a valid Jami archive file exists at a known path
    And the archive is protected with the password "ExportP@ss1"
    When the user opens the account import wizard
    And the user selects the archive file
    And the user enters the archive password "ExportP@ss1"
    And the user confirms the import
    Then the client emits an "accountAdded" signal
    And the imported account appears in the account list

  @regression
  Scenario: Import a Jami account with an incorrect archive password
    Given a valid Jami archive file exists at a known path
    And the archive is protected with a password
    When the user opens the account import wizard
    And the user selects the archive file
    And the user enters an incorrect archive password "WrongP@ss!"
    And the user confirms the import
    Then the client displays an "incorrect password" error
    And no new account is added to the account list

  @regression
  Scenario: Import fails when the archive file is corrupted
    Given a corrupted or invalid archive file exists at a known path
    When the user opens the account import wizard
    And the user selects the corrupted archive file
    And the user confirms the import
    Then the client displays an import error message
    And no new account is added to the account list

  @regression
  Scenario: Import fails when no archive file is selected
    When the user opens the account import wizard
    And the user does not select an archive file
    Then the import confirmation action is not available
    And no new account is added to the account list

  # ---------------------------------------------------------------------------
  # Wizard-based backup import flow
  # ---------------------------------------------------------------------------

  @smoke
  Scenario: Import an account via the backup restore wizard on first launch
    Given the client has no accounts configured
    When the user selects "Import from backup" in the account creation wizard
    And the user selects a valid archive file
    And the user enters the correct archive password if required
    And the user completes the wizard
    Then the client emits an "accountAdded" signal
    And the restored account appears in the account list
    And the client navigates to the main screen for that account

  # ---------------------------------------------------------------------------
  # Post-import state
  # ---------------------------------------------------------------------------

  @regression
  Scenario: Imported account does not duplicate an existing account with the same identity
    Given the client already has an account imported from archive "alice.gz"
    When the user attempts to import the same archive "alice.gz" again
    Then the client informs the user that the account already exists
    And no duplicate account is added to the account list

  @regression
  Scenario Outline: Export and re-import round-trip preserves account identity
    Given the client has an active Jami account with display name "<display_name>"
    When the user exports the account to an archive with password "<password>"
    And the user imports the archive using password "<password>"
    Then the imported account has the display name "<display_name>"
    And the imported account has the same Jami ID as the original

    Examples:
      | display_name | password     |
      | Alice        | secret123    |
      | Bob Smith    |              |
      | 日本語テスト    | p@ssw0rd!    |
