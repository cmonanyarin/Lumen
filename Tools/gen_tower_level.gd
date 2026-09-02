extends SceneTree

## เจนหอคอย LUMEN ทั้ง 43 ชั้นออกมาเป็น Scenes/Tower.tscn
##
## รันด้วย:  godot --headless --path <โปรเจกต์> --script res://Tools/gen_tower_level.gd
##           ตั้ง seed ด้วย env  LUMEN_SEED=12345
##
## ผลลัพธ์เป็น .tscn ธรรมดา เปิดในเอดิเตอร์แล้วลากแท่นแก้มือได้ทุกจุด
## รันซ้ำเมื่อไหร่ = ทับของเดิมทั้งหมด ให้ก๊อปเก็บไว้ก่อนถ้าแต่งมือไปแล้ว
##
## หลักประกันว่าเล่นจบได้: สร้าง "โซ่แท่นปลอดภัย" จากพื้นถึงยอดก่อน
## โดยทุกก้าวคำนวณจากอาร์คกระโดดจริงใน King.gd แล้วคูณ safety 0.75
## แท่นกับดักเป็นของแถมที่วางข้างทางเท่านั้น ไม่เคยอยู่บนเส้นทางหลัก

const TILE := 20
const SCREEN_W := 480
const SCREEN_H := 360
const COLS := 24					# 480 / 20
const ROWS := 18					# 360 / 20
const LEVELS := 43
const WALL := 2						# ความหนาผนังหอคอย (ไทล์)
const OUT := "res://Scenes/Tower.tscn"

# --- ฟิสิกส์จริงจาก King.gd ---------------------------------------------------
const JUMP_V := 500.0				# maxJump 250 * maxPower 2
const GRAVITY := 800.0
const H_SPEED := 193.2				# moveSpeed 84 * jumpHMultiplier 2.3
const SAFETY := 0.75				# กันไว้ ผู้เล่นไม่ได้ชาร์จเต็มเป๊ะทุกครั้ง

# --- ช่องในอัตลาส -------------------------------------------------------------
const T_STONE := Vector2i(0, 0)
const T_STONE_TOP := Vector2i(1, 0)
const T_STONE_L := Vector2i(2, 0)
const T_STONE_R := Vector2i(3, 0)
const T_STONE_DARK := Vector2i(6, 0)
const T_PILLAR := Vector2i(7, 0)
const T_SAFE_L := Vector2i(0, 1)
const T_SAFE_M := Vector2i(1, 1)
const T_SAFE_R := Vector2i(2, 1)
const T_SAFE_1 := Vector2i(3, 1)
const T_HAZ_L := Vector2i(0, 2)
const T_HAZ_M := Vector2i(1, 2)
const T_HAZ_R := Vector2i(2, 2)
const T_HAZ_1 := Vector2i(3, 2)
const T_WINDOW := Vector2i(0, 3)
const T_CRYSTAL_S := Vector2i(1, 3)
const T_CRYSTAL_L := Vector2i(2, 3)
const T_RUBBLE := Vector2i(3, 3)
const T_BAND := Vector2i(4, 3)

# --- พารามิเตอร์ต่อโซน --------------------------------------------------------
# rise = ระยะไต่ต่อก้าว (px) · w = ความกว้างแท่น (ไทล์) · haz = โอกาสวางกับดัก
const ZONES := [
	{"id": 1, "lv": 1,  "name": "รากที่จมน้ำ",      "rise": [55, 85],   "w": [5, 7], "haz": 0.10,
	 "safe": Color(1.0, 0.82, 0.45), "cold": Color(0.62, 0.84, 0.95), "e": 0.95},
	{"id": 2, "lv": 9,  "name": "หอจดหมายเหตุ",     "rise": [65, 100],  "w": [4, 6], "haz": 0.22,
	 "safe": Color(1.0, 0.86, 0.52), "cold": Color(0.66, 0.80, 0.98), "e": 0.85},
	{"id": 3, "lv": 18, "name": "เส้นเลือดเตาหลอม", "rise": [75, 115],  "w": [3, 5], "haz": 0.34,
	 "safe": Color(1.0, 0.72, 0.38), "cold": Color(0.55, 0.88, 0.98), "e": 0.80},
	{"id": 4, "lv": 27, "name": "มงกุฎแก้ว",        "rise": [85, 125],  "w": [3, 4], "haz": 0.28,
	 "safe": Color(0.94, 0.80, 1.0),  "cold": Color(0.72, 0.78, 1.0),  "e": 0.70},
	{"id": 5, "lv": 37, "name": "ห้องตะเกียง",      "rise": [95, 140],  "w": [2, 3], "haz": 0.18,
	 "safe": Color(1.0, 0.96, 0.88), "cold": Color(0.86, 0.90, 1.0),  "e": 0.55},
]

