@calls @screen-sharing
Feature: Screen Sharing
  As a user of the Jami client
  I want to share my screen or a specific window during a call
  So that I can present content to the other participants

  Background:
    Given the client is running
    And the user has an active account
    And a call is active and connected

  # ─── Starting Screen Share ─────────────────────────────────────────────────

  @smoke
  Scenario: Share the entire screen during a call
    When the user selects to share their entire screen
    Then the screen sharing session starts
    And the client begins transmitting the screen content as a video stream
    And the call view indicates that screen sharing is active

  @smoke
  Scenario: Share a specific window during a call
    Given at least one application window is open on the device
    When the user selects a specific window to share
    Then the screen sharing session starts for that window only
    And the client begins transmitting the selected window's content as a video stream
    And the call view indicates that screen sharing is active

  @regression
  Scenario: Share a file or media as the screen content during a call
    Given a shareable file or media source is available
    When the user selects that file or media source for screen sharing
    Then the screen sharing session starts using the file as the source
    And the client transmits the file content as a video stream
    And the call view indicates that screen sharing is active

  # ─── Stopping Screen Share ─────────────────────────────────────────────────

  @smoke
  Scenario: Stop screen sharing during a call
    Given the user is currently sharing their screen
    When the user stops screen sharing
    Then the screen sharing session ends
    And the client stops transmitting the shared screen stream
    And the call view no longer shows the screen sharing indicator

  # ─── Peer Perspective ──────────────────────────────────────────────────────

  @smoke
  Scenario: Peer sees the shared screen content
    Given the user starts sharing their screen
    When the peer's client receives the screen share stream
    Then the peer sees the shared screen content in their call view
    And the content updates in near-real-time as the screen changes

  # ─── Switching Sources ─────────────────────────────────────────────────────

  @regression
  Scenario: Switch from camera video to screen sharing
    Given a video call is active with the camera stream enabled
    When the user starts screen sharing
    Then the outgoing video stream switches from camera to screen content
    And the peer sees the shared screen instead of the camera feed
    And the local camera preview is replaced by the screen share preview

  @regression
  Scenario: Switch from screen sharing back to camera video
    Given the user is currently sharing their screen during a call
    And a camera device is available
    When the user stops screen sharing and re-enables the camera
    Then the outgoing video stream switches from screen content back to camera
    And the peer sees the camera feed instead of the shared screen
    And the call view shows the local camera preview again

  # ─── Screen Sharing in Conferences ────────────────────────────────────────

  @regression
  Scenario: Screen sharing in a conference call
    Given a conference call is active with multiple participants
    When the user starts screen sharing
    Then all participants receive the screen share stream
    And the conference view indicates which participant is sharing their screen
    And the shared content is visible in each participant's call view

  @regression
  Scenario: Only one participant can share their screen at a time
    Given a conference call is active
    And participant A is currently sharing their screen
    When participant B attempts to start screen sharing
    Then participant B's screen share either replaces participant A's share or is queued
    And at most one screen share stream is active and visible to all participants at any given time
