@calls @audio
Feature: Audio Calls
  As a user of the Jami client
  I want to place and receive audio-only calls
  So that I can communicate with contacts using voice

  Background:
    Given the client is running
    And the user has an active account
    And the user has at least one contact

  # ─── Placing Outgoing Calls ────────────────────────────────────────────────

  @smoke
  Scenario: Place an audio-only call to a contact
    Given the user is on the contacts or conversations view
    When the user initiates an audio call to a contact
    Then the client emits a callStarted signal
    And the call is established in audio-only mode
    And the outgoing call view is displayed

  @smoke
  Scenario: Outgoing call shows ringing state
    When the user initiates an audio call to a contact
    Then the call status changes to ringing
    And the client emits a callStatusChanged signal with status "RINGING"
    And a ringing indication is visible to the user

  @smoke
  Scenario: Peer accepts the call and call connects
    Given the user has placed an outgoing audio call
    And the call is in the ringing state
    When the peer accepts the call
    Then the call status changes to connected
    And the client emits a callStatusChanged signal with status "CURRENT"
    And two-way audio is established

  @smoke
  Scenario: Peer declines the call and call ends
    Given the user has placed an outgoing audio call
    And the call is in the ringing state
    When the peer declines the call
    Then the call status changes to ended
    And the client emits a callEnded signal
    And the call view is dismissed

  @regression
  Scenario: Outgoing call times out with no answer
    Given the user has placed an outgoing audio call
    And the call is in the ringing state
    When the call timeout elapses without a response from the peer
    Then the call status changes to ended
    And the client emits a callEnded signal
    And a missed-call indication is shown to the user

  # ─── Receiving Incoming Calls ──────────────────────────────────────────────

  @smoke
  Scenario: Receive an incoming audio call
    When the peer initiates an audio call to the user
    Then the client emits a newCall signal
    And the incoming call notification is displayed
    And the call is in the ringing state

  @smoke
  Scenario: Incoming call shows caller information
    When the peer initiates an audio call to the user
    Then the incoming call view displays the caller's name or identifier
    And the incoming call view displays the caller's avatar or contact photo if available

  @smoke
  Scenario: Accept an incoming audio call
    Given an incoming audio call is ringing
    When the user accepts the call
    Then the call status changes to connected
    And the client emits a callStatusChanged signal with status "CURRENT"
    And two-way audio is established

  @smoke
  Scenario: Decline an incoming audio call
    Given an incoming audio call is ringing
    When the user declines the call
    Then the call status changes to ended
    And the client emits a callEnded signal
    And the incoming call view is dismissed

  # ─── Active Call Management ────────────────────────────────────────────────

  @smoke
  Scenario: End an active audio call
    Given an audio call is active and connected
    When the user ends the call
    Then the call status changes to ended
    And the client emits a callEnded signal
    And the call view is dismissed

  @smoke
  Scenario: Call duration timer starts when connected
    Given an outgoing audio call has been placed
    When the peer accepts the call
    Then the call duration timer starts from zero
    And the client emits a callStatusChanged signal with status "CURRENT"

  @smoke
  Scenario: Call duration displayed during an active call
    Given an audio call is active and connected
    Then a call duration timer is visible in the call view
    And the timer increments each second
    And the duration is displayed in a human-readable format

  # ─── Missed Calls & Edge Cases ─────────────────────────────────────────────

  @regression
  Scenario: Missed call notification when the user does not answer
    Given an incoming audio call is ringing
    When the call timeout elapses without the user answering
    Then the call is marked as missed
    And a missed-call notification is presented to the user
    And the missed call appears in the conversation history

  @regression
  Scenario: Call to an offline contact fails gracefully
    Given the user's contact is offline or unreachable
    When the user attempts to place an audio call to that contact
    Then the call attempt fails
    And the client displays an appropriate error or unavailable indication
    And no dangling call state remains in the client

  @smoke
  Scenario: Place an audio call from within a 1:1 conversation
    Given the user has an open 1:1 conversation with a contact
    When the user initiates an audio call from the conversation view
    Then the client places an audio call to that contact
    And the outgoing call view is displayed within or alongside the conversation

  @regression
  Scenario Outline: Multiple sequential calls complete without residual state
    Given the user has completed a previous audio call that ended "<end_reason>"
    When the user places a new audio call to a contact
    Then the new call is placed successfully
    And no state from the previous call is present in the call view

    Examples:
      | end_reason          |
      | user hung up        |
      | peer hung up        |
      | peer declined       |
      | call timed out      |
