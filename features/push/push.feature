@pending
Feature: Push

  Background: 
    Given a file named "config/cuki.yaml" with:
      """
      ---
      host: http://mywiki
      mappings:
        123: products/add_product
      """

  Scenario: Push a feature with no scenarios
    Given a file named "config/cuki.yaml" with:
      """
      Feature: Hello world & all

      This is my feature
      """
    When I run `cuki push features/products/add_product.feature`
    Then the feature should be pushed to "http://mywiki/pages/editpage.action?pageId=123"
    And the Confluence content should be:
      """
      This is my feature
      """
    And the Confluence title should be:
      """
      Hello world & all
      """

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

  Scenario: Push a feature containing a scenario outline with multiple example
    Pending
