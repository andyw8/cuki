Feature: Error Handling

  Scenario: Missing action
    When I run `cuki`
    Then it should fail with:
      """
      No action given
      """

  Scenario: Missing config
    Given no file named "config/cuki.yaml" exists
    When I run `cuki pull`
    Then it should fail with:
      """
      No config file found at config/cuki.yaml
      """