var rng := RandomNumberGenerator.new()
var world: Node2D
var map: TileMapLayer
var back: TileMapLayer
var props: Node2D
var lights: Node2D
var hazards: Node2D
var safe_count := 0
var haz_count := 0
var max_step := 0.0
var max_rise := 0.0


func _initialize() -> void:
	var seed_env := OS.get_environment("LUMEN_SEED")
	rng.seed = int(seed_env) if seed_env != "" else 20260903
	print("GEN: seed=", rng.seed)

	_build_root()
	_build_shell()
	_build_climb()
	_build_actors()

	var packed := PackedScene.new()
	var err := packed.pack(world)
	if err != OK:
		printerr("GEN: pack ล้มเหลว ", err)
		quit(1)
		return
	err = ResourceSaver.save(packed, OUT)
	world.free()
	print("GEN: ", OUT, " err=", err,
		"  ชั้น=", LEVELS, "  แท่นปลอดภัย=", safe_count, "  กับดัก=", haz_count,
		"  ก้าวไกลสุด=%.0fpx  ไต่สูงสุด=%.0fpx" % [max_step, max_rise])
	quit()


# ---------------------------------------------------------------- โครงฉาก

func _build_root() -> void:
	world = Node2D.new()
	world.name = "World"					# King.gd หาที่ /root/World ตอนสร้างอนุภาค

	var parallax := CanvasLayer.new()
	parallax.name = "Parallax"
	parallax.layer = -10
	_own(parallax, world)

	var sky := Parallax2D.new()
	sky.name = "Sky"
	sky.scroll_scale = Vector2(0.0, 0.04)
	sky.repeat_size = Vector2(0, 1086)
	sky.repeat_times = 4
	_own(sky, parallax)

	var sky_img := Sprite2D.new()
	sky_img.name = "SkyArt"
	sky_img.texture = load("res://Sprites/Logos/lumen_bg.png")
	sky_img.centered = false
	sky_img.light_mask = 0				# พื้นหลังห้ามโดนไฟผู้เล่น ไม่งั้นมิติความลึกพัง
	sky_img.modulate = Color(0.55, 0.5, 0.72)
	sky_img.scale = Vector2(1.1, 1.1)
	sky_img.position = Vector2(-40, -300)
	_own(sky_img, sky)

	map = TileMapLayer.new()
	map.name = "CollisionMap"			# King.gd อ่านกลุ่มนี้เพื่อเช็กพื้น
	map.tile_set = load("res://Resources/Tower/tower_tileset.tres")
	map.add_to_group("map_collision", true)	# persistent ไม่งั้นกลุ่มไม่ติดไปกับ .tscn
	map.physics_quadrant_size = 16		# รวมรูปคอลลิชันในควอดแดรนต์ ลดรอยต่อ
	map.z_index = 2
	map.z_as_relative = false
	_own(map, world)

	# ผนังหลังของปล่อง — ไม่มีคอลลิชัน มีไว้ให้ฉากไม่โล่งเป็นดำสนิท
	# และเพื่อให้ผนังซ้าย/ขวาอ่านออกด้วยคอนทราสต์ ไม่ใช่ด้วยเส้นขอบ
	back = TileMapLayer.new()
	back.name = "BackWall"
	back.tile_set = load("res://Resources/Tower/tower_tileset.tres")
	back.collision_enabled = false
	back.z_index = 0
	back.z_as_relative = false
	_own(back, world)

	props = Node2D.new()
	props.name = "Props"
	props.z_index = 1
	props.z_as_relative = false
	_own(props, world)

	lights = Node2D.new()
	lights.name = "Lights"
	_own(lights, world)

	hazards = Node2D.new()
	hazards.name = "Hazards"
	hazards.z_index = 2
	hazards.z_as_relative = false
	_own(hazards, world)


