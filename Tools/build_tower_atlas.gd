extends SceneTree

## ประกอบอัตลาสไทล์ของหอคอยจากอาร์ตดิบ — หนึ่งแผ่นต่อหนึ่งโซน
##
## รันด้วย:  godot --headless --path <โปรเจกต์> --script res://Tools/build_tower_atlas.gd
##
## ผลลัพธ์: res://Sprites/Tower/tower_tiles_z1.png ... _z5.png  (แผ่นละ 160x80)
##          และ tower_tiles.png ซึ่งเป็นสำเนาของโซน 1 ไว้ให้ Entity อ้างของประดับ
##
## ทั้ง 5 แผ่นมีผังช่องเหมือนกันเป๊ะ ต่างกันแค่ "แถว 0" ที่เป็นเนื้อผนังของโซนนั้น
## แถว 1-3 (แท่นปลอดภัย / แท่นกับดัก / ของประดับ) ใช้ร่วมกันทุกโซนโดยตั้งใจ:
## ขอบทองคือสัญญาณ "เหยียบได้" ของทั้งเกม ถ้าเปลี่ยนตามโซนผู้เล่นต้องเรียนกติกาใหม่ทุกโซน
##
## ค่าครอปวัดจากไฟล์จริง ไม่ได้กะเอา — เจนอาร์ตใหม่แล้วองค์ประกอบขยับต้องวัดใหม่

const SRC := "D:/Gamedev/project game 2d/"
const OUT_DIR := "res://Sprites/Tower/"
const TS := 20
const AW := 8 * TS
const AH := 4 * TS

## ผนังประจำโซน เรียงจากชั้นล่างขึ้นบน
const ZONE_WALLS := [
	"รากที่จมน้ำ.png",
	"หอจดหมายเหตุ.png",
	"เส้นเลือดเตาหลอม.png",
	"มงกุฎแก้ว.png",
	"ห้องตะเกียง.png",
]

const F_SAFE := "แท่นปลอดภัย ขอบทอง.png"
const F_HAZ := "แท่นกับดัก (แสงเย็น).png"
const F_CRY := "คริสตัล.png"
const F_WIN := "หน้าต่างโกธิค.png"
const F_BAND := "แถบทองคาดผนัง (หมุดบอกความสูงทุก 5 ชั้น).png"

var atlas: Image
var shared: Image			# แถว 1-3 ที่ใช้ร่วมกันทุกโซน สร้างครั้งเดียว


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	shared = Image.create_empty(AW, AH, false, Image.FORMAT_RGBA8)
	shared.fill(Color(0, 0, 0, 0))
	atlas = shared
	_do_ledges()
	_do_decor()

	for i in ZONE_WALLS.size():
		atlas = Image.create_empty(AW, AH, false, Image.FORMAT_RGBA8)
		atlas.fill(Color(0, 0, 0, 0))
		atlas.blit_rect(shared, Rect2i(0, TS, AW, AH - TS), Vector2i(0, TS))
		_do_walls(ZONE_WALLS[i])
		var path := "%stower_tiles_z%d.png" % [OUT_DIR, i + 1]
		print("BUILD: ", path, " err=", atlas.save_png(path), "  <- ", ZONE_WALLS[i])
		if i == 0:
			atlas.save_png(OUT_DIR + "tower_tiles.png")
	quit()


# ---------------------------------------------------------------- ผนังประจำโซน

