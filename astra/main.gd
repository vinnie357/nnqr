extends Node
## Astra's local game controller. Authoritative state only changes through Rules.
const Rules = preload("res://src/core/rules.gd")
const Powers = preload("res://src/core/powers.gd")
const AI = preload("res://src/core/ai.gd")
const BoardView = preload("res://src/view/board_view.gd")
const Diagnostics = preload("res://src/services/diagnostics.gd")
const BUILD = "0.1.0 • ASTRA PLAYTEST"
const INK = Color("0c121b")
const PANEL = Color("131e2a")
const TEXT = Color("e5e6dc")
const MUTED = Color("8d9fad")
const CYAN = Color("55dfed")
const AMBER = Color("ffb657")
var state: Dictionary = {}
var selected = -1
var armed = ""
var mode = "ai"
var difficulty = "medium"
var paused = true
var handing_off = false
var thinking = false
var sandbox = false
var sound_enabled = true
var reduced_motion = false
var ai_chain = 0
var last_observer = -1
var generation = 0
var diag = Diagnostics.new()
var view: Node3D
var root: Control
var board_container: SubViewportContainer
var viewport: SubViewport
var header_turn: Label
var counters: Label
var orb_counter: Label
var status_label: Label
var inspector: VBoxContainer
var log_label: RichTextLabel
var overlay: PanelContainer
var overlay_body: VBoxContainer
var feedback: TextEdit
var action_log: Array[String] = []
var hover_label: Label
var sound: AudioStreamPlayer

func _ready() -> void:
	_build_ui()
	state = Rules.new_game(int(Time.get_unix_time_from_system()) % 2147483646 + 1)
	diag.start(state)
	_refresh()
	_title()
	if "--qa" in OS.get_cmdline_user_args():
		call_deferred("_qa")

func _style(color: Color, border: Color=Color.TRANSPARENT, radius: int=12) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color=color
	style.border_color=border
	style.set_border_width_all(1 if border.a>0 else 0)
	style.set_corner_radius_all(radius)
	style.content_margin_left=18
	style.content_margin_right=18
	style.content_margin_top=12
	style.content_margin_bottom=12
	return style

func _label(text: String, size: int=16, color: Color=TEXT) -> Label:
	var label = Label.new()
	label.text=text
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	return label

func _button(text: String, callback: Callable, primary: bool=false) -> Button:
	var button = Button.new()
	button.text=text
	button.custom_minimum_size.y=42
	button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal",_style(Color("22444c") if primary else Color("1b2b39"),Color("42636e") if primary else Color("304353"),8))
	button.add_theme_stylebox_override("hover",_style(Color("305263"),CYAN,8))
	button.add_theme_stylebox_override("pressed",_style(Color("17333e"),CYAN,8))
	button.add_theme_stylebox_override("focus",_style(Color.TRANSPARENT,CYAN,8))
	button.add_theme_color_override("font_color",TEXT)
	button.add_theme_font_size_override("font_size",15)
	button.pressed.connect(callback)
	return button

