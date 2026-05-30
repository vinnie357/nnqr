# User story: power menu and collected powers list

Covers collecting power orbs and using them from the menu.

```gherkin
Feature: Collecting and using powers
  Background:
    Given the game is running at http://localhost:1425
    And a new game has started

  Scenario: A piece that has collected powers lists them in the menu
    Given a piece owned by the current player holds the powers ["bomb", "bomb", "relocate"]
    When I select that piece
    Then the power menu shows a header "Powers"
    And the menu lists "bomb" with a count of "×2"
    And the menu lists "relocate"
    And a piece with no powers shows "(none)" in the menu

  Scenario: A piece approaching overheat is flagged
    Given a piece holds 7 or more copies of the same power
    Then that power's menu entry shows an overheat warning marker
    And collecting a 10th copy of one power destroys the piece (overheat)

  Scenario: Activating an immediate power from the menu
    Given a selected piece holds an immediate (non-targeted) power
    When I click that power in the menu (or press its number key)
    Then the power's effect is applied and the power is consumed
    And a screenshot reflects the board change

  Scenario: Activating a targeted power
    Given a selected piece holds a targeted power (e.g. raise_tile)
    When I click that power in the menu
    Then valid target tiles are highlighted
    And clicking a highlighted tile applies the power to that tile
    And pressing Escape instead cancels targeting without consuming the power

  Scenario: Orbs become collectable powers
    Given the game has reached a turn where orbs have spawned
    When a piece moves onto an orb's tile
    Then the orb is removed from the board
    And that piece's power list gains the orb's power
    And a screenshot shows the piece's power badge
```