## ผนังหอคอยสองข้าง พื้นชั้นล่าง และแถบทองบอกระดับทุก 5 ชั้น
func _build_shell() -> void:
	var top_cy := -(LEVELS - 1) * ROWS - 2
	for cy in range(top_cy, ROWS + 1):
		var sid := _src_at_cy(cy)
		for k in WALL:
			map.set_cell(Vector2i(k, cy), sid, T_STONE_R if k == WALL - 1 else T_STONE)
			map.set_cell(Vector2i(COLS - 1 - k, cy), sid, T_STONE_L if k == WALL - 1 else T_STONE)

	# ผนังหลังเต็มปล่อง
	for cy in range(top_cy, ROWS):
		var sid := _src_at_cy(cy)
		for cx in range(WALL, COLS - WALL):
			back.set_cell(Vector2i(cx, cy), sid, T_STONE_DARK)

	# เสาประดับบนผนังหลัง ทุก 6 ไทล์ ให้ปล่องมีจังหวะแนวตั้ง
	for cy in range(top_cy, ROWS):
		if cy % 6 == 0:
			var sid := _src_at_cy(cy)
			back.set_cell(Vector2i(WALL + 3, cy), sid, T_PILLAR)
			back.set_cell(Vector2i(COLS - WALL - 4, cy), sid, T_PILLAR)

	# พื้นชั้นล่างสุด
	for cx in range(WALL, COLS - WALL):
		map.set_cell(Vector2i(cx, ROWS - 1), 0, T_STONE_TOP)		# พื้นชั้นล่างสุด = โซน 1 เสมอ

	# แถบทองทุก 5 ชั้น — ผู้เล่นนับความสูงได้โดยไม่ต้องมีตัวเลข
	for lv in range(5, LEVELS + 1, 5):
		var cy := -(lv - 1) * ROWS + ROWS - 1
		var bsid := _src_at_cy(cy)
		for k in WALL:
			map.set_cell(Vector2i(k, cy), bsid, T_BAND)
			map.set_cell(Vector2i(COLS - 1 - k, cy), bsid, T_BAND)

	# หน้าต่างบนผนัง สลับข้าง ให้จังหวะสายตาระหว่างไต่
	for lv in range(2, LEVELS + 1, 3):
		var cy := -(lv - 1) * ROWS + 6
		var left := (lv / 3) % 2 == 0
		back.set_cell(Vector2i(WALL + 1 if left else COLS - WALL - 2, cy), _src_at_cy(cy), T_WINDOW)


# ---------------------------------------------------------------- เส้นทางไต่

func _build_climb() -> void:
	var top_y := -(LEVELS - 1) * SCREEN_H
	var px := float(SCREEN_W) * 0.5
	var py := float((ROWS - 1) * TILE)			# ผิวบนของพื้นชั้นล่าง
	var dir := 1.0

	while py > top_y:
		var z: Dictionary = _zone_at(py)
		var rise: Array = z["rise"]
		var dy := rng.randf_range(rise[0], rise[1])
		var span := _reach(dy)
		if span <= 0.0:
			dy = 140.0
			span = _reach(dy)

		# สลับข้างเป็นหลัก แต่มีโอกาสย้อนกลับเพื่อไม่ให้เป็นซิกแซกจักรกล
		if rng.randf() < 0.25:
			dir = -dir
		var dx := dir * rng.randf_range(span * 0.35, span)

		var wr: Array = z["w"]
		var w := rng.randi_range(wr[0], wr[1])
		var nx := px + dx
		var half := float(w * TILE) * 0.5
		var lo := float(WALL * TILE) + half
		var hi := float((COLS - WALL) * TILE) - half
		if nx < lo or nx > hi:
			dir = -dir
			nx = clampf(px - dx, lo, hi)
		nx = clampf(nx, lo, hi)

		# กันกรณีถูกดันชนผนังจนก้าวไกลเกินอาร์คกระโดดจริง
		# ถ้าไม่ดักตรงนี้ หอคอยจะมีจุดที่กระโดดยังไงก็ไม่ถึงโดยที่ไม่มีใครรู้
		if absf(nx - px) > span:
			nx = clampf(px + signf(nx - px) * span, lo, hi)
		max_step = maxf(max_step, absf(nx - px))
		max_rise = maxf(max_rise, dy)

		var ny := snappedf(py - dy, TILE)
		_platform(nx, ny, w, false, z)

		# กับดัก: วางเป็นทางเลือกลวงที่ระดับใกล้กัน แต่คนละฝั่งกับเส้นทางจริง
		if rng.randf() < float(z["haz"]):
			var hw := maxi(2, w - 1)
			var hx := clampf(nx - dir * rng.randf_range(120.0, 200.0),
				float(WALL * TILE) + hw * TILE * 0.5,
				float((COLS - WALL) * TILE) - hw * TILE * 0.5)
			var hy := ny + snappedf(rng.randf_range(-30.0, 30.0), TILE)
			if absf(hx - nx) > float((w + hw) * TILE) * 0.5 + TILE:
				_platform(hx, hy, hw, true, z)

		px = nx
		py = ny

	# ชานพักสายตา: ยอดหอคอย
	_platform(float(SCREEN_W) * 0.5, snappedf(top_y + 80.0, TILE), 8, false, ZONES[4])


