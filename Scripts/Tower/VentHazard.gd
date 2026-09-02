extends Node2D

## โซน 3 (เส้นเลือดเตาหลอม) — ท่อไอเย็นที่พ่นเป็นจังหวะ
##
## GDD R4: ไฟสว่างขึ้นเรื่อยๆ = นับถอยหลัง สว่างสุด = พ่น
## ผู้เล่นอ่านจังหวะจากแสงอย่างเดียว ไม่มีไอคอน ไม่มีตัวเลข
##
## โดนแล้วไม่ตาย แต่ผลักออกด้านข้างแรงพอที่จะทำให้ร่วง
## ซึ่งในเกมแนวนี้เจ็บกว่าการตายมาก

@export var cycle := 3.0				# วินาทีต่อรอบ
@export var blast := 0.6				# วินาทีที่ไอพ่นออกมา
@export var phase := 0.0				# เหลื่อมเฟส ท่อข้างกันจะได้ไม่พ่นพร้อมกัน
@export var push := Vector2(190.0, -120.0)

@onready var light: PointLight2D = $Light
@onready var jet: Area2D = $Jet
@onready var jet_sprite: Sprite2D = $Jet/Sprite2D

var _t := 0.0
var _base_energy := 1.0
var _firing := false


func _ready() -> void:
	_base_energy = light.energy
	_t = phase * cycle
	jet.monitoring = false
	jet_sprite.visible = false


func _physics_process(delta: float) -> void:
	_t = fmod(_t + delta, cycle)
	var charge := cycle - blast
	var should_fire := _t >= charge

	if should_fire:
		# ช่วงพ่น: สว่างสุดค้างไว้
		light.energy = _base_energy * 1.7
	else:
		# ช่วงชาร์จ: ไต่ความสว่างขึ้นเรื่อยๆ = นาฬิกาที่มองเห็น
		light.energy = _base_energy * lerpf(0.25, 1.5, pow(_t / charge, 1.8))

	if should_fire != _firing:
		_firing = should_fire
		jet.monitoring = should_fire
		jet_sprite.visible = should_fire

	if _firing:
		for b in jet.get_overlapping_bodies():
			if b.name == "Wick":
				_shove(b)


func _shove(king: Node) -> void:
	var dir := signf(king.global_position.x - global_position.x)
	if dir == 0.0:
		dir = 1.0
	king.velocity.x = dir * push.x
	king.velocity.y = minf(king.velocity.y, push.y)
	king.stunned = true
	king.currentState = king.state.FALLING
