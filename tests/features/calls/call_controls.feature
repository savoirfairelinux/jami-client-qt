@calls @controls
Feature: Call Controls
  As a user of the Jami client
  I want to control an active call using available in-call controls
  So that I can manage audio, video, hold state, and window behaviour during a call

  Background:
    Given the client is running
    And the user has an active account
    And a call is active and connected

  # ─── Microphone Mute / Unmute ──────────────────────────────────────────────

  @smoke
  Scenario: Mute the microphone during a call
    Given the microphone is currently unmuted
    When the user mutes the microphone
    Then the microphone mute state is LOCAL_MUTED
    And the mute indicator is visible in the call view
    And the user's audio is no longer transmitted to the peer

  @smoke
  Scenario: Unmute the microphone during a call
    Given the microphone mute state is LOCAL_MUTED
    When the user unmutes the microphone
    Then the microphone mute state is UNMUTED
    And the mute indicator is no longer shown
    And the user's audio is transmitted to the peer again

  @regression
  Scenario Outline: Microphone mute state reflects combined local and moderator state
    Given the microphone local mute state is "<local_state>"
    And the moderator mute state is "<moderator_state>"
    Then the combined microphone mute state is "<combined_state>"
    And the call view reflects the "<combined_state>" mute indicator

    Examples:
      | local_state | moderator_state | combined_state     |
      | unmuted     | not muted       | UNMUTED            |
      | muted       | not muted       | LOCAL_MUTED        |
      | unmuted     | muted           | MODERATOR_MUTED    |
      | muted       | muted           | BOTH_MUTED         |

  # ─── Hold / Resume ─────────────────────────────────────────────────────────

  @smoke
  Scenario: Hold an active call
    Given the call is not currently on hold
    When the user places the call on hold
    Then the call status changes to held
    And the call view indicates the call is on hold
    And audio transmission is paused in both directions

  @smoke
  Scenario: Resume a held call
    Given the call is currently on hold
    When the user resumes the call
    Then the call status changes to connected
    And the call view no longer shows the on-hold indication
    And audio transmission resumes in both directions

  # ─── DTMF ──────────────────────────────────────────────────────────────────

  @regression
  Scenario: Send a DTMF tone during an active call
    Given the call is active and connected
    When the user sends the DTMF tone "5"
    Then the client transmits the DTMF tone "5" over the call
    And no error is reported

  @regression
  Scenario Outline: Send multiple DTMF tones in sequence
    Given the call is active and connected
    When the user sends the DTMF sequence "<sequence>"
    Then each tone in "<sequence>" is transmitted in order
    And the call remains connected

    Examples:
      | sequence |
      | 1234     |
      | *9#      |
      | 0        |

  # ─── Push-to-Talk ──────────────────────────────────────────────────────────

  @regression
  Scenario: Push-to-talk keeps the microphone active while the button is held
    Given the microphone mute state is LOCAL_MUTED
    When the user presses and holds the push-to-talk control
    Then the microphone is temporarily unmuted
    And audio is transmitted to the peer while the control is held
    When the user releases the push-to-talk control
    Then the microphone returns to LOCAL_MUTED
    And audio transmission stops

  # ─── Picture-in-Picture ────────────────────────────────────────────────────

  @smoke
  Scenario: Pop out the call to a picture-in-picture window
    Given the call view is displayed in the main window
    When the user triggers the pop-out action
    Then the call is displayed in a floating picture-in-picture window
    And the main window no longer shows the call view as the primary content
    And the call audio and video continue uninterrupted

  @smoke
  Scenario: Pop the call back from PIP to the main window
    Given the call is displayed in a floating picture-in-picture window
    When the user triggers the pop-in action from the PIP window
    Then the call view is restored to the main window
    And the picture-in-picture window is closed
    And the call audio and video continue uninterrupted

  @regression
  Scenario: Close the PIP window while the call is active
    Given the call is displayed in a floating picture-in-picture window
    When the user closes the picture-in-picture window
    Then the call view is restored to the main window
    And the call remains active and connected
    And no call data is lost

  # ─── Call Information ──────────────────────────────────────────────────────

  @regression
  Scenario: View call quality and codec information
    Given the call is active and connected
    When the user opens the call information panel
    Then the panel displays the audio codec in use
    And the panel displays video codec information if the call has video
    And the panel displays network quality or signal indicators

  @regression
  Scenario: View advanced call information
    Given the call is active and connected
    When the user opens the advanced call information view
    Then the view displays the call identifier
    And the view displays the peer's identifier or URI
    And the view displays the current call duration
