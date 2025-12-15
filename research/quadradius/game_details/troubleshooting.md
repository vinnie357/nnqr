# Quadradius Troubleshooting & Strategy Guide

> Research Date: 2025-12-14
> Source: https://quadradius.ddns.net/directions.html

## Common Gameplay Mistakes

### Power Management Errors

#### Overheat
**Problem**: Piece overheats and **explodes (destroyed)**.

**Cause**: Accumulating 10+ of the same power on a single piece.

**Prevention**:
- Distribute powers across multiple pieces using **Teach**
- Use powers before collecting more of the same type
- Track power counts on key pieces

#### Power Hoarding
**Problem**: Concentrating too many powers on one piece makes it a high-value target.

**Solution**:
- Spread powers across your squadron
- Use **Teach** to share powers with allies
- Keep some "decoy" pieces with moderate power

### Movement Mistakes

#### Forgetting Movement Limits
**Problem**: Attempting diagonal movement without the power.

**Rule Reminder**: Default movement is only in 4 cardinal directions (up, down, left, right).

**Solution**: Acquire **Move Diagonal** power to enable 8-directional movement.

#### Edge Awareness
**Problem**: Getting cornered at board edges.

**Solution**:
- Use **Flat To Sphere** power to treat edges as connected (wraparound)
- Plan escape routes before advancing deep into enemy territory

### Tactical Errors

#### Leaving Pieces Unprotected
**Problem**: Pieces get jumped by opponents.

**Solutions**:
- Use **Jump Proof** on valuable pieces
- Position pieces on higher terrain (use **Plateau**)
- Keep pieces supported by allies

#### Ignoring Terrain
**Problem**: Not leveraging elevation advantages.

**Solutions**:
- Use **Raise Tile** to create defensive positions
- Block enemy paths with **Wall Row/Column**
- Create traps with **Trench Row/Column**

## Rule Clarifications

### Power Activation Timing

**Q**: When can powers be used?
**A**: Powers are activated **BEFORE** movement. You may use any number of powers, then move. **Moving ends your turn** (unless you have Move Again power).

### Jump Mechanics

**Q**: How does jumping work?
**A**: Land on an opponent's piece to eliminate it. The **Jump Proof** power prevents this.

### Power Orb Collection

**Q**: How are powers acquired?
**A**: Land on a power orb tile. The power is randomly assigned from the 87 available powers (all equally likely) and stored on the piece that collected it.

### Terrain Elevation

**Q**: How does elevation affect gameplay?
**A**: Elevation ranges ±4 levels from start (9 total levels).
- **Step UP**: Max 1 level without Climb Tile
- **Step UP 2+**: Requires Climb Tile (acts as wall otherwise)
- **Step DOWN**: Unlimited - can descend any height

## Strategy Tips

### Early Game

1. **Spread Out**: Don't cluster pieces together
2. **Grab Orbs**: Prioritize collecting power orbs
3. **Scout Terrain**: Identify advantageous positions

### Mid Game

1. **Power Distribution**: Use Teach/Learn to share powers
2. **Territory Control**: Use terrain manipulation
3. **Target Selection**: Identify high-value enemy pieces

### Late Game

1. **Concentrate Force**: Consolidate remaining pieces
2. **Use Combos**: Deploy power combinations for decisive attacks
3. **Protect Leaders**: Keep your strongest pieces safe

## Diagnostic Questions

When losing consistently, ask:

1. **Power Balance**: Are you using powers or hoarding them?
2. **Positioning**: Are your pieces supporting each other?
3. **Terrain**: Are you using elevation to your advantage?
4. **Timing**: Are you activating powers at optimal moments?
5. **Target Priority**: Are you eliminating the right enemy pieces?

## NNQR Implementation Issues

### Known Differences from Original

When playing NNQR, be aware:

- Board options: 8x8 (default) or 10x10
- All 87 powers will be included

### Reporting Bugs

For NNQR-specific issues, check:
- `rust/bevy/bug_reports/` for known issues
- Test cases in `rust/bevy/src/tests/`
