extends Node2D

# ─────────────────────────────────────────────────────────────
#  EDIT HERE - ชื่อสมาชิกในกลุ่ม
#  เพิ่ม/ลบบรรทัดได้อิสระ จอจะจัดกึ่งกลางให้เอง
#  แก้ได้ทั้งในไฟล์นี้ หรือเลือก node "Credits_scene" แล้วแก้ใน Inspector
# ─────────────────────────────────────────────────────────────
@export var members: PackedStringArray = [
	"673380353-1  นายอชิรวิทย์ ศรีชา",
	"673380521-6  นายธีรปรัชญ์ สาขาคำ",
	"673380344-2  นายวีรภัทร โพธิ์สิงห์",
	"673380531-3  นายวิษณุ รีชัยพิชิตกุล",
]
@export var based_on := ""
@export var original_game := ""
@export var engine_line := "Made with Godot Engine 4"
# ─────────────────────────────────────────────────────────────

const LINE_HEIGHT := 20
const NAMES_TOP := 96

var openSound := preload("res://Audio/gui_sfx/menu_open.wav")
var backSound := preload("res://Audio/gui_sfx/SelectC.wav")

var leaving := false


func _ready():
	$Names.text = "\n".join(members)
	# grow the label box so long member lists stay centred instead of clipping
	$Names.offset_top = NAMES_TOP
	$Names.offset_bottom = NAMES_TOP + LINE_HEIGHT * max(members.size(), 1)
	$sfxplayer.stream = openSound
	$sfxplayer.play()


func _input(event):
	if leaving or event == null:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("jump"):
		leaving = true
		$sfxplayer.stream = backSound
		$sfxplayer.play()
		await $sfxplayer.finished
		get_tree().change_scene_to_file("res://Scenes/Title_scene.tscn")
