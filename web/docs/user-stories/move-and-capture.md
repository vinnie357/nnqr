# User story: move and capture (walking skeleton)

The first `/qa` scenario — proves the AI can see and drive the web game.

```gherkin
Feature: Basic piece movement and capture
  Background:
    Given the game is running at http://localhost:1425

  Scenario: A player selects a piece and sees its valid moves
    When I evaluate "window.NNQR.api.select(2, 5)"
    Then "window.NNQR.getState().selected" equals { row: 2, col: 5 }
    And "window.NNQR.getState().validMoves" is not empty
    And a screenshot shows the selected tile outlined and move markers

  Scenario: Moving a piece ends the turn
    Given I evaluate "window.NNQR.api.reset()"
    When I evaluate "window.NNQR.api.select(2, 5)"
    And I evaluate "window.NNQR.api.move(3, 5)"
    Then "window.NNQR.getState().currentPlayer" equals 2
    And "window.NNQR.getState().turn" equals 1
    And a screenshot shows a player-1 piece on row 3, column 5

  Scenario: Capturing the last enemy piece wins the game
    # Driven from a constructed state in a focused test; full-board capture is exercised in vitest.
    Then "window.NNQR.getState().status" can reach "won" with a "winner"
```
