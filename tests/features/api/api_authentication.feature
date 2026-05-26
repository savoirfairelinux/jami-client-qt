@api @authentication
Feature: API Authentication
  As an integrator or developer
  I want to manage API bearer tokens
  So that I can securely authenticate requests and revoke access when needed

  Background:
    Given the client is running
    And the user has an active account
    And the API server is running

  # ─── Token Creation ──────────────────────────────────────────────────────

  @token-creation @smoke
  Scenario: Create a new API token
    When the user creates a new API token for the account
    Then the client returns a token string
    And the token is associated with the account

  @token-creation
  Scenario: Token has a unique identifier
    When the user creates two API tokens for the account
    Then each token has a distinct identifier
    And the identifiers are not equal

  @token-creation
  Scenario: Token has creation timestamp and expiration
    When the user creates a new API token for the account
    Then the token record includes a creation timestamp
    And the token record includes an expiration value

  @token-creation
  Scenario: Token metadata (description/name) is stored
    When the user creates a new API token with the description "CI integration token"
    Then the token record stores the description "CI integration token"
    And the description is returned when the token list is queried

  @token-creation
  Scenario: Create multiple tokens for the same account
    When the user creates 3 API tokens for the account
    Then 3 tokens appear in the token list for the account
    And each token has a unique identifier

  # ─── Authentication ──────────────────────────────────────────────────────

  @auth @smoke
  Scenario: Authenticate a request with a valid bearer token
    Given a valid API token exists for the account
    When a client sends GET /api/account with the bearer token in the Authorization header
    Then the response status code is 200
    And the response body contains account information

  @auth @smoke
  Scenario: Reject a request with an invalid bearer token
    When a client sends GET /api/account with an invalid bearer token
    Then the response status code is 401

  @auth @smoke
  Scenario: Reject a request with no authentication token
    When a client sends GET /api/account without any Authorization header
    Then the response status code is 401

  # ─── Token Revocation ────────────────────────────────────────────────────

  @revocation @smoke
  Scenario: Revoke a specific token
    Given a valid API token "token-A" exists for the account
    When the user revokes "token-A"
    Then the client confirms that "token-A" was revoked

  @revocation @smoke
  Scenario: Revoked token no longer authenticates
    Given a valid API token "token-A" exists for the account
    And "token-A" has been revoked
    When a client sends GET /api/account with "token-A" as the bearer token
    Then the response status code is 401

  @revocation
  Scenario: Revoking one token does not affect other tokens
    Given valid API tokens "token-A" and "token-B" exist for the account
    When the user revokes "token-A"
    Then a request authenticated with "token-B" succeeds with status code 200

  @revocation
  Scenario: Revoke all tokens for an account
    Given multiple valid API tokens exist for the account
    When the user revokes all tokens for the account
    Then the token list for the account is empty
    And requests using any of the previously valid tokens return status code 401

  # ─── Token Listing ───────────────────────────────────────────────────────

  @listing
  Scenario: List all active tokens for an account
    Given 3 active API tokens exist for the account
    When the user requests the token list via GET /api/tokens
    Then the response contains exactly 3 token entries
    And each entry includes the token identifier and creation timestamp

  # ─── Persistence ─────────────────────────────────────────────────────────

  @persistence @smoke
  Scenario: Tokens persist across API server restarts
    Given a valid API token "persistent-token" exists for the account
    When the API server is restarted
    Then "persistent-token" is still present in the token list
    And a request authenticated with "persistent-token" succeeds with status code 200

  # ─── Token Expiration ────────────────────────────────────────────────────

  @expiration
  Scenario Outline: Token expiration behaviour
    Given an API token created with expiration setting "<expiration>"
    When the token's expiration condition is reached
    Then a request authenticated with that token returns status code <expected_status>

    Examples:
      | expiration   | expected_status |
      | never        | 200             |
      | already past | 401             |
