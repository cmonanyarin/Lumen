extends Node

## ปิดไฟที่อยู่ไกลจากกล้อง
##
## หอคอยเต็มมีไฟราว 250 ดวง ถ้าเปิดหมดพร้อมกันเฟรมเรตตกบนเครื่องสเปกกลาง
## ตัวนี้เปิดเฉพาะดวงที่อยู่ในระยะ margin หน้าจอรอบกล้อง ที่เหลือ visible = false
## (Light2D ที่ visible = false ไม่เข้าคิวเรนเดอร์เลย)

@export_range(1.0, 5.0, 0.1) var margin: float = 1.6
@export var lights_path: NodePath = NodePath("../Lights")
@export var camera_path: NodePath = NodePath("../Camera2D")

var _lights: Array[Node2D] = []
var _cam: Node2D
var _range: float = 0.0


func _ready() -> void:
	var root := get_node_or_null(lights_path)
	_cam = get_node_or_null(camera_path)
	if root == null or _cam == null:
		push_warning("LightCuller: หา Lights หรือ Camera2D ไม่เจอ — ปิดตัวเอง")
		set_process(false)
		return
	for c in root.get_children():
		if c is Node2D:
			_lights.append(c)
	_range = 360.0 * margin
	_update()


func _process(_delta: float) -> void:
	_update()


func _update() -> void:
	var y := _cam.global_position.y
	for l in _lights:
		l.visible = absf(l.global_position.y - y) < _range
