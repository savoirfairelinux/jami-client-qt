@contacts @banning
Feature: Contact Banning
  As a user of the Jami client
  I want to ban and unban contacts
  So that I can prevent unwanted communication without deleting my account

  Background:
    Given the client is running
    And the user has an active Jami account
    And the contact list contains at least one contact

  # ─── Banning a Contact ─────────────────────────────────────────────────────

  @smoke
  Scenario: Ban a contact
    Given "alice" is in the user's contact list and is not banned
    When the user bans "alice"
    Then the client emits a "bannedStatusChanged" signal for "alice" with status "banned"
    And "alice" is marked as banned in the client's data model

  @smoke
  Scenario: Banned contact appears in the banned contacts list
    Given "alice" has been banned
    When the user views the banned contacts list
    Then "alice" appears in the banned contacts list

  @smoke
  Scenario: Banned contact is removed from the main contact list
    Given "bob" is in the user's contact list
    When the user bans "bob"
    Then "bob" no longer appears in the main contact list
    And "bob" appears in the banned contacts list

  # ─── Blocked Communication ─────────────────────────────────────────────────

  @regression
  Scenario: Banned contact cannot send messages to the user
    Given "carol" has been banned by the user
    When "carol" attempts to send a message to the user
    Then the message from "carol" is not delivered to the user
    And the user does not receive a notification for "carol"'s message

  @regression
  Scenario: Banned contact cannot call the user
    Given "dave" has been banned by the user
    When "dave" attempts to call the user
    Then the call from "dave" is not connected
    And the user does not receive a ringing notification for "dave"'s call

  @regression
  Scenario: Banned contact cannot send a new trust request
    Given "eve" has been banned by the user
    When "eve" sends a trust request to the user
    Then the trust request from "eve" is automatically rejected
    And the trust request does not appear in the pending requests list

  # ─── Unbanning a Contact ───────────────────────────────────────────────────

  @smoke
  Scenario: Unban a contact
    Given "frank" is on the banned contacts list
    When the user unbans "frank"
    Then the client emits a "bannedStatusChanged" signal for "frank" with status "unbanned"
    And "frank" is no longer on the banned contacts list

  @smoke
  Scenario: Unbanned contact returns to the contact list
    Given "grace" is on the banned contacts list
    When the user unbans "grace"
    Then "grace" appears in the main contact list
    And "grace" no longer appears in the banned contacts list

  @regression
  Scenario: Unbanned contact can send messages to the user again
    Given "henry" was previously banned and has now been unbanned
    When "henry" sends a message to the user
    Then the message is delivered to the user
    And the conversation with "henry" is accessible in the client

  # ─── Viewing the Banned List ───────────────────────────────────────────────

  @smoke
  Scenario: View the banned contacts list
    Given the user has previously banned the following contacts:
      | contact |
      | ivan    |
      | judy    |
    When the user navigates to the banned contacts list
    Then the banned list contains an entry for "ivan"
    And the banned list contains an entry for "judy"
    And neither "ivan" nor "judy" appears in the main contact list

  @regression
  Scenario: Banned contacts list is empty when no contacts are banned
    Given no contacts have been banned on the account
    When the user navigates to the banned contacts list
    Then the banned contacts list is empty
    And the client displays a "no banned contacts" indicator

  # ─── Ban a Contact With a Pending Trust Request ────────────────────────────

  @regression
  Scenario: Ban a contact who has a pending trust request
    Given a trust request from peer "kevin" is in the pending requests list
    When the user bans "kevin" from the pending requests list
    Then the trust request from "kevin" is removed from the pending requests list
    And "kevin" is added to the banned contacts list
    And "kevin" does not appear in the main contact list
    And the client emits a "bannedStatusChanged" signal for "kevin" with status "banned"

  # ─── Parameterised Ban and Unban ───────────────────────────────────────────

  @regression
  Scenario Outline: Ban and unban produces correct list membership
    Given "<contact>" is in the user's contact list and is not banned
    When the user bans "<contact>"
    Then "<contact>" appears in the banned list and not the contact list
    When the user unbans "<contact>"
    Then "<contact>" appears in the contact list and not the banned list

    Examples:
      | contact |
      | laura   |
      | mike    |
      | nancy   |
