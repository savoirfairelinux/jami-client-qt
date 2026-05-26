@contacts
Feature: Contact Management
  As a user of the Jami client
  I want to add, remove, and view contacts on my account
  So that I can communicate with the people I trust

  Background:
    Given the client is running
    And the user has an active Jami account
    And the contact list is visible

  # ─── Adding Contacts ───────────────────────────────────────────────────────

  @smoke
  Scenario: Add a contact by Jami ID
    When the user initiates adding a new contact
    And the user enters the Jami ID "3a5f8c0e9b2d7a4f1e6c3b8d5a2f9e7c4b1d8a5f2e9c6b3d0a7f4e1c8b5d2a9f"
    And the user confirms the add contact action
    Then the client emits a "contactAdded" signal for the entered Jami ID
    And a trust request is sent to the peer with that Jami ID

  @smoke
  Scenario: Add a contact by registered username
    When the user initiates adding a new contact
    And the user enters the registered username "alice"
    And the nameserver resolves "alice" to a valid Jami ID
    And the user confirms the add contact action
    Then the client emits a "contactAdded" signal for the resolved Jami ID
    And a trust request is sent to the peer identified by "alice"

  @smoke
  Scenario: Contact appears in the contact list after adding
    Given the user has sent a trust request to a peer
    When the peer accepts the trust request
    Then the client emits a "contactAdded" signal
    And the peer appears in the contact list
    And the contact entry displays the peer's display name or Jami ID

  # ─── Removing Contacts ─────────────────────────────────────────────────────

  @smoke
  Scenario: Remove a contact from the list
    Given "alice" is in the user's contact list
    When the user removes "alice" from the contact list
    Then the client emits a "contactRemoved" signal for "alice"
    And "alice" no longer appears in the contact list

  @regression
  Scenario: Contact disappears from the list after removal
    Given "bob" is in the user's contact list
    And the user is viewing the contact list
    When the user removes "bob"
    Then "bob" is absent from the contact list immediately after removal
    And no orphaned entry for "bob" remains in the list

  # ─── Viewing Contact Details ───────────────────────────────────────────────

  @smoke
  Scenario: View contact details showing name, ID, and avatar
    Given "carol" is in the user's contact list
    When the user opens the detail view for "carol"
    Then the client displays "carol"'s display name
    And the client displays "carol"'s Jami ID
    And the client displays "carol"'s avatar or a default placeholder avatar

  # ─── Presence ──────────────────────────────────────────────────────────────

  @smoke
  Scenario: Contact comes online and presence indicator updates
    Given "dave" is in the user's contact list
    And "dave" is currently shown as offline
    When "dave" connects to the network
    Then the client emits a "contactUpdated" signal for "dave"
    And the presence indicator for "dave" changes to online

  @smoke
  Scenario: Contact goes offline and presence indicator updates
    Given "eve" is in the user's contact list
    And "eve" is currently shown as online
    When "eve" disconnects from the network
    Then the client emits a "contactUpdated" signal for "eve"
    And the presence indicator for "eve" changes to offline

  # ─── Duplicate Prevention ──────────────────────────────────────────────────

  @regression
  Scenario: Adding an already-existing contact does not create a duplicate
    Given "frank" is already in the user's contact list
    When the user attempts to add "frank" again using the same Jami ID
    Then no duplicate entry for "frank" appears in the contact list
    And the client indicates that "frank" is already a contact
    And no additional trust request is sent to "frank"

  # ─── Profile Updates ───────────────────────────────────────────────────────

  @regression
  Scenario: Contact profile update is reflected in the contact list
    Given "grace" is in the user's contact list with display name "Grace"
    When "grace" updates their profile with a new display name "Grace M."
    Then the client emits a "profileUpdated" signal for "grace"
    And the contact list entry for "grace" shows the updated display name "Grace M."

  @regression
  Scenario: Contact avatar update is reflected in the contact list
    Given "henry" is in the user's contact list
    When "henry" updates their profile avatar
    Then the client emits a "profileUpdated" signal for "henry"
    And the contact list entry for "henry" displays the new avatar

  # ─── Parameterised Add Contact ─────────────────────────────────────────────

  @regression
  Scenario Outline: Add a contact via different identifier formats
    When the user initiates adding a new contact
    And the user enters the identifier "<identifier>"
    And the identifier resolves successfully
    And the user confirms the add contact action
    Then the client emits a "contactAdded" signal
    And the contact is added for the account "<account_type>"

    Examples:
      | identifier                                                               | account_type |
      | 3a5f8c0e9b2d7a4f1e6c3b8d5a2f9e7c4b1d8a5f2e9c6b3d0a7f4e1c8b5d2a9f | Jami         |
      | alice_jami                                                               | Jami         |
      | ring:3a5f8c0e9b2d7a4f1e6c3b8d5a2f9e7c4b1d8a5f2e9c6b3d0a7f4e1c8b5d2a9f | Jami         |
