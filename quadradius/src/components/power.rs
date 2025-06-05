use bevy::prelude::*;
use rand::Rng;
use serde::{Deserialize, Serialize};

#[derive(Component, Clone, Copy, PartialEq, Eq, Hash, Debug, Serialize, Deserialize)]
pub enum PowerType {
    // Phase 2 powers (first 5)
    MoveDiagonal,
    RaiseColumn,
    LowerColumn,
    DestroyColumn,
    Multiply,

    // Phase 3: Movement Powers
    Teleport,
    Jump,      // Jump over pieces
    MoveTwo,   // Move 2 squares in one direction
    Knight,    // Move like chess knight
    Swap,      // Swap positions with another piece
    Push,      // Push adjacent piece
    Pull,      // Pull piece towards you
    Slide,     // Slide until hitting obstacle
    MoveTwice, // Take two moves in one turn
    Leap,      // Jump to any empty square within 3 tiles

    // Phase 3: Combat Powers
    SmartBomb, // Destroy all pieces in 3x3 area
    Sniper,    // Destroy piece at distance
    Shield,    // Protect from one attack
    Invisible, // Become invisible for 3 turns
    Recruit,   // Convert enemy piece
    Freeze,    // Prevent enemy piece from moving
    Poison,    // Piece dies after 3 turns
    Explode,   // Destroy self and adjacent pieces
    Assassin,  // Kill piece without capturing
    Resurrect, // Bring back destroyed piece

    // Phase 3: Board Manipulation Powers
    RaiseArea,   // Raise 3x3 area
    LowerArea,   // Lower 3x3 area
    CreateWall,  // Create impassable wall
    DestroyWall, // Remove wall
    Rotate,      // Rotate 3x3 section of board
    Shuffle,     // Shuffle pieces in area
    Earthquake,  // Random height changes
    Bridge,      // Create path over gaps
    Pit,         // Create hole in board
    Terraform,   // Set specific tile height

    // Phase 3: Meta Powers
    StealPower,   // Steal opponent's power
    CopyPower,    // Copy your own power
    NullifyPower, // Cancel opponent's power
    DoublePower,  // Use power twice
    RandomPower,  // Get random power effect
    PowerSwap,    // Exchange powers with opponent
    PowerGift,    // Give power to opponent
    PowerDrain,   // Remove all opponent powers
    Reflect,      // Reflect next power back
    Absorb,       // Gain power when attacked
}

#[derive(Component)]
pub struct PowerOrb {
    pub power_type: PowerType,
    pub board_position: (u8, u8),
}

// Components for power effects that persist across turns
#[derive(Component)]
pub struct PowerEffect {
    pub power_type: PowerType,
    pub duration: f32,
    pub target: Entity,
}

// For shields that block attacks
#[derive(Component)]
pub struct Shield {
    pub remaining_hits: u32,
}

// For invisibility effect
#[derive(Component)]
pub struct Invisible {
    pub remaining_turns: u32,
}

// For poison effect
#[derive(Component)]
pub struct Poisoned {
    pub remaining_turns: u32,
}

// For frozen pieces that can't move
#[derive(Component)]
pub struct Frozen {
    pub remaining_turns: u32,
}

// For walls on the board
#[derive(Component)]
pub struct Wall {
    pub height: i8,
    pub board_position: (u8, u8),
}

// For pieces that can move twice in one turn
#[derive(Component)]
pub struct MoveTwiceActive {
    pub moves_remaining: u32,
}

// For pieces that are reflecting powers
#[derive(Component)]
pub struct Reflecting {
    pub remaining_turns: u32,
}

// For pieces that absorb power effects
#[derive(Component)]
pub struct Absorbing {
    pub remaining_turns: u32,
}

