Feature: Textile

  Scenario: 
    Given a file named "config/cuki.yaml" with:
      """
      ---
      host: http://example.com
      mappings:
        123: products/add_product
      """
    And a Confluence page on "example.com" with id 123:
      """
      <input id="content-title" value="Add Product">
      <div id="markupTextarea">
      h5. Scenario: Foo
      
      h6. Scenario Outline: Bar
      </div>
      """
    When I run `cuki pull`
    Then the file "features/products/add_product.feature" should contain exactly:
      """
      Feature: Add Product

      http://example.com/pages/editpage.action?pageId=123


      Scenario: Foo
      
      Scenario Outline: Bar

      """