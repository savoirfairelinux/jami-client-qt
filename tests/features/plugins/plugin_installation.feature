@plugins @installation
Feature: Plugin Installation
  As a user of the Jami client
  I want to browse, install, and uninstall plugins
  So that I can extend the client's functionality

  Background:
    Given the client is running
    And the user has an active account
    And the plugin system is enabled

  # ─── Store Browsing ────────────────────────────────────────────────────────

  @store @smoke
  Scenario: Browse available plugins in the store
    When the user opens the plugin store
    Then the store displays a list of available plugins
    And each entry shows at minimum a name and a short description

  @store
  Scenario: View plugin details
    Given the plugin store is open
    And at least one plugin is listed
    When the user selects a plugin from the store
    Then the client displays the plugin detail view
    And the detail view contains the plugin name
    And the detail view contains the plugin description
    And the detail view contains the plugin version
    And the detail view contains the plugin icon

  # ─── Installation ──────────────────────────────────────────────────────────

  @store @smoke
  Scenario: Install a plugin from the store
    Given the plugin store is open
    And a plugin named "TestPlugin" is available in the store
    And "TestPlugin" is not currently installed
    When the user installs "TestPlugin" from the store
    Then the client reports that "TestPlugin" was installed successfully
    And "TestPlugin" appears in the installed plugins list

  @local
  Scenario: Install a plugin from a local file
    Given the user has a valid plugin package file at a local path
    When the user installs the plugin from the local file
    Then the client reports that the plugin was installed successfully
    And the plugin appears in the installed plugins list

  @store
  Scenario: Plugin appears in installed list after installation
    Given a plugin named "AuditPlugin" is not in the installed plugins list
    When the user installs "AuditPlugin" from the store
    Then "AuditPlugin" appears in the installed plugins list

  # ─── Uninstallation ────────────────────────────────────────────────────────

  @smoke
  Scenario: Uninstall an installed plugin
    Given a plugin named "TestPlugin" is installed
    When the user uninstalls "TestPlugin"
    Then the client reports that "TestPlugin" was uninstalled successfully
    And "TestPlugin" no longer appears in the installed plugins list

  Scenario: Plugin removed from installed list after uninstallation
    Given a plugin named "AuditPlugin" is in the installed plugins list
    When the user uninstalls "AuditPlugin"
    Then "AuditPlugin" is absent from the installed plugins list

  # ─── Download Progress ─────────────────────────────────────────────────────

  @store @progress
  Scenario: Install plugin with download progress
    Given the plugin store is open
    And a plugin named "HeavyPlugin" is available in the store
    When the user begins installing "HeavyPlugin"
    Then the client displays a download progress indicator
    And the progress indicator updates as the download advances
    And when the download completes the plugin is marked as installed

  @store @progress @cancellation
  Scenario: Cancel plugin download mid-installation
    Given the plugin store is open
    And a plugin named "HeavyPlugin" is available in the store
    And the user has begun installing "HeavyPlugin" and the download is in progress
    When the user cancels the download
    Then the download stops
    And "HeavyPlugin" is not added to the installed plugins list
    And the client returns to a ready state without errors

  # ─── Already-Installed Handling ────────────────────────────────────────────

  @store @update
  Scenario Outline: Install a plugin that is already installed
    Given a plugin named "<plugin>" is already installed with version "<current_version>"
    And the store offers "<plugin>" at version "<store_version>"
    When the user attempts to install "<plugin>" from the store
    Then the client responds with "<expected_outcome>"

    Examples:
      | plugin       | current_version | store_version | expected_outcome                 |
      | PluginAlpha  | 1.0.0           | 2.0.0         | offers to update to version 2.0.0 |
      | PluginBeta   | 1.5.0           | 1.5.0         | indicates the plugin is up to date |
      | PluginGamma  | 2.0.0           | 1.9.0         | indicates the installed version is newer |
