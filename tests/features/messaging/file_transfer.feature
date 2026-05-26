@messaging
Feature: File Transfer
  As a user of the Jami communication client
  I want to send and receive files within conversations
  So that I can share documents, images, and other content with peers

  Background:
    Given the client is running
    And the user is authenticated with a valid account
    And the user has opened a conversation with a peer

  # ---------------------------------------------------------------------------
  # Sending files
  # ---------------------------------------------------------------------------

  @smoke
  Scenario: Send a file in a conversation
    Given the user has selected a file "document.pdf" to send
    When the user initiates the file transfer
    Then a file transfer entry for "document.pdf" appears in the conversation timeline
    And the transfer status transitions to "in_progress"
    And the transfer status eventually transitions to "completed"

  @regression
  Scenario: Send multiple files simultaneously
    Given the user has selected the following files to send:
      | filename       |
      | photo.jpg      |
      | report.pdf     |
      | archive.zip    |
    When the user initiates all file transfers
    Then a file transfer entry for each file appears in the conversation timeline
    And all transfers progress independently

  @regression
  Scenario: Large file transfer handling
    Given the user has selected a file that is larger than 100 MB
    When the user initiates the file transfer
    Then a file transfer entry appears in the conversation timeline
    And file transfer progress is indicated throughout the transfer
    And the transfer status eventually transitions to "completed"

  @regression
  Scenario: File transfer to offline peer — queued
    Given the peer is currently offline
    When the user sends a file "queued_file.txt"
    Then a file transfer entry for "queued_file.txt" appears in the conversation timeline
    And the transfer status is "pending"
    When the peer comes online
    Then the transfer status transitions to "in_progress"
    And the transfer eventually completes

  # ---------------------------------------------------------------------------
  # Receiving files
  # ---------------------------------------------------------------------------

  @smoke
  Scenario: Receive a file transfer request
    When the peer initiates a file transfer of "shared_image.png"
    Then a file transfer entry for "shared_image.png" appears in the conversation timeline
    And the transfer entry shows options to accept or decline

  @smoke
  Scenario: Accept a file transfer — file downloaded
    Given the peer has initiated a file transfer of "shared_document.pdf"
    When the user accepts the file transfer
    Then the transfer status transitions to "in_progress"
    And a progress indicator is displayed during the download
    And the transfer status eventually transitions to "completed"
    And the file is available to open or save locally

  @regression
  Scenario: Decline a file transfer
    Given the peer has initiated a file transfer of "unwanted_file.exe"
    When the user declines the file transfer
    Then the transfer status transitions to "cancelled"
    And the file is not saved locally
    And the peer is notified that the transfer was declined

  # ---------------------------------------------------------------------------
  # Cancellation
  # ---------------------------------------------------------------------------

  @regression
  Scenario: Cancel an in-progress file transfer (sender side)
    Given the user has initiated a file transfer that is currently "in_progress"
    When the user cancels the file transfer from the sender side
    Then the transfer status transitions to "cancelled"
    And the peer's transfer entry also reflects the cancellation

  @regression
  Scenario: Cancel an in-progress file transfer (receiver side)
    Given the peer has initiated a file transfer that the user has accepted and is "in_progress"
    When the user cancels the file transfer from the receiver side
    Then the transfer status transitions to "cancelled"
    And the partially downloaded file is not retained locally

  # ---------------------------------------------------------------------------
  # Progress and status
  # ---------------------------------------------------------------------------

  @regression
  Scenario: File transfer progress indication
    Given the user has accepted an incoming file transfer
    When the transfer is in progress
    Then a progress indicator shows the current transfer progress
    And the progress indicator updates as more data is received

  @regression
  Scenario Outline: Transfer status transitions
    Given a file transfer is initiated
    Then the transfer status follows the expected transitions:
      | initial_status | event            | resulting_status |
      | pending        | transfer starts  | in_progress      |
      | in_progress    | transfer done    | completed        |
      | in_progress    | sender cancels   | cancelled        |
      | in_progress    | receiver cancels | cancelled        |
      | in_progress    | network error    | failed           |

  # ---------------------------------------------------------------------------
  # Post-transfer actions
  # ---------------------------------------------------------------------------

  @regression
  Scenario: Open a received file
    Given the user has a completed incoming file transfer for "received_photo.jpg"
    When the user opens the file from the conversation timeline
    Then the file is opened using the appropriate application

  @regression
  Scenario: Copy received file to downloads folder
    Given the user has a completed incoming file transfer for "received_report.pdf"
    When the user saves the file to the downloads folder
    Then the file is copied to the downloads folder
    And the file is accessible outside the client

  @regression
  Scenario: Remove a file transfer from the conversation
    Given there is a completed or cancelled file transfer entry in the conversation timeline
    When the user removes the file transfer entry
    Then the file transfer entry is no longer visible in the conversation timeline
    And the removal does not affect other messages in the timeline