func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func _build_ui() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var background = ColorRect.new()
	background.color=INK
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	var outer = MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: outer.add_theme_constant_override("margin_"+side,20)
	root.add_child(outer)
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation",14)
	outer.add_child(column)
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation",24)
	column.add_child(header)
	var brand = VBoxContainer.new()
	header.add_child(brand)
	brand.add_child(_label("N N Q R",30))
	brand.add_child(_label("A S T R A   E D I T I O N",11,CYAN))
	var spacer = Control.new()
	spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var match_info = VBoxContainer.new()
	header.add_child(match_info)
	header_turn=_label("CYAN TO MOVE",19,CYAN)
	match_info.add_child(header_turn)
	counters=_label("",14,MUTED)
	match_info.add_child(counters)
	header.add_child(_button("How to play",_help))
	header.add_child(_button("Report issue",_report_dialog))
	header.add_child(_button("Pause  ·  Esc",_pause))
	var center = HBoxContainer.new()
	center.add_theme_constant_override("separation",16)
	center.size_flags_vertical=Control.SIZE_EXPAND_FILL
	column.add_child(center)
	var board_column = VBoxContainer.new()
	board_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	center.add_child(board_column)
	var board_frame = PanelContainer.new()
	board_frame.add_theme_stylebox_override("panel",_style(Color("0b1119"),Color("263747")))
	board_frame.size_flags_vertical=Control.SIZE_EXPAND_FILL
	board_column.add_child(board_frame)
	board_container=SubViewportContainer.new()
	board_container.stretch=true
	board_container.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	board_container.size_flags_vertical=Control.SIZE_EXPAND_FILL
	board_frame.add_child(board_container)
	viewport=SubViewport.new()
	viewport.size=Vector2i(1000,700)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d=Viewport.MSAA_2X
	board_container.add_child(viewport)
	view=BoardView.new()
	viewport.add_child(view)
	view.tile_clicked.connect(_tile_clicked)
	view.tile_hovered.connect(_tile_hovered)
	var camera_bar = HBoxContainer.new()
	camera_bar.add_theme_constant_override("separation",8)
	board_column.add_child(camera_bar)
	camera_bar.add_child(_button("↶  Rotate",func(): view.rotate_camera(-PI/4)))
	camera_bar.add_child(_button("Rotate  ↷",func(): view.rotate_camera(PI/4)))
	camera_bar.add_child(_button("Overhead",func(): view.toggle_overhead()))
	camera_bar.add_child(_button("Reset view",func(): view.reset_camera()))
	hover_label=_label("Scroll to zoom · Click a torus to begin",13,MUTED)
	hover_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	hover_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	camera_bar.add_child(hover_label)
	var side = PanelContainer.new()
	side.custom_minimum_size.x=310
	side.add_theme_stylebox_override("panel",_style(PANEL,Color("263747")))
	center.add_child(side)
	var side_column=VBoxContainer.new()
	side_column.add_theme_constant_override("separation",12)
	side.add_child(side_column)
	orb_counter=_label("",13,CYAN)
	side_column.add_child(orb_counter)
	side_column.add_child(HSeparator.new())
	var scroll=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	side_column.add_child(scroll)
	inspector=VBoxContainer.new()
	inspector.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	inspector.add_theme_constant_override("separation",10)
	scroll.add_child(inspector)
	side_column.add_child(HSeparator.new())
	side_column.add_child(_label("RECENT ACTIONS",12,MUTED))
	log_label=RichTextLabel.new()
	log_label.custom_minimum_size=Vector2(270,130)
	log_label.add_theme_color_override("default_color",MUTED)
	log_label.add_theme_font_size_override("normal_font_size",13)
	log_label.scroll_following=true
	side_column.add_child(log_label)
	var footer=HBoxContainer.new()
	column.add_child(footer)
	status_label=_label("",14,MUTED)
	status_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	footer.add_child(status_label)
	footer.add_child(_label(BUILD,11,Color("637685")))
	# A full-screen mouse shield prevents board actions behind dialogs.
	var shield=ColorRect.new()
	shield.name="Shield"
	shield.color=Color(0.015,0.025,0.04,0.77)
	shield.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(shield)
	var centered=CenterContainer.new()
	centered.name="Dialogs"
	centered.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(centered)
	overlay=PanelContainer.new()
	overlay.custom_minimum_size.x=580
	overlay.add_theme_stylebox_override("panel",_style(PANEL,Color("395366"),18))
	centered.add_child(overlay)
	overlay_body=VBoxContainer.new()
	overlay_body.add_theme_constant_override("separation",14)
	overlay.add_child(overlay_body)
	sound=AudioStreamPlayer.new()
	add_child(sound)

func _dialog(title: String, subtitle: String="") -> void:
	paused=true
	root.get_node("Shield").color=Color(0.015,0.025,0.04,1.0 if handing_off else 0.77)
	root.get_node("Shield").show()
	root.get_node("Dialogs").show()
	_clear(overlay_body)
	overlay_body.add_child(_label(title,28))
	if not subtitle.is_empty():
		var sub=_label(subtitle,15,MUTED)
		sub.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		sub.custom_minimum_size.x=540
		overlay_body.add_child(sub)

