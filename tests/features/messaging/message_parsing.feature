@messaging
Feature: Message Parsing
  As a user of the Jami communication client
  I want messages to be rendered with markdown formatting, clickable hyperlinks, and link previews
  So that rich content is presented clearly and is easy to interact with

  Background:
    Given the client is running
    And the user is authenticated with a valid account
    And the user has opened a conversation with a peer
    And the messageParsed signal is observed for incoming messages

  # ---------------------------------------------------------------------------
  # Markdown — inline formatting
  # ---------------------------------------------------------------------------

  @smoke
  Scenario Outline: Inline markdown formatting rendered correctly
    When the peer sends the message "<raw_text>"
    Then the message is rendered with the formatting "<expected_rendering>"
    And the markdown syntax characters are not displayed literally

    Examples:
      | raw_text                  | expected_rendering        |
      | **bold text**             | bold text (bold)          |
      | *italic text*             | italic text (italic)      |
      | ***bold italic text***    | bold italic text          |
      | `inline code`             | inline code (monospace)   |

  @regression
  Scenario: Fenced code block rendered correctly
    When the peer sends a message containing a fenced code block:
      """
      ```
      def hello():
          print("Hello, world!")
      ```
      """
    Then the code block is rendered in a monospace block style
    And the content of the code block is preserved exactly, including indentation
    And the code block is visually distinct from surrounding prose

  @regression
  Scenario: Line breaks preserved in message
    When the peer sends a message with explicit line breaks between paragraphs
    Then each line break is rendered as a visible vertical separation
    And the overall message layout reflects the original structure

  @regression
  Scenario: Plain text with no formatting rendered as-is
    When the peer sends the message "Just plain text with no special syntax"
    Then the message is displayed as "Just plain text with no special syntax"
    And no formatting is applied

  # ---------------------------------------------------------------------------
  # Hyperlinks
  # ---------------------------------------------------------------------------

  @smoke
  Scenario: Hyperlink auto-detected and rendered as clickable
    When the peer sends the message "Check out https://jami.net for more info"
    Then the URL "https://jami.net" is rendered as a clickable hyperlink
    And the surrounding text is rendered as plain text

  @regression
  Scenario: Complex URL with special characters parsed correctly
    When the peer sends a message containing the URL "https://example.com/path?query=hello%20world&ref=test#section"
    Then the full URL is detected and rendered as a clickable hyperlink
    And the URL is not truncated or corrupted

  @regression
  Scenario: Multiple links in a single message each rendered as clickable
    When the peer sends the message "Visit https://jami.net and https://gnu.org for more"
    Then "https://jami.net" is rendered as a clickable hyperlink
    And "https://gnu.org" is rendered as a clickable hyperlink
    And the text between the links is rendered as plain text

  # ---------------------------------------------------------------------------
  # Link previews
  # ---------------------------------------------------------------------------

  @regression
  Scenario: Link preview generated for a supported URL
    Given the linkInfoReady signal is observed
    When the peer sends a message containing a URL to a supported webpage
    Then a link preview is displayed beneath the message
    And the link preview contains a title extracted from the page

  @regression
  Scenario: Link preview shows title and description
    Given the linkInfoReady signal fires for a URL in a message
    When the link preview is rendered
    Then the preview displays the page title
    And the preview displays the page description
    And the preview is visually associated with the original message

  @regression
  Scenario: Link preview includes an image for pages that provide one
    Given the linkInfoReady signal fires for a URL that has an open-graph image
    When the link preview is rendered
    Then the preview displays the image alongside the title and description

  @regression
  Scenario: YouTube link shows video preview
    When the peer sends a message containing a YouTube video URL
    Then a link preview for the video is displayed
    And the preview includes the video title
    And the preview includes a thumbnail image

  @regression
  Scenario: Multiple links in single message each get previews
    When the peer sends a message containing two distinct URLs
    And the linkInfoReady signal fires for both URLs
    Then a link preview is generated for each URL
    And both previews are displayed in association with the message
