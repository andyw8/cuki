Feature: Splitting
  
  Instead of association one wiki page per feature file, you can split a wiki file across multiple feature files.

  @announce
  Scenario: Pull all features
    Given a file named "config/cuki.yaml" with:
      """
      ---
      host: http://example.com
      container: !ruby/regexp '/h1\. Acceptance Criteria(.*)h1\./m'
      mappings:
        123: features/products
      """
    And a Confluence page on "example.com" with id 123:
      """
      <input id="content-title" value="Product Management">
      <div id="markupTextarea">
      h1. Acceptance Criteria

      Something

      h2. Add Product

      This feature describes adding a product

      h6. Scenario: Scenario A

      h2. Remove Product

      This feature describes removing a product

      h6. Scenario Outline: Scenario B

      h1. Next Section
      </div>
      """
    When I run `cuki pull --skip-autoformat --skip-header`
    Then the file "features/products/add_product.feature" should contain exactly:
      """
      Feature: Add Product



      http://example.com/pages/viewpage.action?pageId=123#ProductManagement-AddProduct

      This feature describes adding a product

      Scenario: Scenario A


      """
    And the file "features/products/remove_product.feature" should contain exactly:
      """
      Feature: Remove Product



      http://example.com/pages/viewpage.action?pageId=123#ProductManagement-RemoveProduct

      This feature describes removing a product

      Scenario Outline: Scenario B


      """

