-- Busted tests for game animations integration
-- Run with: busted spec/
-- TDD: Write tests first (RED), then implement (GREEN)

describe("GameAnimations", function()
	local GameAnimations
	local Animations
	local GameLogic
	local PowerEffects

	setup(function()
		GameAnimations = require("src.shared.game_animations")
		Animations = require("src.shared.animations")
		GameLogic = require("src.shared.game_logic")
		PowerEffects = require("src.shared.power_effects")
	end)

	describe("create", function()
		it("returns game animations state with empty queue", function()
			local ga = GameAnimations.create()
			assert.is_table(ga)
			assert.is_table(ga.queue)
			assert.are.equal(0, #ga.queue.animations)
		end)
	end)

	describe("queuePowerAnimation", function()
		it("queues destroy_row as blocking animation", function()
			local ga = GameAnimations.create()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 1, 5)

			GameAnimations.queuePowerAnimation(ga, state, piece, "destroy_row")

			assert.are.equal(1, #ga.queue.animations)
			assert.are.equal("destroy_row", ga.queue.animations[1].type)
			assert.is_true(ga.queue.animations[1].blocking)
		end)

		it("queues destroy_column as blocking animation", function()
			local ga = GameAnimations.create()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 1, 5)

			GameAnimations.queuePowerAnimation(ga, state, piece, "destroy_column")

			assert.are.equal(1, #ga.queue.animations)
			assert.are.equal("destroy_column", ga.queue.animations[1].type)
			assert.is_true(ga.queue.animations[1].blocking)
		end)

		it("queues bomb as blocking animation", function()
			local ga = GameAnimations.create()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 1, 5)

			GameAnimations.queuePowerAnimation(ga, state, piece, "bomb")

			assert.are.equal(1, #ga.queue.animations)
			assert.are.equal("bomb", ga.queue.animations[1].type)
			assert.is_true(ga.queue.animations[1].blocking)
		end)

		it("queues move_diagonal as non-blocking animation", function()
			local ga = GameAnimations.create()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 1, 5)

			GameAnimations.queuePowerAnimation(ga, state, piece, "move_diagonal")

			assert.are.equal(1, #ga.queue.animations)
			assert.are.equal("move_diagonal", ga.queue.animations[1].type)
			assert.is_false(ga.queue.animations[1].blocking)
		end)

		it("queues jump_proof as non-blocking animation", function()
			local ga = GameAnimations.create()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 1, 5)

			GameAnimations.queuePowerAnimation(ga, state, piece, "jump_proof")

			assert.are.equal(1, #ga.queue.animations)
			assert.are.equal("jump_proof", ga.queue.animations[1].type)
			assert.is_false(ga.queue.animations[1].blocking)
		end)

		it("queues invisible as non-blocking animation", function()
			local ga = GameAnimations.create()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 1, 5)

			GameAnimations.queuePowerAnimation(ga, state, piece, "invisible")

			assert.are.equal(1, #ga.queue.animations)
			assert.are.equal("invisible", ga.queue.animations[1].type)
			assert.is_false(ga.queue.animations[1].blocking)
		end)
	end)

	describe("isBlocking", function()
		it("returns false when no animations", function()
			local ga = GameAnimations.create()
			assert.is_false(GameAnimations.isBlocking(ga))
		end)

		it("returns true when blocking animation is active", function()
			local ga = GameAnimations.create()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 1, 5)

			GameAnimations.queuePowerAnimation(ga, state, piece, "destroy_row")

			assert.is_true(GameAnimations.isBlocking(ga))
		end)

		it("returns false when only non-blocking animations", function()
			local ga = GameAnimations.create()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 1, 5)

			GameAnimations.queuePowerAnimation(ga, state, piece, "move_diagonal")

			assert.is_false(GameAnimations.isBlocking(ga))
		end)
	end)

	describe("update", function()
		it("progresses animations", function()
			local ga = GameAnimations.create()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 1, 5)

			GameAnimations.queuePowerAnimation(ga, state, piece, "move_diagonal")
			local anim = ga.queue.animations[1]

			GameAnimations.update(ga, 0.1)

			assert.are.equal(0.1, anim.elapsed)
		end)

		it("removes completed animations", function()
			local ga = GameAnimations.create()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 1, 5)

			GameAnimations.queuePowerAnimation(ga, state, piece, "move_diagonal")

			-- Update past animation duration
			GameAnimations.update(ga, 1.0)

			assert.are.equal(0, #ga.queue.animations)
		end)
	end)

	describe("onComplete callback", function()
		it("executes power effect when animation completes", function()
			local ga = GameAnimations.create()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.powers = { "move_diagonal" }

			-- Queue with callback that applies effect
			GameAnimations.queuePowerAnimationWithEffect(ga, state, piece, "move_diagonal")

			-- Animation not complete yet
			assert.is_nil(piece.canMoveDiagonally)

			-- Complete the animation
			GameAnimations.update(ga, 1.0)

			-- Effect should now be applied
			assert.is_true(piece.canMoveDiagonally)
		end)

		it("applies destroy_row effect on completion", function()
			local ga = GameAnimations.create()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 1, 5)
			piece.powers = { "destroy_row" }

			local initialCount = #state.pieces

			GameAnimations.queuePowerAnimationWithEffect(ga, state, piece, "destroy_row")

			-- Animation not complete yet - pieces still there
			assert.are.equal(initialCount, #state.pieces)

			-- Complete the animation
			GameAnimations.update(ga, 1.0)

			-- Effect should now be applied - pieces destroyed
			assert.is_true(#state.pieces < initialCount)
		end)
	end)

	describe("getActiveAnimations", function()
		it("returns all active animations", function()
			local ga = GameAnimations.create()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 1, 5)

			GameAnimations.queuePowerAnimation(ga, state, piece, "move_diagonal")
			GameAnimations.queuePowerAnimation(ga, state, piece, "jump_proof")

			local active = GameAnimations.getActiveAnimations(ga)
			assert.are.equal(2, #active)
		end)
	end)
end)
