@settings @account
Feature: Account Settings
  As a user of the communication client
  I want to configure per-account settings including network, security, and call behaviour
  So that each account operates according to my individual requirements

  Background:
    Given the client is running
    And the user has at least one configured account
    And the user has opened the settings for that account

  # ---------------------------------------------------------------------------
  # DHT Proxy
  # ---------------------------------------------------------------------------

  @dht-proxy @smoke
  Scenario: Enable DHT proxy for an account
    Given the DHT proxy is currently disabled for the account
    When the user enables the DHT proxy
    Then the DHT proxy setting is saved as enabled for the account
    And the account uses the DHT proxy for subsequent DHT operations

  @dht-proxy @smoke
  Scenario: Disable DHT proxy for an account
    Given the DHT proxy is currently enabled for the account
    When the user disables the DHT proxy
    Then the DHT proxy setting is saved as disabled for the account
    And the account performs DHT operations without a proxy

  # ---------------------------------------------------------------------------
  # TURN Server
  # ---------------------------------------------------------------------------

  @turn @smoke
  Scenario: Configure a TURN server URL for an account
    Given the account TURN server field is empty or has a previous value
    When the user enters a valid TURN server address "turn.example.com:3478"
    And saves the account settings
    Then the TURN server address is stored as "turn.example.com:3478" for the account
    And the account uses that TURN server for call relay

  @turn @edge-case
  Scenario: Clear the TURN server URL
    Given the account has a TURN server configured as "turn.example.com:3478"
    When the user clears the TURN server address field
    And saves the account settings
    Then no TURN server is configured for the account
    And the client operates without TURN relay for that account

  # ---------------------------------------------------------------------------
  # STUN Server
  # ---------------------------------------------------------------------------

  @stun @smoke
  Scenario: Configure a STUN server URL for an account
    Given the account STUN server field is empty or has a previous value
    When the user enters a valid STUN server address "stun.example.com:3478"
    And saves the account settings
    Then the STUN server address is stored as "stun.example.com:3478" for the account
    And the account uses that STUN server for NAT traversal

  @stun @edge-case
  Scenario: Clear the STUN server URL
    Given the account has a STUN server configured as "stun.example.com:3478"
    When the user clears the STUN server address field
    And saves the account settings
    Then no STUN server is configured for the account

  # ---------------------------------------------------------------------------
  # SRTP Encryption
  # ---------------------------------------------------------------------------

  @srtp @security @smoke
  Scenario: Enable SRTP encryption for an account
    Given SRTP is currently disabled for the account
    When the user enables SRTP encryption in the security settings
    Then the SRTP setting is saved as enabled for the account
    And calls on that account will use SRTP-encrypted media streams

  @srtp @security @smoke
  Scenario: Disable SRTP encryption for an account
    Given SRTP is currently enabled for the account
    When the user disables SRTP encryption in the security settings
    Then the SRTP setting is saved as disabled for the account
    And calls on that account will not require SRTP

  # ---------------------------------------------------------------------------
  # Auto-Answer
  # ---------------------------------------------------------------------------

  @auto-answer @smoke
  Scenario: Enable auto-answer for incoming calls
    Given auto-answer is currently disabled for the account
    When the user enables auto-answer
    Then the auto-answer setting is saved as enabled for the account
    And incoming calls on that account are answered automatically

  @auto-answer @smoke
  Scenario: Disable auto-answer for incoming calls
    Given auto-answer is currently enabled for the account
    When the user disables auto-answer
    Then the auto-answer setting is saved as disabled for the account
    And incoming calls present a ringing UI awaiting manual answer

  # ---------------------------------------------------------------------------
  # Auto-Transfer
  # ---------------------------------------------------------------------------

  @auto-transfer
  Scenario Outline: Configure auto-transfer timeout
    Given auto-answer is enabled for the account
    When the user sets the auto-transfer timeout to "<timeout_seconds>" seconds
    Then the auto-transfer timeout is stored as "<timeout_seconds>" for the account

    Examples:
      | timeout_seconds |
      | 0               |
      | 30              |
      | 120             |

  # ---------------------------------------------------------------------------
  # Ringtone
  # ---------------------------------------------------------------------------

  @ringtone @smoke
  Scenario: Set a custom ringtone for an account
    Given the account is using the default ringtone
    When the user selects a custom ringtone file for the account
    Then the selected ringtone is saved for that account
    And incoming calls on that account play the custom ringtone

  @ringtone
  Scenario: Revert to the default ringtone
    Given the account has a custom ringtone configured
    When the user resets the ringtone to the default
    Then the account reverts to using the default ringtone

  # ---------------------------------------------------------------------------
  # Rendez-Vous Mode
  # ---------------------------------------------------------------------------

  @rendezvous @smoke
  Scenario: Enable rendez-vous mode for an account
    Given rendez-vous mode is currently disabled for the account
    When the user enables rendez-vous mode
    Then the rendez-vous setting is saved as enabled for the account
    And the account acts as a persistent conference room

  @rendezvous @smoke
  Scenario: Disable rendez-vous mode for an account
    Given rendez-vous mode is currently enabled for the account
    When the user disables rendez-vous mode
    Then the rendez-vous setting is saved as disabled for the account
    And the account returns to normal call behaviour

  # ---------------------------------------------------------------------------
  # Local Video Default
  # ---------------------------------------------------------------------------

  @local-video @smoke
  Scenario: Enable local video by default for an account
    Given local video by default is currently disabled for the account
    When the user enables the "local video by default" option
    Then the setting is saved as enabled for the account
    And outgoing calls on that account start with video enabled by default

  @local-video @smoke
  Scenario: Disable local video by default for an account
    Given local video by default is currently enabled for the account
    When the user disables the "local video by default" option
    Then the setting is saved as disabled for the account
    And outgoing calls on that account start as audio-only by default

  # ---------------------------------------------------------------------------
  # TLS Settings
  # ---------------------------------------------------------------------------

  @tls @security @smoke
  Scenario: Configure a TLS CA certificate for an account
    Given the account TLS CA certificate field is empty
    When the user provides a valid CA certificate file path
    And saves the account settings
    Then the CA certificate path is stored for the account
    And TLS connections use that CA for server verification

  @tls @security @smoke
  Scenario: Configure a TLS client certificate for an account
    Given the account TLS client certificate field is empty
    When the user provides a valid client certificate file path
    And saves the account settings
    Then the client certificate path is stored for the account

  @tls @security @smoke
  Scenario: Configure a TLS private key for an account
    Given the account TLS private key field is empty
    When the user provides a valid private key file path
    And saves the account settings
    Then the private key path is stored for the account

  @tls @security
  Scenario: Full TLS configuration — CA, certificate, and key together
    When the user sets the CA certificate to "ca.crt"
    And the user sets the client certificate to "client.crt"
    And the user sets the private key to "client.key"
    And saves the account settings
    Then all three TLS fields are stored correctly for the account
    And the account uses mutual TLS authentication for outbound connections

  @tls @security @edge-case
  Scenario: Invalid TLS certificate file is rejected
    When the user provides a file that is not a valid certificate as the CA certificate
    Then the client rejects the file
    And an informative error message is shown
    And the previous CA certificate value is unchanged

  # ---------------------------------------------------------------------------
  # Persistence & Reset
  # ---------------------------------------------------------------------------

  @persistence @smoke
  Scenario: Account settings persist across client restart
    Given the user has configured specific settings for an account
    When the client is closed and restarted
    And the user opens the settings for that account
    Then all previously configured settings are present and unchanged

  @defaults @smoke
  Scenario: Reset account settings to defaults
    Given the user has customised multiple settings for an account
    When the user resets the account settings to their defaults
    Then all account settings return to their default values
    And the reset is reflected immediately in the settings view
    And the account identifier and credentials are not affected

  @defaults
  Scenario: Reset account settings does not affect other accounts
    Given the user has two or more configured accounts
    And account "A" has customised settings
    And account "B" has customised settings
    When the user resets account "A" settings to defaults
    Then only account "A" settings are reset
    And account "B" settings remain unchanged
