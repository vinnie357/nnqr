# 0002 — Rules and research precedence
Status: Accepted

## Context
Old implementations and research disagree on catalog sizes, spawn timing and effects.
## Decision
Original directions at https://quadradius.ddns.net/directions.html take precedence, then research/quadradius/game_details/powers.md and overview.md. Use all named collectible powers; Cancel Multiply is UI cancellation, not loot. Record uncertain interpretations in docs/rules.md.
Default 10 columns x 8 rows; 20 pieces each; heights -4..4; orthogonal moves, climb <=1, unlimited descent. Powers precede movement; moving ends the turn except Move Again. Capture by occupation. Powers are piece-owned.
Five equally likely power orbs spawn every seven rounds (14 completed turns), on available empty tiles; initial five orbs make the opening engaging. These exact counts and initial wave are Astra tuning. Overheat at >=10 copies of one inventory power destroys the piece and tile. Forced pass only with no moves. Two consecutive forced passes without a state change draw; simultaneous elimination draws. No turn timer in local play.
## Alternatives
Exact parity with old code would inherit contradictions. No invented powers merely to reach a claimed count.
## Consequences and interfaces
Tests and tooltips must agree with actual effects. Original descriptions are reference material, not a license to copy long prose verbatim.
## Verification
Catalog completeness, every effect family, turn semantics, boundaries, overload, capture and elimination scenarios.