func _dismiss() -> void:
	paused=false
	root.get_node("Shield").hide()
	root.get_node("Dialogs").hide()

func _title() -> void:
	_dialog("N N Q R  /  ASTRA", "A mechanical arena. An unpredictable arsenal.\nOutmaneuver your opponent. Leave no torus standing.")
	overlay_body.add_child(_label("LOCAL PLAY",12,CYAN))
	var options=OptionButton.new()
	for item in ["Easy","Medium","Hard","Expert"]: options.add_item(item)
	options.select(["easy","medium","hard","expert"].find(difficulty))
	options.item_selected.connect(func(index): difficulty=["easy","medium","hard","expert"][index])
	overlay_body.add_child(options)
	overlay_body.add_child(_button("Play against AI",func(): _new_game("ai"),true))
	overlay_body.add_child(_button("Hotseat · two players, one screen",func(): _new_game("hotseat")))
	overlay_body.add_child(_button("Power laboratory",func(): _new_game("sandbox")))
	var saved: Dictionary=diag.load_save()
	if not saved.is_empty():
		overlay_body.add_child(_button("Continue saved match",func():
			generation+=1
			thinking=false
			ai_chain=0
			action_log.clear()
			state=saved
			mode=str(state.get("local_mode","ai"))
			sandbox=mode=="sandbox"
			selected=-1
			armed=""
			diag.start(state)
			_dismiss()
			_refresh()))
	overlay_body.add_child(_label("Made by GPT Astra · Inspired by Quadradius",12,MUTED))

func _new_game(next_mode: String) -> void:
	generation+=1
	last_observer=-1
	thinking=false
	mode=next_mode
	sandbox=mode=="sandbox"
	state=Rules.new_game(int(Time.get_unix_time_from_system())%2147483646+1)
	state["local_mode"]=mode
	selected=-1
	armed=""
	ai_chain=0
	action_log.clear()
	if sandbox:
		state.tiles[34].height=2
		state.tiles[35].height=-2
		state.tiles[44].destroyed=true
		state.tiles[44].orb=""
		state.tiles[33].orb=""
		state.pieces[0].row=3
		state.pieces[0].col=3
		selected=int(state.pieces[0].id)
	diag.start(state)
	diag.save(state)
	_dismiss()
	_log("A new arena. Seed %s." % state.seed)
	_refresh()

func _refresh() -> void:
	if state.is_empty(): return
	var p=Rules.piece_by_id(state,selected)
	if p.is_empty(): selected=-1
	var observer=1 if mode=="ai" else int(state.active)
	if observer!=last_observer:
		hover_label.text="Scroll to zoom · Click selected torus to deselect"
		view._hover=Vector2i(-1,-1)
		last_observer=observer
	var observed: Dictionary=Rules.observation(state,observer)
	var legal: Array=Rules.legal_moves(observed,selected) if selected>=0 and int(p.get("owner",0))==int(state.active) else []
	var preview: Array=Powers.targets(observed,selected,armed) if not armed.is_empty() and selected>=0 else []
	view.display(observed,selected,legal,preview,observer)
	view.reduced_motion=reduced_motion
	var counts=[0,0]
	for piece in state.pieces: counts[int(piece.owner)-1]+=1
	header_turn.text=("CYAN" if state.active==1 else "AMBER")+ (" · THINKING" if thinking else " TO MOVE")
	header_turn.add_theme_color_override("font_color",CYAN if state.active==1 else AMBER)
	counters.text="CYAN  %02d     /     AMBER  %02d     ·     ROUND %d" % [counts[0],counts[1],int(state.turn)/2+1]
	orb_counter.text="NEXT ORB WAVE  ·  %d TURNS" % (14-int(state.turn)%14)
	_inspect()
	if state.status!="playing":
		header_turn.text="DRAW" if state.status=="draw" else ("CYAN WINS" if state.winner==1 else "AMBER WINS")
	status_label.text="Power laboratory · Choose a piece, then add a power." if sandbox else "Powers first. Move once to end your turn."

