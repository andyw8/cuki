Feature: Pull

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
      
      # Some comment
      
      Blah
      </div>
      """
    And a Confluence page on "example.com" with id 456:
      """
      <input id="content-title" value="Remove Product">
      <div id="markupTextarea">
      This feature describes removing a product
      </div>
      """
    When I run `cuki pull --skip-autoformat`
    Then the file "features/products/add_product.feature" should contain exactly:
      """
      Feature: Add Product

      http://example.com/pages/viewpage.action?pageId=123


      This feature describes adding a product
      
      - Some comment
      
      Blah

      """
    And the file "features/products/remove_product.feature" should contain exactly:
      """
      Feature: Remove Product

      http://example.com/pages/viewpage.action?pageId=456


      This feature describes removing a product

      """

