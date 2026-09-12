extends Node3D
## Pure presentation: all selection coordinates come from top-face ray intersections.
signal tile_clicked(row: int, col: int)
signal tile_hovered(row: int, col: int)

const CYAN = Color("55dfed")
const AMBER = Color("ffb657")
const IVORY = Color("e5e6dc")
var camera: Camera3D
var terrain_root: Node3D
var pieces_root: Node3D
var overlay_root: Node3D
var effects_root: Node3D
var environment: WorldEnvironment
var state: Dictionary = {}
var viewer = 1
var selected_id = -1
var moves: Array = []
var targets: Array = []
var angle = 0.0
var overhead = false
var zoom = 10.8
var reduced_motion = false
var _clock = 0.0
var _orbs: Array = []
var _hover = Vector2i(-1,-1)
var _mat_cache: Dictionary = {}

func _ready() -> void:
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.near = 0.1
	camera.far = 100.0
	add_child(camera)
	camera.current = true
	_update_camera()
	environment = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("0b1119")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("afc4d5")
	env.ambient_light_energy = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	add_child(environment)
	var key = DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-58,-30,0)
	key.light_color = Color("e2eced")
	key.light_energy = 1.6
	key.shadow_enabled = true
	add_child(key)
	var fill = DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-35,145,0)
	fill.light_color = CYAN
	fill.light_energy = 0.5
	add_child(fill)
	terrain_root = Node3D.new()
	pieces_root = Node3D.new()
	overlay_root = Node3D.new()
	add_child(terrain_root)
	add_child(pieces_root)
	add_child(overlay_root)
	effects_root=Node3D.new()
	add_child(effects_root)

func material(color: Color, metallic: float = 0.0, glow: float = 0.0) -> StandardMaterial3D:
	var key = str(color)+str(metallic)+str(glow)
	if _mat_cache.has(key): return _mat_cache[key]
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = 0.42 if metallic > 0 else 0.8
	if glow > 0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = glow
	_mat_cache[key] = mat
	return mat

func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, metal: float=0.0) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = material(color,metal)
	node.position = pos
	parent.add_child(node)
	return node

func ring(parent: Node3D, pos: Vector3, radius: float, width: float, color: Color, glow: float=0.0) -> MeshInstance3D:
	var mesh = TorusMesh.new()
	mesh.inner_radius = radius-width
	mesh.outer_radius = radius
	mesh.rings = 32
	mesh.ring_segments = 12
	var node = MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material(color,0.6,glow)
	node.position = pos
	parent.add_child(node)
	return node

func label3(parent: Node3D, text: String, pos: Vector3, color: Color, size: int=28) -> Label3D:
	var label = Label3D.new()
	label.text = text
	label.position = pos
	label.font_size = size
	label.pixel_size = 0.008
	label.modulate = color
	label.outline_modulate = Color("0b1119")
	label.outline_size = 5
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = false
	parent.add_child(label)
	return label

func _clear(root: Node3D) -> void:
	for child in root.get_children():
		root.remove_child(child)
		child.queue_free()

func cell_position(row: int,col: int) -> Vector3:
	var tile: Dictionary = state.tiles[row*10+col]
	return Vector3(float(col)-4.5, float(tile.height)*0.26, float(row)-3.5)

