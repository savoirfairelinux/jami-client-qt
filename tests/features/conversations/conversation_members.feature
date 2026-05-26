@conversations
Feature: Conversation Member Management
  As a user of the client
  I want to manage members of swarm conversations
  So that I can control who participates and with what permissions

  Background:
    Given the client is running
    And the user is authenticated with a valid account
    And the user has an existing swarm conversation "Team Room"
    And the user is an admin of "Team Room"
    And "Team Room" currently has members "Bob" and "Carol" with role "member"

  # ── Viewing Members ────────────────────────────────────────────────────────

  @smoke
  Scenario: View the member list of a swarm conversation
    When the user opens the member list for "Team Room"
    Then the member list displays the user, "Bob", and "Carol"
    And each member entry shows the member's display name and role

  @smoke
  Scenario: View the member count for a swarm conversation
    When the user opens the settings panel for "Team Room"
    Then the member count is displayed as 3

  # ── Adding Members ─────────────────────────────────────────────────────────

  @smoke
  Scenario: An admin can add a new member to a swarm conversation
    Given the user has a registered contact "Dave"
    When the user adds "Dave" to "Team Room"
    Then "Dave" appears in the member list of "Team Room"
    And the member count for "Team Room" increases by 1

  @regression
  Scenario: A newly added member receives a conversation invitation
    Given the user has a registered contact "Dave"
    When the user adds "Dave" to "Team Room"
    Then "Dave" receives an invitation to "Team Room"

  # ── Removing Members ──────────────────────────────────────────────────────

  @smoke
  Scenario: An admin can remove a member from a swarm conversation
    When the user removes "Bob" from "Team Room"
    Then "Bob" is no longer listed in the member list of "Team Room"
    And the member count for "Team Room" decreases by 1

  @regression
  Scenario: A removed member loses access to the conversation
    When the user removes "Bob" from "Team Room"
    Then "Bob" can no longer send or receive messages in "Team Room"

  # ── Roles and Permissions ─────────────────────────────────────────────────

  @smoke
  Scenario: Member list distinguishes admin and regular member roles
    Given the user is an admin of "Team Room"
    When the user opens the member list for "Team Room"
    Then the user's role is shown as "admin"
    And "Bob"'s role is shown as "member"
    And "Carol"'s role is shown as "member"

  @regression
  Scenario: An admin can promote a regular member to admin
    When the user promotes "Bob" to "admin" in "Team Room"
    Then "Bob"'s role in "Team Room" is updated to "admin"
    And "Bob" can now add and remove members in "Team Room"

  @regression
  Scenario: An admin can demote another admin to regular member
    Given "Bob" has the role "admin" in "Team Room"
    When the user demotes "Bob" to "member" in "Team Room"
    Then "Bob"'s role in "Team Room" is updated to "member"
    And "Bob" can no longer add or remove members in "Team Room"

  @regression
  Scenario: A regular member cannot add or remove other members
    Given the client is acting as "Bob"
    When "Bob" attempts to add a new contact "Eve" to "Team Room"
    Then the action is rejected
    And the client indicates "Bob" does not have permission to add members

  @regression
  Scenario: A regular member cannot remove another member
    Given the client is acting as "Bob"
    When "Bob" attempts to remove "Carol" from "Team Room"
    Then the action is rejected
    And the client indicates "Bob" does not have permission to remove members

  # ── Leaving a Conversation ────────────────────────────────────────────────

  @smoke
  Scenario: A member can leave a group conversation
    Given the client is acting as "Bob"
    When "Bob" leaves "Team Room"
    Then "Bob" is no longer listed in the member list of "Team Room"
    And "Team Room" is removed from "Bob"'s conversation list

  @regression
  Scenario: When the last admin leaves a group conversation the conversation defines the outcome
    Given the user is the only admin of "Team Room"
    And "Team Room" has no other members with the admin role
    When the user leaves "Team Room"
    Then the client handles the last-admin-leaves condition according to the conversation policy
    And the conversation either promotes another member to admin or is marked as adminless
