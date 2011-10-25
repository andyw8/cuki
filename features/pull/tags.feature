Feature: Tags

  @announce
  Scenario: 
    Given a file named "config/cuki.yaml" with:
      """
      ---
      host: http://example.com
      tags:
        draft: "{info:title=Draft version}"
        pending: "{info:title=Pending}"
        another: "{info:title=Another}"
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
      
      {info:title=Pending}
      {info:title=Another}
      
      h6. Scenario: Foo
      </div>
      """
    When I run `cuki pull --skip-autoformat`
    Then the file "features/products/add_product.feature" should contain exactly:
      """
      @draft
      Feature: Add Product

      http://example.com/pages/viewpage.action?pageId=123#Products-AddProduct

      @pending

      @another


      Scenario: Foo

      """

