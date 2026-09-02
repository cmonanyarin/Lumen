extends Control

## LUMEN — ฉากจบ
##
## บทดำเนินเอง ผู้เล่นดูอย่างเดียว ยกเว้นตอนท้ายที่กดกลับหน้าหลักได้
## ครึ่งแรกเป็นข้อความบนความมืด ครึ่งหลังคือภาพเมืองข้างล่างที่ทยอยติดไฟ
## ซึ่งเป็นการจ่ายคืนของทั้งเกม — ผู้เล่นเห็นหน้าต่างมืดมาตลอดทาง

const BEATS_DARK := ["end_01", "end_02", "end_03", "end_04", "end_05", "end_06"]
const BEATS_CITY := ["end_08", "end_09"]
const TITLE_SCENE := "res://Scenes/Title_scene.tscn"

@onready var caption: Label = $Caption
@onready var flash: ColorRect = $Flash
@onready var city: Node2D = $City
@onready var title_label: Label = $Title
@onready var sub_label: Label = $Sub
@onready var stats_label: Label = $Stats
@onready var prompt: Label = $Prompt

var _windows: Array[ColorRect] = []
var _can_exit := false


func _ready() -> void:
	caption.modulate.a = 0.0
	title_label.modulate.a = 0.0
	sub_label.modulate.a = 0.0
	stats_label.modulate.a = 0.0
	prompt.modulate.a = 0.0
	flash.color = Color(1, 1, 1, 0)
	_build_city()
	_play()


func _input(event: InputEvent) -> void:
	if _can_exit and event.is_action_pressed("jump"):
		Globals.titleIntroPlayed = true
		get_tree().change_scene_to_file(TITLE_SCENE)


# ---------------------------------------------------------------- ลำดับภาพ

func _play() -> void:
	await get_tree().create_timer(1.4).timeout

	for key in BEATS_DARK:
		await _say(Loc.t(key), 3.4)

	# ก้าวเข้าไป — จอขาววาบแล้วค้าง สร้างช่วงเงียบก่อนเปลี่ยนฉาก
	await _say(Loc.t("end_07"), 2.2)
	await _flash_white()

	# ตัดลงไปมองเมืองจากข้างบน
	city.modulate.a = 1.0
	await get_tree().create_timer(1.2).timeout

	for i in BEATS_CITY.size():
		_light_window(i)
		await _say(Loc.t(BEATS_CITY[i]), 2.6)

	# ที่เหลือติดไฟรัวขึ้นเรื่อยๆ
	for i in range(2, _windows.size()):
		_light_window(i)
		await get_tree().create_timer(maxf(0.06, 0.34 - i * 0.012)).timeout

	await get_tree().create_timer(1.0).timeout
	await _say(Loc.t("end_10"), 3.0)

	_show_title()


func _say(text: String, seconds: float) -> void:
	caption.text = text
	var tw := create_tween()
	tw.tween_property(caption, "modulate:a", 1.0, 0.9)
	tw.tween_interval(seconds)
	tw.tween_property(caption, "modulate:a", 0.0, 0.9)
	await tw.finished


func _flash_white() -> void:
	var tw := create_tween()
	tw.tween_property(flash, "color:a", 1.0, 1.6)
	tw.tween_interval(1.0)
	tw.tween_property(flash, "color:a", 0.0, 2.2)
	await tw.finished


func _show_title() -> void:
	title_label.text = Loc.t("end_title")
	sub_label.text = Loc.t("end_sub")
	stats_label.text = "%s     %s" % [
		Loc.t("end_stat_falls") % Globals.run_falls,
		Loc.t("end_stat_time") % Globals.run_time_text()]
	prompt.text = Loc.t("end_prompt")

	var tw := create_tween()
	tw.tween_property(title_label, "modulate:a", 1.0, 1.6)
	tw.tween_property(sub_label, "modulate:a", 1.0, 1.2)
	tw.tween_property(stats_label, "modulate:a", 0.75, 1.0)
	tw.tween_property(prompt, "modulate:a", 0.6, 0.8)
	await tw.finished
	_can_exit = true


# ---------------------------------------------------------------- เมืองข้างล่าง

## เมืองเป็นเงาตึกเรียงกัน แต่ละตึกมีหน้าต่างที่ยังดับอยู่
## ปั้นด้วยโค้ดเพราะเป็นรูปทรงเรียบๆ ไม่คุ้มที่จะทำเป็นอาร์ตแยก
func _build_city() -> void:
	city.modulate.a = 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 4114

	var x := 8.0
	while x < 472.0:
		var w := rng.randf_range(22.0, 46.0)
		var h := rng.randf_range(38.0, 104.0)
		var top := 360.0 - h
		_rect(city, Rect2(x, top, w, h), Color(0.05, 0.04, 0.10))
		# หน้าต่างในตึก
		var wy := top + 7.0
		while wy < 360.0 - 10.0:
			var wx := x + 5.0
			while wx < x + w - 7.0:
				var win := _rect(city, Rect2(wx, wy, 3, 4), Color(1.0, 0.78, 0.42))
				win.modulate.a = 0.0
				_windows.append(win)
				wx += 8.0
			wy += 10.0
		x += w + rng.randf_range(3.0, 9.0)

	_windows.shuffle()


func _rect(parent: Node, r: Rect2, col: Color) -> ColorRect:
	var cr := ColorRect.new()
	cr.color = col
	cr.position = r.position
	cr.size = r.size
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(cr)
	return cr


func _light_window(index: int) -> void:
	if index < 0 or index >= _windows.size():
		return
	create_tween().tween_property(_windows[index], "modulate:a", 1.0, 0.5)
