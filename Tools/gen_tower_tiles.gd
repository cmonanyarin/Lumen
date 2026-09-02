extends SceneTree

## เจนอัตลาสไทล์ "ชั่วคราว" ของหอคอย LUMEN
##
## รันด้วย:  godot --headless --path <โปรเจกต์> --script res://Tools/gen_tower_tiles.gd
##
## ผลลัพธ์: res://Sprites/Tower/tower_tiles.png  ขนาด 160x80 = 8x4 ไทล์ ไทล์ละ 20x20
##
## ตอนคุณมีอาร์ตจริงแล้ว: วาดทับไฟล์นี้ให้ตรงช่องเดิม แล้ว TileSet/เลเวลทั้งหอคอย
## จะใช้ได้ทันทีโดยไม่ต้องแก้อะไรเลย ตารางช่องอยู่ท้ายไฟล์นี้

const TS := 20
const COLS := 8
const ROWS := 4
const OUT := "res://Sprites/Tower/tower_tiles.png"

# พาเลตต์ LUMEN — ดึงจาก BG.png และโลโก้
const STONE      := Color8(0x3D, 0x31, 0x60)
const STONE_LIT  := Color8(0x6E, 0x59, 0x9E)
const STONE_DARK := Color8(0x1E, 0x18, 0x33)
const MORTAR     := Color8(0x2A, 0x21, 0x45)
const GOLD       := Color8(0xC9, 0xA2, 0x27)
const GOLD_LIT   := Color8(0xF0, 0xD0, 0x80)
const SAFE_BODY  := Color8(0x4A, 0x3B, 0x72)
const HAZ_BODY   := Color8(0x2E, 0x44, 0x5E)
const HAZ_LIT    := Color8(0x9F, 0xD8, 0xF0)
const CRYSTAL    := Color8(0xB9, 0x8C, 0xFF)
const CRYSTAL_LIT := Color8(0xE6, 0xD2, 0xFF)
const WINDOW     := Color8(0x6E, 0x4F, 0xC8)
const CLEAR      := Color(0, 0, 0, 0)

var img: Image


func _initialize() -> void:
	img = Image.create_empty(COLS * TS, ROWS * TS, false, Image.FORMAT_RGBA8)
	img.fill(CLEAR)

	# ---- แถว 0: หินโครงสร้าง (ผนัง/พื้นหอคอย) ----
	_stone(0, 0, false, false, false)          # 0,0 เนื้อหินล้วน
	_stone(1, 0, true, false, false)           # 1,0 ขอบบน
	_stone(2, 0, false, true, false)           # 2,0 ขอบซ้าย
	_stone(3, 0, false, false, true)           # 3,0 ขอบขวา
	_stone(4, 0, true, true, false)            # 4,0 มุมบนซ้าย
	_stone(5, 0, true, false, true)            # 5,0 มุมบนขวา
	_backwall(6, 0)                            # 6,0 ผนังหลังของปล่อง (ชั้นหลัง ไม่มีคอลลิชัน)
	_pillar(7, 0)                              # 7,0 เสา

	# ---- แถว 1: แท่นปลอดภัย ขอบทอง (R1 อุ่น = จริง) ----
	_ledge(0, 1, SAFE_BODY, GOLD, GOLD_LIT, true, false)
	_ledge(1, 1, SAFE_BODY, GOLD, GOLD_LIT, false, false)
	_ledge(2, 1, SAFE_BODY, GOLD, GOLD_LIT, false, true)
	_ledge(3, 1, SAFE_BODY, GOLD, GOLD_LIT, true, true)

	# ---- แถว 2: แท่นกับดัก ขอบเย็น (R1 เย็น = โกหก) ----
	_ledge(0, 2, HAZ_BODY, HAZ_LIT.darkened(0.45), HAZ_LIT, true, false)
	_ledge(1, 2, HAZ_BODY, HAZ_LIT.darkened(0.45), HAZ_LIT, false, false)
	_ledge(2, 2, HAZ_BODY, HAZ_LIT.darkened(0.45), HAZ_LIT, false, true)
	_ledge(3, 2, HAZ_BODY, HAZ_LIT.darkened(0.45), HAZ_LIT, true, true)

	# ---- แถว 3: ของประดับ (ไม่มีคอลลิชัน) ----
	_window(0, 3)
	_crystal(1, 3, 5)
	_crystal(2, 3, 8)
	_rubble(3, 3)
	_band(4, 3)

	var dir := DirAccess.open("res://Sprites")
	if dir and not dir.dir_exists("Tower"):
		dir.make_dir("Tower")

	var err := img.save_png(OUT)
	print("GEN: ", OUT, " err=", err, " size=", img.get_size())
	quit()


# ---------------------------------------------------------------- ตัวช่วยวาด

func _px(x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)

func _rect(tx: int, ty: int, x: int, y: int, w: int, h: int, c: Color) -> void:
	for j in h:
		for i in w:
			_px(tx * TS + x + i, ty * TS + y + j, c)

func _fill(tx: int, ty: int, c: Color) -> void:
	_rect(tx, ty, 0, 0, TS, TS, c)