func _do_walls(fname: String) -> void:
	var wall := _load(fname)
	wall.resize(80, 80, Image.INTERPOLATE_LANCZOS)
	var stone := _sub(wall, 0, 0, TS, TS)

	_lift(stone, 0.27)											# ดูหมายเหตุด้านล่าง
	_put(stone, 0, 0)											# 0,0 หินล้วน
	_put(_edge(stone, true, false, false), 1, 0)				# 1,0 ขอบบน
	_put(_edge(stone, false, true, false), 2, 0)				# 2,0 ขอบซ้าย
	_put(_edge(stone, false, false, true), 3, 0)				# 3,0 ขอบขวา
	_put(_edge(stone, true, true, false), 4, 0)					# 4,0 มุมบนซ้าย
	_put(_edge(stone, true, false, true), 5, 0)					# 5,0 มุมบนขวา

	# ผนังหน้าของแต่ละโซนสว่างไม่เท่ากันมาก (ห้องสมุดกับเตาหลอมเข้ากว่าโซนอื่นเยอะ)
	# ถ้าคูณด้วยค่าคงที่ โซนเข้มจะกลายเป็นดำสนิทและฉากดูว่างเปล่า
	# จึงวัดความสว่างเฉลี่ยจริงแล้วดันขึ้นให้ถึงพื้นขั้นต่ำ — โซนที่สว่างพออยู่แล้วไม่ถูกแตะ
	# 6,0 ผนังหลัง — ผูกความสว่างกับผนังหน้าของโซนเดียวกัน ไม่ใช่ค่าตายตัว
	# ค่าตายตัวทำให้ห้องตะเกียงที่ผนังขาวโพลนมีปล่องดำสนิทอยู่ตรงกลาง ซึ่งผิดธีม
	# ส่วน clamp ล่างกันไม่ให้โซนที่อาร์ตเข้ามากอย่างเตาหลอมกลายเป็นดำจนมองไม่เห็นลาย
	var front_v := _mean_v(stone)
	var back := _sub(wall, TS * 2, TS, TS, TS)
	_retarget(back, clampf(front_v * 0.45, 0.14, 0.45))
	_put(back, 6, 0)

	# 7,0 เสา — ปั้นจากเนื้อผนังของโซนเอง โทนจึงตรงกันเสมอ
	var pillar := _sub(wall, TS, 0, TS, TS)
	for y in TS:
		for x in TS:
			var c := pillar.get_pixel(x, y)
			if x < 3 or x > 16:
				c = c.darkened(0.55)
			elif x < 5:
				c = c.lightened(0.28)
			elif x > 14:
				c = c.darkened(0.3)
			pillar.set_pixel(x, y, c)
	_put(pillar, 7, 0)


## ดันความสว่างเฉลี่ยขึ้นให้ถึงพื้นขั้นต่ำ ถ้าสว่างพอแล้วไม่แตะ
func _lift(img: Image, floor_v: float) -> void:
	var m := _mean_v(img)
	if m >= floor_v or m <= 0.001:
		return
	_scale_rgb(img, floor_v / m)


## ปรับความสว่างเฉลี่ยให้ตรงเป้าหมาย ทั้งขึ้นและลง
func _retarget(img: Image, target_v: float) -> void:
	var m := _mean_v(img)
	if m <= 0.001:
		return
	_scale_rgb(img, target_v / m)


func _mean_v(img: Image) -> float:
	var total := 0.0
	var n := 0
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.5:
				total += c.v
				n += 1
	return total / float(maxi(n, 1))


## คูณ RGB ตรงๆ เพื่อรักษาเฉดสีของโซน — darkened()/lightened() จะดันไปทางดำ/ขาว
func _scale_rgb(img: Image, k: float) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			img.set_pixel(x, y, Color(
				minf(c.r * k, 1.0), minf(c.g * k, 1.0), minf(c.b * k, 1.0), c.a))


func _edge(src: Image, top: bool, left: bool, right: bool) -> Image:
	var img := _sub(src, 0, 0, TS, TS)
	if top:
		for x in TS:
			img.set_pixel(x, 0, img.get_pixel(x, 0).lightened(0.5))
			img.set_pixel(x, 1, img.get_pixel(x, 1).lightened(0.34))
			img.set_pixel(x, 2, img.get_pixel(x, 2).lightened(0.14))
	if left:
		for y in TS:
			img.set_pixel(0, y, img.get_pixel(0, y).lightened(0.26))
	if right:
		for y in TS:
			img.set_pixel(TS - 1, y, img.get_pixel(TS - 1, y).darkened(0.4))
	return img


# ---------------------------------------------------------------- แท่น (ใช้ร่วม)

func _do_ledges() -> void:
	# ฮาโลเรืองแสงที่ AI ใส่มาอยู่ในชั้นอัลฟาต่ำ ตัดด้วยเกณฑ์ a>0.5 ได้สะอาด
	var safe := _load(F_SAFE)
	_key_alpha(safe, 0.5)
	var s := _sub(safe, 9, 384, 1516, 214)
	s.resize(5 * TS, 14, Image.INTERPOLATE_LANCZOS)
	_slice_ledge(s, 14, 1)

	# แท่นกับดักพื้นหลังเป็นดำทึบ ไม่มีอัลฟา ต้องคีย์ด้วยความสว่าง
	var haz := _load(F_HAZ)
	_key_black(haz, 0.10)
	var z := _sub(haz, 18, 357, 1531, 310)
	z.resize(5 * TS, TS, Image.INTERPOLATE_LANCZOS)
	_slice_ledge(z, TS, 2)


