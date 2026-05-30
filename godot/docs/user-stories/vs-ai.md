# User story: human move then AI responds

Covers the two-turn loop: player 1 makes a move, then the AI (player 2) responds.

QA scenario: `res://scenarios/qa_vs_ai.json`

```gherkin
Feature: Human move followed by AI response
  Background:
    Given the see-harness is run against a scenario JSON

  Scenario: AI responds with a legal move after the human's turn
    Given a small board with player-1 piece at (3,5) and player-2 pieces at (6,4), (6,5), (6,6)
    And current_player is 1
    When the scenario input clicks (3,5) to select
    And clicks (4,5) to move player 1's piece
    And applies an ai_turn with difficulty "medium"
    Then state.json shows current_player == 1 (cycled back after two turns)
    And state.json shows a player-2 piece is no longer at its original position
      (the AI moved one of its pieces — verified by checking player-2 piece positions changed)
    And state.json shows status == "playing"

  Notes:
    - After human move: current_player becomes 2, turn increments
    - After ai_turn: current_player becomes 1, turn increments again
    - The assertion checks that at least one player-2 piece position changed,
      proving the AI made a real move rather than passing
```
