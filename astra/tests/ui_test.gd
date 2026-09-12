extends SceneTree
## Headless controller and camera integration; screenshot acceptance is a separate rendered run.
var failures: Array[String]=[]
func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value: failures.append(message)

func _run() -> void:
	var scene=load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._new_game("hotseat")
	check(scene.state.pieces.size()==40,"new game has forty pieces")
	scene._tile_clicked(1,4)
	check(scene.selected>0,"click selects own piece")
	scene._tile_clicked(2,4)
	check(scene.state.turn==1 and scene.state.active==2,"click moves and ends turn")
	check(scene.handing_off and scene.paused,"hotseat conceals next player")
	check(scene.root.get_node("Shield").color.a==1.0,"handoff shield is fully opaque")
	scene.handing_off=false
	scene._dismiss()
	scene._new_game("sandbox")
	var id=int(scene.selected)
	var p: Dictionary=scene.Rules.piece_by_id(scene.state,id)
	p.inventory["move_diagonal"]=1
	scene._arm("move_diagonal")
	check(scene.armed=="move_diagonal","inventory arms preview")
	scene._activate({})
	p=scene.Rules.piece_by_id(scene.state,id)
	check(p.flags.get("move_diagonal",false),"power preview activates actual rules")
	check(scene.state.turn==0,"power does not end turn")
	# Verify camera picking for all top faces that are actually visible to a ray.
	for angle in [0.0,PI/2,PI,3*PI/2]:
		scene.view.angle=angle
		scene.view._update_camera()
		for cell in [Vector2i(0,0),Vector2i(0,9),Vector2i(7,0),Vector2i(7,9),Vector2i(3,3)]:
			var pos: Vector3=scene.view.cell_position(cell.x,cell.y)+Vector3(0,0.055,0)
			var screen: Vector2=scene.view.camera.unproject_position(pos)
			check(scene.view.pick(screen)==cell,"camera picks %s at angle %s" % [cell,angle])
	scene.mode="ai"
	scene.state.active=2
	scene.thinking=false
	scene.selected=-1
	scene._tile_clicked(6,0)
	check(scene.selected==-1,"human input rejected between AI actions")
	scene.mode="sandbox"
	scene.state.active=1
	scene._help()
	check(scene.paused,"help pauses input")
	scene._dismiss()
	scene._pause()
	check(scene.paused,"pause dialog opens")
	scene._dismiss()
	scene._act({"type":"resign"})
	check(scene.state.status=="won" and scene.paused,"resignation opens result")
	for failure in failures: printerr(failure)
	print("Astra controller/camera integration: %d failures" % failures.size())
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
