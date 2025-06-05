# Quadradius Windows Release v0.2.0

## Release Date
June 5, 2025

## Overview
This is a major bugfix release that resolves critical power system issues reported by players. Quadradius is now fully functional with a working power collection and activation system.

## 🔧 Major Bug Fixes

### Power System Issues Resolved
- **Fixed power orb pickup failures** - Power orbs can now be properly collected by moving pieces over them
- **Fixed power activation UI** - Powers now correctly appear in the activation UI during the PowerActivation phase  
- **Fixed coordinate system mismatches** - Resolved visual/logical position inconsistencies between power spawn systems
- **Enabled debug controls** - P, O, and I keys now work for testing and debugging

### Code Quality Improvements
- Applied code formatting with `cargo fmt`
- Addressed linting warnings with `cargo clippy`
- All 21 unit tests pass successfully
- Improved code organization and documentation

## ✨ Features Working

### Power System (12/50 Powers Implemented)
**Phase 2 Foundation Powers (5/5):**
- ✅ **Move Diagonal** - Enables diagonal piece movement
- ✅ **Raise Column** - Increases terrain height of entire column  
- ✅ **Lower Column** - Decreases terrain height of entire column
- ✅ **Destroy Column** - Removes all tiles and pieces in column
- ✅ **Multiply** - Creates a copy of selected piece

**Movement Powers (5/10):**
- ✅ **Teleport** - Move piece to any empty position
- ✅ **Jump** - Jump over pieces and obstacles
- ✅ **Move Two** - Move 2 squares in one direction
- ✅ **Knight** - L-shaped movement like chess knight
- ✅ **Slide** - Slide piece until hitting obstacle

**Combat Powers (2/10):**
- ✅ **Smart Bomb** - Destroys all pieces in 3x3 area
- ✅ **Sniper** - Destroys distant enemy piece

### Core Gameplay
- ✅ **8x8 Board** - Standard Quadradius board with terrain heights
- ✅ **Turn-based gameplay** - Alternating player turns with movement and power phases
- ✅ **Piece movement** - Standard movement rules with terrain height restrictions
- ✅ **Win conditions** - Game ends when one player has no pieces remaining
- ✅ **Terrain system** - Multi-level board with movement restrictions

### Testing & Debug Features
- ✅ **Automated testing** - Tests all 12 implemented powers automatically after 5 seconds
- ✅ **Debug controls** - Manual testing tools for developers
- ✅ **100% test pass rate** - All implemented powers verified working

## 🎮 How to Play

### Basic Controls
- **Mouse** - Click and drag pieces to move them
- **Space** - End turn or skip power phase
- **P** - Spawn random power orb (debug)
- **O** - Display current player's power inventory (debug)  
- **I** - Generate power test report (debug)

### Game Flow
1. **Player Turn** - Move one of your pieces (red or blue)
2. **Power Phase** - If you have powers, select one to use or skip
3. **Collect Powers** - Move pieces over power orbs to collect them
4. **Win** - Eliminate all enemy pieces to victory

### Power Usage
- Powers are collected by moving pieces over colored orbs
- During your power phase, available powers appear as buttons
- Click a power button to activate it, or click "Skip" to continue
- Different powers have different targeting requirements

## 🖥️ System Requirements

### Windows
- **OS**: Windows 10 or later (64-bit)
- **RAM**: 4GB minimum, 8GB recommended
- **Graphics**: DirectX 11 compatible
- **Storage**: 50MB available space

### Performance
- **Target FPS**: 60 FPS
- **Resolution**: 800x600 (windowed)
- **Dependencies**: No additional runtime dependencies required

## 📁 Installation

1. Download `quadradius.exe` (28MB)
2. Place in desired folder
3. Double-click to run
4. No installation required - portable executable

## 🐛 Known Issues

### Limitations
- Only 12 of 50 planned powers are implemented
- No network multiplayer (local play only)
- No save/load game functionality
- Minimal visual effects and sound

### Planned Improvements
- Implement remaining 38 powers
- Add network multiplayer support
- Enhanced visual effects and animations
- Sound effects and music
- Tutorial system

## 🔍 Testing Instructions

### Quick Test
1. Run `quadradius.exe`
2. Wait 5 seconds for automated tests to complete
3. Check console for "100% PASS" confirmation

### Manual Testing
1. Press **P** to spawn power orbs
2. Move pieces over orbs to collect them
3. Press **O** to verify collection
4. Use powers during PowerActivation phase
5. Press **I** for detailed test report

## 📋 Technical Details

### Build Information
- **Rust Version**: 1.75+
- **Target**: x86_64-pc-windows-gnu
- **Build Type**: Release (optimized)
- **File Size**: 28MB
- **Tests**: 21 passed, 0 failed

### Code Quality
- **Formatted**: ✅ cargo fmt applied
- **Linted**: ✅ cargo clippy passed  
- **Tested**: ✅ All unit tests pass
- **Coverage**: Core gameplay and power systems

## 🆘 Support

### Getting Help
- Check debug output in console window
- Use debug keys (P, O, I) to diagnose issues
- Refer to test reports for power functionality verification

### Reporting Issues
- Include console output
- Describe steps to reproduce
- Mention which powers were being used

## 📈 Changelog

### v0.2.0 (June 5, 2025)
- **FIXED**: Power orb collection system
- **FIXED**: Power activation UI display  
- **FIXED**: Coordinate system consistency
- **FIXED**: Debug controls functionality
- **IMPROVED**: Code quality and organization
- **VERIFIED**: All 12 powers working correctly

### v0.1.0 (Previous)
- Initial implementation
- Basic gameplay and movement
- 12 power types implemented
- Known issues with power system

## 🚀 Future Roadmap

### Phase 3 (Next Release)
- Implement remaining 38 powers
- Power combination effects
- Enhanced visual feedback

### Phase 4 (Future)
- Network multiplayer
- Enhanced UI/UX
- Sound and music
- Tournament mode

---

**Quadradius** - "Checkers on Steroids"
*A faithful recreation of the beloved 2007 Flash game*