func _stone(tx: int, ty: int, top: bool, left: bool, right: bool) -> void:
	_fill(tx, ty, STONE)
	# ร่องปูนแบบก่ออิฐสลับแถว ให้ผนังไม่เรียบจนดูเป็นบล็อกเปล่า
	_rect(tx, ty, 0, 9, TS, 1, MORTAR)
	_rect(tx, ty, 9, 0, 1, 9, MORTAR)
	_rect(tx, ty, 4, 10, 1, 10, MORTAR)
	_rect(tx, ty, 15, 10, 1, 10, MORTAR)
	if top:
		_rect(tx, ty, 0, 0, TS, 2, STONE_LIT)
		_rect(tx, ty, 0, 2, TS, 1, STONE_LIT.darkened(0.25))
	if left:
		_rect(tx, ty, 0, 0, 1, TS, STONE_LIT.darkened(0.35))
	if right:
		_rect(tx, ty, TS - 1, 0, 1, TS, STONE_DARK)


## ผนังหลังของปล่องหอคอย — ต้องเห็นเป็นก่ออิฐ ไม่ใช่ดำทึบ ไม่งั้นฉากจะว่างเปล่า
func _backwall(tx: int, ty: int) -> void:
	_fill(tx, ty, STONE_DARK)
	_rect(tx, ty, 0, 9, TS, 1, STONE_DARK.lightened(0.16))
	_rect(tx, ty, 9, 0, 1, 9, STONE_DARK.lightened(0.16))
	_rect(tx, ty, 4, 10, 1, 10, STONE_DARK.lightened(0.16))
	_rect(tx, ty, 15, 10, 1, 10, STONE_DARK.lightened(0.16))


func _pillar(tx: int, ty: int) -> void:
	_fill(tx, ty, STONE_DARK)
	_rect(tx, ty, 3, 0, 14, TS, STONE)
	_rect(tx, ty, 3, 0, 2, TS, STONE_LIT)
	_rect(tx, ty, 15, 0, 2, TS, STONE_DARK)
	_rect(tx, ty, 3, 9, 14, 1, MORTAR)


## แท่นยืน: ขอบบนคือเส้นสว่าง 2 px = สัญญาณว่าเหยียบได้ (GDD R2)
func _ledge(tx: int, ty: int, body: Color, trim: Color, trim_lit: Color, cap_l: bool, cap_r: bool) -> void:
	_fill(tx, ty, CLEAR)
	_rect(tx, ty, 0, 0, TS, 13, body)
	_rect(tx, ty, 0, 0, TS, 2, trim_lit)
	_rect(tx, ty, 0, 2, TS, 1, trim)
	_rect(tx, ty, 0, 11, TS, 2, body.darkened(0.4))
	# ชายห้อยใต้แท่น ทำให้อ่านความหนาได้จากเงา
	_rect(tx, ty, 2, 13, 3, 3, body.darkened(0.55))
	_rect(tx, ty, 15, 13, 3, 3, body.darkened(0.55))
	if cap_l:
		_rect(tx, ty, 0, 0, 2, 13, trim)
	if cap_r:
		_rect(tx, ty, TS - 2, 0, 2, 13, trim)


func _window(tx: int, ty: int) -> void:
	_fill(tx, ty, STONE_DARK)
	_rect(tx, ty, 5, 3, 10, 15, WINDOW.darkened(0.55))
	_rect(tx, ty, 6, 5, 8, 13, WINDOW)
	_rect(tx, ty, 8, 7, 4, 9, WINDOW.lightened(0.45))
	_rect(tx, ty, 4, 2, 12, 1, GOLD)
	_rect(tx, ty, 4, 2, 1, 16, GOLD.darkened(0.3))
	_rect(tx, ty, 15, 2, 1, 16, GOLD.darkened(0.3))


func _crystal(tx: int, ty: int, w: int) -> void:
	_fill(tx, ty, CLEAR)
	var cx := TS / 2
	var h := 16
	for j in h:
		var half: int = maxi(1, int(round(float(w) * 0.5 * (1.0 - float(j) / float(h)))))
		for i in range(cx - half, cx + half):
			var c := CRYSTAL if i > cx - half + 1 else CRYSTAL_LIT
			_px(tx * TS + i, ty * TS + (TS - 1 - j), c)
	_rect(tx, ty, cx - 1, TS - h, 1, h - 2, CRYSTAL_LIT)


func _rubble(tx: int, ty: int) -> void:
	_fill(tx, ty, CLEAR)
	_rect(tx, ty, 2, 15, 6, 5, STONE)
	_rect(tx, ty, 2, 15, 6, 1, STONE_LIT)
	_rect(tx, ty, 10, 17, 5, 3, STONE)
	_rect(tx, ty, 10, 17, 5, 1, STONE_LIT)
	_rect(tx, ty, 16, 16, 3, 4, STONE_DARK)


## แถบทองคาดผนัง ใช้เป็นเส้นบอกระดับความสูงทุกๆ กี่ชั้น
func _band(tx: int, ty: int) -> void:
	_fill(tx, ty, STONE)
	_rect(tx, ty, 0, 6, TS, 8, GOLD.darkened(0.45))
	_rect(tx, ty, 0, 6, TS, 2, GOLD)
	_rect(tx, ty, 0, 12, TS, 2, GOLD.darkened(0.65))


# ---------------------------------------------------------------- ตารางช่อง
#
#        col 0        col 1       col 2       col 3       col 4    ...
# row 0  หินล้วน      หินขอบบน    หินขอบซ้าย  หินขอบขวา   มุมบนซ้าย  มุมบนขวา / หินเงา / เสา
# row 1  แท่นปลอดภัย ปลายซ้าย · กลาง · ปลายขวา · แท่นเดี่ยว
# row 2  แท่นกับดัก  ปลายซ้าย · กลาง · ปลายขวา · แท่นเดี่ยว
# row 3  หน้าต่าง · คริสตัลเล็ก · คริสตัลใหญ่ · เศษหิน · แถบทอง