impl PowerType {
    pub fn random() -> Self {
        let mut rng = rand::thread_rng();
        // For Phase 3, let's make common powers more likely
        let roll = rng.gen_range(0..100);

        match roll {
            // Phase 2 powers (30% chance total)
            0..6 => PowerType::MoveDiagonal,
            6..12 => PowerType::RaiseColumn,
            12..18 => PowerType::LowerColumn,
            18..24 => PowerType::DestroyColumn,
            24..30 => PowerType::Multiply,

            // Movement powers (25% chance)
            30..33 => PowerType::Teleport,
            33..36 => PowerType::Jump,
            36..39 => PowerType::MoveTwo,
            39..42 => PowerType::Knight,
            42..45 => PowerType::Swap,
            45..47 => PowerType::Push,
            47..49 => PowerType::Pull,
            49..51 => PowerType::Slide,
            51..53 => PowerType::MoveTwice,
            53..55 => PowerType::Leap,

            // Combat powers (25% chance)
            55..58 => PowerType::SmartBomb,
            58..61 => PowerType::Sniper,
            61..64 => PowerType::Shield,
            64..67 => PowerType::Invisible,
            67..70 => PowerType::Recruit,
            70..72 => PowerType::Freeze,
            72..74 => PowerType::Poison,
            74..76 => PowerType::Explode,
            76..78 => PowerType::Assassin,
            78..80 => PowerType::Resurrect,

            // Board powers (15% chance)
            80..82 => PowerType::RaiseArea,
            82..84 => PowerType::LowerArea,
            84..86 => PowerType::CreateWall,
            86..87 => PowerType::DestroyWall,
            87..88 => PowerType::Rotate,
            88..89 => PowerType::Shuffle,
            89..90 => PowerType::Earthquake,
            90..91 => PowerType::Bridge,
            91..92 => PowerType::Pit,
            92..95 => PowerType::Terraform,

            // Meta powers (5% chance - rare)
            95..96 => PowerType::StealPower,
            96..97 => PowerType::CopyPower,
            97..98 => PowerType::NullifyPower,
            98..99 => PowerType::DoublePower,
            _ => PowerType::RandomPower,
        }
    }

    pub fn color(&self) -> Color {
        match self {
            // Phase 2 powers
            PowerType::MoveDiagonal => Color::rgb(0.6, 0.6, 1.0),
            PowerType::RaiseColumn => Color::rgb(0.6, 1.0, 0.6),
            PowerType::LowerColumn => Color::rgb(1.0, 0.8, 0.4),
            PowerType::DestroyColumn => Color::rgb(1.0, 0.4, 0.4),
            PowerType::Multiply => Color::rgb(0.8, 0.4, 1.0),

            // Movement powers (shades of blue)
            PowerType::Teleport => Color::rgb(0.2, 0.2, 1.0),
            PowerType::Jump => Color::rgb(0.3, 0.5, 1.0),
            PowerType::MoveTwo => Color::rgb(0.4, 0.6, 1.0),
            PowerType::Knight => Color::rgb(0.5, 0.7, 1.0),
            PowerType::Swap => Color::rgb(0.2, 0.8, 0.8),
            PowerType::Push => Color::rgb(0.3, 0.7, 0.9),
            PowerType::Pull => Color::rgb(0.4, 0.6, 0.8),
            PowerType::Slide => Color::rgb(0.5, 0.5, 0.9),
            PowerType::MoveTwice => Color::rgb(0.6, 0.4, 0.9),
            PowerType::Leap => Color::rgb(0.3, 0.3, 0.8),

            // Combat powers (shades of red/orange)
            PowerType::SmartBomb => Color::rgb(1.0, 0.2, 0.2),
            PowerType::Sniper => Color::rgb(0.9, 0.3, 0.3),
            PowerType::Shield => Color::rgb(0.7, 0.7, 0.9),
            PowerType::Invisible => Color::rgb(0.5, 0.5, 0.5),
            PowerType::Recruit => Color::rgb(0.9, 0.5, 0.2),
            PowerType::Freeze => Color::rgb(0.4, 0.8, 1.0),
            PowerType::Poison => Color::rgb(0.4, 0.8, 0.2),
            PowerType::Explode => Color::rgb(1.0, 0.5, 0.0),
            PowerType::Assassin => Color::rgb(0.3, 0.0, 0.3),
            PowerType::Resurrect => Color::rgb(1.0, 1.0, 0.7),

            // Board powers (shades of green/brown)
            PowerType::RaiseArea => Color::rgb(0.4, 0.8, 0.4),
            PowerType::LowerArea => Color::rgb(0.8, 0.6, 0.3),
            PowerType::CreateWall => Color::rgb(0.5, 0.5, 0.5),
            PowerType::DestroyWall => Color::rgb(0.9, 0.7, 0.5),
            PowerType::Rotate => Color::rgb(0.6, 0.8, 0.6),
            PowerType::Shuffle => Color::rgb(0.7, 0.5, 0.7),
            PowerType::Earthquake => Color::rgb(0.6, 0.4, 0.2),
            PowerType::Bridge => Color::rgb(0.7, 0.6, 0.5),
            PowerType::Pit => Color::rgb(0.2, 0.2, 0.2),
            PowerType::Terraform => Color::rgb(0.5, 0.7, 0.4),

            // Meta powers (shades of purple/pink)
            PowerType::StealPower => Color::rgb(0.8, 0.2, 0.8),
            PowerType::CopyPower => Color::rgb(0.7, 0.3, 0.9),
            PowerType::NullifyPower => Color::rgb(0.6, 0.2, 0.6),
            PowerType::DoublePower => Color::rgb(0.9, 0.4, 0.9),
            PowerType::RandomPower => Color::rgb(0.8, 0.8, 0.8),
            PowerType::PowerSwap => Color::rgb(0.7, 0.4, 0.7),
            PowerType::PowerGift => Color::rgb(0.9, 0.6, 0.9),
            PowerType::PowerDrain => Color::rgb(0.4, 0.1, 0.4),
            PowerType::Reflect => Color::rgb(0.8, 0.7, 0.9),
            PowerType::Absorb => Color::rgb(0.6, 0.3, 0.8),
        }
    }

