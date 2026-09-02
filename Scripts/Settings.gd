extends Node

## LUMEN — ค่าตั้งของผู้เล่น (autoload)
##
## เก็บที่ user://settings.cfg  โหลดตอนเปิดเกม เขียนตอนเปลี่ยนค่า
## ใครแก้ค่าให้เรียก apply_all() หรือ set_* แล้วสัญญาณ changed จะยิงเอง
##
## ปุ่มที่สำคัญที่สุดในหน้า Video คือ glow_quality — มันคือสวิตช์เดียว
## ที่พาเครื่องสเปกต่ำจาก 30 fps ไป 60 fps ได้ (GDD หัวข้อ 05)

signal changed

const PATH := "user://settings.cfg"
const SECTION := "lumen"

enum GlowQuality { OFF, LOW, HIGH }

const GLOW_SCALE := {
	GlowQuality.OFF: 0.0,
	GlowQuality.LOW: 0.6,
	GlowQuality.HIGH: 1.0,
}

## ปิด level 1 ทุกโหมด (ฟุ้งแคบเกินจนเห็นเป็นขอบ) · Low เหลือแค่รัศมีกลาง-กว้าง
const GLOW_LEVELS := {
	GlowQuality.OFF: {},
	GlowQuality.LOW: {4: 1.0, 5: 1.0},
	GlowQuality.HIGH: {2: 0.4, 3: 0.8, 4: 1.0, 5: 1.0, 6: 0.6},
}

enum WindowMode { WINDOWED_2X, MAXIMIZED, FULLSCREEN }

@export var language: String = "th"
@export var window_mode: int = WindowMode.MAXIMIZED
@export var show_story: bool = true
@export var show_intro: bool = true
@export var glow_quality: int = GlowQuality.HIGH
@export var screen_shake: float = 0.6
@export var master_volume: float = 1.0
@export var music_volume: float = 0.8
@export var sfx_volume: float = 1.0
@export var show_altitude: bool = false
@export var show_fall_count: bool = false

var _loaded := false


func _ready() -> void:
	load_settings()
	apply_audio()
	apply_window()


# ---------------------------------------------------------------- หน้าต่าง

func apply_window() -> void:
	# บนเว็บ ขนาดหน้าต่างถูกคุมโดย canvas ของเบราว์เซอร์
	# ถ้าไปสั่ง window_set_mode/size เอง canvas จะเพี้ยนหรือเกมค้างที่หน้าโหลด
	if OS.has_feature("web"):
		return
	match window_mode:
		WindowMode.FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		WindowMode.MAXIMIZED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		_:
			# 2 เท่าพอดีของ 480x360 — พิกเซลคมที่สุด ไม่มีการปัดเศษ
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(Vector2i(960, 720))
			var screen := DisplayServer.window_get_current_screen()
			var area := DisplayServer.screen_get_usable_rect(screen)
			DisplayServer.window_set_position(
				area.position + (area.size - Vector2i(960, 720)) / 2)


func set_window_mode(m: int) -> void:
	window_mode = clampi(m, WindowMode.WINDOWED_2X, WindowMode.FULLSCREEN)
	apply_window()
	save_settings()
	changed.emit()


# ---------------------------------------------------------------- แสงฟุ้ง

func glow_scale() -> float:
	return GLOW_SCALE.get(glow_quality, 1.0)


func apply_glow_levels(env: Environment) -> void:
	if env == null:
		return
	var levels: Dictionary = GLOW_LEVELS.get(glow_quality, {})
	for i in range(1, 8):
		env.set("glow_levels/%d" % i, float(levels.get(i, 0.0)))
	# ยกเกณฑ์ให้สูงขึ้นในโหมดประหยัด = พิกเซลเข้าเงื่อนไขฟุ้งน้อยลง = เบาลงจริง
	if glow_quality == GlowQuality.LOW:
		env.glow_hdr_threshold = maxf(env.glow_hdr_threshold, 1.1)


func set_glow_quality(q: int) -> void:
	glow_quality = clampi(q, GlowQuality.OFF, GlowQuality.HIGH)
	save_settings()
	changed.emit()


# ---------------------------------------------------------------- เสียง

func apply_audio() -> void:
	_set_bus("Master", master_volume)
	_set_bus("Music", music_volume)
	_set_bus("SFX", sfx_volume)


func _set_bus(bus_name: String, pct: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	# linear_to_db(0.0) คืน -inf แล้ว AudioServer จะพังเงียบๆ — ต้อง clamp เสมอ
	AudioServer.set_bus_mute(idx, pct <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(pct, 0.0001, 1.0)))


func set_volume(bus_name: String, pct: float) -> void:
	match bus_name:
		"Master": master_volume = clampf(pct, 0.0, 1.0)
		"Music": music_volume = clampf(pct, 0.0, 1.0)
		"SFX": sfx_volume = clampf(pct, 0.0, 1.0)
	apply_audio()
	save_settings()
	changed.emit()


# ---------------------------------------------------------------- เซฟ/โหลด

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		_loaded = true
		return
	language = cfg.get_value(SECTION, "language", language)
	window_mode = cfg.get_value(SECTION, "window_mode", window_mode)
	show_story = cfg.get_value(SECTION, "show_story", show_story)
	show_intro = cfg.get_value(SECTION, "show_intro", show_intro)
	glow_quality = cfg.get_value(SECTION, "glow_quality", glow_quality)
	screen_shake = cfg.get_value(SECTION, "screen_shake", screen_shake)
	master_volume = cfg.get_value(SECTION, "master_volume", master_volume)
	music_volume = cfg.get_value(SECTION, "music_volume", music_volume)
	sfx_volume = cfg.get_value(SECTION, "sfx_volume", sfx_volume)
	show_altitude = cfg.get_value(SECTION, "show_altitude", show_altitude)
	show_fall_count = cfg.get_value(SECTION, "show_fall_count", show_fall_count)
	_loaded = true


func save_settings() -> void:
	if not _loaded:
		return
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, "language", language)
	cfg.set_value(SECTION, "window_mode", window_mode)
	cfg.set_value(SECTION, "show_story", show_story)
	cfg.set_value(SECTION, "show_intro", show_intro)
	cfg.set_value(SECTION, "glow_quality", glow_quality)
	cfg.set_value(SECTION, "screen_shake", screen_shake)
	cfg.set_value(SECTION, "master_volume", master_volume)
	cfg.set_value(SECTION, "music_volume", music_volume)
	cfg.set_value(SECTION, "sfx_volume", sfx_volume)
	cfg.set_value(SECTION, "show_altitude", show_altitude)
	cfg.set_value(SECTION, "show_fall_count", show_fall_count)
	cfg.save(PATH)
