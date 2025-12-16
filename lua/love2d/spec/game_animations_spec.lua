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

	-- =============================================================================
	-- Power Animation Coverage Tests by Category
	-- =============================================================================

	describe("createPowerAnimation - self-targeting powers", function()
		local piece

		setup(function()
			piece = { row = 5, col = 5, player = 1, powers = {} }
		end)

		it("creates animation for move_diagonal", function()
			local anim = GameAnimations.createPowerAnimation(piece, "move_diagonal")
			assert.is_not_nil(anim)
			assert.are.equal("move_diagonal", anim.type)
			assert.is_false(anim.blocking)
		end)

		it("creates animation for move_again", function()
			local anim = GameAnimations.createPowerAnimation(piece, "move_again")
			assert.is_not_nil(anim)
			assert.are.equal("move_again", anim.type)
			assert.is_false(anim.blocking)
		end)

		it("creates animation for relocate", function()
			local anim = GameAnimations.createPowerAnimation(piece, "relocate")
			assert.is_not_nil(anim)
			assert.are.equal("relocate", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for jump_proof", function()
			local anim = GameAnimations.createPowerAnimation(piece, "jump_proof")
			assert.is_not_nil(anim)
			assert.are.equal("jump_proof", anim.type)
			assert.is_false(anim.blocking)
		end)

		it("creates animation for invisible", function()
			local anim = GameAnimations.createPowerAnimation(piece, "invisible")
			assert.is_not_nil(anim)
			assert.are.equal("invisible", anim.type)
			assert.is_false(anim.blocking)
		end)

		it("creates animation for climb_tile", function()
			local anim = GameAnimations.createPowerAnimation(piece, "climb_tile")
			assert.is_not_nil(anim)
			assert.are.equal("power_self", anim.type)
			assert.is_false(anim.blocking)
		end)

		it("creates animation for double_powers", function()
			local anim = GameAnimations.createPowerAnimation(piece, "double_powers")
			assert.is_not_nil(anim)
			assert.are.equal("power_self", anim.type)
			assert.is_false(anim.blocking)
		end)

		it("creates animation for grow_quadradius", function()
			local anim = GameAnimations.createPowerAnimation(piece, "grow_quadradius")
			assert.is_not_nil(anim)
			assert.are.equal("power_self", anim.type)
			assert.is_false(anim.blocking)
		end)

		it("creates animation for beneficiary", function()
			local anim = GameAnimations.createPowerAnimation(piece, "beneficiary")
			assert.is_not_nil(anim)
			assert.are.equal("power_self", anim.type)
			assert.is_false(anim.blocking)
		end)

		it("creates animation for scavenger", function()
			local anim = GameAnimations.createPowerAnimation(piece, "scavenger")
			assert.is_not_nil(anim)
			assert.are.equal("power_self", anim.type)
			assert.is_false(anim.blocking)
		end)

		it("creates animation for flat_to_sphere", function()
			local anim = GameAnimations.createPowerAnimation(piece, "flat_to_sphere")
			assert.is_not_nil(anim)
			assert.are.equal("power_self", anim.type)
			assert.is_false(anim.blocking)
		end)

		it("creates animation for hotspot", function()
			local anim = GameAnimations.createPowerAnimation(piece, "hotspot")
			assert.is_not_nil(anim)
			assert.are.equal("power_self", anim.type)
			assert.is_false(anim.blocking)
		end)
	end)

	describe("createPowerAnimation - row-targeting powers", function()
		local piece

		setup(function()
			piece = { row = 5, col = 5, player = 1, powers = {} }
		end)

		it("creates animation for destroy_row", function()
			local anim = GameAnimations.createPowerAnimation(piece, "destroy_row")
			assert.is_not_nil(anim)
			assert.are.equal("destroy_row", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for kamikaze_row", function()
			local anim = GameAnimations.createPowerAnimation(piece, "kamikaze_row")
			assert.is_not_nil(anim)
			assert.are.equal("power_row", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for recruit_row", function()
			local anim = GameAnimations.createPowerAnimation(piece, "recruit_row")
			assert.is_not_nil(anim)
			assert.are.equal("power_row", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for acidic_row", function()
			local anim = GameAnimations.createPowerAnimation(piece, "acidic_row")
			assert.is_not_nil(anim)
			assert.are.equal("power_row", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for scramble_row", function()
			local anim = GameAnimations.createPowerAnimation(piece, "scramble_row")
			assert.is_not_nil(anim)
			assert.are.equal("power_row", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for trench_row", function()
			local anim = GameAnimations.createPowerAnimation(piece, "trench_row")
			assert.is_not_nil(anim)
			assert.are.equal("power_row", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for wall_row", function()
			local anim = GameAnimations.createPowerAnimation(piece, "wall_row")
			assert.is_not_nil(anim)
			assert.are.equal("power_row", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for invert_row", function()
			local anim = GameAnimations.createPowerAnimation(piece, "invert_row")
			assert.is_not_nil(anim)
			assert.are.equal("power_row", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for dredge_row", function()
			local anim = GameAnimations.createPowerAnimation(piece, "dredge_row")
			assert.is_not_nil(anim)
			assert.are.equal("power_row", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for teach_row", function()
			local anim = GameAnimations.createPowerAnimation(piece, "teach_row")
			assert.is_not_nil(anim)
			assert.are.equal("power_row", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for learn_row", function()
			local anim = GameAnimations.createPowerAnimation(piece, "learn_row")
			assert.is_not_nil(anim)
			assert.are.equal("power_row", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for pilfer_row", function()
			local anim = GameAnimations.createPowerAnimation(piece, "pilfer_row")
			assert.is_not_nil(anim)
			assert.are.equal("power_row", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for spyware_row", function()
			local anim = GameAnimations.createPowerAnimation(piece, "spyware_row")
			assert.is_not_nil(anim)
			assert.are.equal("power_row", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for orb_spy_row", function()
			local anim = GameAnimations.createPowerAnimation(piece, "orb_spy_row")
			assert.is_not_nil(anim)
			assert.are.equal("power_row", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for refurb_row", function()
			local anim = GameAnimations.createPowerAnimation(piece, "refurb_row")
			assert.is_not_nil(anim)
			assert.are.equal("power_row", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for bankrupt_row", function()
			local anim = GameAnimations.createPowerAnimation(piece, "bankrupt_row")
			assert.is_not_nil(anim)
			assert.are.equal("power_row", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for tripwire_row", function()
			local anim = GameAnimations.createPowerAnimation(piece, "tripwire_row")
			assert.is_not_nil(anim)
			assert.are.equal("power_row", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for inhibit_row", function()
			local anim = GameAnimations.createPowerAnimation(piece, "inhibit_row")
			assert.is_not_nil(anim)
			assert.are.equal("power_row", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for parasite_row", function()
			local anim = GameAnimations.createPowerAnimation(piece, "parasite_row")
			assert.is_not_nil(anim)
			assert.are.equal("power_row", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for purify_row", function()
			local anim = GameAnimations.createPowerAnimation(piece, "purify_row")
			assert.is_not_nil(anim)
			assert.are.equal("power_row", anim.type)
			assert.is_true(anim.blocking)
		end)
	end)

	describe("createPowerAnimation - column-targeting powers", function()
		local piece

		setup(function()
			piece = { row = 5, col = 5, player = 1, powers = {} }
		end)

		it("creates animation for destroy_column", function()
			local anim = GameAnimations.createPowerAnimation(piece, "destroy_column")
			assert.is_not_nil(anim)
			assert.are.equal("destroy_column", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for kamikaze_column", function()
			local anim = GameAnimations.createPowerAnimation(piece, "kamikaze_column")
			assert.is_not_nil(anim)
			assert.are.equal("power_column", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for recruit_column", function()
			local anim = GameAnimations.createPowerAnimation(piece, "recruit_column")
			assert.is_not_nil(anim)
			assert.are.equal("power_column", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for acidic_column", function()
			local anim = GameAnimations.createPowerAnimation(piece, "acidic_column")
			assert.is_not_nil(anim)
			assert.are.equal("power_column", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for scramble_column", function()
			local anim = GameAnimations.createPowerAnimation(piece, "scramble_column")
			assert.is_not_nil(anim)
			assert.are.equal("power_column", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for trench_column", function()
			local anim = GameAnimations.createPowerAnimation(piece, "trench_column")
			assert.is_not_nil(anim)
			assert.are.equal("power_column", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for wall_column", function()
			local anim = GameAnimations.createPowerAnimation(piece, "wall_column")
			assert.is_not_nil(anim)
			assert.are.equal("power_column", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for invert_column", function()
			local anim = GameAnimations.createPowerAnimation(piece, "invert_column")
			assert.is_not_nil(anim)
			assert.are.equal("power_column", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for dredge_column", function()
			local anim = GameAnimations.createPowerAnimation(piece, "dredge_column")
			assert.is_not_nil(anim)
			assert.are.equal("power_column", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for teach_column", function()
			local anim = GameAnimations.createPowerAnimation(piece, "teach_column")
			assert.is_not_nil(anim)
			assert.are.equal("power_column", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for learn_column", function()
			local anim = GameAnimations.createPowerAnimation(piece, "learn_column")
			assert.is_not_nil(anim)
			assert.are.equal("power_column", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for pilfer_column", function()
			local anim = GameAnimations.createPowerAnimation(piece, "pilfer_column")
			assert.is_not_nil(anim)
			assert.are.equal("power_column", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for spyware_column", function()
			local anim = GameAnimations.createPowerAnimation(piece, "spyware_column")
			assert.is_not_nil(anim)
			assert.are.equal("power_column", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for orb_spy_column", function()
			local anim = GameAnimations.createPowerAnimation(piece, "orb_spy_column")
			assert.is_not_nil(anim)
			assert.are.equal("power_column", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for refurb_column", function()
			local anim = GameAnimations.createPowerAnimation(piece, "refurb_column")
			assert.is_not_nil(anim)
			assert.are.equal("power_column", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for bankrupt_column", function()
			local anim = GameAnimations.createPowerAnimation(piece, "bankrupt_column")
			assert.is_not_nil(anim)
			assert.are.equal("power_column", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for tripwire_column", function()
			local anim = GameAnimations.createPowerAnimation(piece, "tripwire_column")
			assert.is_not_nil(anim)
			assert.are.equal("power_column", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for inhibit_column", function()
			local anim = GameAnimations.createPowerAnimation(piece, "inhibit_column")
			assert.is_not_nil(anim)
			assert.are.equal("power_column", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for parasite_column", function()
			local anim = GameAnimations.createPowerAnimation(piece, "parasite_column")
			assert.is_not_nil(anim)
			assert.are.equal("power_column", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for purify_column", function()
			local anim = GameAnimations.createPowerAnimation(piece, "purify_column")
			assert.is_not_nil(anim)
			assert.are.equal("power_column", anim.type)
			assert.is_true(anim.blocking)
		end)
	end)

	describe("createPowerAnimation - radial-targeting powers", function()
		local piece

		setup(function()
			piece = { row = 5, col = 5, player = 1, powers = {} }
		end)

		it("creates animation for bomb", function()
			local anim = GameAnimations.createPowerAnimation(piece, "bomb")
			assert.is_not_nil(anim)
			assert.are.equal("bomb", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for destroy_radial", function()
			local anim = GameAnimations.createPowerAnimation(piece, "destroy_radial")
			assert.is_not_nil(anim)
			assert.are.equal("power_radial", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for kamikaze_radial", function()
			local anim = GameAnimations.createPowerAnimation(piece, "kamikaze_radial")
			assert.is_not_nil(anim)
			assert.are.equal("power_radial", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for scramble_radial", function()
			local anim = GameAnimations.createPowerAnimation(piece, "scramble_radial")
			assert.is_not_nil(anim)
			assert.are.equal("power_radial", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for smart_bombs", function()
			local anim = GameAnimations.createPowerAnimation(piece, "smart_bombs")
			assert.is_not_nil(anim)
			assert.are.equal("power_radial", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for acidic_radial", function()
			local anim = GameAnimations.createPowerAnimation(piece, "acidic_radial")
			assert.is_not_nil(anim)
			assert.are.equal("power_radial", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for plateau", function()
			local anim = GameAnimations.createPowerAnimation(piece, "plateau")
			assert.is_not_nil(anim)
			assert.are.equal("power_radial", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for moat", function()
			local anim = GameAnimations.createPowerAnimation(piece, "moat")
			assert.is_not_nil(anim)
			assert.are.equal("power_radial", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for invert_radial", function()
			local anim = GameAnimations.createPowerAnimation(piece, "invert_radial")
			assert.is_not_nil(anim)
			assert.are.equal("power_radial", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for dredge_radial", function()
			local anim = GameAnimations.createPowerAnimation(piece, "dredge_radial")
			assert.is_not_nil(anim)
			assert.are.equal("power_radial", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for teach_radial", function()
			local anim = GameAnimations.createPowerAnimation(piece, "teach_radial")
			assert.is_not_nil(anim)
			assert.are.equal("power_radial", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for learn_radial", function()
			local anim = GameAnimations.createPowerAnimation(piece, "learn_radial")
			assert.is_not_nil(anim)
			assert.are.equal("power_radial", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for pilfer_radial", function()
			local anim = GameAnimations.createPowerAnimation(piece, "pilfer_radial")
			assert.is_not_nil(anim)
			assert.are.equal("power_radial", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for spyware_radial", function()
			local anim = GameAnimations.createPowerAnimation(piece, "spyware_radial")
			assert.is_not_nil(anim)
			assert.are.equal("power_radial", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for orb_spy_radial", function()
			local anim = GameAnimations.createPowerAnimation(piece, "orb_spy_radial")
			assert.is_not_nil(anim)
			assert.are.equal("power_radial", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for refurb_radial", function()
			local anim = GameAnimations.createPowerAnimation(piece, "refurb_radial")
			assert.is_not_nil(anim)
			assert.are.equal("power_radial", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for bankrupt_radial", function()
			local anim = GameAnimations.createPowerAnimation(piece, "bankrupt_radial")
			assert.is_not_nil(anim)
			assert.are.equal("power_radial", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for tripwire_radial", function()
			local anim = GameAnimations.createPowerAnimation(piece, "tripwire_radial")
			assert.is_not_nil(anim)
			assert.are.equal("power_radial", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for inhibit_radial", function()
			local anim = GameAnimations.createPowerAnimation(piece, "inhibit_radial")
			assert.is_not_nil(anim)
			assert.are.equal("power_radial", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for parasite_radial", function()
			local anim = GameAnimations.createPowerAnimation(piece, "parasite_radial")
			assert.is_not_nil(anim)
			assert.are.equal("power_radial", anim.type)
			assert.is_true(anim.blocking)
		end)

		it("creates animation for purify_radial", function()
			local anim = GameAnimations.createPowerAnimation(piece, "purify_radial")
			assert.is_not_nil(anim)
			assert.are.equal("power_radial", anim.type)
			assert.is_true(anim.blocking)
		end)
	end)
end)
