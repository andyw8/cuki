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
        123: products/add_product
      """
    And a Confluence page on "example.com" with id 123:
      """
      <input id="content-title" value="Add Product">
      <div id="markupTextarea">{info:title=Draft version}
      h5. Scenario: Foo
      </div>
      """
    When I run `cuki pull`
    Then the file "features/products/add_product.feature" should contain exactly:
      """
      @draft
      Feature: Add Product

      http://example.com/pages/editpage.action?pageId=123


      Scenario: Foo

      """
