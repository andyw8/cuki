# Assume no header for single column tables?
Feature: Tables

  Scenario: Table with more than one column

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

      Given this:
      || foo || bar ||
      | a | 1 |
      | b | 2 |
      </div>
      """
    When I run `cuki pull`
    Then the file "features/products/add_product.feature" should contain exactly:
      """
      Feature: Add Product

      http://example.com/pages/editpage.action?pageId=123


      Scenario: Foo

      Given this:
      | foo | bar |
      | a | 1 |
      | b | 2 |

      """
