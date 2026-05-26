@media @video
Feature: Video Device Management
  As a user of the communication client
  I want to manage video capture devices and their settings
  So that I can control the quality and source of my video during calls

  Background:
    Given the client is running

  # ---------------------------------------------------------------------------
  # Device Enumeration
  # ---------------------------------------------------------------------------

  @video-devices @smoke
  Scenario: List available video capture devices
    Given at least one video capture device is connected
    When the user opens the video device settings
    Then the client displays a list of available video capture devices
    And each listed device shows a human-readable name
    And the currently selected device is visually indicated

  @video-devices @smoke
  Scenario: Select default video device
    Given at least one video capture device is connected
    When the client starts for the first time
    Then a video capture device is automatically selected as the default
    And the selected device is shown in the video device settings

  # ---------------------------------------------------------------------------
  # Resolution & Frame Rate
  # ---------------------------------------------------------------------------

  @video-settings @smoke
  Scenario: Change video resolution for a device
    Given a video capture device is selected
    And the device supports multiple resolutions
    When the user opens the video device settings
    And the user selects a different resolution for the device
    Then the client records the chosen resolution for that device
    And video capture uses the new resolution on the next call

  @video-settings @smoke
  Scenario: Change video frame rate for a device
    Given a video capture device is selected
    And the device supports multiple frame rates
    When the user opens the video device settings
    And the user selects a different frame rate for the device
    Then the client records the chosen frame rate for that device
    And video capture uses the new frame rate on the next call

  @video-settings
  Scenario Outline: Resolution and frame rate options are device-specific
    Given video device "<device>" is selected
    When the user views the available resolutions
    Then only resolutions supported by "<device>" are listed
    And only frame rates supported by "<device>" at the current resolution are listed

    Examples:
      | device            |
      | Built-in Camera   |
      | External Webcam   |

  @video-settings @smoke
  Scenario: Display current FPS during active preview
    Given a video capture device is selected and previewing
    When the user observes the video preview in settings
    Then the client displays the current capture frame rate
    And the displayed FPS corresponds to the configured frame rate for that device

  # ---------------------------------------------------------------------------
  # Hotplug — FirstDevice
  # ---------------------------------------------------------------------------

  @hotplug @first-device @smoke
  Scenario: First camera connected is automatically selected
    Given no video capture device is connected
    And the client is running with video capture unavailable
    When the user connects the first video capture device
    Then the client detects the new device (hotplug event: FirstDevice)
    And that device is automatically selected as the active video device
    And video features become available to the user

  # ---------------------------------------------------------------------------
  # Hotplug — Device Added
  # ---------------------------------------------------------------------------

  @hotplug @device-added
  Scenario: Camera added while client is running appears in the list
    Given at least one video capture device is already connected
    And the client is running
    When an additional video capture device is connected
    Then the client detects the new device (hotplug event: Added)
    And the new device appears in the video device list
    And the previously selected device remains selected

  @hotplug @device-added @edge-case
  Scenario: Multiple cameras connected in quick succession
    Given no video capture device is connected
    When two video capture devices are connected within a short interval
    Then both devices appear in the video device list
    And one device is selected as the active video device
    And the client does not crash or present duplicate entries

  # ---------------------------------------------------------------------------
  # Hotplug — Device Removed
  # ---------------------------------------------------------------------------

  @hotplug @device-removed @smoke
  Scenario: Camera removed while client is running is removed from list
    Given two or more video capture devices are connected
    And the non-active video device "Secondary Camera" is connected
    When the device "Secondary Camera" is disconnected
    Then the client detects the removal (hotplug event: Removed)
    And "Secondary Camera" no longer appears in the video device list
    And the active video device remains unchanged

  @hotplug @device-removed @smoke
  Scenario: Active camera removed triggers fallback to another device
    Given two or more video capture devices are connected
    And "Primary Camera" is the selected active device
    When the device "Primary Camera" is disconnected
    Then the client detects the removal (hotplug event: Removed)
    And the client automatically selects an available fallback device
    And the user is notified that the video device changed

  @hotplug @device-removed
  Scenario: Active camera removed during a call — fallback without crash
    Given an active call with video is in progress
    And the video is sourced from "USB Webcam"
    When the device "USB Webcam" is disconnected during the call
    Then the client switches video to an available fallback device
    And the call continues without crashing
    And the user is informed that the video device changed

  # ---------------------------------------------------------------------------
  # No Device (hotplug event: None)
  # ---------------------------------------------------------------------------

  @hotplug @no-device @edge-case @smoke
  Scenario: No camera available — video features gracefully disabled
    Given no video capture device is connected
    When the user opens the video device settings
    Then the client reports that no video capture device is available (hotplug event: None)
    And video-specific controls are disabled or hidden
    And the client does not crash or show an error dialog
    And the user can still use audio-only features normally

  @hotplug @no-device @edge-case
  Scenario: Last camera removed while client is running
    Given exactly one video capture device is connected and selected
    When that device is disconnected
    Then the client detects the removal (hotplug event: None)
    And the video device list shows no available devices
    And any in-progress video preview stops gracefully
    And the client remains stable and usable for audio calls
