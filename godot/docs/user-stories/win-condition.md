# User story: win condition — eliminate the last enemy piece

Covers the end-game condition: when the last opponent piece is captured, the game ends
with a win banner.

QA scenario: `res://scenarios/qa_win.json`

```gherkin
Feature: Win condition — capturing the last enemy piece ends the game
  Background:
    Given the see-harness is run against a scenario JSON

  Scenario: Player 1 captures player 2's only remaining piece and wins
    Given a board with only one player-1 piece at (4,4) and one player-2 piece at (5,4)
    And current_player is 1
    When the scenario input clicks (4,4) to select the player-1 piece
    And clicks (5,4) to move onto and capture the player-2 piece
    Then state.json shows status == "won"
    And state.json shows winner == 1
    And state.json shows no player-2 pieces remain in pieces[]
    And the rendered frame shows the win/game-over state

  Notes:
    - board.gd check_winner returns 1 when no player-2 pieces remain
    - move_to sets status = "won" and winner = 1 after check_winner
    - The scenario uses the minimal 1v1 board to guarantee the capture ends the game
```
