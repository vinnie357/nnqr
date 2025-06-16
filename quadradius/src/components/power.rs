use crate::components::Player;
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

    // Missing research-identified powers
    GrowQuadradius, // Massively extends kill power range (most powerful)
    JumpProof,      // Permanent immunity to capture
    Bombs,          // Drops 16 random bombs destroying pieces and terrain
    SnakeTunneling, // Destructive snake across board, raises terrain 2 levels
    DredgeColumn,   // Sinks enemies 2 levels, raises friendlies 2 levels
    TeachRow,       // Shares powers with friendly pieces in same row
    TeachRadial,    // Shares powers with friendly pieces in 3x3 area
    Acid,           // Creates permanent holes in board
    RecruitRadial,  // Area effect version of recruit
}

#[derive(Component)]
pub struct PowerOrb {
    pub power_type: PowerType,
    pub board_position: (u8, u8),
}

// Components for power effects that persist across turns
#[derive(Component, Clone, Debug)]
pub struct PowerEffect {
    pub power_type: PowerType,
    pub duration_turns: u32,
    pub target_entity: Entity,
    pub effect_data: EffectData,
    pub source_player: Player,
    pub turn_applied: u32,
}

// Data for different types of effects
#[derive(Clone, Debug)]
pub enum EffectData {
    // Movement effects
    Movement(MovementRestriction),
    // Combat effects
    Protection(ProtectionType),
    // Status effects
    Status(StatusEffect),
    // Area effects
    Area(AreaEffect),
}

#[derive(Clone, Debug)]
pub enum MovementRestriction {
    None,                   // Can't move
    Limited(Vec<(i8, i8)>), // Can only move to specific relative positions
    Enhanced(MovementType), // Enhanced movement abilities
}

#[derive(Clone, Debug)]
pub enum MovementType {
    Diagonal,
    Teleport,
    Jump,
    Knight,
    Double, // Can move twice
}

#[derive(Clone, Debug)]
pub enum ProtectionType {
    Shield { hits_remaining: u32 },
    Immunity { damage_types: Vec<DamageType> },
    Reflection { turns_remaining: u32 },
}

#[derive(Clone, Debug)]
pub enum DamageType {
    Capture,
    Explosion,
    Magic,
    All,
}

#[derive(Clone, Debug)]
pub enum StatusEffect {
    Invisible,
    Poisoned { death_timer: u32 },
    Frozen,
    Recruiting { conversion_power: u32 },
}

#[derive(Clone, Debug)]
pub struct AreaEffect {
    pub center: (u8, u8),
    pub radius: u8,
    pub effect_type: AreaEffectType,
}

#[derive(Clone, Debug)]
pub enum AreaEffectType {
    Damage,
    Heal,
    Convert,
    Terrain,
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
    pub wall_type: WallType,
    pub health: u32,
    pub created_turn: u32,
}

#[derive(Clone, Copy, Debug, PartialEq)]
pub enum WallType {
    Stone,  // Permanent wall
    Ice,    // Temporary wall (melts after N turns)
    Energy, // Energy barrier (blocks movement but not powers)
    Bridge, // Allows passage over gaps
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

// Missing research power components
#[derive(Component)]
pub struct GrowQuadradiusActive {
    pub remaining_turns: u32,
    pub range_extension: u8,
}

#[derive(Component)]
pub struct JumpProof;

// For tiles affected by acid
#[derive(Component)]
pub struct DissolvedTile {
    pub board_position: (u8, u8),
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

            // Meta powers (3% chance - rare)
            95..96 => PowerType::StealPower,
            96 => PowerType::CopyPower,
            97 => PowerType::NullifyPower,

            // Missing research powers (2% chance - very rare)
            98 => PowerType::GrowQuadradius, // Most powerful, rarest
            99 => PowerType::JumpProof,

            // Fallback
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

            // Missing research powers (distinctive colors)
            PowerType::GrowQuadradius => Color::rgb(1.0, 0.0, 1.0), // Bright magenta - most powerful
            PowerType::JumpProof => Color::rgb(0.0, 1.0, 1.0),      // Bright cyan - immunity
            PowerType::Bombs => Color::rgb(1.0, 0.5, 0.0),          // Orange - destructive
            PowerType::SnakeTunneling => Color::rgb(0.5, 1.0, 0.0), // Lime green - snake
            PowerType::DredgeColumn => Color::rgb(0.6, 0.4, 0.2),   // Brown - earth manipulation
            PowerType::TeachRow => Color::rgb(0.0, 0.8, 1.0),       // Light blue - teaching
            PowerType::TeachRadial => Color::rgb(0.2, 0.6, 1.0),    // Sky blue - radial teaching
            PowerType::Acid => Color::rgb(0.8, 1.0, 0.2),           // Yellow-green - acid
            PowerType::RecruitRadial => Color::rgb(1.0, 0.8, 0.4),  // Gold - recruitment
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

