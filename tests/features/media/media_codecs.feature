@media @codecs
Feature: Media Codec Management
  As a user of the communication client
  I want to manage audio and video codecs per account
  So that I can control call quality, compatibility, and bandwidth usage

  Background:
    Given the client is running
    And the user has at least one configured account
    And the user has opened the codec settings for that account

  # ---------------------------------------------------------------------------
  # Audio Codecs — Viewing
  # ---------------------------------------------------------------------------

  @audio-codecs @smoke
  Scenario: View list of available audio codecs for an account
    When the user navigates to the audio codec section of the account settings
    Then the client displays a list of audio codecs supported for that account
    And each codec entry shows at minimum its name and enabled state
    And the list is ordered by current priority (highest priority first)

  # ---------------------------------------------------------------------------
  # Audio Codecs — Enable / Disable
  # ---------------------------------------------------------------------------

  @audio-codecs @smoke
  Scenario: Enable an audio codec
    Given at least one audio codec is currently disabled
    When the user enables a disabled audio codec
    Then that codec is marked as enabled
    And it becomes a candidate for use during the next audio call

  @audio-codecs @smoke
  Scenario: Disable an audio codec
    Given at least two audio codecs are currently enabled
    When the user disables one of the enabled audio codecs
    Then that codec is marked as disabled
    And it is no longer used during calls

  @audio-codecs @guard
  Scenario: Cannot disable the last remaining enabled audio codec
    Given exactly one audio codec is currently enabled
    When the user attempts to disable that last enabled audio codec
    Then the client prevents the action
    And an informative message is shown explaining that at least one codec must remain enabled
    And the codec list state is unchanged

  # ---------------------------------------------------------------------------
  # Audio Codecs — Priority
  # ---------------------------------------------------------------------------

  @audio-codecs @priority
  Scenario: Increase priority of an audio codec (move up)
    Given two or more audio codecs are listed
    And an audio codec "Codec B" is not already at the top of the list
    When the user moves "Codec B" up in priority
    Then "Codec B" appears one position higher in the codec list
    And the previously higher-ranked codec moves down by one position

  @audio-codecs @priority
  Scenario: Decrease priority of an audio codec (move down)
    Given two or more audio codecs are listed
    And an audio codec "Codec A" is not already at the bottom of the list
    When the user moves "Codec A" down in priority
    Then "Codec A" appears one position lower in the codec list
    And the previously lower-ranked codec moves up by one position

  @audio-codecs @priority @edge-case
  Scenario: Cannot move the top-priority audio codec further up
    Given the highest-priority audio codec "Codec A" is at position 1
    When the user attempts to move "Codec A" further up
    Then the codec list order remains unchanged

  @audio-codecs @priority @edge-case
  Scenario: Cannot move the lowest-priority audio codec further down
    Given the lowest-priority audio codec is at the last position
    When the user attempts to move it further down
    Then the codec list order remains unchanged

  # ---------------------------------------------------------------------------
  # Video Codecs — Viewing
  # ---------------------------------------------------------------------------

  @video-codecs @smoke
  Scenario: View list of available video codecs for an account
    When the user navigates to the video codec section of the account settings
    Then the client displays a list of video codecs supported for that account
    And each codec entry shows at minimum its name and enabled state
    And the list is ordered by current priority (highest priority first)

  # ---------------------------------------------------------------------------
  # Video Codecs — Enable / Disable
  # ---------------------------------------------------------------------------

  @video-codecs @smoke
  Scenario: Enable a video codec
    Given at least one video codec is currently disabled
    When the user enables a disabled video codec
    Then that codec is marked as enabled
    And it becomes a candidate for use during the next video call

  @video-codecs @smoke
  Scenario: Disable a video codec
    Given at least two video codecs are currently enabled
    When the user disables one of the enabled video codecs
    Then that codec is marked as disabled
    And it is no longer used during video calls

  @video-codecs @guard
  Scenario: Cannot disable the last remaining enabled video codec
    Given exactly one video codec is currently enabled
    When the user attempts to disable that last enabled video codec
    Then the client prevents the action
    And an informative message is shown explaining that at least one codec must remain enabled
    And the codec list state is unchanged

  # ---------------------------------------------------------------------------
  # Video Codecs — Priority
  # ---------------------------------------------------------------------------

  @video-codecs @priority
  Scenario Outline: Change video codec priority
    Given two or more video codecs are listed
    And codec "<codec>" is at position <initial_pos>
    When the user moves "<codec>" "<direction>" in priority
    Then "<codec>" is at position <final_pos>

    Examples:
      | codec   | direction | initial_pos | final_pos |
      | H.264   | up        | 2           | 1         |
      | VP8     | down      | 1           | 2         |
      | H.265   | up        | 3           | 2         |

  # ---------------------------------------------------------------------------
  # Video Codecs — Quality & Bitrate
  # ---------------------------------------------------------------------------

  @video-codecs @quality @smoke
  Scenario: Toggle auto quality for a video codec
    Given a video codec that supports quality configuration is selected
    When the user toggles the auto quality setting for that codec
    Then the auto quality state is updated accordingly
    And when auto quality is on, manual bitrate controls are disabled
    And when auto quality is off, manual bitrate controls become available

  @video-codecs @quality @smoke
  Scenario: Set a custom bitrate for a video codec
    Given a video codec with auto quality disabled is selected
    When the user sets the bitrate to a valid value
    Then the codec records the new bitrate value
    And the bitrate is applied when that codec is used in a call

  @video-codecs @quality @edge-case
  Scenario Outline: Bitrate boundary validation for a video codec
    Given a video codec with auto quality disabled is selected
    When the user enters "<bitrate>" as the bitrate value
    Then the client "<outcome>"

    Examples:
      | bitrate | outcome                                          |
      | 0       | rejects the value and shows a validation message |
      | -1      | rejects the value and shows a validation message |
      | 500     | accepts the value and saves it                   |
      | 4000    | accepts the value and saves it                   |

  # ---------------------------------------------------------------------------
  # Persistence
  # ---------------------------------------------------------------------------

  @persistence
  Scenario: Codec settings persist across application restarts
    Given the user has configured a specific codec order and enabled state for an account
    When the client is closed and restarted
    And the user opens the codec settings for that account
    Then the codec order and enabled states match what was previously configured
