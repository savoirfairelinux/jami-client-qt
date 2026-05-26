@account
Feature: Profile Management
  As a user of a Jami client
  I want to manage my account profile (display name and avatar)
  So that my contacts can identify me and my profile stays up to date

  Background:
    Given the client has an active Jami account
    And the user is on the account profile settings screen

  # ---------------------------------------------------------------------------
  # Display name
  # ---------------------------------------------------------------------------

  @smoke
  Scenario: Set a display name for an account that has none
    Given the account currently has no display name set
    When the user enters the display name "Alice"
    And the user saves the profile
    Then the client emits a "profileUpdated" signal for the account
    And the account's display name is shown as "Alice" in the account list

  @smoke
  Scenario: Change the display name of an account
    Given the account's current display name is "Alice"
    When the user clears the display name field and enters "Alice Smith"
    And the user saves the profile
    Then the client emits a "profileUpdated" signal for the account
    And the account's display name is shown as "Alice Smith"

  @regression
  Scenario: Display name field accepts Unicode characters
    Given the account currently has no display name set
    When the user enters the display name "日本語テスト"
    And the user saves the profile
    Then the client emits a "profileUpdated" signal for the account
    And the account's display name is shown as "日本語テスト"

  @regression
  Scenario: Saving the profile without changing the display name does not emit a spurious update
    Given the account's current display name is "Alice"
    When the user opens the profile settings and saves without making any changes
    Then no "profileUpdated" signal is emitted

  # ---------------------------------------------------------------------------
  # Avatar
  # ---------------------------------------------------------------------------

  @smoke
  Scenario: Set an avatar image for an account
    Given the account currently has no custom avatar set
    When the user selects an image file as the avatar
    And the user saves the profile
    Then the client emits a "profileUpdated" signal for the account
    And the account's avatar displays the selected image

  @smoke
  Scenario: Change the avatar image of an account
    Given the account currently has a custom avatar set
    When the user selects a new image file as the avatar
    And the user saves the profile
    Then the client emits a "profileUpdated" signal for the account
    And the account's avatar displays the newly selected image

  @regression
  Scenario: Remove a custom avatar — account reverts to the default generated avatar
    Given the account currently has a custom avatar set
    When the user removes the custom avatar
    And the user saves the profile
    Then the client emits a "profileUpdated" signal for the account
    And the account's avatar reverts to the default generated avatar

  @regression
  Scenario: Uploading an unsupported image format shows an error
    Given the account currently has no custom avatar set
    When the user selects an unsupported file type as the avatar
    Then the client displays a file format error
    And the account's avatar remains unchanged
    And no "profileUpdated" signal is emitted

  # ---------------------------------------------------------------------------
  # Immediate UI visibility
  # ---------------------------------------------------------------------------

  @smoke
  Scenario: Profile changes are visible to the user immediately after saving
    Given the account's current display name is "Alice"
    When the user changes the display name to "Alice Smith" and saves
    Then the account list shows "Alice Smith" without requiring a restart
    And the profile screen reflects "Alice Smith" immediately

  @smoke
  Scenario: Avatar change is visible in the client UI immediately after saving
    Given the account currently has a custom avatar set
    When the user sets a new avatar and saves the profile
    Then the new avatar is displayed in the account list immediately
    And the new avatar is displayed in the conversation header immediately

  # ---------------------------------------------------------------------------
  # Propagation to contacts
  # ---------------------------------------------------------------------------

  @regression
  Scenario: Display name update propagates to contacts
    Given the account's current display name is "Alice"
    And the account has at least one contact
    When the user changes the display name to "Alice Smith" and saves
    Then the client emits a "profileUpdated" signal for the account
    And the updated display name "Alice Smith" is sent to the account's contacts

  @regression
  Scenario: Avatar update propagates to contacts
    Given the account has at least one contact
    When the user sets a new avatar and saves the profile
    Then the client emits a "profileUpdated" signal for the account
    And the updated avatar is sent to the account's contacts

  # ---------------------------------------------------------------------------
  # Scenario Outline: combined name and avatar updates
  # ---------------------------------------------------------------------------

  @regression
  Scenario Outline: Setting display name and avatar together persists both changes
    Given the account currently has no display name or custom avatar
    When the user enters the display name "<display_name>"
    And the user selects the avatar "<avatar_source>"
    And the user saves the profile
    Then the client emits a "profileUpdated" signal
    And the account's display name is "<display_name>"
    And the account's avatar reflects the selection "<avatar_source>"

    Examples:
      | display_name | avatar_source        |
      | Alice        | portrait_photo.png   |
      | Bob Smith    | company_logo.jpg     |
      | 日本語        | avatar_icon.png      |

  # ---------------------------------------------------------------------------
  # Default moderator status
  # ---------------------------------------------------------------------------

  @regression
  Scenario: Set default moderator status for a conference account
    Given the account supports conference moderation
    When the user enables "Set as default moderator" in the profile settings
    And the user saves the profile
    Then the account is configured as a default moderator
    And the moderator setting is reflected in the account settings screen
