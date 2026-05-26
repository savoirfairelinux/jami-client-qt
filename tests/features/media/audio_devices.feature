@media @audio
Feature: Audio Device Management
  As a user of the communication client
  I want to manage audio input, output, and ringtone devices
  So that I can control how I hear and am heard during calls and notifications

  Background:
    Given the client is running
    And at least one audio input device is connected
    And at least one audio output device is connected

  # ---------------------------------------------------------------------------
  # Audio Input (Microphone)
  # ---------------------------------------------------------------------------

  @audio-input @smoke
  Scenario: List available audio input devices
    When the user opens the audio device settings
    Then the client displays a list of available audio input devices
    And each listed device shows a human-readable name
    And the currently selected input device is visually indicated

  @audio-input @smoke
  Scenario: Select an audio input device
    Given the client has more than one audio input device available
    And the user is on the audio device settings page
    When the user selects a different audio input device
    Then the client uses the newly selected device as the active microphone
    And the selection is confirmed in the settings

  @audio-input @edge-case
  Scenario: Only one audio input device available
    Given exactly one audio input device is connected
    When the user opens the audio device settings
    Then that single device is shown as both available and selected
    And the input device selector reflects that no other choice exists

  # ---------------------------------------------------------------------------
  # Audio Output (Speaker)
  # ---------------------------------------------------------------------------

  @audio-output @smoke
  Scenario: List available audio output devices
    When the user opens the audio device settings
    Then the client displays a list of available audio output devices
    And each listed device shows a human-readable name
    And the currently selected output device is visually indicated

  @audio-output @smoke
  Scenario: Select an audio output device
    Given the client has more than one audio output device available
    And the user is on the audio device settings page
    When the user selects a different audio output device
    Then the client routes call audio to the newly selected device
    And the selection is confirmed in the settings

  # ---------------------------------------------------------------------------
  # Ringtone Output
  # ---------------------------------------------------------------------------

  @ringtone-output @smoke
  Scenario: List available ringtone output devices
    When the user opens the audio device settings
    Then the client displays a list of available ringtone output devices
    And the currently selected ringtone output device is visually indicated

  @ringtone-output @smoke
  Scenario: Select a ringtone output device
    Given the client has more than one audio output device available
    And the user is on the audio device settings page
    When the user selects a different ringtone output device
    Then incoming call ringtones are played through the newly selected device
    And the selection is confirmed in the settings

  @ringtone-output
  Scenario: Ringtone output can differ from call audio output
    Given the client has more than one audio output device available
    When the user selects device "A" as the call audio output
    And the user selects device "B" as the ringtone output device
    Then call audio plays through device "A"
    And ringtone audio plays through device "B"

  # ---------------------------------------------------------------------------
  # Persistence
  # ---------------------------------------------------------------------------

  @persistence @smoke
  Scenario Outline: Selected audio device persists across sessions
    Given the user has selected "<device_role>" device "<device_name>"
    When the user closes and restarts the client
    Then the client opens with "<device_name>" still selected as the "<device_role>" device

    Examples:
      | device_role     | device_name           |
      | audio input     | Built-in Microphone   |
      | audio output    | External Speakers     |
      | ringtone output | Built-in Speakers     |

  # ---------------------------------------------------------------------------
  # Hotplug — Disconnection
  # ---------------------------------------------------------------------------

  @hotplug @disconnection
  Scenario: Active audio input device is disconnected during a call
    Given an active call is in progress
    And the selected audio input device is "USB Microphone"
    When the device "USB Microphone" is physically disconnected
    Then the client switches to an available fallback audio input device
    And the call audio capture continues without crashing
    And the user is notified that the audio input device changed

  @hotplug @disconnection
  Scenario: Active audio output device is disconnected during a call
    Given an active call is in progress
    And the selected audio output device is "USB Headset"
    When the device "USB Headset" is physically disconnected
    Then the client switches to an available fallback audio output device
    And the call audio playback continues without crashing
    And the user is notified that the audio output device changed

  @hotplug @disconnection @edge-case
  Scenario: Last audio input device is disconnected
    Given exactly one audio input device is connected
    And it is selected as the active input device
    When that device is disconnected
    Then the client reports that no audio input device is available
    And the client does not crash
    And the user is informed that microphone input is unavailable

  # ---------------------------------------------------------------------------
  # Hotplug — Connection
  # ---------------------------------------------------------------------------

  @hotplug @connection
  Scenario: New audio input device connected while client is running
    Given the client is running with one audio input device
    When a new audio input device is connected to the system
    Then the new device appears in the audio input device list
    And the previously selected input device remains selected

  @hotplug @connection
  Scenario: New audio output device connected while client is running
    Given the client is running with one audio output device
    When a new audio output device is connected to the system
    Then the new device appears in the audio output device list
    And the previously selected output device remains selected
