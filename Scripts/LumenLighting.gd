extends Node2D

## LUMEN — ตัวกำกับบรรยากาศตามความสูงของหอคอย
##
## หน้าที่:
##   1. ถือ Environment กลาง (glow / tonemap / color grading) และ CanvasModulate
##   2. สร้างไฟถ่าน (PointLight2D) ให้ผู้เล่นตอนรัน — ไม่ต้องแก้ King.tscn
##   3. ปลดล็อก light_mask ของเลเยอร์อาร์ตที่ต้องการให้โดนไฟ
##   4. เบลนด์ทุกอย่างข้างบนเข้าหา ZoneProfile ของโซนปัจจุบันเมื่อผู้เล่นข้ามโซน
##
## อ่านความสูงจาก Globals.currentLevel ซึ่ง cameraController.gd เป็นคนอัปเดต
## ให้อยู่ตอนไหนของ World ก็ได้ ขอแค่ player_path ชี้ถูก

const EMBER_NAME := "Ember"
const EMBER_TEXTURE := preload("res://Resources/ember_light.tres")

@export_group("โซน")
## เรียงจากล่างขึ้นบน — first_level ของแต่ละตัวต้องมากขึ้นเรื่อยๆ
@export var zones: Array[ZoneProfile] = []
## วินาทีที่ใช้เบลนด์ตอนข้ามโซน สั้นกว่า 1.5 จะรู้สึกเป็นการ "สวิตช์" ไม่ใช่การเดินทาง
@export_range(0.0, 10.0, 0.1) var blend_time: float = 2.4
## บังคับใช้โซนนี้ตลอดเวลาเพื่อเทสต์ภาพ (0 = ปิด, 1-5 = ล็อกโซน)
@export_range(0, 5, 1) var debug_force_zone: int = 0

@export_group("ไฟถ่านผู้เล่น")
@export var spawn_ember: bool = true
@export var player_path: NodePath = NodePath("../Wick")
@export var ember_offset: Vector2 = Vector2(0, 2)
## การกะพริบของเปลวไฟ 0 = นิ่งสนิท, 0.06 = ค่าที่ใช้จริง
@export_range(0.0, 0.3, 0.005) var ember_flicker: float = 0.06

@export_group("เลเยอร์ที่ให้ไฟส่องถึง")
## อาร์ตของเกมนี้ตั้ง light_mask = 0 ไว้แทบทุกโหนด ไฟ 2D จึงไม่มีผลกับอะไรเลย
## สคริปต์จะเปิด light_mask ให้เฉพาะเลเยอร์ที่ระบุตรงนี้ตอนรัน (ไม่แตะไฟล์ซีน)
## จงใจไม่ใส่ Backgrounds และ Parallax — ไม่งั้นไฟผู้เล่นจะไปสว่างพื้นหลังจนมิติความลึกพัง
@export var unmask_light: bool = true
@export var lit_layers: Array[NodePath] = [
	NodePath("../Middlegrounds"),
	NodePath("../Foregrounds"),
	NodePath("../Props"),
	NodePath("../Secret_walls"),
]

@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var tint: CanvasModulate = $CanvasModulate

var ember: PointLight2D
var _zone_index: int = -1
var _tween: Tween
var _flicker_t: float = 0.0
var _ember_base_energy: float = 1.0


func _ready() -> void:
	if zones.is_empty():
		push_warning("LumenLighting: ยังไม่ได้ผูก ZoneProfile — ระบบแสงปิดตัวเอง")
		set_process(false)
		return

	if unmask_light:
		_unmask_layers()
	if spawn_ember:
		_spawn_ember()

	if get_node_or_null("/root/Settings") != null:
		Settings.changed.connect(_on_settings_changed)

	_apply(_zone_for_level(_current_level()), 0.0)


func _process(delta: float) -> void:
	var wanted := _zone_for_level(_current_level())
	if wanted != _zone_index:
		_apply(wanted, blend_time)

	if ember != null:
		var wobble := 0.0
		if ember_flicker > 0.0:
			_flicker_t += delta
			# สองคลื่นความถี่ไม่ลงตัวกัน ทำให้จังหวะไม่ซ้ำจนหูจับได้
			wobble = sin(_flicker_t * 7.3) * 0.6 + sin(_flicker_t * 17.1) * 0.4
		ember.energy = _ember_base_energy * (1.0 + wobble * ember_flicker)