## source_id ของ TileSet = index ของโซน (0..4) เลือกจากแถวไทล์ที่กำลังวาง
func _src_at_cy(cy: int) -> int:
	return int(_zone_at(float(cy) * TILE)["id"]) - 1


## source ของโซนหนึ่งๆ โดยตรง
func _src_of(z: Dictionary) -> int:
	return int(z["id"]) - 1


## ชั้นที่เท่าไหร่ ณ ความสูง py (ใช้สูตรเดียวกับ cameraController)
func _level_at(py: float) -> int:
	return maxi(1, 1 + int(floor((float(SCREEN_H) - py) / float(SCREEN_H))))


func _zone_at(py: float) -> Dictionary:
	var lv := _level_at(py)
	var found: Dictionary = ZONES[0]
	for z in ZONES:
		if lv >= int(z["lv"]):
			found = z
	return found


## ระยะแนวนอนสูงสุดที่ยังลงจอดได้ ที่ความสูง dy — ใช้รากขาลงของสมการวิถี
func _reach(dy: float) -> float:
	var disc := JUMP_V * JUMP_V - 2.0 * GRAVITY * dy
	if disc < 0.0:
		return -1.0
	var t := (JUMP_V + sqrt(disc)) / GRAVITY
	return H_SPEED * t * SAFETY


func _platform(cx_px: float, cy_px: float, w: int, hazard: bool, z: Dictionary) -> void:
	var cx := int(round((cx_px - w * TILE * 0.5) / TILE))
	var cy := int(round(cy_px / TILE))
	cx = clampi(cx, WALL, COLS - WALL - w)

	for i in w:
		var t: Vector2i
		if w == 1:
			t = T_HAZ_1 if hazard else T_SAFE_1
		elif i == 0:
			t = T_HAZ_L if hazard else T_SAFE_L
		elif i == w - 1:
			t = T_HAZ_R if hazard else T_SAFE_R
		else:
			t = T_HAZ_M if hazard else T_SAFE_M
		map.set_cell(Vector2i(cx + i, cy), _src_of(z), t)

	var mid := Vector2(float(cx) * TILE + float(w * TILE) * 0.5, float(cy) * TILE)

	if hazard:
		haz_count += 1
		# R2: กับดักเปล่งแสงเย็นจากในตัวเอง ไม่มีแหล่งกำเนิดข้างบน
		_light(mid + Vector2(0, 6), z["cold"], float(z["e"]) * 0.8, 0.75)
		_decor(T_CRYSTAL_S, Vector2i(cx + w / 2, cy - 1))
	else:
		safe_count += 1
		# R2: แท่นจริงถูกส่องจากด้านบน — ไฟลอยเหนือแท่น 34 px
		_light(mid + Vector2(0, -34), z["safe"], float(z["e"]), 1.05)
		if rng.randf() < 0.35:
			_decor(T_RUBBLE, Vector2i(cx + rng.randi_range(0, maxi(0, w - 1)), cy - 1))
		_zone_feature(int(z["id"]), mid, w, cx, cy)


## อุปสรรคที่ทำให้แต่ละโซนเล่นไม่เหมือนกัน ไม่ใช่แค่เปลี่ยนสี
func _zone_feature(zone_id: int, mid: Vector2, w: int, cx: int, cy: int) -> void:
	match zone_id:
		1:	# รากที่จมน้ำ — หินเปียกลื่น ไถลออกขอบถ้ายืนเฉยๆ
			if rng.randf() < 0.35:
				_surface("ice", mid, w)
		2:	# หอจดหมายเหตุ — ชั้นกระดาษที่ยุบหลังเหยียบ (กลับมาใหม่ได้ เส้นทางจึงไม่ตัน)
			if rng.randf() < 0.28:
				_crumble(mid, w, cx, cy)
		3:	# เส้นเลือดเตาหลอม — ท่อไอเย็นพ่นเป็นจังหวะ อ่านจังหวะจากแสง
			if rng.randf() < 0.40:
				var side := 1.0 if rng.randf() < 0.5 else -1.0
				var vx := clampf(mid.x + side * float(w * TILE) * 0.5 + side * TILE,
					float((WALL + 1) * TILE), float((COLS - WALL - 1) * TILE))
				_vent(Vector2(vx, mid.y - TILE))
		5:	# ห้องตะเกียง — พื้นหิมะ ยืนแล้วขยับแนวนอนไม่ได้ ต้องกระโดดอย่างเดียว
			if rng.randf() < 0.45:
				_surface("snow", mid, w)
		# โซน 4 ไม่มีของวาง เพราะลมเป็นระบบรวมที่ WindManager คุมทั้งโซน


