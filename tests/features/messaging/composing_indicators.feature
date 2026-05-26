@messaging
Feature: Composing Indicators
  As a user of the Jami communication client
  I want to see when peers are typing
  So that I know a response is being composed before it arrives

  Background:
    Given the client is running
    And the user is authenticated with a valid account
    And the composingStatusChanged signal is observed
    And the user has opened a conversation

  # ---------------------------------------------------------------------------
  # Peer typing — indicator visibility
  # ---------------------------------------------------------------------------

  @smoke
  Scenario: Peer starts typing — composing indicator shown
    Given the user is in a 1:1 conversation with a peer
    When the peer begins typing a message
    Then a composing indicator is displayed in the conversation
    And the composing indicator is associated with the peer

  @smoke
  Scenario: Peer stops typing — composing indicator hidden
    Given the composing indicator is currently shown for a peer
    When the peer stops typing and sends no message
    Then the composing indicator disappears from the conversation

  @regression
  Scenario: Composing indicator disappears after peer sends message
    Given the composing indicator is currently shown for a peer
    When the peer sends their message
    Then the composing indicator disappears
    And the peer's message appears in the conversation timeline

  @regression
  Scenario: Composing indicator timeout — auto-hide after inactivity
    Given the peer began typing and the composing indicator is shown
    When the peer has not typed anything for an extended period without sending
    Then the composing indicator automatically disappears
    And no further notification is required from the peer to hide it

  # ---------------------------------------------------------------------------
  # User typing — status sent to peer
  # ---------------------------------------------------------------------------

  @regression
  Scenario: User typing sends composing status to peer
    Given the user is in a 1:1 conversation
    When the user begins typing in the message input
    Then the client sends a composing status notification to the peer
    And the peer's client displays a composing indicator for the user

  @regression
  Scenario: User stops typing — composing status cleared
    Given the user has been typing and the peer's client shows a composing indicator
    When the user clears the message input without sending
    Then the client sends a composing-stopped notification to the peer
    And the peer's client hides the composing indicator for the user

  # ---------------------------------------------------------------------------
  # Group conversations
  # ---------------------------------------------------------------------------

  @regression
  Scenario: Composing indicator in group conversation shows who is typing
    Given the user has opened a group conversation with multiple peers
    When one peer begins typing
    Then the composing indicator identifies that specific peer by name or avatar
    And no other peer is shown as typing

  @regression
  Scenario: Multiple peers typing simultaneously in group
    Given the user has opened a group conversation with multiple peers
    When peer A begins typing
    And peer B also begins typing before peer A has stopped or sent a message
    Then the composing indicator shows that both peer A and peer B are typing
    And the indicator updates when either peer stops typing or sends a message

  @regression
  Scenario: Composing indicator in group clears individually
    Given peer A and peer B are both shown as typing in a group conversation
    When peer A sends their message
    Then the composing indicator no longer shows peer A as typing
    And the composing indicator still shows peer B as typing
