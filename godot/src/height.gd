## height.gd — Terrain height rules, ported from web/src/core/height.ts.
##
## Heights range 0..4. A piece may drop any number of levels but may climb
## at most 1 level per move. Coordinate convention: 1-indexed row/col, so
## height_map[row-1][col-1].
##
## Usage:
##   var hm = Height.create_height_map(8, 10, 0)
##   var h  = Height.get_height(hm, row, col)
##   if Height.can_climb(from_h, to_h): ...
extends RefCounted

const MIN_HEIGHT: int = 0
const MAX_HEIGHT: int = 4
const MAX_CLIMB: int = 1


## Returns a rows×cols 2D array (Array of Array[int]) filled with `fill`.
static func create_height_map(rows: int, cols: int, fill: int = 0) -> Array:
	var hm: Array = []
	for _r in range(rows):
		var row_arr: Array = []
		row_arr.resize(cols)
		row_arr.fill(fill)
		hm.append(row_arr)
	return hm


## Returns the height at (row, col) using 1-indexed coords. Returns 0 for OOB.
static func get_height(height_map: Array, row: int, col: int) -> int:
	var r := row - 1
	var c := col - 1
	if r < 0 or r >= height_map.size():
		return 0
	var row_arr: Array = height_map[r]
	if c < 0 or c >= row_arr.size():
		return 0
	return int(row_arr[c])


## Returns true if a piece at `from_h` height may move to a tile at `to_h`.
## Dropping any number of levels is allowed; climbing is capped at MAX_CLIMB=1.
static func can_climb(from_h: int, to_h: int) -> bool:
	return to_h - from_h <= MAX_CLIMB
