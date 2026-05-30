# User story: move and capture

Basic piece movement and capture flow for the Godot implementation.

QA scenario: `res://scenarios/capture.json`

```gherkin
Feature: Basic piece movement and capture
  Background:
    Given the see-harness is run against a scenario JSON

  Scenario: A player selects a piece and sees its valid moves
    Given a state with a player-1 piece at (4,5)
    When the scenario input clicks (4,5)
    Then state.json shows selected == {row:4, col:5}
    And state.json shows valid_moves non-empty
    And the rendered frame shows the selected tile outlined

  Scenario: Moving a piece ends the turn
    Given a selected piece at (4,5) with a valid move to (4,4)
    When the scenario input clicks (4,4)
    Then state.json shows the piece at row:4 col:4
    And state.json shows current_player == 2
    And state.json shows turn incremented by 1

  Scenario: Moving onto the last enemy piece wins the game
    Given only one enemy piece remains and a player piece is adjacent
    When the player piece moves onto the enemy tile
    Then state.json shows status == "won" and winner is set
```