func _surface(mode: String, mid: Vector2, w: int) -> void:
	var area := Area2D.new()
	area.name = "%s%d" % [mode.capitalize(), hazards.get_child_count()]
	area.set_script(load("res://Scripts/Tower/SurfaceArea.gd"))
	area.set("mode", mode)
	area.position = mid + Vector2(0, -6)
	area.monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(float(w * TILE), 14.0)
	shape.shape = rect
	_own(area, hazards)
	_own(shape, area)


## แท่นยุบ: ไม่วางสไปรต์ทับ แต่มอบ "ช่องไทล์" ให้มันไปลบ/คืนเอง
## ภาพจึงตรงกับแท่นรอบข้างเป๊ะ และคอลลิชันหายไปจริงตอนยุบ
func _crumble(mid: Vector2, w: int, cx: int, cy: int) -> void:
	var node: Node2D = load("res://Entities/CrumblePlatform.tscn").instantiate()
	node.position = mid
	var cells: Array[Vector2i] = []
	var tiles: Array[Vector2i] = []
	var srcs: Array[int] = []
	for i in w:
		var cell := Vector2i(cx + i, cy)
		cells.append(cell)
		tiles.append(map.get_cell_atlas_coords(cell))
		srcs.append(map.get_cell_source_id(cell))
	node.set("cells", cells)
	node.set("tiles", tiles)
	node.set("sources", srcs)
	node.get_node("Trigger/CollisionShape2D").shape.size.x = float(w * TILE)
	_own(node, hazards)


func _vent(pos: Vector2) -> void:
	var node: Node2D = load("res://Entities/VentHazard.tscn").instantiate()
	node.position = pos
	node.set("phase", rng.randf())
	node.set("cycle", rng.randf_range(2.6, 3.6))
	_own(node, hazards)


func _light(pos: Vector2, col: Color, energy: float, tex_scale: float) -> void:
	var l := PointLight2D.new()
	l.name = "L%d" % lights.get_child_count()
	l.position = pos
	l.color = col
	l.energy = energy
	l.texture = load("res://Resources/ember_light.tres")
	l.texture_scale = tex_scale
	l.blend_mode = Light2D.BLEND_MODE_ADD
	l.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	l.range_z_min = 0
	l.range_z_max = 8
	_own(l, lights)


func _decor(tile: Vector2i, cell: Vector2i) -> void:
	# ของประดับวางเป็นไทล์บนแผนที่เดียวกัน (ไทล์แถว 3 ไม่มีคอลลิชัน)
	if map.get_cell_source_id(cell) == -1:
		map.set_cell(cell, _src_at_cy(cell.y), tile)


# ---------------------------------------------------------------- ตัวละคร/กล้อง

func _build_actors() -> void:
	var lighting: Node = load("res://Entities/LumenLighting.tscn").instantiate()
	_own(lighting, world)

	var king: Node2D = load("res://Entities/Wick.tscn").instantiate()
	king.name = "Wick"
	king.position = Vector2(240, float((ROWS - 1) * TILE) - 16.0)
	_own(king, world)

	var cam := Camera2D.new()
	cam.name = "Camera2D"
	cam.set_script(load("res://Scripts/cameraController.gd"))
	cam.position = Vector2(240, 180)
	cam.z_index = 6
	cam.z_as_relative = false
	cam.set("goalY", -float((LEVELS - 1) * SCREEN_H))
	_own(cam, world)

	var story: Node = load("res://Entities/StoryDirector.tscn").instantiate()
	_own(story, world)

	var culler := Node.new()
	culler.name = "LightCuller"
	culler.set_script(load("res://Scripts/Tower/LightCuller.gd"))
	_own(culler, world)

	var hud := CanvasLayer.new()
	hud.name = "HUD"
	hud.layer = 10
	_own(hud, world)
	_label(hud, "PercentageLabel", Vector2(12, 5), "0%")
	_label(hud, "LevelLabel", Vector2(12, 341), "")


func _label(parent: Node, nm: String, pos: Vector2, txt: String) -> void:
	var l := Label.new()
	l.name = nm
	l.position = pos
	l.size = Vector2(200, 15)
	l.text = txt
	_own(l, parent)


func _own(node: Node, parent: Node) -> void:
	parent.add_child(node)
	node.owner = world if node != world else null
