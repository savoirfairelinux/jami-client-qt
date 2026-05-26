@settings @application
Feature: Application Settings
  As a user of the communication client
  I want to read, write, and reset global application settings
  So that the client behaves according to my preferences across sessions

  Background:
    Given the client is running
    And the user has navigated to the application settings view

  # ---------------------------------------------------------------------------
  # Navigation to Settings
  # ---------------------------------------------------------------------------

  @navigation @smoke
  Scenario: Navigate to settings view via keyboard shortcut
    Given the user is anywhere in the client interface
    When the user presses the keyboard shortcut Ctrl+,
    Then the application settings view is displayed

  @navigation @smoke
  Scenario: Navigate to settings view via the menu
    Given the user is anywhere in the client interface
    When the user opens the application menu
    And selects the settings option
    Then the application settings view is displayed

  @navigation
  Scenario: Settings view can be dismissed and reopened
    Given the application settings view is open
    When the user closes the settings view
    Then the settings view is no longer displayed
    When the user reopens the settings view
    Then the settings view is displayed again with the same state

  # ---------------------------------------------------------------------------
  # Read / Write Settings
  # ---------------------------------------------------------------------------

  @read-write @smoke
  Scenario: Read a setting value
    Given the application setting "notifications.enabled" has a stored value
    When the user views the notifications section of the settings
    Then the displayed value matches the stored value for "notifications.enabled"

  @read-write @smoke
  Scenario: Write and change a setting value
    Given the current value of setting "notifications.enabled" is "true"
    When the user changes "notifications.enabled" to "false"
    Then the setting "notifications.enabled" is stored with value "false"

  @read-write @smoke
  Scenario: Setting change takes effect immediately
    Given the user is in the application settings view
    When the user changes any setting
    Then the change is applied to the running client without requiring a restart
    And the new value is reflected in the interface immediately

  # ---------------------------------------------------------------------------
  # Setting Types
  # ---------------------------------------------------------------------------

  @setting-types @smoke
  Scenario Outline: Different setting types can be read and written correctly
    Given a setting "<key>" of type "<type>" with value "<initial_value>"
    When the user changes the setting to "<new_value>"
    Then the stored value for "<key>" is "<new_value>"
    And the setting is applied correctly by the client

    Examples:
      | key                         | type    | initial_value | new_value |
      | general.startMinimized      | boolean | false         | true      |
      | general.language            | string  | en            | fr        |
      | general.historyLimit        | numeric | 30            | 60        |
      | notifications.enabled       | boolean | true          | false     |
      | calls.enableAutoAnswer      | boolean | false         | true      |

  @setting-types @edge-case
  Scenario: Boolean setting is stored as a distinct true/false value
    When the user enables a boolean setting
    Then it is stored as the boolean value true
    When the user disables the same boolean setting
    Then it is stored as the boolean value false

  @setting-types @edge-case
  Scenario Outline: Numeric setting boundary validation
    Given the numeric setting "<key>" with valid range "<min>" to "<max>"
    When the user enters the value "<input>" for that setting
    Then the client "<outcome>"

    Examples:
      | key                      | min | max  | input | outcome                                          |
      | general.historyLimit     | 1   | 365  | 0     | rejects the value and shows a validation message |
      | general.historyLimit     | 1   | 365  | 30    | accepts and stores the value                     |
      | general.historyLimit     | 1   | 365  | 366   | rejects the value and shows a validation message |

  # ---------------------------------------------------------------------------
  # Defaults & Persistence
  # ---------------------------------------------------------------------------

  @defaults @smoke
  Scenario: Reset all settings to defaults
    Given the user has customised multiple application settings
    When the user chooses to reset all settings to defaults
    Then all settings are restored to their default values
    And the reset is reflected immediately in the settings view

  @defaults
  Scenario: Reset settings to defaults does not affect account data
    Given the user has at least one configured account
    And the user has customised application settings
    When the user resets all application settings to defaults
    Then account configuration is not modified
    And the user's accounts remain intact and usable

  @persistence @smoke
  Scenario: Settings persist across application restart
    Given the user has changed a setting from its default value
    When the client is closed
    And the client is restarted
    Then the previously changed setting retains the updated value
    And the client does not revert to defaults on startup

  @persistence
  Scenario: Multiple changed settings all persist after restart
    Given the user has changed three or more distinct settings
    When the client is closed and restarted
    Then each changed setting retains its updated value after restart
