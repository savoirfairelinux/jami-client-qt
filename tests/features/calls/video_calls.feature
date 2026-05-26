@calls @video
Feature: Video Calls
  As a user of the Jami client
  I want to place and receive video calls
  So that I can communicate with contacts using voice and video

  Background:
    Given the client is running
    And the user has an active account
    And the user has at least one contact

  # ─── Placing & Receiving Video Calls ──────────────────────────────────────

  @smoke
  Scenario: Place a video call to a contact
    Given a camera device is available
    When the user initiates a video call to a contact
    Then the client emits a callStarted signal
    And the call is established in video mode
    And the outgoing call view is displayed with a local video preview

  @smoke
  Scenario: Receive an incoming video call
    Given a camera device is available
    When the peer initiates a video call to the user
    Then the client emits a newCall signal
    And the incoming call notification indicates a video call
    And the user is given the option to answer with or without video

  # ─── Video Streams ─────────────────────────────────────────────────────────

  @smoke
  Scenario: Video call shows local and remote video streams
    Given a video call is active and connected
    Then the user's local video stream is rendered in the call view
    And the peer's remote video stream is rendered in the call view
    And both streams are visually distinct from one another

  @smoke
  Scenario: Toggle camera off during a video call
    Given a video call is active and connected
    When the user mutes their camera
    Then the local video stream is no longer transmitted
    And the user's video tile shows a placeholder or avatar
    And the call continues as an audio-only stream from the user's side

  @smoke
  Scenario: Toggle camera back on during a call
    Given a video call is active and the user's camera is currently muted
    When the user unmutes their camera
    Then the local video stream resumes transmission
    And the user's local video preview is visible again in the call view

  @regression
  Scenario: Switch camera device during an active video call
    Given a video call is active and connected
    And the device has more than one camera available
    When the user switches to a different camera device
    Then the local video stream switches to the selected camera
    And the peer receives video from the new camera without interruption to the call

  @regression
  Scenario: Video call with no camera available falls back to audio only
    Given no camera device is available or accessible
    When the user initiates a video call to a contact
    Then the client places the call in audio-only mode
    And the client indicates to the user that no camera was found
    And the call is established without a local video stream

  @regression
  Scenario: Peer toggles their camera off during a video call
    Given a video call is active and connected
    And the peer's video stream is being displayed
    When the peer mutes their camera
    Then the peer's video tile shows a placeholder or avatar
    And the call audio continues uninterrupted

  # ─── Audio-to-Video Upgrade ────────────────────────────────────────────────

  @regression
  Scenario: Upgrade an active audio call to video
    Given an audio-only call is active and connected
    And a camera device is available
    When the user enables their camera during the call
    Then the call upgrades to include a local video stream
    And the peer receives the user's video stream
    And the call view transitions to show the local video preview
