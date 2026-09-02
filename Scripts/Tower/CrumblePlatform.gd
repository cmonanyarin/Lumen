extends Node2D

## โซน 2 (หอจดหมายเหตุ) — ชั้นกระดาษปลอมที่ยุบหลังเหยียบ
##
## ตัวนี้ไม่มีสไปรต์และคอลลิชันของตัวเอง มันสั่ง "ลบไทล์" ออกจาก CollisionMap
## โดยตรงแล้วเอากลับมาทีหลัง วิธีนี้ดีกว่าการวางสไปรต์ทับ เพราะ:
##   - ภาพตรงกับแท่นรอบข้างเป๊ะ ไม่ต้องยืดสไปรต์ให้พอดีความกว้าง
##   - คอลลิชันหายไปจริง ไม่ใช่มีสองชั้นซ้อนกันจนยุบแล้วยังยืนได้
##
## กติกาตาม GDD: ตัวแท่นดู "ปลอดภัย" ทุกอย่าง (ขอบทองเหมือนกัน)
## แต่ไฟที่ส่องมันเป็นสีเย็น — ผู้เล่นที่อ่านไวยากรณ์แสงเป็นจะรู้ตัวก่อน
## และพอเหยียบ ไฟจะสั่นถี่ขึ้นเรื่อยๆ เป็นการนับถอยหลังที่มองเห็นได้

signal crumbled

## เวลานับจากเหยียบจนยุบ — ห้ามต่ำกว่า 1.17 วินาที
## ชาร์จกระโดดเต็มใช้ maxPower(2) / jumpPowerStep(3.0) = 0.667 วิ
## และถ้าลงแรงจนสตัน (SplatTimer) เสียอีก 0.5 วิ ก่อนจะเริ่มชาร์จได้
## ค่าเดิม 0.45 ทำให้ชาร์จได้สูงสุดแค่ 67% กระโดดเต็มแรงจากแท่นยุบเป็นไปไม่ได้เลย
@export var delay := 1.25
@export var respawn := 3.5					# วินาทีจนกลับมา (0 = หายถาวร)
@export var map_path: NodePath = NodePath("../../CollisionMap")
@export var cells: Array[Vector2i] = []		# ช่องบนแผนที่ที่ตัวนี้ดูแล
@export var tiles: Array[Vector2i] = []		# พิกัดในอัตลาสของแต่ละช่อง ใช้ตอนคืนค่า
@export var sources: Array[int] = []		# source_id (= โซน) ของแต่ละช่อง ไม่งั้นคืนไทล์ผิดโซน

@onready var light: PointLight2D = $Light

var _map: TileMapLayer
var _armed := false
var _down := false
var _base_energy := 1.0
var _t := 0.0


func _ready() -> void:
	_base_energy = light.energy
	_map = get_node_or_null(map_path)
	if _map == null:
		push_warning("CrumblePlatform: หา CollisionMap ไม่เจอที่ %s" % map_path)
		set_process(false)
		return
	$Trigger.body_entered.connect(_on_touch)


func _process(delta: float) -> void:
	if not _armed or _down:
		return
	_t += delta
	# ความถี่การสั่นไต่ขึ้นตามเวลาที่เหลือน้อยลง = นาฬิกาที่อ่านด้วยตา
	var p := clampf(_t / delay, 0.0, 1.0)
	light.energy = _base_energy * (1.0 + sin(_t * lerpf(6.0, 34.0, p)) * 0.55 * p)


func _on_touch(node: Node) -> void:
	if _armed or _down or node.name != "Wick":
		return
	# ต้องเป็นการ "ลงมาเหยียบ" จริงเท่านั้น
	# ถ้าผู้เล่นกระโดดพุ่งขึ้นผ่านใต้แท่น Area2D ก็ยิง body_entered เหมือนกัน
	# ปล่อยไว้แท่นจะยุบทิ้งทั้งที่ยังไม่มีใครแตะ แล้วพอวนกลับมาจะเจอช่องว่างโดยไม่รู้สาเหตุ
	if node.velocity.y < -10.0:
		return
	if node.global_position.y > global_position.y:
		return
	_armed = true
	_t = 0.0
	await get_tree().create_timer(delay).timeout
	if is_instance_valid(self):
		_collapse()


func _collapse() -> void:
	_down = true
	_armed = false
	for c in cells:
		_map.erase_cell(c)
	light.energy = _base_energy * 0.15
	crumbled.emit()

	if respawn <= 0.0:
		return
	await get_tree().create_timer(respawn).timeout
	if not is_instance_valid(self):
		return
	_restore()


func _restore() -> void:
	for i in cells.size():
		if i < tiles.size():
			_map.set_cell(cells[i], sources[i] if i < sources.size() else 0, tiles[i])
	light.energy = _base_energy
	_down = false
	_t = 0.0
