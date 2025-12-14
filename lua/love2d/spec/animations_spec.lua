-- Busted tests for animations module
-- Run with: busted spec/
-- TDD: Write tests first (RED), then implement (GREEN)

describe("Animations", function()
	local Animations

	setup(function()
		Animations = require("src.shared.animations")
	end)

	-- Step 1: Animation Foundation
	describe("createAnimation", function()
		it("returns a table with required fields", function()
			local anim = Animations.createAnimation("test", 0.5)
			assert.is_table(anim)
			assert.are.equal("test", anim.type)
			assert.are.equal(0.5, anim.duration)
			assert.are.equal(0, anim.elapsed)
		end)

		it("accepts optional data parameter", function()
			local data = { row = 3, col = 5 }
			local anim = Animations.createAnimation("test", 0.5, data)
			assert.are.equal(3, anim.data.row)
			assert.are.equal(5, anim.data.col)
		end)

		it("accepts optional blocking parameter", function()
			local anim = Animations.createAnimation("test", 0.5, {}, true)
			assert.is_true(anim.blocking)
		end)

		it("defaults blocking to false", function()
			local anim = Animations.createAnimation("test", 0.5)
			assert.is_false(anim.blocking)
		end)

		it("accepts optional onComplete callback", function()
			local called = false
			local callback = function()
				called = true
			end
			local anim = Animations.createAnimation("test", 0.5, {}, false, callback)
			assert.is_function(anim.onComplete)
		end)
	end)

	describe("updateAnimation", function()
		it("increases elapsed time by dt", function()
			local anim = Animations.createAnimation("test", 1.0)
			Animations.updateAnimation(anim, 0.1)
			assert.are.equal(0.1, anim.elapsed)
		end)

		it("accumulates elapsed time across multiple updates", function()
			local anim = Animations.createAnimation("test", 1.0)
			Animations.updateAnimation(anim, 0.1)
			Animations.updateAnimation(anim, 0.2)
			Animations.updateAnimation(anim, 0.15)
			assert.is_true(math.abs(anim.elapsed - 0.45) < 0.001)
		end)

		it("does not exceed duration", function()
			local anim = Animations.createAnimation("test", 0.5)
			Animations.updateAnimation(anim, 1.0)
			assert.are.equal(0.5, anim.elapsed)
		end)
	end)

	describe("getProgress", function()
		it("returns 0 at start", function()
			local anim = Animations.createAnimation("test", 1.0)
			assert.are.equal(0, Animations.getProgress(anim))
		end)

		it("returns 0.5 at halfway", function()
			local anim = Animations.createAnimation("test", 1.0)
			anim.elapsed = 0.5
			assert.are.equal(0.5, Animations.getProgress(anim))
		end)

		it("returns 1 at completion", function()
			local anim = Animations.createAnimation("test", 1.0)
			anim.elapsed = 1.0
			assert.are.equal(1, Animations.getProgress(anim))
		end)

		it("clamps to 1 if elapsed exceeds duration", function()
			local anim = Animations.createAnimation("test", 0.5)
			anim.elapsed = 0.8
			assert.are.equal(1, Animations.getProgress(anim))
		end)

		it("handles zero duration gracefully", function()
			local anim = Animations.createAnimation("test", 0)
			assert.are.equal(1, Animations.getProgress(anim))
		end)
	end)

	describe("isComplete", function()
		it("returns false when elapsed < duration", function()
			local anim = Animations.createAnimation("test", 1.0)
			anim.elapsed = 0.5
			assert.is_false(Animations.isComplete(anim))
		end)

		it("returns true when elapsed >= duration", function()
			local anim = Animations.createAnimation("test", 1.0)
			anim.elapsed = 1.0
			assert.is_true(Animations.isComplete(anim))
		end)

		it("returns true when elapsed exceeds duration", function()
			local anim = Animations.createAnimation("test", 0.5)
			anim.elapsed = 0.8
			assert.is_true(Animations.isComplete(anim))
		end)
	end)

	describe("ease", function()
		describe("linear", function()
			it("returns input unchanged", function()
				assert.are.equal(0, Animations.ease.linear(0))
				assert.are.equal(0.5, Animations.ease.linear(0.5))
				assert.are.equal(1, Animations.ease.linear(1))
			end)
		end)

		describe("easeOutQuad", function()
			it("returns 0 at t=0", function()
				assert.are.equal(0, Animations.ease.easeOutQuad(0))
			end)

			it("returns 1 at t=1", function()
				assert.are.equal(1, Animations.ease.easeOutQuad(1))
			end)

			it("returns value > t for 0 < t < 1 (decelerating)", function()
				local t = 0.5
				local eased = Animations.ease.easeOutQuad(t)
				assert.is_true(eased > t)
			end)

			it("follows formula 1 - (1-t)^2", function()
				local t = 0.3
				local expected = 1 - (1 - t) * (1 - t)
				assert.is_true(math.abs(Animations.ease.easeOutQuad(t) - expected) < 0.001)
			end)
		end)

		describe("easeInOutCubic", function()
			it("returns 0 at t=0", function()
				assert.are.equal(0, Animations.ease.easeInOutCubic(0))
			end)

			it("returns 1 at t=1", function()
				assert.are.equal(1, Animations.ease.easeInOutCubic(1))
			end)

			it("returns 0.5 at t=0.5", function()
				assert.are.equal(0.5, Animations.ease.easeInOutCubic(0.5))
			end)

			it("accelerates in first half (value < t)", function()
				local t = 0.25
				local eased = Animations.ease.easeInOutCubic(t)
				assert.is_true(eased < t)
			end)

			it("decelerates in second half (value > t)", function()
				local t = 0.75
				local eased = Animations.ease.easeInOutCubic(t)
				assert.is_true(eased > t)
			end)
		end)

		describe("easeOutElastic", function()
			it("returns 0 at t=0", function()
				assert.are.equal(0, Animations.ease.easeOutElastic(0))
			end)

			it("returns 1 at t=1", function()
				assert.are.equal(1, Animations.ease.easeOutElastic(1))
			end)

			it("overshoots past 1 during animation (bounce effect)", function()
				-- Elastic easing should overshoot
				local hasOvershoot = false
				for i = 1, 9 do
					local t = i / 10
					local eased = Animations.ease.easeOutElastic(t)
					if eased > 1.0 then
						hasOvershoot = true
						break
					end
				end
				assert.is_true(hasOvershoot)
			end)
		end)

		describe("easeOutBack", function()
			it("returns 0 at t=0", function()
				assert.are.equal(0, Animations.ease.easeOutBack(0))
			end)

			it("returns 1 at t=1", function()
				assert.is_true(math.abs(Animations.ease.easeOutBack(1) - 1) < 0.001)
			end)

			it("overshoots slightly before settling", function()
				-- easeOutBack overshoots around t=0.7-0.9
				local t = 0.7
				local eased = Animations.ease.easeOutBack(t)
				assert.is_true(eased > 1.0)
			end)
		end)
	end)

	-- Step 2: Animation Queue System
	describe("AnimationQueue", function()
		describe("create", function()
			it("returns empty queue table", function()
				local queue = Animations.AnimationQueue.create()
				assert.is_table(queue)
				assert.are.equal(0, #queue.animations)
			end)
		end)

		describe("add", function()
			it("adds animation to queue", function()
				local queue = Animations.AnimationQueue.create()
				local anim = Animations.createAnimation("test", 0.5)
				Animations.AnimationQueue.add(queue, anim)
				assert.are.equal(1, #queue.animations)
			end)

			it("adds multiple animations", function()
				local queue = Animations.AnimationQueue.create()
				Animations.AnimationQueue.add(queue, Animations.createAnimation("a", 0.5))
				Animations.AnimationQueue.add(queue, Animations.createAnimation("b", 0.5))
				Animations.AnimationQueue.add(queue, Animations.createAnimation("c", 0.5))
				assert.are.equal(3, #queue.animations)
			end)
		end)

		describe("update", function()
			it("updates all animations by dt", function()
				local queue = Animations.AnimationQueue.create()
				local anim1 = Animations.createAnimation("a", 1.0)
				local anim2 = Animations.createAnimation("b", 1.0)
				Animations.AnimationQueue.add(queue, anim1)
				Animations.AnimationQueue.add(queue, anim2)

				Animations.AnimationQueue.update(queue, 0.3)

				assert.are.equal(0.3, anim1.elapsed)
				assert.are.equal(0.3, anim2.elapsed)
			end)

			it("removes completed animations", function()
				local queue = Animations.AnimationQueue.create()
				local anim1 = Animations.createAnimation("short", 0.2)
				local anim2 = Animations.createAnimation("long", 1.0)
				Animations.AnimationQueue.add(queue, anim1)
				Animations.AnimationQueue.add(queue, anim2)

				Animations.AnimationQueue.update(queue, 0.5)

				assert.are.equal(1, #queue.animations)
				assert.are.equal("long", queue.animations[1].type)
			end)

			it("fires onComplete callback when animation completes", function()
				local callbackFired = false
				local queue = Animations.AnimationQueue.create()
				local anim = Animations.createAnimation("test", 0.2, {}, false, function()
					callbackFired = true
				end)
				Animations.AnimationQueue.add(queue, anim)

				Animations.AnimationQueue.update(queue, 0.3)

				assert.is_true(callbackFired)
			end)

			it("fires onComplete only once", function()
				local callCount = 0
				local queue = Animations.AnimationQueue.create()
				local anim = Animations.createAnimation("test", 0.2, {}, false, function()
					callCount = callCount + 1
				end)
				Animations.AnimationQueue.add(queue, anim)

				Animations.AnimationQueue.update(queue, 0.3)
				Animations.AnimationQueue.update(queue, 0.3)

				assert.are.equal(1, callCount)
			end)
		end)

		describe("getActive", function()
			it("returns all active animations", function()
				local queue = Animations.AnimationQueue.create()
				Animations.AnimationQueue.add(queue, Animations.createAnimation("a", 0.5))
				Animations.AnimationQueue.add(queue, Animations.createAnimation("b", 0.5))

				local active = Animations.AnimationQueue.getActive(queue)
				assert.are.equal(2, #active)
			end)

			it("returns empty table when no animations", function()
				local queue = Animations.AnimationQueue.create()
				local active = Animations.AnimationQueue.getActive(queue)
				assert.are.equal(0, #active)
			end)
		end)

		describe("isBlocking", function()
			it("returns false when no animations", function()
				local queue = Animations.AnimationQueue.create()
				assert.is_false(Animations.AnimationQueue.isBlocking(queue))
			end)

			it("returns false when only non-blocking animations", function()
				local queue = Animations.AnimationQueue.create()
				Animations.AnimationQueue.add(queue, Animations.createAnimation("a", 0.5, {}, false))
				Animations.AnimationQueue.add(queue, Animations.createAnimation("b", 0.5, {}, false))
				assert.is_false(Animations.AnimationQueue.isBlocking(queue))
			end)

			it("returns true when any blocking animation present", function()
				local queue = Animations.AnimationQueue.create()
				Animations.AnimationQueue.add(queue, Animations.createAnimation("a", 0.5, {}, false))
				Animations.AnimationQueue.add(queue, Animations.createAnimation("b", 0.5, {}, true))
				assert.is_true(Animations.AnimationQueue.isBlocking(queue))
			end)
		end)

		describe("clear", function()
			it("removes all animations", function()
				local queue = Animations.AnimationQueue.create()
				Animations.AnimationQueue.add(queue, Animations.createAnimation("a", 0.5))
				Animations.AnimationQueue.add(queue, Animations.createAnimation("b", 0.5))

				Animations.AnimationQueue.clear(queue)

				assert.are.equal(0, #queue.animations)
			end)

			it("does not fire onComplete callbacks", function()
				local callbackFired = false
				local queue = Animations.AnimationQueue.create()
				local anim = Animations.createAnimation("test", 0.5, {}, false, function()
					callbackFired = true
				end)
				Animations.AnimationQueue.add(queue, anim)

				Animations.AnimationQueue.clear(queue)

				assert.is_false(callbackFired)
			end)
		end)

		describe("hasAnimations", function()
			it("returns false when empty", function()
				local queue = Animations.AnimationQueue.create()
				assert.is_false(Animations.AnimationQueue.hasAnimations(queue))
			end)

			it("returns true when animations present", function()
				local queue = Animations.AnimationQueue.create()
				Animations.AnimationQueue.add(queue, Animations.createAnimation("a", 0.5))
				assert.is_true(Animations.AnimationQueue.hasAnimations(queue))
			end)
		end)
	end)

	-- Step 3: Animation Type Definitions (Factory Functions)
	describe("Animation Factories", function()
		describe("createDestroyRow", function()
			it("returns animation with type 'destroy_row'", function()
				local anim = Animations.createDestroyRow(3, 5)
				assert.are.equal("destroy_row", anim.type)
			end)

			it("stores row and origin column in data", function()
				local anim = Animations.createDestroyRow(3, 5)
				assert.are.equal(3, anim.data.row)
				assert.are.equal(5, anim.data.originCol)
			end)

			it("is blocking", function()
				local anim = Animations.createDestroyRow(3, 5)
				assert.is_true(anim.blocking)
			end)

			it("has appropriate duration", function()
				local anim = Animations.createDestroyRow(3, 5)
				assert.is_true(anim.duration >= 0.6)
			end)
		end)

		describe("createDestroyColumn", function()
			it("returns animation with type 'destroy_column'", function()
				local anim = Animations.createDestroyColumn(5, 3)
				assert.are.equal("destroy_column", anim.type)
			end)

			it("stores column and origin row in data", function()
				local anim = Animations.createDestroyColumn(5, 3)
				assert.are.equal(5, anim.data.col)
				assert.are.equal(3, anim.data.originRow)
			end)

			it("is blocking", function()
				local anim = Animations.createDestroyColumn(5, 3)
				assert.is_true(anim.blocking)
			end)
		end)

		describe("createBomb", function()
			it("returns animation with type 'bomb'", function()
				local anim = Animations.createBomb(4, 5)
				assert.are.equal("bomb", anim.type)
			end)

			it("stores center position in data", function()
				local anim = Animations.createBomb(4, 5)
				assert.are.equal(4, anim.data.row)
				assert.are.equal(5, anim.data.col)
			end)

			it("is blocking", function()
				local anim = Animations.createBomb(4, 5)
				assert.is_true(anim.blocking)
			end)

			it("has longer duration for elaborate effect", function()
				local anim = Animations.createBomb(4, 5)
				assert.is_true(anim.duration >= 0.8)
			end)
		end)

		describe("createRelocate", function()
			it("returns animation with type 'relocate'", function()
				local anim = Animations.createRelocate(2, 3, 6, 8)
				assert.are.equal("relocate", anim.type)
			end)

			it("stores from and to positions", function()
				local anim = Animations.createRelocate(2, 3, 6, 8)
				assert.are.equal(2, anim.data.fromRow)
				assert.are.equal(3, anim.data.fromCol)
				assert.are.equal(6, anim.data.toRow)
				assert.are.equal(8, anim.data.toCol)
			end)

			it("is blocking", function()
				local anim = Animations.createRelocate(2, 3, 6, 8)
				assert.is_true(anim.blocking)
			end)
		end)

		describe("createRaiseTile", function()
			it("returns animation with type 'raise_tile'", function()
				local anim = Animations.createRaiseTile(3, 5, 1, 2)
				assert.are.equal("raise_tile", anim.type)
			end)

			it("stores position and height change", function()
				local anim = Animations.createRaiseTile(3, 5, 1, 2)
				assert.are.equal(3, anim.data.row)
				assert.are.equal(5, anim.data.col)
				assert.are.equal(1, anim.data.fromHeight)
				assert.are.equal(2, anim.data.toHeight)
			end)

			it("is blocking", function()
				local anim = Animations.createRaiseTile(3, 5, 1, 2)
				assert.is_true(anim.blocking)
			end)
		end)

		describe("createLowerTile", function()
			it("returns animation with type 'lower_tile'", function()
				local anim = Animations.createLowerTile(3, 5, 2, 1)
				assert.are.equal("lower_tile", anim.type)
			end)

			it("stores position and height change", function()
				local anim = Animations.createLowerTile(3, 5, 2, 1)
				assert.are.equal(3, anim.data.row)
				assert.are.equal(5, anim.data.col)
				assert.are.equal(2, anim.data.fromHeight)
				assert.are.equal(1, anim.data.toHeight)
			end)
		end)

		describe("createRecruit", function()
			it("returns animation with type 'recruit'", function()
				local anim = Animations.createRecruit(4, 5, 2, 1)
				assert.are.equal("recruit", anim.type)
			end)

			it("stores position and player change", function()
				local anim = Animations.createRecruit(4, 5, 2, 1)
				assert.are.equal(4, anim.data.row)
				assert.are.equal(5, anim.data.col)
				assert.are.equal(2, anim.data.fromPlayer)
				assert.are.equal(1, anim.data.toPlayer)
			end)

			it("is blocking", function()
				local anim = Animations.createRecruit(4, 5, 2, 1)
				assert.is_true(anim.blocking)
			end)
		end)

		describe("createMultiply", function()
			it("returns animation with type 'multiply'", function()
				local anim = Animations.createMultiply(3, 4, 4, 4)
				assert.are.equal("multiply", anim.type)
			end)

			it("stores origin and target positions", function()
				local anim = Animations.createMultiply(3, 4, 4, 4)
				assert.are.equal(3, anim.data.originRow)
				assert.are.equal(4, anim.data.originCol)
				assert.are.equal(4, anim.data.targetRow)
				assert.are.equal(4, anim.data.targetCol)
			end)

			it("is blocking", function()
				local anim = Animations.createMultiply(3, 4, 4, 4)
				assert.is_true(anim.blocking)
			end)
		end)

		describe("createMoveDiagonal", function()
			it("returns animation with type 'move_diagonal'", function()
				local anim = Animations.createMoveDiagonal(3, 5)
				assert.are.equal("move_diagonal", anim.type)
			end)

			it("stores position", function()
				local anim = Animations.createMoveDiagonal(3, 5)
				assert.are.equal(3, anim.data.row)
				assert.are.equal(5, anim.data.col)
			end)

			it("is NOT blocking (passive power)", function()
				local anim = Animations.createMoveDiagonal(3, 5)
				assert.is_false(anim.blocking)
			end)
		end)

		describe("createJumpProof", function()
			it("returns animation with type 'jump_proof'", function()
				local anim = Animations.createJumpProof(3, 5)
				assert.are.equal("jump_proof", anim.type)
			end)

			it("stores position", function()
				local anim = Animations.createJumpProof(3, 5)
				assert.are.equal(3, anim.data.row)
				assert.are.equal(5, anim.data.col)
			end)

			it("is NOT blocking (passive power)", function()
				local anim = Animations.createJumpProof(3, 5)
				assert.is_false(anim.blocking)
			end)
		end)

		describe("createInvisible", function()
			it("returns animation with type 'invisible'", function()
				local anim = Animations.createInvisible(3, 5)
				assert.are.equal("invisible", anim.type)
			end)

			it("stores position", function()
				local anim = Animations.createInvisible(3, 5)
				assert.are.equal(3, anim.data.row)
				assert.are.equal(5, anim.data.col)
			end)

			it("is NOT blocking (passive power)", function()
				local anim = Animations.createInvisible(3, 5)
				assert.is_false(anim.blocking)
			end)
		end)

		describe("createMoveAgain", function()
			it("returns animation with type 'move_again'", function()
				local anim = Animations.createMoveAgain(3, 5)
				assert.are.equal("move_again", anim.type)
			end)

			it("stores position", function()
				local anim = Animations.createMoveAgain(3, 5)
				assert.are.equal(3, anim.data.row)
				assert.are.equal(5, anim.data.col)
			end)

			it("is NOT blocking (quick effect)", function()
				local anim = Animations.createMoveAgain(3, 5)
				assert.is_false(anim.blocking)
			end)
		end)
	end)

	-- Step 4: Animation Interpolation Helpers
	describe("Interpolation Helpers", function()
		describe("getDestroyRowWavePosition", function()
			it("returns 0 at progress 0", function()
				local anim = Animations.createDestroyRow(3, 5)
				local pos = Animations.getDestroyRowWavePosition(anim, 0)
				assert.are.equal(0, pos)
			end)

			it("returns 1 at progress 1", function()
				local anim = Animations.createDestroyRow(3, 5)
				local pos = Animations.getDestroyRowWavePosition(anim, 1)
				assert.are.equal(1, pos)
			end)

			it("returns value between 0 and 1 at mid-progress", function()
				local anim = Animations.createDestroyRow(3, 5)
				local pos = Animations.getDestroyRowWavePosition(anim, 0.5)
				assert.is_true(pos > 0 and pos < 1)
			end)
		end)

		describe("getBombRadius", function()
			it("returns 0 at progress 0", function()
				local anim = Animations.createBomb(4, 5)
				local radius = Animations.getBombRadius(anim, 0)
				assert.are.equal(0, radius)
			end)

			it("returns max radius at progress 0.5 (peak expansion)", function()
				local anim = Animations.createBomb(4, 5)
				local radius = Animations.getBombRadius(anim, 0.5)
				assert.is_true(radius > 0)
			end)

			it("returns smaller radius at progress 1 (implosion)", function()
				local anim = Animations.createBomb(4, 5)
				local peakRadius = Animations.getBombRadius(anim, 0.5)
				local endRadius = Animations.getBombRadius(anim, 1)
				assert.is_true(endRadius < peakRadius)
			end)
		end)

		describe("getRelocateFadeAlpha", function()
			it("returns 1 at progress 0 (fully visible)", function()
				local anim = Animations.createRelocate(2, 3, 6, 8)
				local alpha = Animations.getRelocateFadeAlpha(anim, 0)
				assert.are.equal(1, alpha)
			end)

			it("returns 0 at progress 0.5 (fully faded)", function()
				local anim = Animations.createRelocate(2, 3, 6, 8)
				local alpha = Animations.getRelocateFadeAlpha(anim, 0.5)
				assert.are.equal(0, alpha)
			end)

			it("returns 1 at progress 1 (fully visible again)", function()
				local anim = Animations.createRelocate(2, 3, 6, 8)
				local alpha = Animations.getRelocateFadeAlpha(anim, 1)
				assert.are.equal(1, alpha)
			end)

			it("fades out in first half", function()
				local anim = Animations.createRelocate(2, 3, 6, 8)
				local alpha = Animations.getRelocateFadeAlpha(anim, 0.25)
				assert.is_true(alpha > 0 and alpha < 1)
			end)
		end)

		describe("getRelocatePosition", function()
			it("returns from position at progress 0", function()
				local anim = Animations.createRelocate(2, 3, 6, 8)
				local row, col = Animations.getRelocatePosition(anim, 0)
				assert.are.equal(2, row)
				assert.are.equal(3, col)
			end)

			it("returns to position at progress 1", function()
				local anim = Animations.createRelocate(2, 3, 6, 8)
				local row, col = Animations.getRelocatePosition(anim, 1)
				assert.are.equal(6, row)
				assert.are.equal(8, col)
			end)

			it("returns from position in first half (before teleport)", function()
				local anim = Animations.createRelocate(2, 3, 6, 8)
				local row, col = Animations.getRelocatePosition(anim, 0.4)
				assert.are.equal(2, row)
				assert.are.equal(3, col)
			end)

			it("returns to position in second half (after teleport)", function()
				local anim = Animations.createRelocate(2, 3, 6, 8)
				local row, col = Animations.getRelocatePosition(anim, 0.6)
				assert.are.equal(6, row)
				assert.are.equal(8, col)
			end)
		end)

		describe("getTileHeightOffset", function()
			it("returns fromHeight at progress 0", function()
				local anim = Animations.createRaiseTile(3, 5, 1, 3)
				local height = Animations.getTileHeightOffset(anim, 0)
				assert.are.equal(1, height)
			end)

			it("returns toHeight at progress 1", function()
				local anim = Animations.createRaiseTile(3, 5, 1, 3)
				local height = Animations.getTileHeightOffset(anim, 1)
				assert.are.equal(3, height)
			end)

			it("returns interpolated height at mid-progress", function()
				local anim = Animations.createRaiseTile(3, 5, 0, 4)
				local height = Animations.getTileHeightOffset(anim, 0.5)
				-- With easing, mid-progress gives ~75% of the way
				assert.is_true(height > 0 and height < 4)
			end)

			it("works for lowering tiles", function()
				local anim = Animations.createLowerTile(3, 5, 4, 2)
				local height = Animations.getTileHeightOffset(anim, 0.5)
				-- With easing, mid-progress is closer to end
				assert.is_true(height > 2 and height < 4)
			end)
		end)

		describe("getRecruitColor", function()
			it("returns fromPlayer color at progress 0", function()
				local anim = Animations.createRecruit(4, 5, 2, 1)
				local r, g, b = Animations.getRecruitColor(anim, 0)
				-- Player 2 is red-ish
				assert.is_true(r > g)
			end)

			it("returns toPlayer color at progress 1", function()
				local anim = Animations.createRecruit(4, 5, 2, 1)
				local r, g, b = Animations.getRecruitColor(anim, 1)
				-- Player 1 is blue-ish
				assert.is_true(b > r)
			end)

			it("returns blended color at mid-progress", function()
				local anim = Animations.createRecruit(4, 5, 2, 1)
				local r, g, b = Animations.getRecruitColor(anim, 0.5)
				-- Should be somewhere in between
				assert.is_true(r > 0 and b > 0)
			end)
		end)

		describe("getShieldScale", function()
			it("returns 0 at progress 0", function()
				local anim = Animations.createJumpProof(3, 5)
				local scale = Animations.getShieldScale(anim, 0)
				assert.are.equal(0, scale)
			end)

			it("returns 1 at progress 1 (settled)", function()
				local anim = Animations.createJumpProof(3, 5)
				local scale = Animations.getShieldScale(anim, 1)
				assert.are.equal(1, scale)
			end)

			it("overshoots past 1 during animation (bounce effect)", function()
				local anim = Animations.createJumpProof(3, 5)
				-- Check around 70% progress where easeOutBack overshoots
				local scale = Animations.getShieldScale(anim, 0.7)
				assert.is_true(scale > 1)
			end)
		end)

		describe("getInvisibleAlpha", function()
			it("returns 1 at progress 0 (fully visible)", function()
				local anim = Animations.createInvisible(3, 5)
				local alpha = Animations.getInvisibleAlpha(anim, 0)
				assert.are.equal(1, alpha)
			end)

			it("returns 0.3 at progress 1 (semi-transparent)", function()
				local anim = Animations.createInvisible(3, 5)
				local alpha = Animations.getInvisibleAlpha(anim, 1)
				assert.is_true(math.abs(alpha - 0.3) < 0.01)
			end)

			it("fades smoothly between values", function()
				local anim = Animations.createInvisible(3, 5)
				local alpha = Animations.getInvisibleAlpha(anim, 0.5)
				assert.is_true(alpha > 0.3 and alpha < 1)
			end)
		end)
	end)
end)
