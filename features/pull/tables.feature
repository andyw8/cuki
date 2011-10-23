# Assume no header for single column tables?
Feature: Tables

  Scenario: Table with more than one column
    Given a file named "config/cuki.yaml" with:
      """
      ---
      host: http://example.com
      mappings:
        123: features/products
      """
    And a Confluence page on "example.com" with id 123:
      """
      <input id="content-title" value="Products">
      <div id="markupTextarea">
      h1. Acceptance Criteria
      
      h2. Add Product
      
      h6. Scenario: Foo

      Given this:
      || foo || bar ||
      | a | 1 |
      | b | 2 |
      </div>
      """
    When I run `cuki pull --skip-autoformat`
    Then the file "features/products/add_product.feature" should contain exactly:
      """
      Feature: Add Product

      http://example.com/pages/viewpage.action?pageId=123#Products-AddProduct

      Scenario: Foo

      Given this:
      | foo | bar |
      | a | 1 |
      | b | 2 |

      """

