@messaging
Feature: Message Editing
  As a user of the Jami communication client
  I want to edit messages I have already sent
  So that I can correct mistakes or update information without resending

  Background:
    Given the client is running
    And the user is authenticated with a valid account
    And the user has opened a conversation with a peer
    And the user has sent at least one message in the conversation

  # ---------------------------------------------------------------------------
  # Core editing behaviour
  # ---------------------------------------------------------------------------

  @smoke
  Scenario: Edit a sent message
    Given the user has sent the message "Original content"
    When the user initiates editing on that message
    And the user changes the text to "Edited content"
    And the user confirms the edit
    Then the message displays "Edited content" in the conversation timeline
    And the original text "Original content" is no longer visible as current content

  @smoke
  Scenario: Edited message shows edit indicator
    Given the user has sent the message "Before edit"
    When the user edits the message to "After edit"
    Then the message in the conversation timeline displays an edited indicator
    And the edited indicator is visible to both the user and the peer

  @regression
  Scenario: Edit replaces original content
    Given the user has sent the message "First version"
    When the user edits the message to "Second version"
    Then the conversation timeline shows "Second version"
    And the conversation timeline does not show "First version" as current content

  @regression
  Scenario: Cancel editing a message
    Given the user has sent the message "Unchanged message"
    When the user initiates editing on that message
    And the user modifies the text in the input field
    And the user cancels the edit
    Then the message in the conversation timeline still displays "Unchanged message"
    And no edited indicator is shown on the message
    And the message input returns to its default state

  # ---------------------------------------------------------------------------
  # Permissions
  # ---------------------------------------------------------------------------

  @regression
  Scenario: Cannot edit another user's message
    Given the peer has sent the message "Peer's message"
    When the user attempts to initiate editing on the peer's message
    Then the edit action is not available for that message
    And the message content remains "Peer's message"

  # ---------------------------------------------------------------------------
  # Edit history
  # ---------------------------------------------------------------------------

  @regression
  Scenario: Edit history preserved
    Given the user has sent the message "Version one"
    When the user edits the message to "Version two"
    And the user edits the message again to "Version three"
    Then the message displays "Version three"
    And the edited indicator is shown
    And the edit history is accessible and contains at least the previous versions

  # ---------------------------------------------------------------------------
  # Group conversations
  # ---------------------------------------------------------------------------

  @regression
  Scenario: Edit a message in a group conversation
    Given the user has opened a group conversation with multiple peers
    And the user has sent the message "Group original"
    When the user edits the message to "Group edited"
    Then the message displays "Group edited" in the group conversation timeline
    And the edited indicator is visible to all participants in the group
    And no other participant's message is affected