            // Missing research powers
            PowerType::GrowQuadradius => "Grow Quadradius",
            PowerType::JumpProof => "Jump Proof",
            PowerType::Bombs => "Bombs",
            PowerType::SnakeTunneling => "Snake Tunneling",
            PowerType::DredgeColumn => "Dredge Column",
            PowerType::TeachRow => "Teach Row",
            PowerType::TeachRadial => "Teach Radial",
            PowerType::Acid => "Acid",
            PowerType::RecruitRadial => "Recruit Radial",
        }
    }

    pub fn description(&self) -> &'static str {
        match self {
            // Phase 2 powers
            PowerType::MoveDiagonal => "Enables diagonal movement for this piece",
            PowerType::RaiseColumn => "Raises an entire column by one level",
            PowerType::LowerColumn => "Lowers an entire column by one level",
            PowerType::DestroyColumn => "Destroys all pieces in a column",
            PowerType::Multiply => "Creates a copy of this piece",

            // Movement powers
            PowerType::Teleport => "Instantly move to any empty square",
            PowerType::Jump => "Jump over pieces to empty squares",
            PowerType::MoveTwo => "Move 2 squares in one direction",
            PowerType::Knight => "Move like a chess knight",
            PowerType::Swap => "Swap positions with another piece",
            PowerType::Push => "Push adjacent piece away",
            PowerType::Pull => "Pull piece towards you",
            PowerType::Slide => "Slide until hitting an obstacle",
            PowerType::MoveTwice => "Take two moves in one turn",
            PowerType::Leap => "Jump to any empty square within 3 tiles",

            // Combat powers
            PowerType::SmartBomb => "Destroy all pieces in 3x3 area",
            PowerType::Sniper => "Destroy piece at distance",
            PowerType::Shield => "Protect from one attack",
            PowerType::Invisible => "Become invisible for 3 turns",
            PowerType::Recruit => "Convert enemy piece to your side",
            PowerType::Freeze => "Prevent enemy piece from moving",
            PowerType::Poison => "Piece dies after 3 turns",
            PowerType::Explode => "Destroy self and adjacent pieces",
            PowerType::Assassin => "Kill piece without capturing",
            PowerType::Resurrect => "Bring back destroyed piece",

            // Board manipulation
            PowerType::RaiseArea => "Raise 3x3 area",
            PowerType::LowerArea => "Lower 3x3 area",
            PowerType::CreateWall => "Create impassable wall",
            PowerType::DestroyWall => "Remove wall",
            PowerType::Rotate => "Rotate 3x3 section of board",
            PowerType::Shuffle => "Shuffle pieces in area",
            PowerType::Earthquake => "Random height changes",
            PowerType::Bridge => "Create path over gaps",
            PowerType::Pit => "Create hole in board",
            PowerType::Terraform => "Set specific tile height",

            // Meta powers
            PowerType::StealPower => "Steal opponent's power",
            PowerType::CopyPower => "Copy your own power",
            PowerType::NullifyPower => "Cancel opponent's power",
            PowerType::DoublePower => "Use power twice",
            PowerType::RandomPower => "Get random power effect",
            PowerType::PowerSwap => "Exchange powers with opponent",
            PowerType::PowerGift => "Give power to opponent",
            PowerType::PowerDrain => "Remove all opponent powers",
            PowerType::Reflect => "Reflect next power back",
            PowerType::Absorb => "Gain power when attacked",

            // Missing research powers
            PowerType::GrowQuadradius => {
                "Massively extends kill power range to entire board - most powerful power"
            }
            PowerType::JumpProof => "Permanent immunity to capture by enemy pieces",
            PowerType::Bombs => "Drops 16 random bombs destroying pieces and depressing terrain",
            PowerType::SnakeTunneling => {
                "Sends destructive snake across board while raising terrain 2 levels"
            }
            PowerType::DredgeColumn => {
                "Sinks enemy pieces 2 levels while raising friendly pieces 2 levels"
            }
            PowerType::TeachRow => "Shares powers with all friendly pieces in the same row",
            PowerType::TeachRadial => "Shares powers with all friendly pieces in 3x3 area",
            PowerType::Acid => "Creates permanent holes in the board making tiles unusable",
            PowerType::RecruitRadial => "Converts all enemy pieces in 3x3 area to friendly pieces",
        }
    }

    pub fn power_category(&self) -> PowerCategory {
        match self {
            PowerType::MoveDiagonal
            | PowerType::Teleport
            | PowerType::Jump
            | PowerType::MoveTwo
            | PowerType::Knight
            | PowerType::Swap
            | PowerType::Push
            | PowerType::Pull
            | PowerType::Slide
            | PowerType::MoveTwice
            | PowerType::Leap => PowerCategory::Movement,

            PowerType::SmartBomb
            | PowerType::Sniper
            | PowerType::Invisible
            | PowerType::Recruit
            | PowerType::Freeze
            | PowerType::Poison
            | PowerType::Explode
            | PowerType::Assassin
            | PowerType::Resurrect
            | PowerType::Bombs
            | PowerType::SnakeTunneling
            | PowerType::Acid => PowerCategory::Combat,

            PowerType::Shield | PowerType::JumpProof => PowerCategory::Defensive,

            PowerType::RaiseColumn
            | PowerType::LowerColumn
            | PowerType::DestroyColumn
            | PowerType::RaiseArea
            | PowerType::LowerArea
            | PowerType::CreateWall
            | PowerType::DestroyWall
            | PowerType::Rotate
            | PowerType::Shuffle
            | PowerType::Earthquake
            | PowerType::Bridge
            | PowerType::Pit
            | PowerType::Terraform
            | PowerType::DredgeColumn => PowerCategory::Terrain,

            PowerType::Multiply
            | PowerType::GrowQuadradius
            | PowerType::TeachRow
            | PowerType::TeachRadial
            | PowerType::RecruitRadial => PowerCategory::Strategic,

            PowerType::StealPower
            | PowerType::CopyPower
            | PowerType::NullifyPower
            | PowerType::DoublePower
            | PowerType::RandomPower
            | PowerType::PowerSwap
            | PowerType::PowerGift
            | PowerType::PowerDrain
            | PowerType::Reflect
            | PowerType::Absorb => PowerCategory::Meta,
        }
    }
}

