extends CanvasLayer

## LUMEN — ผู้กำกับเนื้อเรื่องระหว่างไต่
##
## หน้าที่:
##   1. โผล่บทขึ้นมาเมื่อผู้เล่นไปถึงชั้นที่กำหนด (ครั้งเดียวต่อรอบการเล่น)
##   2. นับจำนวนครั้งที่ตกและเวลาที่ใช้ เก็บไว้ให้ฉากจบเอาไปแสดง
##   3. ตัดไปฉากจบเมื่อถึงยอดหอคอย
##
## บทถูกผูกกับ "ชั้น" ไม่ใช่ Area2D เพราะผู้เล่นเกมแนวนี้เด้งขึ้นลงข้ามเส้นซ้ำๆ
## ถ้าใช้ Area2D บทจะเด้งซ้ำจนรำคาญ

const BEATS := {
	1: "story_01",
	2: "story_02",
	4: "story_03",
	6: "story_04",
	9: "story_05",
	13: "story_06",
	18: "story_07",
	22: "story_08",
	27: "story_09",
	32: "story_10",
	37: "story_11",
	41: "story_12",
}

const SUMMIT_LEVEL := 43
const ENDING_SCENE := "res://Scenes/Ending.tscn"

@export var fade_in := 1.2
@export var hold := 5.0
@export var fade_out := 1.6
@export var player_path: NodePath = NodePath("../Wick")

@onready var label: Label = $Caption

var _shown: Dictionary = {}
var _player: Node
var _was_splat := false
var _ending := false
var _tween: Tween


func _ready() -> void:
	label.modulate.a = 0.0
	label.text = ""
	_player = get_node_or_null(player_path)
	Globals.run_reset()
	if get_node_or_null("/root/Loc") != null:
		Loc.changed.connect(_on_lang_changed)


func _process(_delta: float) -> void:
	if _ending:
		return
	_track_falls()

	var lv: int = Globals.currentLevel
	Globals.run_best_level = maxi(Globals.run_best_level, lv)

	if lv >= SUMMIT_LEVEL:
		_go_to_ending()
		return

	if BEATS.has(lv) and not _shown.has(lv):
		_shown[lv] = true
		if Settings.show_story:
			_show(Loc.t(BEATS[lv]))


## นับการตกจากการที่ตัวละครเข้าสถานะ SPLAT (ตกแรงจนสตัน)
func _track_falls() -> void:
	if _player == null:
		return
	var splat: bool = _player.currentState == _player.state.SPLAT
	if splat and not _was_splat:
		Globals.run_falls += 1
	_was_splat = splat


func _show(text: String) -> void:
	label.text = text
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(label, "modulate:a", 1.0, fade_in)
	_tween.tween_interval(hold)
	_tween.tween_property(label, "modulate:a", 0.0, fade_out)


func _on_lang_changed() -> void:
	# เปลี่ยนภาษากลางเกม: บทที่ค้างอยู่บนจอเปลี่ยนตามทันที
	var lv: int = Globals.currentLevel
	if BEATS.has(lv) and label.modulate.a > 0.01:
		label.text = Loc.t(BEATS[lv])


func _go_to_ending() -> void:
	_ending = true
	Globals.run_time_ms = Time.get_ticks_msec() - Globals.run_start_ms
	set_process(false)
	get_tree().change_scene_to_file(ENDING_SCENE)
