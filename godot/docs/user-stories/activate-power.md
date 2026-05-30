# User story: activate a power and observe its board effect

Covers activating a collected power and verifying the resulting board state change.

QA scenario: `res://scenarios/qa_activate_power.json`

```gherkin
Feature: Activate a power and observe its board effect
  Background:
    Given the see-harness is run against a scenario JSON

  Scenario: Activating jump_proof marks the piece as jump-proof in state
    Given a state with a player-1 piece at (4,5) holding ["jump_proof"] in powers
    And the piece is selected so it is the active piece
    When the scenario input activates "jump_proof" (no target needed — self power)
    Then state.json shows the piece at (4,5) with is_jump_proof == true
    And state.json shows the piece's powers no longer contains "jump_proof" (consumed)

  Notes:
    - jump_proof is a permanent, self-targeting power (needs_target returns false)
    - The effect is directly assertable: is_jump_proof field on the piece in state.json
    - The power is consumed from inventory on activation (single_use duration)
    - Starting state provides the power in inventory (acceptable: task brief permits
      a starting power when the focus is activation behavior, not collection)
```