func _wrapped(text: String, color: Color=MUTED) -> Label:
	var label=_label(text,14,color)
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x=270
	return label

func _inspect() -> void:
	_clear(inspector)
	var observer=1 if mode=="ai" else int(state.active)
	var p=Rules.piece_by_id(Rules.observation(state,observer),selected)
	if p.is_empty():
		inspector.add_child(_label("YOUR NEXT MOVE",20))
		inspector.add_child(_wrapped("Select one of your torus pieces to inspect its powers and legal moves. Capture by moving onto an opponent."))
		inspector.add_child(_wrapped("Rise one level at a time. Descend freely. Collect luminous orbs to change the rules."))
	else:
		inspector.add_child(_label("TORUS  %02d" % int(p.id),22))
		inspector.add_child(_label("%s%d  ·  ELEVATION %+d" % [String.chr(65+int(p.col)),8-int(p.row),int(state.tiles[int(p.row)*10+int(p.col)].height)],12,CYAN))
		if not p.flags.is_empty():
			var active_flags: Array[String]=[]
			for key in p.flags:
				if p.flags[key]: active_flags.append(str(key).replace("_"," "))
			if not active_flags.is_empty(): inspector.add_child(_wrapped("Installed: "+", ".join(active_flags),CYAN))
		if not armed.is_empty():
			var definition: Dictionary=Powers.catalog().get(armed,{})
			inspector.add_child(_label("POWER PREVIEW",12,Color("b5a0fa")))
			inspector.add_child(_wrapped(str(definition.get("description","")),TEXT))
			if str(definition.get("target","self"))=="self":
				inspector.add_child(_button("Activate "+str(definition.get("name",armed)),func(): _activate({}),true))
			else:
				inspector.add_child(_wrapped("Click a highlighted target on the board.",TEXT))
			inspector.add_child(_button("Cancel preview",func(): armed=""; _refresh()))
		inspector.add_child(_label("POWER INVENTORY",12,MUTED))
		var keys: Array=p.inventory.keys()
		keys.sort()
		if keys.is_empty(): inspector.add_child(_wrapped("No powers yet. Move onto an orb to collect one."))
		for id in keys:
			if int(p.inventory[id])<=0: continue
			var definition: Dictionary=Powers.catalog().get(id,{})
			var button=_button("%s  ×%d" % [definition.get("name",id),int(p.inventory[id])],_arm.bind(str(id)))
			button.disabled=int(p.owner)!=int(state.active)
			button.tooltip_text=str(definition.get("description",""))
			button.clip_text=true
			inspector.add_child(button)
		if sandbox:
			inspector.add_child(_button("Add power…",_grant_dialog,true))
			inspector.add_child(_button("Raise tile",_sandbox_height.bind(1)))
			inspector.add_child(_button("Lower tile",_sandbox_height.bind(-1)))
	if state.status=="playing":
		var any_moves=false
		for piece in state.pieces:
			if int(piece.owner)==int(state.active) and not Rules.legal_moves(state,int(piece.id)).is_empty(): any_moves=true; break
		if not any_moves: inspector.add_child(_button("Pass · no legal moves",func(): _act({"type":"pass"})))

func _arm(id: String) -> void:
	var piece=Rules.piece_by_id(state,selected)
	if paused or thinking or (mode=="ai" and int(state.active)!=1) or piece.is_empty() or int(piece.owner)!=int(state.active): return
	armed=id
	_refresh()

