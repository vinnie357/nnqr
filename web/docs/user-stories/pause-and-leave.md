# User story: pause and leave a game

A player must be able to pause an in-progress game and to leave it back to the
title screen. (Playtest gap: after starting a game there was no discoverable way
to pause or quit.)

```gherkin
Feature: Pausing and leaving a game
  Background:
    Given the game is running at http://localhost:1425
    And a vs-AI game is in progress

  Scenario: Pause and resume
    When I press Escape (and no power-targeting is active)
    Then a pause overlay appears with "Resume" and "Quit to Title" options
    And the board input is suspended while paused
    And choosing "Resume" (or pressing Escape again) returns to the game in the same state

  Scenario: Leave to the title screen
    Given the pause overlay is open
    When I choose "Quit to Title"
    Then the title screen is shown
    And starting a new game from the title begins a fresh game (turn 0)

  Scenario: Escape still cancels power targeting first
    Given a targeted power is in targeting mode
    When I press Escape
    Then targeting is cancelled (the pause overlay does NOT open)
    And pressing Escape again (now idle) opens the pause overlay

  Scenario: The pause/menu control is discoverable
    Then an on-screen control (a "Menu" button or visible hint) indicates how to pause/leave
```
