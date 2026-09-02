extends Control

## LUMEN — หน้าตั้งค่า
##
## ใช้รูปแบบเดียวกับเมนูหลัก: ขึ้น/ลง เลือกหัวข้อ · ซ้าย/ขวา เปลี่ยนค่า · กระโดด/ESC ออก
## จงใจไม่ใช้สไลเดอร์กับดรอปดาวน์ เพราะเกมนี้ต้องเล่นด้วยจอยได้ 100% โดยไม่ต้องแตะเมาส์
## และการเปลี่ยนค่าทุกอย่างมีผลทันที ไม่มีปุ่ม "ยืนยัน"
##
## แถวถูกสร้างด้วยโค้ด ไม่ได้วางในซีน เพราะข้อความเปลี่ยนตามภาษา
## ถ้าวางเป็นโหนดตายตัวจะต้องมาไล่แก้ทุกจุดเวลาเพิ่มภาษา

const TITLE_SCENE := "res://Scenes/Title_scene.tscn"
const ROW_H := 19.0
const TOP := 62.0
const LABEL_X := 74.0
const VALUE_X := 268.0

const DIM := Color(0.70, 0.65, 0.82, 1)
const LIT := Color(1, 1, 1, 1)
const GOLD := Color(0.94, 0.82, 0.45, 1)

enum Row { LANG, WINDOW, GLOW, SHAKE, MASTER, MUSIC, SFX, INTRO, STORY, ALTITUDE, FALLS, BACK }

var selected: int = Row.LANG
var _names: Array[Label] = []
var _values: Array[Label] = []

@onready var header: Label = $Header
@onready var hint: Label = $Hint
@onready var rows: Control = $Rows
@onready var sfx: AudioStreamPlayer = $Sfx

var move_sound := preload("res://Audio/gui_sfx/selectA.wav")
var confirm_sound := preload("res://Audio/gui_sfx/menu_confirm.wav")


func _ready() -> void:
	for i in Row.size():
		_names.append(_make_label(LABEL_X, TOP + i * ROW_H, 200.0, HORIZONTAL_ALIGNMENT_LEFT))
		_values.append(_make_label(VALUE_X, TOP + i * ROW_H, 150.0, HORIZONTAL_ALIGNMENT_LEFT))
	Loc.changed.connect(refresh)
	refresh()


func _make_label(x: float, y: float, w: float, align: int) -> Label:
	var l := Label.new()
	l.position = Vector2(x, y)
	l.size = Vector2(w, ROW_H)
	l.horizontal_alignment = align
	l.label_settings = $Proto.label_settings
	rows.add_child(l)
	return l


# ---------------------------------------------------------------- อินพุต

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("up"):
		_move(-1)
	elif event.is_action_pressed("down"):
		_move(1)
	elif event.is_action_pressed("left"):
		_change(-1)
	elif event.is_action_pressed("right"):
		_change(1)
	elif event.is_action_pressed("jump"):
		if selected == Row.BACK:
			_leave()
		else:
			_change(1)
	elif event.is_action_pressed("pause"):
		_leave()


func _move(dir: int) -> void:
	selected = wrapi(selected + dir, 0, Row.size())
	_play(move_sound)
	refresh()


func _leave() -> void:
	_play(confirm_sound)
	Settings.save_settings()
	Globals.titleIntroPlayed = true
	get_tree().change_scene_to_file(TITLE_SCENE)


func _play(stream: AudioStream) -> void:
	sfx.stream = stream
	sfx.play()


# ---------------------------------------------------------------- เปลี่ยนค่า

func _change(dir: int) -> void:
	match selected:
		Row.LANG:
			Loc.set_lang(Loc.LANGS[wrapi(Loc.LANGS.find(Loc.lang) + dir, 0, Loc.LANGS.size())])
		Row.WINDOW:
			if OS.has_feature("web"):
				return
			Settings.set_window_mode(wrapi(Settings.window_mode + dir, 0, 3))
		Row.GLOW:
			Settings.set_glow_quality(wrapi(Settings.glow_quality + dir, 0, 3))
		Row.SHAKE:
			Settings.screen_shake = clampf(Settings.screen_shake + dir * 0.1, 0.0, 1.0)
			Settings.save_settings()
		Row.MASTER:
			Settings.set_volume("Master", Settings.master_volume + dir * 0.1)
		Row.MUSIC:
			Settings.set_volume("Music", Settings.music_volume + dir * 0.1)
		Row.SFX:
			Settings.set_volume("SFX", Settings.sfx_volume + dir * 0.1)
		Row.INTRO:
			Settings.show_intro = not Settings.show_intro
			Settings.save_settings()
		Row.STORY:
			Settings.show_story = not Settings.show_story
			Settings.save_settings()
		Row.ALTITUDE:
			Settings.show_altitude = not Settings.show_altitude
			Settings.save_settings()
		Row.FALLS:
			Settings.show_fall_count = not Settings.show_fall_count
			Settings.save_settings()
		Row.BACK:
			_leave()
			return
	_play(move_sound)
	refresh()


# ---------------------------------------------------------------- แสดงผล

func refresh() -> void:
	header.text = Loc.t("opt_title")

	var labels := {
		Row.LANG: "opt_language", Row.WINDOW: "opt_window", Row.GLOW: "opt_glow",
		Row.SHAKE: "opt_shake", Row.MASTER: "opt_master", Row.MUSIC: "opt_music",
		Row.SFX: "opt_sfx", Row.INTRO: "opt_intro", Row.STORY: "opt_story",
		Row.ALTITUDE: "opt_altitude",
		Row.FALLS: "opt_falls", Row.BACK: "menu_back",
	}
	for i in Row.size():
		_names[i].text = Loc.t(labels[i])
		_values[i].text = _value_text(i)
		var on := i == selected
		_names[i].modulate = GOLD if on else DIM
		_values[i].modulate = LIT if on else DIM

	hint.text = Loc.t("opt_glow_hint") if selected == Row.GLOW else ""


func _value_text(row: int) -> String:
	match row:
		Row.LANG:
			return "< %s >" % Loc.lang_name()
		Row.WINDOW:
			if OS.has_feature("web"):
				return "—"			# เบราว์เซอร์คุมขนาดเอง ปรับจากในเกมไม่ได้
			return "< %s >" % Loc.t(["opt_window_2x", "opt_window_max", "opt_window_full"][Settings.window_mode])
		Row.GLOW:
			return "< %s >" % Loc.t(["opt_glow_off", "opt_glow_low", "opt_glow_high"][Settings.glow_quality])
		Row.SHAKE:
			return _bar(Settings.screen_shake)
		Row.MASTER:
			return _bar(Settings.master_volume)
		Row.MUSIC:
			return _bar(Settings.music_volume)
		Row.SFX:
			return _bar(Settings.sfx_volume)
		Row.INTRO:
			return "< %s >" % Loc.t("opt_on" if Settings.show_intro else "opt_off")
		Row.STORY:
			return "< %s >" % Loc.t("opt_on" if Settings.show_story else "opt_off")
		Row.ALTITUDE:
			return "< %s >" % Loc.t("opt_on" if Settings.show_altitude else "opt_off")
		Row.FALLS:
			return "< %s >" % Loc.t("opt_on" if Settings.show_fall_count else "opt_off")
	return ""


## แถบระดับแบบข้อความ อ่านง่ายกว่าตัวเลขเปอร์เซ็นต์บนจอ 480x360
func _bar(v: float) -> String:
	var filled := int(round(clampf(v, 0.0, 1.0) * 10.0))
	return "%s%s %d%%" % ["|".repeat(filled), ".".repeat(10 - filled), filled * 10]
