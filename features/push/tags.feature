@pending
Feature: Tags
  
  Tags on a feature or scenario should be turned into {info} macros.

  Scenario: Tagged feature
    
    Tag names should be titleised, with underscores converted to spaces.
    Given the feature:
      """
      @pending @in_progress @some-other
      Feature: Hello world

      Here is the feature
      """
    When I push that feature to Confluence
    Then the Confluence content should be:
      """
      {info:Pending}
      {info:In Progress}
      {info:Some-other}

      Here is a feature
      """