func _tile_clicked(row: int,col: int) -> void:
	if paused or thinking or (mode=="ai" and int(state.active)!=1) or state.status!="playing": return
	if not armed.is_empty():
		var definition: Dictionary=Powers.catalog()[armed]
		if definition.target!="self": _activate({"row":row,"col":col}); return
	var p=Rules.piece_at(state,row,col)
	if not p.is_empty() and int(p.id)==selected:
		selected=-1
		armed=""
		_refresh()
		return
	if selected>=0 and not p.is_empty() and int(p.id)!=selected:
		for move in Rules.legal_moves(state,selected):
			if int(move.row)==row and int(move.col)==col:
				_act({"type":"move","piece_id":selected,"row":row,"col":col})
				return
	if not p.is_empty() and int(p.owner)!=int(state.active) and not p.flags.get("invisible",false):
		if int(p.flags.get("spyware",0))==int(state.active):
			selected=int(p.id)
			armed=""
			_refresh()
			return
	if not p.is_empty() and int(p.owner)==int(state.active):
		selected=int(p.id)
		armed=""
		_refresh()
		return
	if selected>=0:
		_act({"type":"move","piece_id":selected,"row":row,"col":col})

func _tile_hovered(row: int,col: int) -> void:
	if row<0 or state.is_empty(): return
	var tile: Dictionary=state.tiles[row*10+col]
	hover_label.text="%s%d  ·  %s" % [String.chr(65+col),8-row,"DESTROYED" if tile.destroyed else "HEIGHT %+d" % int(tile.height)]
	var observer=1 if mode=="ai" else int(state.active)
	if not str(tile.orb).is_empty() and int(tile.marks.get("orb_spy",0))==observer:
		hover_label.text+=" · "+str(Powers.catalog().get(tile.orb,{}).get("name",tile.orb))

func _activate(target: Dictionary) -> void:
	if paused or (mode=="ai" and int(state.active)!=1): return
	_act({"type":"power","piece_id":selected,"power_id":armed,"target":target})

func _act(action: Dictionary) -> void:
	var before=int(state.active)
	var result: Dictionary=Rules.apply_action(state,action)
	diag.record(action,result)
	if not result.ok:
		status_label.text=str(result.get("error","That action is unavailable."))
		_log("Action declined: "+status_label.text)
		if thinking: ai_chain=12
		return
	state=result.state
	state["local_mode"]=mode
	armed=""
	if before!=int(state.active): selected=-1; ai_chain=0
	var text=""
	if action.type=="move": text="%s moved to %s%d." % ["Cyan" if before==1 else "Amber",String.chr(65+int(action.col)),8-int(action.row)]
	elif action.type=="power": text="%s activated %s." % ["Cyan" if before==1 else "Amber",Powers.catalog().get(action.power_id,{}).get("name",action.power_id)]
	else: text=str(action.type).capitalize()+"."
	_log(text)
	diag.save(state)
	_tone(420 if action.type=="power" else 260)
	_refresh()
	if state.status!="playing": _result()
	elif before!=int(state.active) and mode=="hotseat":
		handing_off=true
		_dialog("Pass to "+("Cyan" if state.active==1 else "Amber"),"The board is concealed while you hand over the screen.")
		overlay_body.add_child(_button("Ready · reveal my turn",func(): handing_off=false; _dismiss(); _refresh(),true))

func _log(text: String) -> void:
	action_log.append(text)
	if action_log.size()>40: action_log.pop_front()
	log_label.text="\n".join(action_log)

func _process(_delta: float) -> void:
	if not paused and not thinking and not state.is_empty() and state.status=="playing" and mode=="ai" and state.active==2:
		thinking=true
		_refresh()
		_ai_step(generation)

func _ai_step(epoch: int) -> void:
	await get_tree().create_timer(0.28 if reduced_motion else 0.5).timeout
	if epoch!=generation: return
	if paused:
		thinking=false
		return
	var action: Dictionary={}
	if ai_chain>=8:
		for p in state.pieces:
			if int(p.owner)!=int(state.active): continue
			var legal: Array=Rules.legal_moves(state,int(p.id))
			if not legal.is_empty():
				action={"type":"move","piece_id":p.id,"row":legal[0].row,"col":legal[0].col}
				break
		if action.is_empty(): action={"type":"pass"}
	else:
		action=AI.choose_action(state,difficulty)
	if action.is_empty(): action={"type":"pass"}
	ai_chain+=1
	_act(action)
	thinking=false
	_refresh()

