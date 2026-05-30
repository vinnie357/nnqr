## main.gd — entry point for the NNQR Godot skeleton.
## Launches ScenarioRunner which handles CLI args, renders the board,
## saves QA artifacts (.qa/frame.png + .qa/state.json), then quits.
## With no --scenario arg the initial 10x8 board is displayed interactively.
extends Node

func _ready() -> void:
	pass  # ScenarioRunner node (child of root) handles all logic in its _ready().
