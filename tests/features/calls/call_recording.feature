@calls @recording
Feature: Call Recording
  As a user of the Jami client
  I want to record active calls
  So that I can keep a local record of conversations

  Background:
    Given the client is running
    And the user has an active account
    And a call is active and connected

  # ─── Starting Recording ────────────────────────────────────────────────────

  @smoke
  Scenario: Start recording an active call
    Given the call is not currently being recorded
    When the user starts recording the call
    Then the client emits a recordingStateChanged signal
    And the recording is in progress
    And the call continues uninterrupted

  @smoke
  Scenario: Recording indicator is shown while recording is active
    Given the user has started recording the call
    Then a recording indicator is visible in the call view
    And the indicator clearly distinguishes the call as being recorded

  # ─── Stopping Recording ────────────────────────────────────────────────────

  @smoke
  Scenario: Stop recording an active call
    Given the call is currently being recorded
    When the user stops recording
    Then the client emits a recordingStateChanged signal
    And the recording stops
    And the call continues uninterrupted

  @smoke
  Scenario: Recording indicator is hidden after stopping
    Given the call was being recorded
    When the user stops recording
    Then the recording indicator is no longer visible in the call view

  # ─── Visibility to Participants ────────────────────────────────────────────

  @regression
  Scenario: All participants see the recording indicator when recording is active
    Given a call is active with multiple participants
    When any participant starts recording the call
    Then the recording indicator is shown in every participant's call view
    And the client emits a remoteRecordersChanged signal on all participants' clients

  # ─── Remote Recording Notifications ───────────────────────────────────────

  @regression
  Scenario: User receives a notification when the peer starts recording
    Given the peer is not currently recording the call
    When the peer starts recording the call
    Then the client emits a remoteRecordersChanged signal
    And the user's call view shows a notification that the peer has started recording

  @regression
  Scenario: Notification is updated when the peer stops recording
    Given the peer is currently recording the call
    When the peer stops recording
    Then the client emits a remoteRecordersChanged signal
    And the remote recording notification is removed or updated in the user's call view

  @regression
  Scenario Outline: Remote recording notification reflects current recorder count
    Given a conference call is active with "<initial_recorders>" participants recording
    When "<recorders_after>" participants are recording
    Then the remote recording notification indicates that "<recorders_after>" remote participants are recording

    Examples:
      | initial_recorders | recorders_after |
      | 0                 | 1               |
      | 1                 | 2               |
      | 2                 | 1               |
      | 1                 | 0               |

  # ─── Conference Recording ──────────────────────────────────────────────────

  @regression
  Scenario: Record a conference call
    Given a conference call is active with multiple participants
    When the user starts recording the conference
    Then the recording captures all active audio streams
    And the recording indicator is visible in the conference view
    And all participants' clients show the recording indicator

  # ─── Recording Persistence ─────────────────────────────────────────────────

  @regression
  Scenario: Recording file is saved after the call ends
    Given the user recorded the call
    When the call ends
    Then the recording file is saved to the local device
    And the client indicates where the recording has been saved
    And the recording file is accessible and not empty