func _pause() -> void:
	if handing_off: return
	_dialog("Arena paused","Your match is saved after each action.")
	overlay_body.add_child(_button("Resume",_dismiss,true))
	var audio=CheckButton.new()
	audio.text="Sound effects"
	audio.button_pressed=sound_enabled
	audio.toggled.connect(func(value): sound_enabled=value)
	overlay_body.add_child(audio)
	var motion=CheckButton.new()
	motion.text="Reduced motion"
	motion.button_pressed=reduced_motion
	motion.toggled.connect(func(value): reduced_motion=value; view.reduced_motion=value)
	overlay_body.add_child(motion)
	var size=HSlider.new()
	size.min_value=0.85
	size.max_value=1.3
	size.step=0.05
	size.value=get_tree().root.content_scale_factor
	size.value_changed.connect(func(value): get_tree().root.content_scale_factor=value)
	overlay_body.add_child(_label("Interface scale",14,MUTED))
	overlay_body.add_child(size)
	var resign_button=_button("Resign match",func(): _dismiss(); _act({"type":"resign"}))
	resign_button.disabled=mode=="ai" and int(state.active)!=1
	if resign_button.disabled: resign_button.tooltip_text="Resume and wait for your turn to resign."
	overlay_body.add_child(resign_button)
	overlay_body.add_child(_button("New match…",_title))

func _result() -> void:
	var title="An even finish." if state.status=="draw" else ("Cyan takes the arena." if state.winner==1 else "Amber takes the arena.")
	_dialog(title,"%d turns played. Every power changes the possibilities." % int(state.turn))
	overlay_body.add_child(_button("Rematch",func(): _new_game(mode),true))
	overlay_body.add_child(_button("Inspect final board",_dismiss))
	overlay_body.add_child(_button("Main menu",_title))

func _help() -> void:
	_dialog("FIELD MANUAL","Select your torus, activate any powers, then move one square. Moving ends the turn unless you installed Move Again. Capture by landing on an opponent. Eliminate their squadron to win.\n\nYou may climb one terrain level and descend any distance. Power orbs add abilities to the piece that collects them. Ten identical stored powers overheat a piece.\n\nUse the power laboratory to experiment. Scroll over the board to zoom; rotate or use the overhead view to inspect terrain.")
	var search=LineEdit.new()
	search.placeholder_text="Search the power encyclopedia…"
	overlay_body.add_child(search)
	var scroll=ScrollContainer.new()
	scroll.custom_minimum_size=Vector2(540,260)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	overlay_body.add_child(scroll)
	var list=VBoxContainer.new()
	list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var fill=func(query: String):
		_clear(list)
		for id in Powers.catalog():
			var d: Dictionary=Powers.catalog()[id]
			if not query.is_empty() and not (str(d.name)+str(d.description)).to_lower().contains(query.to_lower()): continue
			list.add_child(_label(str(d.name),16,CYAN))
			var text=_wrapped(str(d.description))
			text.custom_minimum_size.x=510
			list.add_child(text)
	search.text_changed.connect(fill)
	fill.call("")
	overlay_body.add_child(_button("Back to arena",_dismiss,true))

func _grant_dialog() -> void:
	_dialog("POWER LABORATORY","Choose a power to add to the selected torus. Experiments reset the replay baseline.")
	var search=LineEdit.new()
	search.placeholder_text="Search powers…"
	overlay_body.add_child(search)
	var scroll=ScrollContainer.new()
	scroll.custom_minimum_size=Vector2(540,360)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	overlay_body.add_child(scroll)
	var list=VBoxContainer.new()
	list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var fill=func(query: String):
		_clear(list)
		for id in Powers.catalog():
			var d: Dictionary=Powers.catalog()[id]
			if not query.is_empty() and not str(d.name).to_lower().contains(query.to_lower()): continue
			list.add_child(_button(str(d.name),_grant.bind(str(id))))
	search.text_changed.connect(fill)
	fill.call("")
	overlay_body.add_child(_button("Cancel",_dismiss))

