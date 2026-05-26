@api @server
Feature: API Server
  As an integrator or developer
  I want to interact with the embedded API server
  So that I can programmatically manage accounts, conversations, contacts, and calls

  Background:
    Given the client is running
    And the user has an active account
    And a valid API bearer token exists for the account

  # ─── Server Lifecycle ────────────────────────────────────────────────────

  @lifecycle @smoke
  Scenario: Start the API server
    Given the API server is not running
    When the user enables the API server
    Then the API server starts successfully
    And the server is listening on the configured local port

  @lifecycle @smoke
  Scenario: Server reports its listening port
    Given the API server is running
    When the user queries the server configuration
    Then the client reports the port number the server is listening on

  @lifecycle
  Scenario: Stop the API server
    Given the API server is running
    When the user disables the API server
    Then the API server stops
    And requests to the API are no longer accepted

  # ─── Core REST Endpoints ─────────────────────────────────────────────────

  @rest @account @smoke
  Scenario: Get account information via GET /api/account
    Given the API server is running
    When a client sends GET /api/account with a valid bearer token
    Then the response status code is 200
    And the response body is valid JSON
    And the JSON contains the account identifier
    And the JSON contains the account display name

  @rest @conversations @smoke
  Scenario: List conversations via GET /api/conversations
    Given the API server is running
    And the account has at least one conversation
    When a client sends GET /api/conversations with a valid bearer token
    Then the response status code is 200
    And the response body is valid JSON
    And the JSON contains a list of conversation entries

  @rest @contacts @smoke
  Scenario: List contacts via GET /api/contacts
    Given the API server is running
    And the account has at least one contact
    When a client sends GET /api/contacts with a valid bearer token
    Then the response status code is 200
    And the response body is valid JSON
    And the JSON contains a list of contact entries

  @rest @calls @smoke
  Scenario: Initiate a call via POST /api/calls
    Given the API server is running
    And the account has a contact with a known URI
    When a client sends POST /api/calls with a valid bearer token and the contact URI
    Then the response status code is 200
    And the response body contains a call identifier

  @rest @nameserver
  Scenario: Nameserver lookup via GET /api/nameserver
    Given the API server is running
    When a client sends GET /api/nameserver with a valid bearer token and a registered username
    Then the response status code is 200
    And the response body is valid JSON
    And the JSON contains the resolved address for the username

  # ─── Response Format ─────────────────────────────────────────────────────

  @rest @format
  Scenario Outline: API returns proper JSON for all standard endpoints
    Given the API server is running
    When a client sends <method> <endpoint> with a valid bearer token
    Then the response status code is <expected_status>
    And the response Content-Type header indicates JSON

    Examples:
      | method | endpoint           | expected_status |
      | GET    | /api/account       | 200             |
      | GET    | /api/conversations | 200             |
      | GET    | /api/contacts      | 200             |
      | GET    | /api/tokens        | 200             |

  # ─── Error Responses ────────────────────────────────────────────────────

  @rest @error-handling @smoke
  Scenario: API returns 404 for unknown routes
    Given the API server is running
    When a client sends GET /api/nonexistent-route with a valid bearer token
    Then the response status code is 404

  # ─── Isolation ───────────────────────────────────────────────────────────

  @isolation
  Scenario: Multiple API server instances operate in isolation
    Given two separate client instances are running with different accounts
    And each client has its own API server running on distinct ports
    When a request is made to the first client's API server
    Then the response reflects only the first account's data
    When a request is made to the second client's API server
    Then the response reflects only the second account's data
