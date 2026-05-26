@plugins @store
Feature: Plugin Store
  As a user of the Jami client
  I want to interact with the remote plugin catalog
  So that I can discover updates, install new plugins, and keep existing plugins current

  Background:
    Given the client is running
    And the user has an active account
    And the plugin system is enabled

  # ─── Catalog Retrieval ────────────────────────────────────────────────────

  @catalog @smoke
  Scenario: Fetch available plugins from the remote store
    Given the remote plugin store is reachable
    When the user opens the plugin store
    Then the client fetches the plugin catalog from the remote server
    And the store displays the retrieved list of available plugins

  @catalog
  Scenario: Store list refreshes with latest catalog
    Given the plugin store has been opened previously and displayed a catalog
    And the remote catalog has since been updated with a new plugin
    When the user refreshes the plugin store
    Then the store displays the updated catalog
    And the newly added plugin is visible in the list

  # ─── Update Detection ────────────────────────────────────────────────────

  @updates @smoke
  Scenario: Check for plugin updates
    Given at least one plugin is installed
    When the user triggers a check for plugin updates
    Then the client queries the remote store for newer versions
    And the client reports whether updates are available

  @updates
  Scenario: Plugin update available is shown to the user
    Given a plugin named "PluginAlpha" is installed at version "1.0.0"
    And the remote store lists "PluginAlpha" at version "2.0.0"
    When the user checks for updates
    Then the client indicates that an update is available for "PluginAlpha"
    And the available update version "2.0.0" is displayed

  # ─── Auto-Update ─────────────────────────────────────────────────────────

  @auto-update
  Scenario: Enable auto-update for plugins
    Given auto-update for plugins is currently disabled
    When the user enables the auto-update setting
    Then the client confirms that auto-update is enabled
    And the auto-update status reflects the enabled state

  @auto-update
  Scenario: Disable auto-update for plugins
    Given auto-update for plugins is currently enabled
    When the user disables the auto-update setting
    Then the client confirms that auto-update is disabled
    And the auto-update status reflects the disabled state

  @auto-update @smoke
  Scenario: Auto-update installs a new version automatically
    Given auto-update for plugins is enabled
    And a plugin named "PluginBeta" is installed at version "1.0.0"
    And the remote store publishes version "1.1.0" of "PluginBeta"
    When the auto-update mechanism runs
    Then the client automatically downloads and installs version "1.1.0" of "PluginBeta"
    And the installed version of "PluginBeta" is reported as "1.1.0"

  # ─── Download Cancellation ────────────────────────────────────────────────

  @cancellation
  Scenario: Cancel an ongoing plugin download from the store
    Given the plugin store is open
    And the client is currently downloading a plugin named "HeavyPlugin"
    When the user cancels the download of "HeavyPlugin"
    Then the download is aborted
    And "HeavyPlugin" is not added to the installed plugins list
    And the store returns to a browsable ready state without errors

  # ─── Error Handling ──────────────────────────────────────────────────────

  @error-handling @smoke
  Scenario: Store unavailable — graceful error handling
    Given the remote plugin store server is not reachable
    When the user opens the plugin store
    Then the client does not crash or freeze
    And the client displays an informative error message indicating the store is unavailable
    And any previously installed plugins remain unaffected

  # ─── Auto-Update Toggle Persistence ─────────────────────────────────────

  @auto-update @persistence
  Scenario Outline: Auto-update setting persists across client restarts
    Given auto-update for plugins is set to "<initial_state>"
    When the client is restarted
    Then the auto-update setting is still "<initial_state>"

    Examples:
      | initial_state |
      | enabled       |
      | disabled      |
