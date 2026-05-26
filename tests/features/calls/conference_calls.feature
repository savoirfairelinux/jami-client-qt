@calls @conference
Feature: Conference Calls
  As a user of the Jami client
  I want to create and participate in group/conference calls
  So that I can communicate with multiple contacts simultaneously

  Background:
    Given the client is running
    And the user has an active account
    And the user has at least two contacts available

  # ─── Creating Conferences ──────────────────────────────────────────────────

  @smoke
  Scenario: Create a conference by merging two active calls
    Given the user has two separate active calls each in the connected state
    When the user merges the two calls into a conference
    Then a conference call is created
    And the client emits a participantsChanged signal
    And both peers are listed as participants in the conference

  @smoke
  Scenario: Add a participant to an existing conference call
    Given a conference call is active with at least one participant
    When the user invites an additional contact to the conference
    Then the client initiates a call to the additional contact
    And when the contact accepts, they are added to the conference
    And the client emits a participantsChanged signal
    And the new participant appears in the participant list

  @regression
  Scenario: Call a contact and add them directly to an existing conference
    Given a conference call is active
    When the user places a call to a new contact from the conference view
    And the contact accepts the call
    Then the contact is merged into the conference
    And the participant list is updated

  # ─── Participant Departure & Conference End ────────────────────────────────

  @smoke
  Scenario: Remove a participant from a conference
    Given a conference call is active with multiple participants
    And the user holds a moderator role
    When the moderator disconnects a specific participant
    Then that participant is removed from the conference
    And the client emits a participantsChanged signal
    And the removed participant's call is ended

  @smoke
  Scenario: Participant leaves the conference voluntarily
    Given a conference call is active with multiple participants
    When a participant ends their own call
    Then that participant is removed from the conference
    And the client emits a participantsChanged signal
    And the remaining participants continue the conference

  @regression
  Scenario: Conference ends when the last participant leaves
    Given a conference call has exactly two participants including the user
    When the other participant ends their call
    Then the conference is dissolved
    And the client emits a callEnded signal
    And the call view is dismissed

  # ─── Moderator Controls ────────────────────────────────────────────────────

  @smoke
  Scenario: Moderator mutes a participant
    Given a conference call is active
    And the user holds a moderator role
    And a specific participant is currently unmuted
    When the moderator mutes that participant
    Then the participant's mute state changes to MODERATOR_MUTED
    And the participant list reflects the muted state for that participant

  @smoke
  Scenario: Moderator disconnects a participant
    Given a conference call is active
    And the user holds a moderator role
    When the moderator disconnects a specific participant
    Then the participant is removed from the conference
    And the participant's call is ended
    And the conference continues with the remaining participants

  @regression
  Scenario: Non-moderator cannot mute other participants
    Given a conference call is active
    And the user does not hold a moderator role
    When the user attempts to mute another participant
    Then the mute action is rejected or unavailable
    And the other participant's audio state remains unchanged

  # ─── Raise / Lower Hand ────────────────────────────────────────────────────

  @regression
  Scenario: Participant raises their hand
    Given a conference call is active
    When a participant raises their hand
    Then the client emits a participantsChanged signal
    And the raised-hand indicator is shown for that participant in the participant list

  @regression
  Scenario: Participant lowers their hand
    Given a conference call is active
    And a participant currently has their hand raised
    When the participant lowers their hand
    Then the client emits a participantsChanged signal
    And the raised-hand indicator is removed for that participant

  @regression
  Scenario: Host sees all raised hands in the participant list
    Given a conference call is active
    And the user holds the host or moderator role
    And multiple participants have raised their hands
    Then the host's participant list shows the raised-hand indicator for each of those participants

  # ─── Layout & Active Speaker ───────────────────────────────────────────────

  @smoke
  Scenario Outline: Switch conference layout
    Given a conference call is active with video
    And the current layout is "<current_layout>"
    When the user switches the layout to "<target_layout>"
    Then the conference view transitions to the "<target_layout>" arrangement

    Examples:
      | current_layout | target_layout |
      | grid           | spotlight     |
      | spotlight      | grid          |

  @regression
  Scenario: Active speaker is highlighted in the conference view
    Given a conference call is active with multiple participants
    When a participant is speaking
    Then that participant is highlighted as the active speaker in the conference view

  @regression
  Scenario: Set a specific participant as the active speaker
    Given a conference call is active with multiple participants
    And the user holds a moderator role
    When the moderator sets a specific participant as the active speaker
    Then that participant is displayed prominently in the spotlight layout
    And the other participants' tiles are reduced in prominence

  # ─── Participant List & Joining ────────────────────────────────────────────

  @smoke
  Scenario: Conference participant list is displayed
    Given a conference call is active with multiple participants
    Then the conference view shows a participant list or overlay
    And each participant's name or identifier is shown
    And the participant count reflects the actual number of connected participants

  @regression
  Scenario: Join a conference from a group conversation
    Given the user has an open group conversation
    And a conference call is in progress within that conversation
    When the user joins the ongoing conference from the conversation view
    Then the client connects the user to the conference
    And the user is added to the participant list
    And the conference view is shown
