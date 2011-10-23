Feature: Tags

  Scenario: 
    Given a file named "config/cuki.yaml" with:
      """
      ---
      host: http://example.com
      tags:
        draft: "{info:title=Draft version}"
        signed_off: "{info:title=Signed-off}"
      mappings:
        123: features/products
      """
    And a Confluence page on "example.com" with id 123:
      """
      <input id="content-title" value="Products">
      <div id="markupTextarea">
      h1. Acceptance Criteria
      
      {info:title=Draft version}
      
      h2. Add Product
      
      h6. Scenario: Foo
      </div>
      """
    When I run `cuki pull --skip-autoformat`
    Then the file "features/products/add_product.feature" should contain exactly:
      """
      @draft
      Feature: Add Product

      http://example.com/pages/viewpage.action?pageId=123#Products-AddProduct

      Scenario: Foo

      """

