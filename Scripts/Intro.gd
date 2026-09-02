extends Control

## LUMEN — คัตซีนเปิดเรื่อง
##
## เล่นเฉพาะตอนกด "เริ่มการไต่ใหม่" ไม่ใช่ทุกครั้งที่เปิดเกม
## คนที่ตกแล้วเล่นใหม่จะได้ไม่ต้องทนดูซ้ำ (ปิดถาวรได้ใน Options)
##
## คำบรรยายเป็น Label ของ Godot ที่ดึงจาก Loc ไม่ได้เผาลงเฟรมวิดีโอ
## เพราะถ้าเผาลงไปจะแปลภาษาไม่ได้ตลอดกาล
##
## ถ้ายังไม่มีไฟล์ .ogv ซีนนี้ยังทำงานได้ปกติ — จะเล่นคำบรรยายบนภาพนิ่งแทน
## ทีมจึงเทสต์จังหวะข้อความได้ก่อนวิดีโอจะเสร็จ

const NEXT_SCENE := "res://Scenes/Tower.tscn"
const VIDEO_PATH := "res://Video/intro.ogv"

## คำบรรยาย: [คีย์ข้อความ, วินาทีที่เริ่ม, วินาทีที่ค้างอยู่]
## วิดีโอยาว 14.0 วิ (ต้นฉบับ 10 วิ ยืด 1.4 เท่าตอนแปลง)
## VideoStreamPlayer ค้างเฟรมสุดท้ายไว้หลังจบ ซึ่งคือท้องฟ้าว่างตรงที่ควรมียอดหอคอย
## บทที่ 3 จึงถูกวางไว้ตรงนั้นโดยตั้งใจ — ข้อความเรื่องคนที่ไม่เคยกลับลงมา
## อ่านบนความว่างเปล่าพอดี
const BEATS := [
	["intro_01", 1.4, 4.4],
	["intro_02", 7.4, 4.4],
	["intro_03", 15.0, 4.8],
]
const FADE := 1.0
const TAIL := 1.6						# เวลาเงียบหลังบทสุดท้ายก่อนตัดเข้าเกม

@onready var video: VideoStreamPlayer = $Video
@onready var caption: Label = $Caption
@onready var skip_hint: Label = $SkipHint
@onready var fader: ColorRect = $Fader
@onready var fallback: TextureRect = $Fallback

var _leaving := false
var _elapsed := 0.0


func _ready() -> void:
	caption.modulate.a = 0.0
	skip_hint.text = Loc.t("intro_skip")
	skip_hint.modulate.a = 0.0
	fader.color = Color(0, 0, 0, 1)

	var stream: VideoStream = load(VIDEO_PATH) if ResourceLoader.exists(VIDEO_PATH) else null
	if stream != null:
		video.stream = stream
		video.play()
		# ซ่อนภาพนิ่งสำรอง ไม่งั้นพอวิดีโอจบมันจะโผล่ขึ้นมาแทนจอดำ
		# ซึ่งทำลายจังหวะบทสุดท้ายที่ตั้งใจให้อยู่บนความมืด
		fallback.hide()
	else:
		# ไม่มีวิดีโอ: ใช้ภาพนิ่งที่วางไว้ข้างหลังแทน จังหวะข้อความยังเทสต์ได้
		video.hide()
		push_warning("Intro: ไม่พบ %s — เล่นคำบรรยายบนภาพนิ่งแทน" % VIDEO_PATH)

	create_tween().tween_property(fader, "color:a", 0.0, FADE)
	_run()


func _unhandled_input(event: InputEvent) -> void:
	if _leaving:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		_leave()
	elif event is InputEventJoypadButton and event.pressed:
		_leave()
	elif event is InputEventMouseButton and event.pressed:
		_leave()


func _process(delta: float) -> void:
	if _leaving:
		return
	_elapsed += delta
	# คำใบ้ "กดข้าม" โผล่หลังผ่านไป 2 วิ แล้วจางค้างไว้เบาๆ
	if _elapsed > 2.0 and skip_hint.modulate.a < 0.45:
		skip_hint.modulate.a = minf(skip_hint.modulate.a + delta * 0.5, 0.45)


func _run() -> void:
	for beat in BEATS:
		await _wait_until(float(beat[1]))
		if _leaving:
			return
		_say(Loc.t(beat[0]), float(beat[2]))

	var last: Array = BEATS[BEATS.size() - 1]
	await _wait_until(float(last[1]) + float(last[2]) + 1.0 + TAIL)
	if not _leaving:
		_leave()


## รอจนถึงวินาทีที่กำหนดนับจากเริ่มซีน — อิงเวลาสัมบูรณ์ ไม่ใช่ผลรวมของ timer
## ไม่งั้นความคลาดเคลื่อนจะสะสมจนคำบรรยายหลุดจากภาพ
func _wait_until(t: float) -> void:
	while _elapsed < t and not _leaving:
		await get_tree().process_frame


func _say(text: String, hold: float) -> void:
	caption.text = text
	var tw := create_tween()
	tw.tween_property(caption, "modulate:a", 1.0, 0.8)
	tw.tween_interval(hold)
	tw.tween_property(caption, "modulate:a", 0.0, 0.8)


func _leave() -> void:
	if _leaving:
		return
	_leaving = true
	set_process(false)
	if video.is_playing():
		video.stop()
	var tw := create_tween()
	tw.tween_property(fader, "color:a", 1.0, 0.6)
	await tw.finished
	get_tree().change_scene_to_file(NEXT_SCENE)
