@conversations
Feature: Conversation Requests and Invitations
  As a user of the client
  I want to manage incoming conversation invitations
  So that I can control who can reach me in group conversations

  Background:
    Given the client is running
    And the user is authenticated with a valid account

  # ── Receiving Invitations ──────────────────────────────────────────────────

  @smoke
  Scenario: Receive a conversation invitation from a peer
    When a peer sends the user an invitation to a group conversation "Friends Chat"
    Then the client receives the invitation from the peer
    And the invitation is visible to the user

  @smoke
  Scenario: A received invitation appears in the requests section
    When a peer sends the user an invitation to a group conversation "Friends Chat"
    Then the invitation from that peer appears in the requests section
    And the requests section shows a count of at least 1 pending invitation

  # ── Accepting / Declining / Blocking ──────────────────────────────────────

  @smoke
  Scenario: Accepting a conversation invitation moves it to the main conversation list
    Given the user has a pending invitation to "Friends Chat" from a peer
    When the user accepts the invitation
    Then "Friends Chat" appears in the main conversation list
    And "Friends Chat" is no longer listed in the requests section
    And the conversation is ready to send messages

  @smoke
  Scenario: Declining a conversation invitation removes it from the requests section
    Given the user has a pending invitation to "Project Room" from a peer
    When the user declines the invitation
    Then "Project Room" is removed from the requests section
    And "Project Room" does not appear in the main conversation list

  @regression
  Scenario: Blocking a conversation invitation blocks the sender
    Given the user has a pending invitation to "Spam Group" from a peer
    When the user blocks the invitation
    Then the invitation is removed from the requests section
    And the peer is added to the user's block list
    And the client does not display future invitations from that peer

  # ── Multiple Invitations ───────────────────────────────────────────────────

  @regression
  Scenario: Multiple pending invitations are all listed in the requests section
    Given the following peers have sent the user group conversation invitations:
      | peer   | conversation  |
      | PeerA  | Group Alpha   |
      | PeerB  | Group Beta    |
      | PeerC  | Group Gamma   |
    Then the requests section lists all 3 pending invitations
    And each invitation shows the conversation name and inviting peer

  @regression
  Scenario: Accepting one invitation does not affect other pending invitations
    Given the user has pending invitations from "PeerA" to "Group Alpha" and from "PeerB" to "Group Beta"
    When the user accepts the invitation to "Group Alpha"
    Then "Group Alpha" appears in the main conversation list
    And the invitation to "Group Beta" remains in the requests section

  # ── Auto-rejection ────────────────────────────────────────────────────────

  @regression
  Scenario: An invitation from a banned contact is automatically rejected
    Given the user has banned a contact "MaliciousPeer"
    When "MaliciousPeer" sends the user an invitation to "Unwanted Group"
    Then the invitation is automatically rejected
    And "Unwanted Group" does not appear in the requests section
    And "Unwanted Group" does not appear in the main conversation list

  @regression
  Scenario Outline: Invitation response actions produce the correct outcome
    Given the user has a pending invitation to "<conversation>" from a peer
    When the user performs the "<action>" action on the invitation
    Then the invitation is no longer in the requests section
    And the main conversation list "<contains_conversation>" the conversation

    Examples:
      | conversation  | action  | contains_conversation |
      | Alpha Group   | accept  | contains              |
      | Beta Group    | decline | does not contain      |
      | Gamma Group   | block   | does not contain      |
