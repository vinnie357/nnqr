## rng.gd — Seeded RNG (mulberry32), ported from web/src/core/rng.ts.
##
## GDScript note: ints are 64-bit signed. To replicate JS uint32 semantics we
## mask every arithmetic step with & 0xFFFFFFFF. In-Godot determinism is
## guaranteed for a given seed; exact byte-match to the JS output is NOT
## required (JS uses imul/|0 that are 32-bit; GDScript arithmetic is 64-bit).
##
## Usage:
##   var rng = RNG.new(seed)
##   var f = rng.next()        # float in [0, 1)
##   var i = rng.int(0, 9)     # int in [0..9] inclusive
##   var v = rng.pick(arr)     # random element, null if empty
extends RefCounted

var _s: int  ## Internal 32-bit state (always masked to uint32).


func _init(seed: int) -> void:
	_s = seed & 0xFFFFFFFF


## Returns next float in [0, 1). Advances the RNG state.
func next() -> float:
	# mulberry32 — same algorithm as rng.ts; all steps masked to uint32.
	_s = (_s + 0x6D2B79F5) & 0xFFFFFFFF
	var t: int = (_s ^ (_s >> 15)) & 0xFFFFFFFF
	t = (t * (1 | _s)) & 0xFFFFFFFF
	var u: int = (t ^ (t >> 7)) & 0xFFFFFFFF
	t = (t + u * (61 | t)) & 0xFFFFFFFF
	t = (t ^ (t >> 14)) & 0xFFFFFFFF
	return float(t) / 4294967296.0


## Returns a random integer in [min_val, max_val] inclusive.
func int(min_val: int, max_val: int) -> int:
	return min_val + floori(next() * (max_val - min_val + 1))


## Returns a uniformly random element from arr, or null if arr is empty.
func pick(arr: Array):
	if arr.size() == 0:
		return null
	return arr[floori(next() * arr.size())]