#[derive(PartialEq, Debug, Clone, Copy)]
pub enum PowerCategory {
    Movement,
    Combat,
    Defensive,
    Terrain,
    Strategic,
    Meta,
}

// Effect stacking rules and utility functions
impl PowerEffect {
    pub fn new(
        power_type: PowerType,
        duration_turns: u32,
        target_entity: Entity,
        effect_data: EffectData,
        source_player: Player,
        current_turn: u32,
    ) -> Self {
        Self {
            power_type,
            duration_turns,
            target_entity,
            effect_data,
            source_player,
            turn_applied: current_turn,
        }
    }

    pub fn is_expired(&self, current_turn: u32) -> bool {
        current_turn >= self.turn_applied + self.duration_turns
    }

    pub fn remaining_turns(&self, current_turn: u32) -> u32 {
        let elapsed = current_turn.saturating_sub(self.turn_applied);
        self.duration_turns.saturating_sub(elapsed)
    }

    pub fn can_stack_with(&self, other: &PowerEffect) -> bool {
        match (&self.effect_data, &other.effect_data) {
            // Different effect types can always stack
            (EffectData::Movement(_), EffectData::Protection(_)) => true,
            (EffectData::Movement(_), EffectData::Status(_)) => true,
            (EffectData::Protection(_), EffectData::Status(_)) => true,
            (EffectData::Protection(_), EffectData::Movement(_)) => true,
            (EffectData::Status(_), EffectData::Movement(_)) => true,
            (EffectData::Status(_), EffectData::Protection(_)) => true,

            // Same effect types - check specific stacking rules
            (EffectData::Movement(a), EffectData::Movement(b)) => self.movement_can_stack(a, b),
            (EffectData::Protection(a), EffectData::Protection(b)) => {
                self.protection_can_stack(a, b)
            }
            (EffectData::Status(a), EffectData::Status(b)) => self.status_can_stack(a, b),

            // Area effects don't stack
            (EffectData::Area(_), _) | (_, EffectData::Area(_)) => false,
        }
    }