# ---------------------------------------------------------------- โซน

func _current_level() -> int:
	if debug_force_zone > 0:
		var i: int = clampi(debug_force_zone - 1, 0, zones.size() - 1)
		return zones[i].first_level
	return Globals.currentLevel


func _zone_for_level(level: int) -> int:
	var found := 0
	for i in zones.size():
		if level >= zones[i].first_level:
			found = i
		else:
			break
	return found


func _apply(index: int, dur: float) -> void:
	index = clampi(index, 0, zones.size() - 1)
	_zone_index = index

	var p: ZoneProfile = zones[index]
	var env: Environment = world_env.environment
	if env == null:
		push_warning("LumenLighting: WorldEnvironment ไม่มี Environment ผูกอยู่")
		return

	var glow_scale := _glow_scale()
	var target_glow: float = p.glow_intensity * glow_scale
	env.glow_enabled = glow_scale > 0.0
	_apply_glow_levels(env)

	if _tween != null and _tween.is_valid():
		_tween.kill()

	_ember_base_energy = p.ember_energy

	if dur <= 0.0:
		env.glow_intensity = target_glow
		env.glow_bloom = p.glow_bloom
		env.glow_hdr_threshold = p.glow_hdr_threshold
		env.adjustment_saturation = p.saturation
		env.adjustment_contrast = p.contrast
		tint.color = p.ambient
		if ember != null:
			ember.energy = p.ember_energy
			ember.texture_scale = p.ember_scale
			ember.color = p.ember_color
		return

	_tween = create_tween().set_parallel(true)
	_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(env, "glow_intensity", target_glow, dur)
	_tween.tween_property(env, "glow_bloom", p.glow_bloom, dur)
	_tween.tween_property(env, "glow_hdr_threshold", p.glow_hdr_threshold, dur)
	_tween.tween_property(env, "adjustment_saturation", p.saturation, dur)
	_tween.tween_property(env, "adjustment_contrast", p.contrast, dur)
	_tween.tween_property(tint, "color", p.ambient, dur)
	if ember != null:
		_tween.tween_property(self, "_ember_base_energy", p.ember_energy, dur)
		_tween.tween_property(ember, "texture_scale", p.ember_scale, dur)
		_tween.tween_property(ember, "color", p.ember_color, dur)


# ---------------------------------------------------------------- ไฟถ่าน

func _spawn_ember() -> void:
	var player := get_node_or_null(player_path)
	if player == null:
		push_warning("LumenLighting: หาผู้เล่นไม่เจอที่ %s — ข้ามไฟถ่าน" % player_path)
		return

	var existing := player.get_node_or_null(EMBER_NAME)
	if existing is PointLight2D:
		ember = existing
		return

	ember = PointLight2D.new()
	ember.name = EMBER_NAME
	ember.texture = EMBER_TEXTURE
	ember.blend_mode = Light2D.BLEND_MODE_ADD
	# เท็กซ์เจอร์ทั้งโปรเจกต์ใช้ Nearest ถ้าปล่อยไว้ขอบไฟจะเป็นบันไดหยัก
	ember.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	ember.shadow_enabled = false
	ember.position = ember_offset
	# กันไฟไปโดนเลเยอร์ที่อยู่คนละระดับความลึก (พื้นหลัง z<0, HUD z>8)
	ember.range_z_min = 0
	ember.range_z_max = 8
	player.add_child(ember)


# ---------------------------------------------------------------- light_mask

func _unmask_layers() -> void:
	for path in lit_layers:
		var root := get_node_or_null(path)
		if root == null:
			continue
		_unmask_recursive(root)


func _unmask_recursive(node: Node) -> void:
	if node is CanvasItem and node.light_mask == 0:
		node.light_mask = 1
	for child in node.get_children():
		_unmask_recursive(child)


# ---------------------------------------------------------------- คุณภาพแสงฟุ้ง

func _glow_scale() -> float:
	if get_node_or_null("/root/Settings") == null:
		return 1.0
	return Settings.glow_scale()


func _apply_glow_levels(env: Environment) -> void:
	if get_node_or_null("/root/Settings") == null:
		return
	Settings.apply_glow_levels(env)


func _on_settings_changed() -> void:
	_apply(_zone_index, 0.0)
