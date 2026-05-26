@contacts @requests
Feature: Contact Requests (Trust Requests)
  As a user of the Jami client
  I want to manage incoming trust requests from peers
  So that I can control who is allowed to communicate with me

  Background:
    Given the client is running
    And the user has an active Jami account
    And the pending requests list is accessible

  # ─── Receiving Requests ────────────────────────────────────────────────────

  @smoke
  Scenario: User receives a trust request from an unknown peer
    When an unknown peer sends a trust request to the user's account
    Then the client registers the incoming trust request
    And the trust request appears in the pending requests list
    And the pending requests count increases by one

  @smoke
  Scenario: Trust request displays the sender's information
    Given an unknown peer named "ivan" has sent a trust request
    When the user views the pending requests list
    Then the trust request entry shows the peer's Jami ID
    And the trust request entry shows the peer's display name or a default label if unavailable

  # ─── Accepting Requests ────────────────────────────────────────────────────

  @smoke
  Scenario: Accept a trust request adds the contact to the list
    Given a trust request from peer "judy" is in the pending requests list
    When the user accepts the trust request from "judy"
    Then the client emits a "pendingContactAccepted" signal for "judy"
    And "judy" is added to the user's contact list
    And the trust request for "judy" is removed from the pending requests list

  @regression
  Scenario: Accepted contact can immediately send messages to the user
    Given a trust request from peer "kevin" is in the pending requests list
    When the user accepts the trust request from "kevin"
    Then "kevin" appears in the contact list
    And "kevin" is permitted to send messages to the user

  # ─── Declining Requests ────────────────────────────────────────────────────

  @smoke
  Scenario: Decline a trust request removes it from pending
    Given a trust request from peer "laura" is in the pending requests list
    When the user declines the trust request from "laura"
    Then the trust request for "laura" is removed from the pending requests list
    And "laura" is not added to the user's contact list
    And the client emits a "contactRemoved" signal for "laura"

  @regression
  Scenario: Declined peer cannot send messages to the user
    Given a trust request from peer "mike" has been declined
    When "mike" attempts to send a message to the user
    Then the message is not delivered to the user
    And "mike" does not appear in the user's contact list

  # ─── Ignoring Requests ─────────────────────────────────────────────────────

  @regression
  Scenario: Ignore a trust request leaves it in the pending list
    Given a trust request from peer "nancy" is in the pending requests list
    When the user dismisses the notification without accepting or declining
    Then the trust request for "nancy" remains in the pending requests list
    And "nancy" is not added to the user's contact list

  # ─── Multiple Pending Requests ─────────────────────────────────────────────

  @regression
  Scenario: Multiple pending trust requests are all listed
    Given trust requests from the following peers are received:
      | peer    |
      | oscar   |
      | peggy   |
      | quinn   |
    When the user views the pending requests list
    Then the pending requests list contains entries for "oscar", "peggy", and "quinn"
    And each entry is independently actionable

  @regression
  Scenario: Accepting one request does not affect other pending requests
    Given trust requests from peers "rachel" and "sam" are in the pending requests list
    When the user accepts the trust request from "rachel"
    Then "rachel" is moved to the contact list
    And the trust request from "sam" remains in the pending requests list

  # ─── Banned Contact Auto-Rejection ─────────────────────────────────────────

  @regression
  Scenario: Trust request from a banned contact is automatically rejected
    Given peer "tina" is on the user's banned contacts list
    When "tina" sends a trust request to the user
    Then the trust request from "tina" is not added to the pending requests list
    And "tina" remains on the banned contacts list
    And no notification is shown to the user for "tina"'s request

  # ─── Re-request After Decline ──────────────────────────────────────────────

  @regression
  Scenario: Peer sends a new trust request after a previous one was declined
    Given peer "uri" previously had a trust request that was declined
    When "uri" sends a new trust request to the user
    Then the new trust request from "uri" appears in the pending requests list
    And the user can accept or decline it independently of the previous request

  # ─── Parameterised Accept and Decline ─────────────────────────────────────

  @smoke
  Scenario Outline: Handle a trust request with a given action
    Given a trust request from peer "<peer>" is in the pending requests list
    When the user performs the "<action>" action on the request
    Then the pending request list result is "<list_outcome>"
    And the contact list result is "<contact_outcome>"

    Examples:
      | peer    | action  | list_outcome                        | contact_outcome                |
      | victor  | accept  | request removed from pending list   | contact added to contact list  |
      | wendy   | decline | request removed from pending list   | contact not in contact list    |