    fn movement_can_stack(&self, a: &MovementRestriction, b: &MovementRestriction) -> bool {
        match (a, b) {
            // Frozen state doesn't stack with anything
            (MovementRestriction::None, _) | (_, MovementRestriction::None) => false,
            // Different enhanced movements can stack
            (MovementRestriction::Enhanced(_), MovementRestriction::Enhanced(_)) => true,
            // Limited movements can combine
            (MovementRestriction::Limited(_), MovementRestriction::Limited(_)) => true,
            _ => true,
        }
    }

    fn protection_can_stack(&self, a: &ProtectionType, b: &ProtectionType) -> bool {
        match (a, b) {
            // Shields don't stack
            (ProtectionType::Shield { .. }, ProtectionType::Shield { .. }) => false,
            // Different protection types can stack
            _ => true,
        }
    }

    fn status_can_stack(&self, a: &StatusEffect, b: &StatusEffect) -> bool {
        match (a, b) {
            // Same status effects don't stack
            (StatusEffect::Invisible, StatusEffect::Invisible) => false,
            (StatusEffect::Frozen, StatusEffect::Frozen) => false,
            (StatusEffect::Poisoned { .. }, StatusEffect::Poisoned { .. }) => false,
            // Different status effects can stack
            _ => true,
        }
    }

    pub fn get_visual_priority(&self) -> u32 {
        match &self.effect_data {
            EffectData::Status(StatusEffect::Poisoned { .. }) => 100, // Highest priority
            EffectData::Status(StatusEffect::Frozen) => 90,
            EffectData::Protection(ProtectionType::Shield { .. }) => 80,
            EffectData::Status(StatusEffect::Invisible) => 70,
            EffectData::Protection(ProtectionType::Immunity { .. }) => 60,
            EffectData::Movement(_) => 50,
            EffectData::Protection(ProtectionType::Reflection { .. }) => 40,
            EffectData::Area(_) => 30,
            _ => 10,
        }
    }
}

// Stacking rule definitions
#[derive(Debug, Clone)]
pub enum StackingRule {
    NoStack,     // Effects of this type cannot stack
    Replace,     // New effect replaces old one
    Combine,     // Effects combine their values
    Independent, // Effects work independently
}

impl EffectData {
    pub fn stacking_rule(&self) -> StackingRule {
        match self {
            EffectData::Movement(MovementRestriction::None) => StackingRule::NoStack,
            EffectData::Protection(ProtectionType::Shield { .. }) => StackingRule::Replace,
            EffectData::Status(StatusEffect::Invisible) => StackingRule::Replace,
            EffectData::Status(StatusEffect::Frozen) => StackingRule::NoStack,
            EffectData::Status(StatusEffect::Poisoned { .. }) => StackingRule::Replace,
            EffectData::Movement(MovementRestriction::Enhanced(_)) => StackingRule::Combine,
            EffectData::Protection(ProtectionType::Immunity { .. }) => StackingRule::Combine,
            _ => StackingRule::Independent,
        }
    }

    pub fn get_effect_name(&self) -> &'static str {
        match self {
            EffectData::Movement(MovementRestriction::None) => "Frozen",
            EffectData::Movement(MovementRestriction::Enhanced(MovementType::Diagonal)) => {
                "Diagonal Movement"
            }
            EffectData::Movement(MovementRestriction::Enhanced(MovementType::Teleport)) => {
                "Teleport"
            }
            EffectData::Movement(MovementRestriction::Enhanced(MovementType::Jump)) => "Jump",
            EffectData::Movement(MovementRestriction::Enhanced(MovementType::Knight)) => {
                "Knight Movement"
            }
            EffectData::Movement(MovementRestriction::Enhanced(MovementType::Double)) => {
                "Double Move"
            }
            EffectData::Protection(ProtectionType::Shield { .. }) => "Shield",
            EffectData::Protection(ProtectionType::Immunity { .. }) => "Immunity",
            EffectData::Protection(ProtectionType::Reflection { .. }) => "Reflection",
            EffectData::Status(StatusEffect::Invisible) => "Invisible",
            EffectData::Status(StatusEffect::Poisoned { .. }) => "Poisoned",
            EffectData::Status(StatusEffect::Frozen) => "Frozen",
            EffectData::Status(StatusEffect::Recruiting { .. }) => "Recruiting",
            EffectData::Area(_) => "Area Effect",
            _ => "Unknown Effect",
        }
    }
}
