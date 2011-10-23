Feature: Error Handling

  Scenario: Missing action
    When I run `cuki`
    Then it should fail with:
      """
      No action given
      """

  Scenario: Missing config
    Given no file named "config/cuki.yaml" exists
    When I run `cuki pull`
    Then it should fail with:
      """
      No config file found at config/cuki.yaml
      """

  Scenario: Missing scenarios
    Given a file named "config/cuki.yaml" with:
      """
      ---
      host: http://example.com
      mappings:
        123: features/products
      """
    And a Confluence page on "example.com" with id 123:
      """
      <input id="content-title" value="Add Product">
      <div id="markupTextarea">
      h1. Acceptance Criteria
      </div>
      """
    When I run `cuki pull --skip-autoformat`
    Then it should fail with:
      """
      No scenarios found in doc 123
      """