func _slice_ledge(strip: Image, h: int, row: int) -> void:
	var l := _cell(strip, 0, h)
	var m := _cell(strip, 2, h)
	var r := _cell(strip, 4, h)
	_put(l, 0, row)
	_put(m, 1, row)
	_put(r, 2, row)
	var one := Image.create_empty(TS, TS, false, Image.FORMAT_RGBA8)
	one.fill(Color(0, 0, 0, 0))
	one.blit_rect(l, Rect2i(0, 0, TS / 2, TS), Vector2i(0, 0))
	one.blit_rect(r, Rect2i(TS / 2, 0, TS / 2, TS), Vector2i(TS / 2, 0))
	_put(one, 3, row)


func _cell(strip: Image, index: int, h: int) -> Image:
	var out := Image.create_empty(TS, TS, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	out.blit_rect(strip, Rect2i(index * TS, 0, TS, h), Vector2i(0, 0))
	return out


# ---------------------------------------------------------------- ของประดับ (ใช้ร่วม)

func _do_decor() -> void:
	var win := _load(F_WIN)
	win.resize(TS, TS, Image.INTERPOLATE_LANCZOS)
	_put(win, 0, 3)

	var cry := _load(F_CRY)
	_key_alpha(cry, 0.5)
	_put(_fit_object(cry, _bbox(cry, 0, 560), 13), 1, 3)
	_put(_fit_object(cry, _bbox(cry, 560, cry.get_width()), TS), 2, 3)

	var band := _load(F_BAND)
	var b := _sub(band, 0, 336, 341, 340)
	b.resize(TS, TS, Image.INTERPOLATE_LANCZOS)
	_put(b, 4, 3)

	# เศษหิน: ตัดก้อนจากผนังโซน 1 มาวางชิดล่าง
	var wall := _load(ZONE_WALLS[0])
	wall.resize(80, 80, Image.INTERPOLATE_LANCZOS)
	var rub := Image.create_empty(TS, TS, false, Image.FORMAT_RGBA8)
	rub.fill(Color(0, 0, 0, 0))
	rub.blit_rect(wall, Rect2i(40, 40, 14, 5), Vector2i(2, 15))
	rub.blit_rect(wall, Rect2i(20, 60, 8, 3), Vector2i(11, 17))
	_put(rub, 3, 3)


func _fit_object(src: Image, box: Rect2i, max_h: int) -> Image:
	var out := Image.create_empty(TS, TS, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	if box.size.x <= 0 or box.size.y <= 0:
		return out
	var piece := _sub(src, box.position.x, box.position.y, box.size.x, box.size.y)
	var scale := minf(float(TS) / float(box.size.x), float(max_h) / float(box.size.y))
	var w := maxi(1, int(round(box.size.x * scale)))
	var h := maxi(1, int(round(box.size.y * scale)))
	piece.resize(w, h, Image.INTERPOLATE_LANCZOS)
	out.blit_rect(piece, Rect2i(0, 0, w, h), Vector2i((TS - w) / 2, TS - h))
	return out


# ---------------------------------------------------------------- ตัวช่วย

func _load(fname: String) -> Image:
	var img := Image.load_from_file(SRC + fname)
	if img == null:
		printerr("BUILD: โหลดไม่ได้ ", fname)
		quit(1)
	img.convert(Image.FORMAT_RGBA8)
	return img


func _sub(src: Image, x: int, y: int, w: int, h: int) -> Image:
	return src.get_region(Rect2i(x, y, w, h))


func _put(img: Image, tx: int, ty: int) -> void:
	atlas.blit_rect(img, Rect2i(0, 0, TS, TS), Vector2i(tx * TS, ty * TS))


func _key_alpha(img: Image, threshold: float) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a < threshold:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				c.a = 1.0
				img.set_pixel(x, y, c)


func _key_black(img: Image, threshold: float) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			img.set_pixel(x, y, Color(0, 0, 0, 0) if c.v < threshold else Color(c.r, c.g, c.b, 1.0))


func _bbox(img: Image, x_from: int, x_to: int) -> Rect2i:
	var x0 := x_to
	var y0 := img.get_height()
	var x1 := -1
	var y1 := -1
	for y in img.get_height():
		for x in range(x_from, mini(x_to, img.get_width())):
			if img.get_pixel(x, y).a > 0.5:
				x0 = mini(x0, x); y0 = mini(y0, y)
				x1 = maxi(x1, x); y1 = maxi(y1, y)
	if x1 < 0:
		return Rect2i(0, 0, 0, 0)
	return Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1)
