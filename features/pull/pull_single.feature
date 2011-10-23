Feature: Pull single

  Scenario: Pull single feature
    Given a file named "config/cuki.yaml" with:
      """
      ---
      host: http://example.com
      mappings:
        123: features/products
        456: features/admin
      """
    And a Confluence page on "example.com" with id 123:
      """
      <input id="content-title" value="Products">
      <div id="markupTextarea">
      h1. Acceptance Criteria
      h2. Add Product
      h6. Scenario
      </div>
      """
    And a Confluence page on "example.com" with id 456:
      """
      <input id="content-title" value="Admin">
      <div id="markupTextarea">
      h1. Acceptance Criteria
      h2. Edit User
      h6. Scenario
      </div>
      """
    When I run `cuki pull features/products --skip-autoformat`
    Then a file named "features/products/add_product.feature" should exist
    But the file "features/admin/edit_user.feature" should not exist