func display(next_state: Dictionary, selected: int, legal: Array, preview: Array, observing: int) -> void:
	var previous: Dictionary=state
	state = next_state
	selected_id = selected
	moves = legal
	targets = preview
	viewer = observing
	if not is_node_ready(): return
	_clear(terrain_root)
	_clear(pieces_root)
	_clear(overlay_root)
	_orbs.clear()
	box(terrain_root,Vector3(0,-1.55,0),Vector3(10.65,0.45,8.65),Color("141e29"),0.65)
	box(terrain_root,Vector3(0,-1.28,0),Vector3(10.4,0.1,8.4),Color("394652"),0.65)
	# The recessed perimeter is intentionally quiet; ownership colors belong to pieces.
	for col in range(10):
		label3(terrain_root,String.chr(65+col),Vector3(col-4.5,-0.8,4.48),Color("8b9aa8"),24)
	for row in range(8):
		label3(terrain_root,str(8-row),Vector3(-5.48,-0.8,row-3.5),Color("8b9aa8"),24)
	for row in range(8):
		for col in range(10):
			var tile: Dictionary = state.tiles[row*10+col]
			var pos = cell_position(row,col)
			if tile.destroyed:
				box(terrain_root,Vector3(pos.x,-1.2,pos.z),Vector3(0.88,0.02,0.88),Color("071013"))
				ring(terrain_root,Vector3(pos.x,-1.17,pos.z),0.23,0.02,Color("639943"),0.3)
				continue
			var shade = Color("34434e") if (row+col)%2 == 0 else Color("2b3945")
			shade = shade.lightened(maxf(0,float(tile.height))*0.028)
			var body_height = pos.y+1.2
			box(terrain_root,Vector3(pos.x,-1.2+body_height/2,pos.z),Vector3(0.94,body_height,0.94),Color("202d37"),0.4)
			# A tapered chamfer gives each tile an actual beveled edge.
			var cap = CylinderMesh.new()
			cap.top_radius = 0.635
			cap.bottom_radius = 0.667
			cap.height = 0.08
			cap.radial_segments = 4
			var cap_node = MeshInstance3D.new()
			cap_node.mesh = cap
			cap_node.material_override = material(shade,0.45)
			cap_node.position = pos+Vector3(0,0.015,0)
			if not previous.is_empty() and not reduced_motion:
				var old_y=float(previous.tiles[row*10+col].height)*0.26+0.015
				if absf(old_y-cap_node.position.y)>0.01:
					var target_y=cap_node.position.y
					cap_node.position.y=old_y
					cap_node.create_tween().tween_property(cap_node,"position:y",target_y,0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			cap_node.rotation.y = PI/4
			terrain_root.add_child(cap_node)
			if int(tile.height)!=0:
				label3(terrain_root,("+" if tile.height>0 else "")+str(tile.height),pos+Vector3(0.31,0.09,0.32),Color("a4b2b7"),19)
			var marks: Dictionary = tile.get("marks",{})
			if not marks.is_empty():
				ring(terrain_root,pos+Vector3(0,0.07,0),0.36,0.012,Color("aa8de3"),0.25)
			if not str(tile.orb).is_empty():
				var orb_root = Node3D.new()
				orb_root.position = pos+Vector3(0,0.27,0)
				pieces_root.add_child(orb_root)
				var orb = MeshInstance3D.new()
				var sphere = SphereMesh.new()
				sphere.radius = 0.115
				sphere.height = 0.23
				orb.mesh = sphere
				orb.material_override = material(Color("d9f4c3"),0.25,0.9)
				orb_root.add_child(orb)
				var halo = ring(orb_root,Vector3.ZERO,0.22,0.017,Color("c4e8a0"),0.6)
				halo.rotation_degrees = Vector3(55,0,20)
				_orbs.append({"node":orb_root,"base":orb_root.position.y})
	for p in state.pieces:
		var invisible = bool(p.flags.get("invisible",false))
		if invisible and int(p.owner)!=viewer: continue
		var pos = cell_position(int(p.row),int(p.col))
		var assembly=Node3D.new()
		assembly.position=pos
		pieces_root.add_child(assembly)
		if not previous.is_empty() and not reduced_motion:
			for old in previous.pieces:
				if int(old.id)==int(p.id):
					var origin=Vector3(float(old.col)-4.5,float(previous.tiles[int(old.row)*10+int(old.col)].height)*0.26,float(old.row)-3.5)
					if origin.distance_to(pos)>0.01:
						assembly.position=origin
						assembly.create_tween().tween_property(assembly,"position",pos,0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
					break
		var team: Color = CYAN if int(p.owner)==1 else AMBER
		if invisible: team = team.darkened(0.45)
		ring(assembly,Vector3(0,0.145,0),0.345,0.15,Color("91a2ad"),0.0)
		ring(assembly,Vector3(0,0.205,0),0.29,0.052,team,0.6)
		ring(assembly,Vector3(0,0.075,0),0.30,0.035,Color("101921"))
		# One versus two physical tabs distinguish teams without relying on color.
		for mark in range(int(p.owner)):
			box(assembly,Vector3(-0.06+mark*0.12,0.215,0.27),Vector3(0.07,0.045,0.11),team,0.4)
		if p.flags.get("jump_proof",false):
			ring(assembly,Vector3(0,0.26,0),0.40,0.02,team,0.5)
		var count = 0
		for v in p.inventory.values(): count += int(v)
		if count>0 and (int(p.owner)==viewer or int(p.flags.get("spyware",0))==viewer):
			label3(assembly,str(count),Vector3(0,0.48,0),IVORY,24)
		if int(p.id)==selected:
			ring(overlay_root,pos+Vector3(0,0.09,0),0.455,0.035,IVORY,0.7)
	for move in legal:
		var pos = cell_position(int(move.row),int(move.col))+Vector3(0,0.11,0)
		var color = AMBER if move.get("capture",false) else CYAN
		ring(overlay_root,pos,0.41 if move.get("capture",false) else 0.12,0.025,color,0.8)
	for target in preview:
		var row = int(target.row)
		var col = int(target.col)
		if row<0 or row>=8 or col<0 or col>=10: continue
		ring(overlay_root,cell_position(row,col)+Vector3(0,0.12,0),0.42,0.018,Color("b5a0fa"),0.6)

	if not previous.is_empty() and not reduced_motion:
		for old in previous.pieces:
			var survives=false
			for current in state.pieces:
				if int(current.id)==int(old.id): survives=true; break
			if not survives:
				var location=Vector3(float(old.col)-4.5,float(previous.tiles[int(old.row)*10+int(old.col)].height)*0.26+0.2,float(old.row)-3.5)
				var burst=ring(effects_root,location,0.3,0.025,CYAN if int(old.owner)==1 else AMBER,0.5)
				var tween=burst.create_tween()
				tween.tween_property(burst,"scale",Vector3(2,0.2,2),0.3)
				tween.tween_callback(burst.queue_free)

func _update_camera() -> void:
	if camera == null: return
	var distance = 17.0
	var elevation = 1.31 if overhead else 0.82
	camera.position = Vector3(sin(angle)*cos(elevation)*distance,sin(elevation)*distance,cos(angle)*cos(elevation)*distance)
	camera.look_at(Vector3(0,-0.2,0))
	camera.size = zoom

func rotate_camera(delta: float) -> void:
	angle += delta
	_update_camera()

func toggle_overhead() -> void:
	overhead = not overhead
	_update_camera()

func reset_camera() -> void:
	angle = 0
	overhead = false
	zoom = 10.8
	_update_camera()

func pick(at: Vector2) -> Vector2i:
	if state.is_empty(): return Vector2i(-1,-1)
	var origin = camera.project_ray_origin(at)
	var direction = camera.project_ray_normal(at)
	var best = INF
	var hit = Vector2i(-1,-1)
	for row in range(8):
		for col in range(10):
			var tile: Dictionary = state.tiles[row*10+col]
			var pos = cell_position(row,col)
			var y = -1.17 if tile.destroyed else pos.y+0.055
			if absf(direction.y)<0.001: continue
			var t = (y-origin.y)/direction.y
			var point = origin+direction*t
			if t>0 and t<best and absf(point.x-pos.x)<=0.48 and absf(point.z-pos.z)<=0.48:
				best=t
				hit=Vector2i(row,col)
	return hit

func _input(event: InputEvent) -> void:
	# SubViewport receives only events forwarded through its container.
	if event is InputEventMouseMotion:
		var cell = pick(event.position)
		if cell!=_hover:
			_hover=cell
			tile_hovered.emit(cell.x,cell.y)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_LEFT:
			var cell = pick(event.position)
			if cell.x>=0: tile_clicked.emit(cell.x,cell.y)
		elif event.button_index==MOUSE_BUTTON_WHEEL_UP:
			zoom=clampf(zoom-0.6,8,20)
			_update_camera()
		elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN:
			zoom=clampf(zoom+0.6,8,20)
			_update_camera()

func _process(delta: float) -> void:
	_clock+=delta
	if reduced_motion: return
	for data in _orbs:
		var node: Node3D = data.node
		if is_instance_valid(node):
			node.position.y=float(data.base)+sin(_clock*2.4+node.position.x)*0.045
			node.rotation.y+=delta*0.6
