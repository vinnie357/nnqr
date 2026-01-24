-- Test Helpers Index
-- Exports all helper modules for power executor tests

local Helpers = {}

-- Load sub-modules
Helpers.state = require("spec.helpers.state")
Helpers.pieces = require("spec.helpers.pieces")
Helpers.powers = require("spec.helpers.powers")
Helpers.orbs = require("spec.helpers.orbs")
Helpers.terrain = require("spec.helpers.terrain")

--- Board dimensions (match GameLogic)
Helpers.BOARD_COLS = 10
Helpers.BOARD_ROWS = 8

--- Convenience re-exports
Helpers.createState = Helpers.state.createState
Helpers.createEmptyState = Helpers.state.createEmptyState
Helpers.createPiece = Helpers.pieces.createPiece
Helpers.placePiece = Helpers.pieces.placePiece
Helpers.getPieceAt = Helpers.pieces.getPieceAt
Helpers.countPieces = Helpers.pieces.countPieces
Helpers.givePower = Helpers.powers.givePower
Helpers.assertHasPower = Helpers.powers.assertHasPower
Helpers.assertNoPower = Helpers.powers.assertNoPower
Helpers.countPowers = Helpers.powers.countPowers
Helpers.placeOrb = Helpers.orbs.placeOrb
Helpers.getOrbAt = Helpers.orbs.getOrbAt
Helpers.countOrbs = Helpers.orbs.countOrbs
Helpers.setHeight = Helpers.terrain.setHeight
Helpers.getHeight = Helpers.terrain.getHeight
Helpers.destroyTile = Helpers.terrain.destroyTile
Helpers.isTileDestroyed = Helpers.terrain.isTileDestroyed

return Helpers
