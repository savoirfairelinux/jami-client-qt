@account
Feature: Account Deletion
  As a user of a Jami client
  I want to delete accounts I no longer need
  So that my account list stays relevant and my data is removed

  Background:
    Given the client has at least one account in the account list
    And the user is on the account management screen

  # ---------------------------------------------------------------------------
  # Basic deletion
  # ---------------------------------------------------------------------------

  @smoke
  Scenario: Delete an account from the account list
    Given the account list contains an account named "Alice"
    When the user selects the account "Alice"
    And the user chooses to delete the account
    And the user confirms the deletion prompt
    Then the client emits an "accountRemoved" signal for "Alice"
    And the account "Alice" no longer appears in the account list

  @regression
  Scenario: Deletion prompt is shown before removing an account
    Given the account list contains an account named "Bob"
    When the user selects the account "Bob"
    And the user chooses to delete the account
    Then the client displays a confirmation prompt warning that the action is irreversible
    And the account "Bob" is still present in the account list

  @regression
  Scenario: User cancels the deletion prompt — account is retained
    Given the account list contains an account named "Carol"
    When the user selects the account "Carol"
    And the user chooses to delete the account
    And the user cancels the deletion prompt
    Then no "accountRemoved" signal is emitted
    And the account "Carol" remains in the account list

  # ---------------------------------------------------------------------------
  # Edge case: last account
  # ---------------------------------------------------------------------------

  @smoke
  Scenario: Deleting the only account redirects to the account creation wizard
    Given the account list contains exactly one account named "Dave"
    When the user selects the account "Dave"
    And the user chooses to delete the account
    And the user confirms the deletion prompt
    Then the client emits an "accountRemoved" signal for "Dave"
    And the account list is empty
    And the client navigates to the account creation wizard

  # ---------------------------------------------------------------------------
  # Deletion during an active call
  # ---------------------------------------------------------------------------

  @regression
  Scenario: Deleting an account while it has an active call ends the call first
    Given the account list contains an account named "Eve"
    And the account "Eve" is currently in an active call with a peer
    When the user selects the account "Eve"
    And the user chooses to delete the account
    And the user confirms the deletion prompt
    Then the active call is terminated before deletion proceeds
    And the client emits an "accountRemoved" signal for "Eve"
    And the account "Eve" no longer appears in the account list

  # ---------------------------------------------------------------------------
  # Data clean-up
  # ---------------------------------------------------------------------------

  @regression
  Scenario: Associated conversations are removed when an account is deleted
    Given the account list contains an account named "Frank"
    And the account "Frank" has existing conversations
    When the user deletes the account "Frank" and confirms the prompt
    Then the client emits an "accountRemoved" signal for "Frank"
    And all conversations associated with "Frank" are no longer accessible

  @regression
  Scenario: Associated contacts are removed when an account is deleted
    Given the account list contains an account named "Grace"
    And the account "Grace" has contacts in its contact list
    When the user deletes the account "Grace" and confirms the prompt
    Then the client emits an "accountRemoved" signal for "Grace"
    And all contacts associated with "Grace" are no longer accessible

  # ---------------------------------------------------------------------------
  # Multiple accounts
  # ---------------------------------------------------------------------------

  @regression
  Scenario: Deleting one account does not affect other accounts
    Given the account list contains accounts "Alice" and "Bob"
    When the user deletes the account "Alice" and confirms the prompt
    Then the client emits an "accountRemoved" signal for "Alice"
    And the account "Alice" no longer appears in the account list
    And the account "Bob" is still present and functional in the account list
