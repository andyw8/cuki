Feature: Pull single

  Scenario: Pull all features
    Given a file named "config/cuki.yaml" with:
      """
      ---
      host: http://example.com
      mappings:
        123: features/products/add_product.feature
        456: features/products/remove_product.feature
      """
    And a Confluence page on "example.com" with id 123:
      """
      <input id="content-title" value="Add Product">
      <div id="markupTextarea">
      This feature describes adding a product
      </div>
      """
    And a Confluence page on "example.com" with id 456:
      """
      <input id="content-title" value="Remove Product">
      <div id="markupTextarea">
      This feature describes removing a product
      </div>
      """
    When I run `cuki pull features/products/add_product.feature`
    Then a file named "features/products/add_product.feature" should exist
    But the file "features/products/remove_product.feature" should not exist

