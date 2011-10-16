@pending
Feature: Pull

  Scenario: Missing action
    When I run `cuki`
    Then it should fail with:
      """
      No action given
      """

  Scenario: Missing config
    When I run `cuki pull`
    Then it should fail with:
      """
      No config file found at config/cuki.yaml
      """

  @focus @announce
  Scenario: 
    Given a file named "config/cuki.yaml" with:
      """
      ---
      host: http://example.com
      mappings:
        123: products/add_product
        456: products/remove_product
      """
    And a Confluence page on "example.com" with id "123":
      """
      <input id="#content-title" value="Add Product">
      <div id="markupTextarea">
      This feature describes removing a product
      </div>
      """
    When I run `cuki pull`