func _grant(id: String) -> void:
	var p=Rules.piece_by_id(state,selected)
	if not p.is_empty(): p.inventory[id]=int(p.inventory.get(id,0))+1
	diag.start(state)
	diag.save(state)
	_dismiss()
	_refresh()

func _sandbox_height(delta: int) -> void:
	var p=Rules.piece_by_id(state,selected)
	if p.is_empty(): return
	var tile: Dictionary=state.tiles[int(p.row)*10+int(p.col)]
	tile.height=clampi(int(tile.height)+delta,-4,4)
	diag.start(state)
	diag.save(state)
	_refresh()

func _report_dialog() -> void:
	_dialog("REPORT AN ISSUE","Describe what you tried, what you expected, and what happened. The local report includes your match, recent actions, engine log and a screenshot. Share the ZIP with me here.")
	feedback=TextEdit.new()
	feedback.placeholder_text="Steps to reproduce, visual feedback, or anything that felt wrong…"
	feedback.custom_minimum_size=Vector2(540,160)
	overlay_body.add_child(feedback)
	overlay_body.add_child(_button("Export diagnostic report",_export_report,true))
	overlay_body.add_child(_button("Cancel",_dismiss))

func _export_report() -> void:
	var note=feedback.text
	_dismiss()
	await RenderingServer.frame_post_draw
	var path: String=diag.report(state,note,get_viewport())
	_dialog("Report failed" if path.begins_with("error:") else "Report exported",path+"\n\nAttach the diagnostic ZIP in this conversation with any extra notes.")
	if not OS.has_feature("web") and not path.is_empty() and not path.begins_with("error:"):
		overlay_body.add_child(_button("Open reports folder",func(): OS.shell_open(path.get_base_dir())))
	overlay_body.add_child(_button("Return to match",_dismiss,true))

func _tone(frequency: float) -> void:
	if not sound_enabled or DisplayServer.get_name()=="headless": return
	var data=PackedByteArray()
	var samples=2205
	data.resize(samples*2)
	for i in range(samples):
		var value=int(sin(TAU*frequency*i/22050.0)*exp(-float(i)/420.0)*3200)
		data.encode_s16(i*2,value)
	var stream=AudioStreamWAV.new()
	stream.format=AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate=22050
	stream.data=data
	sound.stream=stream
	sound.play()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		if handing_off: return
		if paused: _dismiss()
		elif not armed.is_empty(): armed=""; _refresh()
		else: _pause()

func _qa() -> void:
	_new_game("sandbox")
	var p=Rules.piece_by_id(state,selected)
	p.inventory["raise_tile"]=1
	p.inventory["destroy_radial"]=1
	p.inventory["move_diagonal"]=1
	diag.start(state)
	_refresh()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://.qa")
	get_viewport().get_texture().get_image().save_png("res://.qa/arena.png")
	var file=FileAccess.open("res://.qa/state.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(state,"  "))
	file.close()
	var hit: Vector2i=view.pick(view.camera.unproject_position(view.cell_position(int(p.row),int(p.col))))
	if hit!=Vector2i(int(p.row),int(p.col)):
		push_error("QA picking mismatch: "+str(hit))
		get_tree().quit(1)
		return
	_act({"type":"power","piece_id":selected,"power_id":"move_diagonal","target":{}})
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.qa/power.png")
	var report_path: String=diag.report(state,"Automated rendered QA: power activation and picking",get_viewport())
	if report_path.begins_with("error:"):
		push_error(report_path)
		get_tree().quit(1)
		return
	print("ASTRA_QA_REPORT: "+report_path)
	print("ASTRA_QA_OK: screenshots, state, report and camera picking verified")
	get_tree().quit(0)

func _exit_tree() -> void:
	if sound != null:
		sound.stop()
		sound.stream=null
