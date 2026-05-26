@plugins @management
Feature: Plugin Management
  As a user of the Jami client
  I want to load, unload, configure, and control plugin handlers
  So that active plugins behave exactly as I need them to

  Background:
    Given the client is running
    And the user has an active account
    And the plugin system is enabled
    And at least one plugin is installed

  # ─── Lifecycle: Load / Unload ──────────────────────────────────────────────

  @lifecycle @smoke
  Scenario: Load an installed plugin
    Given a plugin named "TestPlugin" is installed but not loaded
    When the user loads "TestPlugin"
    Then the client reports that "TestPlugin" was loaded successfully

  @lifecycle @smoke
  Scenario: Loaded plugin appears in the active plugins list
    Given a plugin named "TestPlugin" is installed but not loaded
    When the user loads "TestPlugin"
    Then "TestPlugin" appears in the active plugins list

  @lifecycle
  Scenario: Unload a plugin without uninstalling it
    Given a plugin named "TestPlugin" is currently loaded
    When the user unloads "TestPlugin"
    Then the client reports that "TestPlugin" was unloaded successfully
    And "TestPlugin" is no longer in the active plugins list
    And "TestPlugin" remains in the installed plugins list

  # ─── Media Handlers ────────────────────────────────────────────────────────

  @handlers @media
  Scenario: Enable a media handler from a plugin
    Given a plugin named "MediaPlugin" is loaded
    And "MediaPlugin" provides a media handler named "VideoFilter"
    When the user enables the "VideoFilter" handler
    Then the client confirms the "VideoFilter" handler is active
    And the handler processes audio/video streams during calls

  @handlers @media
  Scenario: Disable a media handler
    Given a plugin named "MediaPlugin" is loaded
    And the "VideoFilter" media handler is currently active
    When the user disables the "VideoFilter" handler
    Then the client confirms the "VideoFilter" handler is inactive
    And the handler no longer processes audio/video streams

  # ─── Chat Handlers ─────────────────────────────────────────────────────────

  @handlers @chat
  Scenario: Enable a chat handler from a plugin
    Given a plugin named "ChatPlugin" is loaded
    And "ChatPlugin" provides a chat handler named "MessageTransformer"
    When the user enables the "MessageTransformer" handler
    Then the client confirms the "MessageTransformer" handler is active
    And the handler processes outgoing and incoming chat messages

  @handlers @chat
  Scenario: Disable a chat handler
    Given a plugin named "ChatPlugin" is loaded
    And the "MessageTransformer" chat handler is currently active
    When the user disables the "MessageTransformer" handler
    Then the client confirms the "MessageTransformer" handler is inactive
    And the handler no longer processes chat messages

  # ─── Preferences ──────────────────────────────────────────────────────────

  @preferences
  Scenario: View plugin preferences
    Given a plugin named "ConfigurablePlugin" is loaded
    And "ConfigurablePlugin" declares at least one configurable preference
    When the user opens the preferences for "ConfigurablePlugin"
    Then the client displays all declared preferences with their current values

  @preferences
  Scenario: Modify a plugin preference
    Given a plugin named "ConfigurablePlugin" is loaded
    And the preference "processingMode" of "ConfigurablePlugin" is set to "standard"
    When the user changes the preference "processingMode" to "enhanced"
    Then the client stores the new value "enhanced" for "processingMode"
    And the preference is reflected correctly when the preferences are reopened

  @preferences
  Scenario: Reset plugin preferences to defaults
    Given a plugin named "ConfigurablePlugin" is loaded
    And the user has previously modified one or more preferences of "ConfigurablePlugin"
    When the user resets the preferences of "ConfigurablePlugin" to defaults
    Then all preferences of "ConfigurablePlugin" return to their factory-default values

  # ─── Global Controls ──────────────────────────────────────────────────────

  @global @smoke
  Scenario: Disable all plugins at once
    Given multiple plugins are currently loaded
    When the user disables the plugin system globally
    Then all loaded plugins are unloaded
    And the active plugins list is empty
    And no plugin handlers are processing any streams or messages

  # ─── Combined Handler Scenario ────────────────────────────────────────────

  @handlers @media @chat
  Scenario: Plugin with both media and chat handlers operates independently
    Given a plugin named "ComboPlugin" is loaded
    And "ComboPlugin" provides a media handler named "AudioEnhancer"
    And "ComboPlugin" provides a chat handler named "EmojiExpander"
    When the user enables the "AudioEnhancer" handler
    And the user enables the "EmojiExpander" handler
    Then both handlers are independently active
    When the user disables the "AudioEnhancer" handler
    Then "AudioEnhancer" is inactive
    And "EmojiExpander" remains active

  # ─── Handler Toggle Matrix ────────────────────────────────────────────────

  @handlers
  Scenario Outline: Toggle a handler on and off
    Given a plugin named "<plugin>" is loaded
    And "<plugin>" provides a <handler_type> handler named "<handler>"
    When the user enables the "<handler>" handler
    Then the "<handler>" handler is active
    When the user disables the "<handler>" handler
    Then the "<handler>" handler is inactive

    Examples:
      | plugin       | handler_type | handler           |
      | MediaPlugin  | media        | VideoFilter       |
      | MediaPlugin  | media        | AudioNoiseCanceler|
      | ChatPlugin   | chat         | MessageTransformer|
      | ChatPlugin   | chat         | SpellChecker      |
