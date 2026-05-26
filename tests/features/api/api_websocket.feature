@api @websocket
Feature: API WebSocket
  As an integrator or developer
  I want to receive real-time events over a WebSocket connection
  So that I can react to account, conversation, and call changes without polling

  Background:
    Given the client is running
    And the user has an active account
    And the API server is running
    And a valid API bearer token exists for the account

  # ─── Connection ──────────────────────────────────────────────────────────

  @connection @smoke
  Scenario: Connect to the WebSocket with valid authentication
    When an external client opens a WebSocket connection to the API server
    And provides the valid bearer token during the handshake
    Then the WebSocket connection is established successfully
    And the server acknowledges the connection

  @connection @smoke
  Scenario: Reject a WebSocket connection without authentication
    When an external client opens a WebSocket connection to the API server
    And provides no bearer token during the handshake
    Then the server rejects the connection
    And the connection is closed with an authentication error

  @connection
  Scenario: Reject a WebSocket connection with an invalid token
    When an external client opens a WebSocket connection to the API server
    And provides an invalid bearer token during the handshake
    Then the server rejects the connection
    And the connection is closed with an authentication error

  # ─── Real-Time Events ────────────────────────────────────────────────────

  @events @account @smoke
  Scenario: Receive real-time account events via WebSocket
    Given a WebSocket connection is open with a valid bearer token
    When an account-level change occurs (such as a profile update)
    Then the connected WebSocket client receives an account event message
    And the event message contains the account identifier
    And the event message contains the event type

  @events @conversations @smoke
  Scenario: Receive real-time conversation events via WebSocket
    Given a WebSocket connection is open with a valid bearer token
    And the account has an existing conversation
    When a new message is received in the conversation
    Then the connected WebSocket client receives a conversation event message
    And the event message contains the conversation identifier
    And the event message contains the event type

  @events @calls @smoke
  Scenario: Receive real-time call events via WebSocket
    Given a WebSocket connection is open with a valid bearer token
    When an incoming call arrives for the account
    Then the connected WebSocket client receives a call event message
    And the event message contains the call identifier
    And the event message contains the event type

  # ─── Multiple Clients ────────────────────────────────────────────────────

  @multi-client
  Scenario: Multiple WebSocket clients receive the same events
    Given two separate WebSocket connections are open for the same account
    Both authenticated with valid but distinct bearer tokens
    When a conversation event occurs for the account
    Then both WebSocket clients receive the event message
    And the event content is identical for both clients

  # ─── Reconnection ────────────────────────────────────────────────────────

  @reconnection
  Scenario: WebSocket disconnection and reconnection
    Given a WebSocket connection is open with a valid bearer token
    When the connection is dropped by the client
    And the external client reconnects with the same valid bearer token
    Then the new WebSocket connection is established successfully
    And the client resumes receiving real-time events

  # ─── Token Revocation Impact ─────────────────────────────────────────────

  @security @smoke
  Scenario: WebSocket connection is closed when its token is revoked
    Given a WebSocket connection is open authenticated with token "ws-token"
    When the user revokes "ws-token"
    Then the active WebSocket connection authenticated with "ws-token" is closed
    And subsequent reconnection attempts using "ws-token" are rejected

  # ─── Event Type Coverage ─────────────────────────────────────────────────

  @events
  Scenario Outline: WebSocket broadcasts events for different domains
    Given a WebSocket connection is open with a valid bearer token
    When a <domain> event of type "<event_type>" is triggered
    Then the WebSocket client receives a message with domain "<domain>" and type "<event_type>"

    Examples:
      | domain       | event_type              |
      | account      | profile-updated         |
      | account      | registration-changed    |
      | conversation | message-received        |
      | conversation | conversation-created    |
      | conversation | member-joined           |
      | call         | call-incoming           |
      | call         | call-state-changed      |
      | call         | call-ended              |
