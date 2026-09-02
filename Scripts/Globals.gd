extends Node

const levelWidth = 480
const levelHeight = 360
var currentLevel = 1
# --- สถิติของรอบการเล่นปัจจุบัน ใช้แสดงตอนจบ ---
var run_falls := 0
var run_start_ms := 0
var run_time_ms := 0
var run_best_level := 1

var titleIntroPlayed = false		# skip the logo rise when coming back from Credits
var titleSelection = 0				# put the cursor back where it was
# หมุดชื่อสถานที่ในหอคอย LUMEN — คีย์คือชั้นที่เริ่มใช้ชื่อนั้น
# ตัวหนาคือหัวโซนทั้ง 5 ตาม GDD ที่เหลือคือหมุดย่อยให้ผู้เล่นรู้ว่าคืบหน้าอยู่
# ใช้อังกฤษเพราะฟอนต์พิกเซลในโปรเจกต์ไม่มีสระ/วรรณยุกต์ไทย และแบรนด์เกมก็อังกฤษอยู่แล้ว
const LANDMARKS := {
	1:  "THE DROWNED FOOT",		# โซน 1
	5:  "THE BROKEN STAIR",
	9:  "THE ARCHIVE",			# โซน 2
	13: "THE MAP ROOM",
	18: "THE FURNACE VEIN",		# โซน 3
	22: "COOLANT RUN",
	27: "THE CROWN OF GLASS",	# โซน 4
	32: "THE WIND GALLERY",
	37: "THE LANTERN",			# โซน 5
	43: "THE WICK",
}

func _ready():
	run_reset()


func run_reset() -> void:
	run_falls = 0
	run_start_ms = Time.get_ticks_msec()
	run_time_ms = 0
	run_best_level = 1


## แปลงมิลลิวินาทีเป็น ช:นน:ss สำหรับหน้าจบ
func run_time_text() -> String:
	var total := int(run_time_ms / 1000.0)
	return "%d:%02d:%02d" % [total / 3600, (total / 60) % 60, total % 60]

## คืนชื่อหมุดล่าสุดที่ผู้เล่นผ่านมาแล้ว — ป้ายจึงค้างไว้จนกว่าจะถึงหมุดถัดไป
## แทนที่จะกะพริบขึ้นแล้วหายเหมือนเวอร์ชันเดิม
func levelname(level):
	var best := ""
	var best_lv := -1
	for lv in LANDMARKS:
		if level >= lv and lv > best_lv:
			best_lv = lv
			best = LANDMARKS[lv]
	return best
		
#func _process(delta):
#	pass
