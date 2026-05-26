@messaging
Feature: Text Messaging
  As a user of the Jami communication client
  I want to send and receive text messages in conversations
  So that I can communicate with peers in real time

  Background:
    Given the client is running
    And the user is authenticated with a valid account
    And the user has at least one established conversation

  # ---------------------------------------------------------------------------
  # Sending messages
  # ---------------------------------------------------------------------------

  @smoke
  Scenario: Send a text message in a 1:1 conversation
    Given the user has opened a 1:1 conversation with a peer
    When the user types "Hello, world!" in the message input
    And the user sends the message
    Then the message "Hello, world!" appears in the conversation timeline
    And the message is attributed to the user

  @smoke
  Scenario: Send a text message in a group conversation
    Given the user has opened a group conversation with multiple peers
    When the user types "Hi everyone!" in the message input
    And the user sends the message
    Then the message "Hi everyone!" appears in the conversation timeline
    And the message is attributed to the user
    And all peers in the group receive the message

  @smoke
  Scenario: Receive a text message from a peer
    Given the user has opened a 1:1 conversation with a peer
    When the peer sends the message "Hey there!"
    Then the message "Hey there!" appears in the conversation timeline
    And the message is attributed to the peer

  @regression
  Scenario: Message appears in conversation timeline
    Given the user has opened a conversation
    When the user sends the message "Timeline test"
    Then the message "Timeline test" is visible in the conversation timeline
    And the message is displayed in chronological order relative to other messages

  @regression
  Scenario: Send a multiline message
    Given the user has opened a conversation
    When the user composes a message with the following lines:
      | Line 1: First line  |
      | Line 2: Second line |
      | Line 3: Third line  |
    And the user sends the message
    Then the full multiline message is visible in the conversation timeline
    And each line break is preserved in the displayed message

  # ---------------------------------------------------------------------------
  # Delivery status
  # ---------------------------------------------------------------------------

  @regression
  Scenario Outline: Message delivery status tracking
    Given the user has opened a 1:1 conversation with an online peer
    When the user sends a message
    Then the message delivery status transitions through the following states in order:
      | sending   |
      | sent      |
      | delivered |
      | read      |

  @regression
  Scenario: Send message to offline peer — delivered when peer comes online
    Given the user has opened a 1:1 conversation with an offline peer
    When the user sends the message "Offline delivery test"
    Then the message delivery status is "sent"
    When the peer comes online
    Then the message delivery status transitions to "delivered"

  # ---------------------------------------------------------------------------
  # Message history and pagination
  # ---------------------------------------------------------------------------

  @regression
  Scenario: Load message history when opening a conversation
    Given the user has a conversation with existing message history
    When the user opens the conversation
    Then recent messages are loaded and displayed in the conversation timeline
    And the messages are displayed in chronological order

  @regression
  Scenario: Scroll up to load more messages (pagination)
    Given the user has opened a conversation with a long message history
    And the initial batch of recent messages is displayed
    When the user scrolls to the top of the conversation timeline
    Then the client requests older messages
    And the older messages are prepended to the conversation timeline
    And the scroll position is preserved after loading

  # ---------------------------------------------------------------------------
  # Input validation
  # ---------------------------------------------------------------------------

  @regression
  Scenario: Empty message cannot be sent
    Given the user has opened a conversation
    When the message input is empty
    Then the send action is disabled
    And attempting to send does not add any message to the timeline

  @regression
  Scenario: Very long message handling
    Given the user has opened a conversation
    When the user composes a message that is 10000 characters long
    And the user sends the message
    Then the full message is visible in the conversation timeline without truncation
    And the message delivery status eventually reaches "delivered"

  # ---------------------------------------------------------------------------
  # Ordering and unread counts
  # ---------------------------------------------------------------------------

  @regression
  Scenario: Messages ordered chronologically
    Given the user has opened a conversation
    When multiple messages are sent and received at different times
    Then all messages are displayed in ascending chronological order
    And no message appears before a message that was sent earlier

  @regression
  Scenario: Unread message count updates
    Given the user is not currently viewing a conversation
    When the peer sends 3 new messages to that conversation
    Then the conversation shows an unread message count of 3
    When the peer sends 2 more messages
    Then the unread message count increases to 5

  @smoke
  Scenario: Opening a conversation marks messages as read
    Given the user has a conversation with 5 unread messages
    When the user opens that conversation
    Then the unread message count for the conversation is reset to 0
    And the messages are marked as read
