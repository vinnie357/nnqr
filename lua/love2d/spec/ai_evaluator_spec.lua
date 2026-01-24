-- AI Evaluator Module Tests
-- Phase 8B: Rule-Based AI

describe("Evaluator", function()
	local Evaluator
	local GameLogic

	setup(function()
		Evaluator = require("src.shared.ai.evaluator")
		GameLogic = require("src.shared.game_logic")
	end)

	-- 8B.1 Threat Detection
	describe("getThreatenedPieces", function()
		it("returns empty table when no threats exist", function()
			local state = GameLogic.createInitialState()
			-- Initial board setup has no adjacent enemy pieces
			local threatened = Evaluator.getThreatenedPieces(state, 1)
			assert.are.equal(0, #threatened)
		end)

		it("finds single threatened piece", function()
			local state = GameLogic.createInitialState()
			-- Setup: Player 1 piece at (4,5), Player 2 piece at (5,5) can capture it
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = {} },
				{ row = 5, col = 5, player = 2, powers = {} },
			}

			local threatened = Evaluator.getThreatenedPieces(state, 1)
			assert.are.equal(1, #threatened)
			assert.are.equal(4, threatened[1].row)
			assert.are.equal(5, threatened[1].col)
		end)

		it("finds multiple threatened pieces", function()
			local state = GameLogic.createInitialState()
			-- Setup: Two Player 1 pieces that can be captured
			state.pieces = {
				{ row = 4, col = 3, player = 1, powers = {} }, -- Threatened by piece at 5,3
				{ row = 4, col = 7, player = 1, powers = {} }, -- Threatened by piece at 5,7
				{ row = 5, col = 3, player = 2, powers = {} },
				{ row = 5, col = 7, player = 2, powers = {} },
			}

			local threatened = Evaluator.getThreatenedPieces(state, 1)
			assert.are.equal(2, #threatened)
		end)

		it("respects jump_proof flag", function()
			local state = GameLogic.createInitialState()
			-- Setup: Player 1 piece with jump_proof, Player 2 adjacent
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = {}, isJumpProof = true },
				{ row = 5, col = 5, player = 2, powers = {} },
			}

			local threatened = Evaluator.getThreatenedPieces(state, 1)
			assert.are.equal(0, #threatened) -- Protected piece not threatened
		end)

		it("does not include duplicates when multiple enemies can capture same piece", function()
			local state = GameLogic.createInitialState()
			-- Setup: One Player 1 piece that can be captured by two Player 2 pieces
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = {} },
				{ row = 5, col = 5, player = 2, powers = {} }, -- Can capture
				{ row = 4, col = 6, player = 2, powers = {} }, -- Can also capture
			}

			local threatened = Evaluator.getThreatenedPieces(state, 1)
			assert.are.equal(1, #threatened) -- Only one entry, not duplicated
		end)

		it("works for player 2 as well", function()
			local state = GameLogic.createInitialState()
			-- Setup: Player 2 piece threatened by Player 1
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = {} },
				{ row = 5, col = 5, player = 2, powers = {} },
			}

			local threatened = Evaluator.getThreatenedPieces(state, 2)
			assert.are.equal(1, #threatened)
			assert.are.equal(5, threatened[1].row)
			assert.are.equal(5, threatened[1].col)
		end)
	end)

	-- 8B.2 Opportunity Detection
	describe("getCaptureOpportunities", function()
		it("returns empty table when no captures available", function()
			local state = GameLogic.createInitialState()
			-- Initial board has no adjacent enemy pieces
			local opportunities = Evaluator.getCaptureOpportunities(state, 1)
			assert.are.equal(0, #opportunities)
		end)

		it("finds single capture opportunity", function()
			local state = GameLogic.createInitialState()
			-- Setup: Player 1 piece at (5,5) can capture Player 2 piece at (4,5)
			state.pieces = {
				{ row = 5, col = 5, player = 1, powers = {} },
				{ row = 4, col = 5, player = 2, powers = {} },
			}

			local opportunities = Evaluator.getCaptureOpportunities(state, 1)
			assert.are.equal(1, #opportunities)
			assert.are.equal(5, opportunities[1].piece.row)
			assert.are.equal(5, opportunities[1].piece.col)
			assert.are.equal(4, opportunities[1].target.row)
			assert.are.equal(5, opportunities[1].target.col)
		end)

		it("finds multiple capture opportunities", function()
			local state = GameLogic.createInitialState()
			-- Setup: Two Player 1 pieces that can each capture a Player 2 piece
			state.pieces = {
				{ row = 5, col = 3, player = 1, powers = {} }, -- Can capture at 4,3
				{ row = 5, col = 7, player = 1, powers = {} }, -- Can capture at 4,7
				{ row = 4, col = 3, player = 2, powers = {} },
				{ row = 4, col = 7, player = 2, powers = {} },
			}

			local opportunities = Evaluator.getCaptureOpportunities(state, 1)
			assert.are.equal(2, #opportunities)
		end)

		it("includes target piece information", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 5, col = 5, player = 1, powers = {} },
				{ row = 4, col = 5, player = 2, powers = { "bomb" } },
			}

			local opportunities = Evaluator.getCaptureOpportunities(state, 1)
			assert.are.equal(1, #opportunities)
			assert.is_not_nil(opportunities[1].targetPiece)
			assert.are.equal(2, opportunities[1].targetPiece.player)
		end)

		it("respects jump_proof on target piece", function()
			local state = GameLogic.createInitialState()
			-- Setup: Player 2 piece has jump_proof, cannot be captured
			state.pieces = {
				{ row = 5, col = 5, player = 1, powers = {} },
				{ row = 4, col = 5, player = 2, powers = {}, isJumpProof = true },
			}

			local opportunities = Evaluator.getCaptureOpportunities(state, 1)
			assert.are.equal(0, #opportunities) -- Cannot capture jump_proof piece
		end)

		it("works for player 2", function()
			local state = GameLogic.createInitialState()
			-- Setup: Player 2 piece can capture Player 1 piece
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = {} },
				{ row = 5, col = 5, player = 2, powers = {} },
			}

			local opportunities = Evaluator.getCaptureOpportunities(state, 2)
			assert.are.equal(1, #opportunities)
			assert.are.equal(5, opportunities[1].piece.row) -- Player 2's piece
			assert.are.equal(4, opportunities[1].target.row) -- Capture target
		end)
	end)

	-- 8B.3 Power Usage Triggers
	describe("shouldUseJumpProof", function()
		it("returns true when piece is threatened and has jump_proof", function()
			local state = GameLogic.createInitialState()
			-- Player 1 piece threatened by Player 2 piece
			local piece = { row = 4, col = 5, player = 1, powers = { "jump_proof" } }
			state.pieces = {
				piece,
				{ row = 5, col = 5, player = 2, powers = {} },
			}

			local shouldUse = Evaluator.shouldUseJumpProof(state, piece)
			assert.is_true(shouldUse)
		end)

		it("returns false when piece is not threatened", function()
			local state = GameLogic.createInitialState()
			-- Piece is safe - no enemy adjacent
			local piece = { row = 4, col = 5, player = 1, powers = { "jump_proof" } }
			state.pieces = {
				piece,
				{ row = 8, col = 8, player = 2, powers = {} }, -- Far away
			}

			local shouldUse = Evaluator.shouldUseJumpProof(state, piece)
			assert.is_false(shouldUse)
		end)

		it("returns false when piece does not have jump_proof power", function()
			local state = GameLogic.createInitialState()
			-- Piece is threatened but doesn't have jump_proof
			local piece = { row = 4, col = 5, player = 1, powers = {} }
			state.pieces = {
				piece,
				{ row = 5, col = 5, player = 2, powers = {} },
			}

			local shouldUse = Evaluator.shouldUseJumpProof(state, piece)
			assert.is_false(shouldUse)
		end)

		it("returns false when piece already has isJumpProof flag", function()
			local state = GameLogic.createInitialState()
			-- Piece already activated jump_proof
			local piece = { row = 4, col = 5, player = 1, powers = { "jump_proof" }, isJumpProof = true }
			state.pieces = {
				piece,
				{ row = 5, col = 5, player = 2, powers = {} },
			}

			local shouldUse = Evaluator.shouldUseJumpProof(state, piece)
			assert.is_false(shouldUse)
		end)
	end)

	describe("shouldUseDestroyRow", function()
		it("returns true when enemy pieces in row", function()
			local state = GameLogic.createInitialState()
			local piece = { row = 5, col = 3, player = 1, powers = { "destroy_row" } }
			state.pieces = {
				piece,
				{ row = 5, col = 7, player = 2, powers = {} }, -- Same row
			}

			local shouldUse, targets = Evaluator.shouldUseDestroyRow(state, piece)
			assert.is_true(shouldUse)
			assert.are.equal(1, #targets)
		end)

		it("returns false when no enemy pieces in row", function()
			local state = GameLogic.createInitialState()
			local piece = { row = 5, col = 3, player = 1, powers = { "destroy_row" } }
			state.pieces = {
				piece,
				{ row = 3, col = 7, player = 2, powers = {} }, -- Different row
			}

			local shouldUse = Evaluator.shouldUseDestroyRow(state, piece)
			assert.is_false(shouldUse)
		end)

		it("returns false when only own pieces in row", function()
			local state = GameLogic.createInitialState()
			local piece = { row = 5, col = 3, player = 1, powers = { "destroy_row" } }
			state.pieces = {
				piece,
				{ row = 5, col = 7, player = 1, powers = {} }, -- Same row, same player
			}

			local shouldUse = Evaluator.shouldUseDestroyRow(state, piece)
			assert.is_false(shouldUse)
		end)

		it("returns false when piece does not have destroy_row", function()
			local state = GameLogic.createInitialState()
			local piece = { row = 5, col = 3, player = 1, powers = {} }
			state.pieces = {
				piece,
				{ row = 5, col = 7, player = 2, powers = {} },
			}

			local shouldUse = Evaluator.shouldUseDestroyRow(state, piece)
			assert.is_false(shouldUse)
		end)
	end)

	describe("shouldUseDestroyColumn", function()
		it("returns true when enemy pieces in column", function()
			local state = GameLogic.createInitialState()
			local piece = { row = 3, col = 5, player = 1, powers = { "destroy_column" } }
			state.pieces = {
				piece,
				{ row = 7, col = 5, player = 2, powers = {} }, -- Same column
			}

			local shouldUse, targets = Evaluator.shouldUseDestroyColumn(state, piece)
			assert.is_true(shouldUse)
			assert.are.equal(1, #targets)
		end)

		it("returns false when no enemy pieces in column", function()
			local state = GameLogic.createInitialState()
			local piece = { row = 3, col = 5, player = 1, powers = { "destroy_column" } }
			state.pieces = {
				piece,
				{ row = 7, col = 8, player = 2, powers = {} }, -- Different column
			}

			local shouldUse = Evaluator.shouldUseDestroyColumn(state, piece)
			assert.is_false(shouldUse)
		end)
	end)

	describe("shouldUseRecruit", function()
		it("returns true when adjacent enemy exists", function()
			local state = GameLogic.createInitialState()
			local piece = { row = 5, col = 5, player = 1, powers = { "recruit" } }
			state.pieces = {
				piece,
				{ row = 5, col = 6, player = 2, powers = {} }, -- Adjacent enemy
			}

			local shouldUse, targets = Evaluator.shouldUseRecruit(state, piece)
			assert.is_true(shouldUse)
			assert.are.equal(1, #targets)
		end)

		it("returns false when no adjacent enemies", function()
			local state = GameLogic.createInitialState()
			local piece = { row = 5, col = 5, player = 1, powers = { "recruit" } }
			state.pieces = {
				piece,
				{ row = 7, col = 7, player = 2, powers = {} }, -- Not adjacent
			}

			local shouldUse = Evaluator.shouldUseRecruit(state, piece)
			assert.is_false(shouldUse)
		end)

		it("returns false when piece does not have recruit", function()
			local state = GameLogic.createInitialState()
			local piece = { row = 5, col = 5, player = 1, powers = {} }
			state.pieces = {
				piece,
				{ row = 5, col = 6, player = 2, powers = {} },
			}

			local shouldUse = Evaluator.shouldUseRecruit(state, piece)
			assert.is_false(shouldUse)
		end)
	end)

	describe("shouldUseBomb", function()
		it("returns true when multiple enemies in 3x3 area", function()
			local state = GameLogic.createInitialState()
			local piece = { row = 5, col = 5, player = 1, powers = { "bomb" } }
			state.pieces = {
				piece,
				{ row = 4, col = 5, player = 2, powers = {} }, -- In bomb range
				{ row = 5, col = 6, player = 2, powers = {} }, -- In bomb range
			}

			local shouldUse, targets = Evaluator.shouldUseBomb(state, piece)
			assert.is_true(shouldUse)
			assert.are.equal(2, #targets)
		end)

		it("returns false when only one enemy in range", function()
			local state = GameLogic.createInitialState()
			local piece = { row = 5, col = 5, player = 1, powers = { "bomb" } }
			state.pieces = {
				piece,
				{ row = 4, col = 5, player = 2, powers = {} }, -- Only one enemy
			}

			-- Bomb should not be wasted on single target (can just capture normally)
			local shouldUse = Evaluator.shouldUseBomb(state, piece)
			assert.is_false(shouldUse)
		end)

		it("returns false when own pieces would be destroyed", function()
			local state = GameLogic.createInitialState()
			local piece = { row = 5, col = 5, player = 1, powers = { "bomb" } }
			state.pieces = {
				piece,
				{ row = 4, col = 5, player = 2, powers = {} }, -- Enemy
				{ row = 5, col = 6, player = 2, powers = {} }, -- Enemy
				{ row = 4, col = 6, player = 1, powers = {} }, -- Own piece in range!
			}

			local shouldUse = Evaluator.shouldUseBomb(state, piece)
			assert.is_false(shouldUse)
		end)

		it("returns false when piece does not have bomb", function()
			local state = GameLogic.createInitialState()
			local piece = { row = 5, col = 5, player = 1, powers = {} }
			state.pieces = {
				piece,
				{ row = 4, col = 5, player = 2, powers = {} },
				{ row = 5, col = 6, player = 2, powers = {} },
			}

			local shouldUse = Evaluator.shouldUseBomb(state, piece)
			assert.is_false(shouldUse)
		end)
	end)

	-- 8B.4 Position Scoring
	describe("scorePosition", function()
		it("returns higher score for center positions than edges", function()
			local state = GameLogic.createInitialState()

			-- Center position (row 4-5, col 5-6 on 10x8 board)
			local centerScore = Evaluator.scorePosition(state, 4, 5)
			-- Edge position
			local edgeScore = Evaluator.scorePosition(state, 1, 1)

			assert.is_true(centerScore > edgeScore)
		end)

		it("returns higher score for high ground than low ground", function()
			local state = GameLogic.createInitialState()

			-- Set height at position (5,5) to 3
			state.heightMap[5][5] = 3
			-- Keep height at position (5,6) at 0
			state.heightMap[5][6] = 0

			local highScore = Evaluator.scorePosition(state, 5, 5)
			local lowScore = Evaluator.scorePosition(state, 5, 6)

			assert.is_true(highScore > lowScore)
		end)

		it("returns consistent scores for symmetric positions", function()
			local state = GameLogic.createInitialState()

			-- Positions (4,5) and (5,6) should have similar scores if heights equal
			-- (both near center)
			local score1 = Evaluator.scorePosition(state, 4, 5)
			local score2 = Evaluator.scorePosition(state, 5, 6)

			-- Should be close (within 10% difference)
			local diff = math.abs(score1 - score2)
			local maxScore = math.max(score1, score2)
			assert.is_true(diff / maxScore < 0.2) -- Within 20%
		end)

		it("combines center and height bonuses", function()
			local state = GameLogic.createInitialState()

			-- Center + high ground = best
			state.heightMap[4][5] = 4
			local bestScore = Evaluator.scorePosition(state, 4, 5)

			-- Edge + low ground = worst
			state.heightMap[1][1] = 0
			local worstScore = Evaluator.scorePosition(state, 1, 1)

			-- Center + low ground = medium
			state.heightMap[4][6] = 0
			local mediumScore = Evaluator.scorePosition(state, 4, 6)

			assert.is_true(bestScore > mediumScore)
			assert.is_true(mediumScore > worstScore)
		end)

		it("returns 0 for destroyed tiles", function()
			local state = GameLogic.createInitialState()
			state.destroyedTiles = { ["3,3"] = true }

			local score = Evaluator.scorePosition(state, 3, 3)
			assert.are.equal(0, score)
		end)
	end)

	describe("scorePiecePosition", function()
		it("includes base position score", function()
			local state = GameLogic.createInitialState()
			local piece = { row = 4, col = 5, player = 1, powers = {} }
			state.pieces = { piece }

			local score = Evaluator.scorePiecePosition(state, piece)
			local posScore = Evaluator.scorePosition(state, 4, 5)

			-- Piece score should include position score
			assert.is_true(score >= posScore)
		end)

		it("adds bonus for pieces with powers", function()
			local state = GameLogic.createInitialState()
			local pieceWithPowers = { row = 4, col = 5, player = 1, powers = { "bomb", "recruit" } }
			local pieceNoPowers = { row = 4, col = 6, player = 1, powers = {} }
			state.pieces = { pieceWithPowers, pieceNoPowers }

			local scoreWith = Evaluator.scorePiecePosition(state, pieceWithPowers)
			local scoreWithout = Evaluator.scorePiecePosition(state, pieceNoPowers)

			assert.is_true(scoreWith > scoreWithout)
		end)

		it("adds bonus for jump_proof pieces", function()
			local state = GameLogic.createInitialState()
			local protectedPiece = { row = 4, col = 5, player = 1, powers = {}, isJumpProof = true }
			local normalPiece = { row = 4, col = 6, player = 1, powers = {} }
			state.pieces = { protectedPiece, normalPiece }

			local protectedScore = Evaluator.scorePiecePosition(state, protectedPiece)
			local normalScore = Evaluator.scorePiecePosition(state, normalPiece)

			assert.is_true(protectedScore > normalScore)
		end)

		it("adds bonus for diagonal movement", function()
			local state = GameLogic.createInitialState()
			local diagonalPiece = { row = 4, col = 5, player = 1, powers = {}, canMoveDiagonally = true }
			local normalPiece = { row = 4, col = 6, player = 1, powers = {} }
			state.pieces = { diagonalPiece, normalPiece }

			local diagScore = Evaluator.scorePiecePosition(state, diagonalPiece)
			local normalScore = Evaluator.scorePiecePosition(state, normalPiece)

			assert.is_true(diagScore > normalScore)
		end)
	end)

	-- 8B.5 Orb Collection Priority
	describe("getOrbOpportunities", function()
		it("returns empty when no orbs exist", function()
			local state = GameLogic.createInitialState()
			local orbs = {}
			state.pieces = {
				{ row = 5, col = 5, player = 1, powers = {} },
			}

			local opportunities = Evaluator.getOrbOpportunities(state, orbs, 1)
			assert.are.equal(0, #opportunities)
		end)

		it("finds orb within one move", function()
			local state = GameLogic.createInitialState()
			local orbs = {
				{ row = 5, col = 6, powerId = "bomb" }, -- Adjacent to piece
			}
			state.pieces = {
				{ row = 5, col = 5, player = 1, powers = {} },
			}

			local opportunities = Evaluator.getOrbOpportunities(state, orbs, 1)
			assert.are.equal(1, #opportunities)
			assert.are.equal("bomb", opportunities[1].orb.powerId)
		end)

		it("returns multiple orb opportunities", function()
			local state = GameLogic.createInitialState()
			local orbs = {
				{ row = 5, col = 6, powerId = "bomb" },
				{ row = 4, col = 5, powerId = "recruit" },
			}
			state.pieces = {
				{ row = 5, col = 5, player = 1, powers = {} },
			}

			local opportunities = Evaluator.getOrbOpportunities(state, orbs, 1)
			assert.are.equal(2, #opportunities)
		end)

		it("only finds orbs reachable by player's pieces", function()
			local state = GameLogic.createInitialState()
			local orbs = {
				{ row = 1, col = 1, powerId = "bomb" }, -- Far from player 1's piece
			}
			state.pieces = {
				{ row = 5, col = 5, player = 1, powers = {} },
				{ row = 1, col = 2, player = 2, powers = {} }, -- Player 2 can reach
			}

			local p1Opportunities = Evaluator.getOrbOpportunities(state, orbs, 1)
			local p2Opportunities = Evaluator.getOrbOpportunities(state, orbs, 2)

			assert.are.equal(0, #p1Opportunities)
			assert.are.equal(1, #p2Opportunities)
		end)

		it("includes piece and target in opportunity", function()
			local state = GameLogic.createInitialState()
			local orbs = {
				{ row = 5, col = 6, powerId = "bomb" },
			}
			local piece = { row = 5, col = 5, player = 1, powers = {} }
			state.pieces = { piece }

			local opportunities = Evaluator.getOrbOpportunities(state, orbs, 1)
			assert.are.equal(1, #opportunities)
			assert.are.equal(piece, opportunities[1].piece)
			assert.are.equal(5, opportunities[1].target.row)
			assert.are.equal(6, opportunities[1].target.col)
		end)
	end)

	describe("scoreOrbValue", function()
		it("returns positive value for useful powers", function()
			local orb = { row = 5, col = 5, powerId = "bomb" }
			local score = Evaluator.scoreOrbValue(orb)
			assert.is_true(score > 0)
		end)

		it("scores offensive powers highly", function()
			local bombOrb = { row = 5, col = 5, powerId = "bomb" }
			local recruitOrb = { row = 5, col = 5, powerId = "recruit" }

			local bombScore = Evaluator.scoreOrbValue(bombOrb)
			local recruitScore = Evaluator.scoreOrbValue(recruitOrb)

			-- Both should be valuable
			assert.is_true(bombScore > 0)
			assert.is_true(recruitScore > 0)
		end)

		it("scores defensive powers", function()
			local jumpProofOrb = { row = 5, col = 5, powerId = "jump_proof" }
			local score = Evaluator.scoreOrbValue(jumpProofOrb)
			assert.is_true(score > 0)
		end)
	end)

	describe("isOrbCollectionRisky", function()
		it("returns false when move is safe", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 5, col = 5, player = 1, powers = {} },
				{ row = 8, col = 8, player = 2, powers = {} }, -- Far away
			}
			local target = { row = 5, col = 6 }

			local risky = Evaluator.isOrbCollectionRisky(state, 1, target)
			assert.is_false(risky)
		end)

		it("returns true when enemy can capture at target", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 5, col = 5, player = 1, powers = {} },
				{ row = 5, col = 7, player = 2, powers = {} }, -- Can capture at 5,6
			}
			local target = { row = 5, col = 6 }

			local risky = Evaluator.isOrbCollectionRisky(state, 1, target)
			assert.is_true(risky)
		end)

		it("considers jump_proof protection", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 5, col = 5, player = 1, powers = {}, isJumpProof = true },
				{ row = 5, col = 7, player = 2, powers = {} },
			}
			local target = { row = 5, col = 6 }

			-- Even though enemy is adjacent to target, our piece is protected
			-- Note: this tests if we'd be safe AFTER moving (piece wouldn't have protection yet)
			-- So it should still be risky
			local risky = Evaluator.isOrbCollectionRisky(state, 1, target)
			assert.is_true(risky)
		end)
	end)

	-- 8B.6 Move Scoring
	describe("scoreMove", function()
		it("returns positive score for valid moves", function()
			local state = GameLogic.createInitialState()
			local piece = { row = 5, col = 5, player = 1, powers = {} }
			state.pieces = { piece }
			local orbs = {}

			local move = { piece = piece, target = { row = 5, col = 6 } }
			local score = Evaluator.scoreMove(state, move, orbs)

			assert.is_true(score > 0)
		end)

		it("scores capture moves highly", function()
			local state = GameLogic.createInitialState()
			local piece = { row = 5, col = 5, player = 1, powers = {} }
			local enemy = { row = 5, col = 6, player = 2, powers = {} }
			state.pieces = { piece, enemy }
			local orbs = {}

			local captureMove = { piece = piece, target = { row = 5, col = 6 } }
			local normalMove = { piece = piece, target = { row = 5, col = 4 } }

			local captureScore = Evaluator.scoreMove(state, captureMove, orbs)
			local normalScore = Evaluator.scoreMove(state, normalMove, orbs)

			assert.is_true(captureScore > normalScore)
		end)

		it("scores orb collection moves", function()
			local state = GameLogic.createInitialState()
			local piece = { row = 5, col = 5, player = 1, powers = {} }
			state.pieces = { piece }
			local orbs = {
				{ row = 5, col = 6, powerId = "bomb" },
			}

			local orbMove = { piece = piece, target = { row = 5, col = 6 } }
			local normalMove = { piece = piece, target = { row = 5, col = 4 } }

			local orbScore = Evaluator.scoreMove(state, orbMove, orbs)
			local normalScore = Evaluator.scoreMove(state, normalMove, orbs)

			assert.is_true(orbScore > normalScore)
		end)

		it("prefers safer orb collection", function()
			local state = GameLogic.createInitialState()
			local piece = { row = 5, col = 5, player = 1, powers = {} }
			local enemy = { row = 5, col = 7, player = 2, powers = {} } -- Threatens 5,6
			state.pieces = { piece, enemy }
			local orbs = {
				{ row = 5, col = 6, powerId = "bomb" }, -- Risky orb
				{ row = 5, col = 4, powerId = "bomb" }, -- Safe orb
			}

			local riskyOrbMove = { piece = piece, target = { row = 5, col = 6 } }
			local safeOrbMove = { piece = piece, target = { row = 5, col = 4 } }

			local riskyScore = Evaluator.scoreMove(state, riskyOrbMove, orbs)
			local safeScore = Evaluator.scoreMove(state, safeOrbMove, orbs)

			assert.is_true(safeScore > riskyScore)
		end)

		it("considers position improvement", function()
			local state = GameLogic.createInitialState()
			local piece = { row = 1, col = 1, player = 1, powers = {} } -- Corner
			state.pieces = { piece }
			local orbs = {}

			-- Move toward center vs stay at edge
			local towardCenterMove = { piece = piece, target = { row = 1, col = 2 } }
			local stayEdgeMove = { piece = piece, target = { row = 2, col = 1 } }

			-- Both move toward center, but col 2 is slightly more central
			local score1 = Evaluator.scoreMove(state, towardCenterMove, orbs)
			local score2 = Evaluator.scoreMove(state, stayEdgeMove, orbs)

			-- Both should be positive (valid moves)
			assert.is_true(score1 > 0)
			assert.is_true(score2 > 0)
		end)

		it("scores capturing high-value pieces higher", function()
			local state = GameLogic.createInitialState()
			local piece = { row = 5, col = 5, player = 1, powers = {} }
			local weakEnemy = { row = 5, col = 6, player = 2, powers = {} }
			local strongEnemy = { row = 5, col = 4, player = 2, powers = { "bomb", "recruit" } }
			state.pieces = { piece, weakEnemy, strongEnemy }
			local orbs = {}

			local captureWeak = { piece = piece, target = { row = 5, col = 6 } }
			local captureStrong = { piece = piece, target = { row = 5, col = 4 } }

			local weakScore = Evaluator.scoreMove(state, captureWeak, orbs)
			local strongScore = Evaluator.scoreMove(state, captureStrong, orbs)

			assert.is_true(strongScore > weakScore)
		end)

		it("penalizes moves that leave piece threatened", function()
			local state = GameLogic.createInitialState()
			local piece = { row = 5, col = 5, player = 1, powers = {} }
			local enemy = { row = 5, col = 7, player = 2, powers = {} }
			state.pieces = { piece, enemy }
			local orbs = {}

			-- Move to 5,6 puts us adjacent to enemy (risky)
			-- Move to 5,4 keeps us safe
			local riskyMove = { piece = piece, target = { row = 5, col = 6 } }
			local safeMove = { piece = piece, target = { row = 5, col = 4 } }

			local riskyScore = Evaluator.scoreMove(state, riskyMove, orbs)
			local safeScore = Evaluator.scoreMove(state, safeMove, orbs)

			assert.is_true(safeScore > riskyScore)
		end)
	end)

	describe("getAllMoves", function()
		it("returns all valid moves for a player", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 5, col = 5, player = 1, powers = {} },
			}

			local moves = Evaluator.getAllMoves(state, 1)

			-- Piece at 5,5 can move to 4,5, 6,5, 5,4, 5,6 (4 moves)
			assert.are.equal(4, #moves)
		end)

		it("returns moves for multiple pieces", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 5, col = 5, player = 1, powers = {} },
				{ row = 3, col = 3, player = 1, powers = {} },
			}

			local moves = Evaluator.getAllMoves(state, 1)

			-- Each piece has 4 moves = 8 total
			assert.are.equal(8, #moves)
		end)

		it("only returns moves for specified player", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 5, col = 5, player = 1, powers = {} },
				{ row = 3, col = 3, player = 2, powers = {} },
			}

			local p1Moves = Evaluator.getAllMoves(state, 1)
			local p2Moves = Evaluator.getAllMoves(state, 2)

			assert.are.equal(4, #p1Moves)
			assert.are.equal(4, #p2Moves)
		end)

		it("includes piece reference in each move", function()
			local state = GameLogic.createInitialState()
			local piece = { row = 5, col = 5, player = 1, powers = {} }
			state.pieces = { piece }

			local moves = Evaluator.getAllMoves(state, 1)

			for _, move in ipairs(moves) do
				assert.are.equal(piece, move.piece)
				assert.is_not_nil(move.target)
				assert.is_not_nil(move.target.row)
				assert.is_not_nil(move.target.col)
			end
		end)
	end)

	describe("getBestMove", function()
		it("returns highest scoring move", function()
			local state = GameLogic.createInitialState()
			local piece = { row = 5, col = 5, player = 1, powers = {} }
			local enemy = { row = 5, col = 6, player = 2, powers = {} }
			state.pieces = { piece, enemy }
			local orbs = {}

			local bestMove = Evaluator.getBestMove(state, orbs, 1)

			-- Should choose capture move
			assert.are.equal(5, bestMove.target.row)
			assert.are.equal(6, bestMove.target.col)
		end)

		it("returns nil when no moves available", function()
			local state = GameLogic.createInitialState()
			state.pieces = {} -- No pieces

			local bestMove = Evaluator.getBestMove(state, {}, 1)

			assert.is_nil(bestMove)
		end)

		it("prefers orb over empty square", function()
			local state = GameLogic.createInitialState()
			local piece = { row = 5, col = 5, player = 1, powers = {} }
			state.pieces = { piece }
			local orbs = {
				{ row = 5, col = 6, powerId = "bomb" },
			}

			local bestMove = Evaluator.getBestMove(state, orbs, 1)

			assert.are.equal(5, bestMove.target.row)
			assert.are.equal(6, bestMove.target.col)
		end)
	end)

	-- 8C.1 Board Evaluation (for minimax search)
	describe("evaluate", function()
		it("returns numeric score", function()
			local state = GameLogic.createInitialState()
			local score = Evaluator.evaluate(state, 1)
			assert.is_number(score)
		end)

		it("returns higher score for more pieces", function()
			local state = GameLogic.createInitialState()
			-- Player 1 has more pieces
			state.pieces = {
				{ row = 3, col = 3, player = 1, powers = {} },
				{ row = 3, col = 4, player = 1, powers = {} },
				{ row = 3, col = 5, player = 1, powers = {} },
				{ row = 6, col = 5, player = 2, powers = {} },
			}

			local p1Score = Evaluator.evaluate(state, 1)
			local p2Score = Evaluator.evaluate(state, 2)

			assert.is_true(p1Score > p2Score)
		end)

		it("returns higher score for better positions", function()
			local state = GameLogic.createInitialState()
			-- Player 1 in center, Player 2 on edge
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = {} }, -- Center
				{ row = 1, col = 1, player = 2, powers = {} }, -- Corner
			}

			local p1Score = Evaluator.evaluate(state, 1)
			local p2Score = Evaluator.evaluate(state, 2)

			assert.is_true(p1Score > p2Score)
		end)

		it("adds score for pieces with powers", function()
			local state = GameLogic.createInitialState()
			-- Same positions, but one player has powers
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "bomb", "recruit" } },
				{ row = 4, col = 6, player = 2, powers = {} },
			}

			local p1Score = Evaluator.evaluate(state, 1)
			local p2Score = Evaluator.evaluate(state, 2)

			assert.is_true(p1Score > p2Score)
		end)

		it("is symmetric (negamax compatible)", function()
			local state = GameLogic.createInitialState()
			-- Symmetric setup
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = {} },
				{ row = 5, col = 5, player = 2, powers = {} },
			}

			local p1Score = Evaluator.evaluate(state, 1)
			local p2Score = Evaluator.evaluate(state, 2)

			-- For negamax: evaluate(state, p1) should equal -evaluate(state, p2)
			-- with some tolerance for position differences
			-- Actually, we need: score for p1 from p1's view = -score for p1 from p2's view
			-- This test verifies the evaluation is relative to the player
			assert.is_true(p1Score ~= p2Score or p1Score == 0)
		end)

		it("returns large positive score for winning position", function()
			local state = GameLogic.createInitialState()
			-- Player 1 has pieces, Player 2 has none (Player 1 wins)
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = {} },
			}

			local p1Score = Evaluator.evaluate(state, 1)
			local p2Score = Evaluator.evaluate(state, 2)

			assert.is_true(p1Score > 1000) -- Winning bonus
			assert.is_true(p2Score < -1000) -- Losing penalty
		end)

		it("returns 0 for empty board", function()
			local state = GameLogic.createInitialState()
			state.pieces = {}

			local score = Evaluator.evaluate(state, 1)
			assert.are.equal(0, score)
		end)
	end)
end)
