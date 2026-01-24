# Sound Files Required

This directory should contain `.ogg` sound files for the game. Below is a list of all required sounds organized by category.

## Game Events
| File | Description | Duration | Style |
|------|-------------|----------|-------|
| `move.ogg` | Piece movement | 0.2-0.3s | Soft click/tap |
| `capture.ogg` | Capturing enemy piece | 0.3-0.4s | Impact/thud |
| `select.ogg` | Selecting a piece | 0.1-0.2s | Light click |
| `menu_select.ogg` | Menu navigation | 0.1s | UI blip |
| `menu_confirm.ogg` | Menu selection confirm | 0.2s | UI confirm |

## Power Sounds by Category

### Destruction Powers
| File | Used By | Description |
|------|---------|-------------|
| `explosion.ogg` | bomb, destroy_row, destroy_column, destroy_radial, kamikaze_* | Explosion/blast sound, 0.4-0.6s |

### Teleportation Powers
| File | Used By | Description |
|------|---------|-------------|
| `teleport.ogg` | relocate, hotspot_teleport, centerpult, switcheroo | Whoosh/warp sound, 0.3-0.5s |

### Defensive Powers
| File | Used By | Description |
|------|---------|-------------|
| `shield.ogg` | jump_proof, invisible, climb_tile | Energy shield/buff sound, 0.3s |

### Recruitment Powers
| File | Used By | Description |
|------|---------|-------------|
| `recruit.ogg` | recruit, recruit_row, recruit_column, recruit_radial | Conversion/charm sound, 0.4s |

### Multiplication Powers
| File | Used By | Description |
|------|---------|-------------|
| `multiply.ogg` | multiply, cancel_multiply | Clone/split sound, 0.4s |

### Movement Enhancement
| File | Used By | Description |
|------|---------|-------------|
| `power_up.ogg` | move_diagonal, move_again, flat_to_sphere, grow_quadradius | Power-up chime, 0.3s |

### Terrain Modification
| File | Used By | Description |
|------|---------|-------------|
| `terrain.ogg` | raise_tile, lower_tile, trench_*, wall_*, plateau, moat, refurb | Earth/stone rumble, 0.4-0.5s |

### Power Manipulation (Magic)
| File | Used By | Description |
|------|---------|-------------|
| `magic.ogg` | double_powers, pilfer_*, teach_*, learn_*, beneficiary, scavenger, orbic_rehash | Mystical chime/sparkle, 0.4s |

### Debuff Effects
| File | Used By | Description |
|------|---------|-------------|
| `debuff.ogg` | bankrupt_*, inhibit_*, parasite_* | Negative/drain sound, 0.3-0.4s |
| `acid.ogg` | acidic_* | Corrosive/sizzle sound, 0.4s |

### Information/Spy Powers
| File | Used By | Description |
|------|---------|-------------|
| `scan.ogg` | spyware_*, orb_spy_* | Scanning/beep sound, 0.3s |

### Trap Powers
| File | Used By | Description |
|------|---------|-------------|
| `trap.ogg` | tripwire_*, smart_bombs, hotspot | Trap setting sound, 0.3s |

### Chaos/Scramble Powers
| File | Used By | Description |
|------|---------|-------------|
| `scramble.ogg` | scramble_*, invert_* | Chaotic/shuffle sound, 0.4s |

### Healing/Restoration
| File | Used By | Description |
|------|---------|-------------|
| `heal.ogg` | purify_*, refurb_*, dredge_* | Healing/restore chime, 0.4s |

### Default
| File | Used By | Description |
|------|---------|-------------|
| `power_activate.ogg` | Any power not in above categories | Generic power activation, 0.3s |

## Audio Specifications
- Format: OGG Vorbis
- Sample Rate: 44100 Hz
- Channels: Mono or Stereo
- Bit Depth: 16-bit

## Free Sound Resources
- [Freesound.org](https://freesound.org)
- [OpenGameArt.org](https://opengameart.org/art-search-advanced?field_art_type_tid%5B%5D=13)
- [Kenney.nl Assets](https://kenney.nl/assets?q=audio)
- [ZapSplat](https://www.zapsplat.com)

## License Notes
Ensure all sounds used are compatible with the project's license. Prefer CC0, CC-BY, or similar permissive licenses.
