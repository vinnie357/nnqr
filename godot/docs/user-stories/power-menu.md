# User story: power menu and collected powers

Covers collecting power orbs from the board and seeing them in the power menu.

QA scenario: `res://scenarios/orb_collect.json` (collection flow),
             `res://scenarios/powermenu.json` (menu display with pre-loaded powers)

```gherkin
Feature: Collecting and using powers
  Background:
    Given the see-harness is run against a scenario JSON

  Scenario: A piece that moves onto an orb tile collects the orb's power
    Given a state with a player-1 piece at (4,5) and an orb at (4,4) with power_id "raise_tile"
    When the scenario inputs select (4,5) then click (4,4) to move
    Then state.json shows the piece at row:4 col:4 with powers containing "raise_tile"
    And state.json shows orbs == []
    And the rendered frame shows the piece's power badge
    QA file: res://scenarios/orb_collect.json

  Scenario: Orbs spawn automatically on the turn interval
    Given a state at turn == SPAWN_INTERVAL - 1 (6) with open tiles
    When the player makes one move (turn becomes 7)
    Then state.json shows orbs non-empty (newly spawned)

  Scenario: Overheat — collecting a 10th copy of one power destroys the piece
    Given a piece already holding 9 copies of "bomb"
    When that piece moves onto an orb tile with power_id "bomb"
    Then state.json shows the piece is absent from pieces (destroyed by overheat)

  Scenario: A selected piece with collected powers shows them in the power menu
    Given a state with a player-1 piece holding ["relocate", "flat_to_sphere", "relocate"]
    When the scenario input clicks the piece tile
    Then state.json shows the piece selected
    And the rendered frame shows the power menu listing "relocate" and "flat_to_sphere"
    QA file: res://scenarios/powermenu.json
```

## QA harness scenarios (driven from a fresh state)

- `res://scenarios/qa_collect_menu.json` — starts with p1 piece having empty powers
  and an orb adjacent; drives move-onto-orb (collect), then ai_turn to return turn to
  player 1, then re-select to show menu. Asserts power gained, orb gone, piece selected.
