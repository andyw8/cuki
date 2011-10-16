Feature: Push

  @focus
  Scenario: Push a feature with no scenarios
    Given a file named "config/cuki.yaml" with:
      """
      ---
      host: http://mywiki
      mappings:
        123: products/add_product
      """
    And a file named "features/products/add_product.feature" with:
      """
      Feature: Hello world & all

      This is my feature
      """
    And a Confluence page exists on "mywiki" with id 123, title "Hello world & all" and content:
      """
      This is my feature
      """
    When I run `cuki push features/products/add_product.feature`
    Then the push should be successful

  @pending
  Scenario: Push a feature containing a scenario
    Given a file named "config/cuki.yaml" with:
      """
      Scenario: My scenario
        Given something
        When something
        Then something
      """
    When I push that feature
    Then the Confluence content should include:
      """
      h2. My scenario

      Given something
      When something
      Then something
      """

  @pending
  Scenario: Push a feature containing a scenario outline
    
    The first row of the examples table should be a header row.
    Given a feature file in "features/hello_world.feature"
    And that feature includes the scenario:
      """
      Scenario: My scenario
        Given <condition>
        When <action>
        Then <outcome>
        Examples:
          | condition | action | outcome |
          | a         | b      | c       |
      """
    When I push that feature
    Then the Confluence content should include:
      """
      h2. My scenario

      Given <condition>
      When <action>
      Then <outcome>
      Examples:
         || condition || action || outcome ||
         | a         | b      | c       |

      """

  @pending
  Scenario: Push a feature containing a scenario outline with multiple example
    Pending

