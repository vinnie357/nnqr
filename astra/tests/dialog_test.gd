extends SceneTree
## Exercise GUI routing, focus, and container geometry through a real scene tree.
var failures: Array[String]=[]

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value: failures.append(message)

func settle() -> void:
	for i in range(4): await process_frame

func key(code: Key, shift: bool=false, echo: bool=false) -> void:
	var event=InputEventKey.new()
	event.keycode=code
	event.pressed=true
	event.shift_pressed=shift
	event.echo=echo
	root.push_input(event)
	event=event.duplicate()
	event.pressed=false
	root.push_input(event)
	await settle()

func _run() -> void:
	var scene=load("res://main.tscn").instantiate()
	root.add_child(scene)
	await settle()
	var focused: Control=root.gui_get_focus_owner()
	check(focused is OptionButton,"title assigns initial focus")
	await key(KEY_ESCAPE)
	check(scene.paused,"cancel cannot bypass mode selection")
	scene._new_game("sandbox")
	var opener: Button=scene.root.find_children("*","Button",true,false)[0]
	opener.grab_focus()
	scene._help()
	await settle()
	focused=root.gui_get_focus_owner()
	check(focused is LineEdit,"manual focuses search")
	var controls: Array[Control]=scene._dialog_controls(scene.overlay_body)
	for i in range(controls.size()+2):
		await key(KEY_TAB)
		check(scene.overlay_body.is_ancestor_of(root.gui_get_focus_owner()),"Tab stays inside manual")
	await key(KEY_TAB,true)
	check(scene.overlay_body.is_ancestor_of(root.gui_get_focus_owner()),"Shift+Tab stays inside manual")
	await key(KEY_ESCAPE)
	check(not scene.paused and root.gui_get_focus_owner()==opener,"cancel restores opener focus")
	await key(KEY_ESCAPE)
	check(scene.paused,"cancel action opens pause")
	await key(KEY_ESCAPE,false,true)
	check(scene.paused,"key repeat does not dismiss pause")
	scene._dismiss()
	scene._grant_dialog()
	await settle()
	focused=root.gui_get_focus_owner()
	focused.text="move diagonal"
	focused.text_changed.emit(focused.text)
	await settle()
	controls=scene._dialog_controls(scene.overlay_body)
	check(controls.size()>=3 and controls.size()<10,"filtered power list rebuilds focus ring")
	for i in range(controls.size()+1):
		await key(KEY_TAB)
		check(scene.overlay_body.is_ancestor_of(root.gui_get_focus_owner()),"filtered power list keeps modal focus")
	scene._dismiss()
	scene._report_dialog()
	await settle()
	check(root.gui_get_focus_owner() is TextEdit,"report focuses editable feedback")
	await key(KEY_ESCAPE)
	check(not scene.paused,"cancel exits focused feedback editor")
	var cancel=InputEventAction.new()
	cancel.action="ui_cancel"
	cancel.pressed=true
	root.push_input(cancel)
	await settle()
	check(scene.paused,"non-keyboard cancel action opens pause")
	scene._dismiss()
	# Test the actual layout after an OS-style resize at two UI scales.
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	for scale in [1.0,1.3]:
		root.content_scale_factor=scale
		root.size=Vector2i(800,600)
		for open_dialog in [scene._help,scene._report_dialog,scene._grant_dialog,scene._pause,scene._title]:
			open_dialog.call()
			await settle()
			var bounds: Rect2=scene.overlay.get_global_rect()
			check(bounds.position.x>=0 and bounds.end.x<=scene.root.size.x+1,"%s fits narrow width at scale %s" % [scene.dialog_heading.text,scale])
			check(bounds.position.y>=0 and bounds.end.y<=scene.root.size.y+1,"%s fits short height at scale %s" % [scene.dialog_heading.text,scale])
			if scene.dialog_heading.text=="FIELD MANUAL":
				check(scene.dialog_scroll.get_v_scroll_bar().max_value>scene.dialog_scroll.size.y,"long manual scrolls")
			scene._dismiss()
	scene._new_game("hotseat")
	scene._tile_clicked(1,4)
	scene._tile_clicked(2,4)
	await settle()
	await key(KEY_ESCAPE)
	check(scene.handing_off and scene.paused,"cancel cannot reveal hotseat board")
	check(scene.root.get_node("Shield").color.a==1.0,"handoff stays opaque")
	for failure in failures: printerr(failure)
	print("Astra dialog focus/layout: %d failures" % failures.size())
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
