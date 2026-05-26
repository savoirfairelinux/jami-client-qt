@messaging
Feature: Message Reactions
  As a user of the Jami communication client
  I want to add and remove emoji reactions to messages
  So that I can express quick responses without sending a full reply

  Background:
    Given the client is running
    And the user is authenticated with a valid account
    And the user has opened a conversation with at least one peer
    And there is at least one message visible in the conversation timeline

  # ---------------------------------------------------------------------------
  # Adding reactions
  # ---------------------------------------------------------------------------

  @smoke
  Scenario: Add an emoji reaction to a message
    Given a message is visible in the conversation timeline
    When the user adds the reaction "👍" to that message
    Then the reaction "👍" is displayed on the message
    And the reaction count for "👍" on that message is 1

  @regression
  Scenario: Add multiple different reactions to the same message
    Given a message is visible in the conversation timeline
    When the user adds the reaction "👍" to the message
    And the user adds the reaction "❤️" to the message
    And the user adds the reaction "😂" to the message
    Then the reactions "👍", "❤️", and "😂" are all displayed on the message
    And each reaction shows a count of 1

  @regression
  Scenario: React to a message in a group conversation
    Given the user has opened a group conversation with multiple peers
    And a message is visible in the group conversation timeline
    When the user adds the reaction "🎉" to that message
    Then the reaction "🎉" is displayed on the message for all participants
    And the reaction is attributed to the user

  # ---------------------------------------------------------------------------
  # Reaction counts and multi-user
  # ---------------------------------------------------------------------------

  @regression
  Scenario: Multiple users react to the same message with the same emoji
    Given a message is visible in the conversation timeline
    And the user has already added the reaction "👍" to the message
    When the peer also adds the reaction "👍" to the same message
    Then the reaction "👍" is displayed on the message
    And the reaction count for "👍" on that message is 2

  @smoke
  Scenario: Reaction count displayed on message
    Given a message is visible in the conversation timeline
    When the user adds the reaction "🔥" to that message
    Then the reaction "🔥" is shown with a visible count indicator
    And the count accurately reflects the number of users who reacted with "🔥"

  # ---------------------------------------------------------------------------
  # Removing reactions
  # ---------------------------------------------------------------------------

  @smoke
  Scenario: Remove own reaction from a message
    Given the user has added the reaction "👍" to a message
    When the user removes the reaction "👍" from that message
    Then the reaction "👍" is no longer attributed to the user on that message
    And if the user was the only one who reacted with "👍", the reaction is removed from the display

  @regression
  Scenario: Remove one reaction while others remain
    Given the user has added the reactions "👍" and "❤️" to a message
    When the user removes the reaction "👍" from that message
    Then the reaction "👍" is no longer shown for the user
    And the reaction "❤️" remains displayed on the message

  # ---------------------------------------------------------------------------
  # Viewing reactions
  # ---------------------------------------------------------------------------

  @regression
  Scenario: View all reactions on a message
    Given multiple reactions have been added to a message by different participants
    When the user views the reactions on that message
    Then all distinct emoji reactions are displayed
    And each reaction shows the correct count of participants who used it
    And it is possible to identify which participants reacted with each emoji
