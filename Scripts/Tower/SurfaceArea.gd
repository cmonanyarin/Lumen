extends Area2D

## พื้นผิวพิเศษ วางทับแท่นเพื่อเปลี่ยนการควบคุมของผู้เล่นในโซนนั้น
##
## ice  = โซน 1 หินเปียก ลื่น ไถลออกขอบ (King.onIce)
## snow = โซน 5 พื้นหิมะ ขยับแนวนอนตอนยืนไม่ได้ ต้องกระโดดอย่างเดียว (King.onSnow)
##
## เขียนใหม่แทนการใช้ Ice_Area/Snow_Area ของโปรเจกต์เดิม เพราะสองตัวนั้น
## ผูกสัญญาณไว้ในไฟล์ซีน ซึ่งตัวเจนเลเวลสร้างให้ไม่ได้

@export_enum("ice", "snow") var mode: String = "ice"


func _ready() -> void:
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)


func _on_enter(body: Node) -> void:
	if body.name != "Wick":
		return
	if mode == "ice":
		body.onIce = true
	else:
		body.onSnow = true


func _on_exit(body: Node) -> void:
	if body.name != "Wick":
		return
	if mode == "ice":
		body.onIce = false
	else:
		body.onSnow = false