    pub fn name(&self) -> &'static str {
        match self {
            // Phase 2 powers
            PowerType::MoveDiagonal => "Move Diagonal",
            PowerType::RaiseColumn => "Raise Column",
            PowerType::LowerColumn => "Lower Column",
            PowerType::DestroyColumn => "Destroy Column",
            PowerType::Multiply => "Multiply",

            // Movement powers
            PowerType::Teleport => "Teleport",
            PowerType::Jump => "Jump",
            PowerType::MoveTwo => "Move Two",
            PowerType::Knight => "Knight",
            PowerType::Swap => "Swap",
            PowerType::Push => "Push",
            PowerType::Pull => "Pull",
            PowerType::Slide => "Slide",
            PowerType::MoveTwice => "Move Twice",
            PowerType::Leap => "Leap",

            // Combat powers
            PowerType::SmartBomb => "Smart Bomb",
            PowerType::Sniper => "Sniper",
            PowerType::Shield => "Shield",
            PowerType::Invisible => "Invisible",
            PowerType::Recruit => "Recruit",
            PowerType::Freeze => "Freeze",
            PowerType::Poison => "Poison",
            PowerType::Explode => "Explode",
            PowerType::Assassin => "Assassin",
            PowerType::Resurrect => "Resurrect",

            // Board powers
            PowerType::RaiseArea => "Raise Area",
            PowerType::LowerArea => "Lower Area",
            PowerType::CreateWall => "Create Wall",
            PowerType::DestroyWall => "Destroy Wall",
            PowerType::Rotate => "Rotate",
            PowerType::Shuffle => "Shuffle",
            PowerType::Earthquake => "Earthquake",
            PowerType::Bridge => "Bridge",
            PowerType::Pit => "Pit",
            PowerType::Terraform => "Terraform",

            // Meta powers
            PowerType::StealPower => "Steal Power",
            PowerType::CopyPower => "Copy Power",
            PowerType::NullifyPower => "Nullify",
            PowerType::DoublePower => "Double Power",
            PowerType::RandomPower => "Random",
            PowerType::PowerSwap => "Power Swap",
            PowerType::PowerGift => "Gift Power",
            PowerType::PowerDrain => "Power Drain",
            PowerType::Reflect => "Reflect",
            PowerType::Absorb => "Absorb",
        }
    }
}
