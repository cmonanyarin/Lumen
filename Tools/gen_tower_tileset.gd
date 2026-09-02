extends SceneTree

## สร้าง TileSet ของหอคอยจากอัตลาสที่ gen_tower_tiles.gd เจนไว้
## รันด้วย:  godot --headless --path <โปรเจกต์> --script res://Tools/gen_tower_tileset.gd
##
## แยกเป็นสคริปต์เพราะรูปทรงคอลลิชันต่อไทล์เขียนมือใน .tres แล้วพลาดง่ายมาก
## ถ้าเปลี่ยนอาร์ตแต่ช่องเหมือนเดิม ไม่ต้องรันซ้ำ

const TEX_FMT := "res://Sprites/Tower/tower_tiles_z%d.png"
const ZONES := 5
const OUT := "res://Resources/Tower/tower_tileset.tres"
const TS := 20

# ไทล์ที่กินเต็มช่อง (ผนัง/พื้นหอคอย)
const SOLID := [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
	Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0),
	Vector2i(4, 3),
]
# แท่นยืน — คอลลิชันเฉพาะครึ่งบน 13 px ให้ตรงกับที่ตาเห็น
const LEDGE := [
	Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1),
	Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2),
]
# ของประดับ ไม่มีคอลลิชัน
const DECOR := [Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3)]


func _initialize() -> void:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TS, TS)
	ts.add_physics_layer(0)
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 1)

	var half := float(TS) * 0.5
	var full := PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half),
		Vector2(half, half), Vector2(-half, half)])
	var top := PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half),
		Vector2(half, -half + 13.0), Vector2(-half, -half + 13.0)])

	# หนึ่ง source ต่อหนึ่งโซน — source_id = index ของโซน (0..4)
	# ผังช่องเหมือนกันทุก source ตัวเจนเลเวลจึงเปลี่ยนแค่ source_id ไม่ต้องแตะพิกัดไทล์
	for i in ZONES:
		var path := TEX_FMT % (i + 1)
		var tex: Texture2D = load(path)
		if tex == null:
			printerr("GEN: โหลด ", path, " ไม่ได้ — รัน build_tower_atlas.gd ก่อน")
			quit(1)
			return
		var src := TileSetAtlasSource.new()
		src.texture = tex
		src.texture_region_size = Vector2i(TS, TS)
		# ต้องผูก source เข้า TileSet ก่อนสร้างไทล์ ไม่งั้น TileData ยังไม่รู้จัก physics layer
		ts.add_source(src, i)
		for c in SOLID:
			_make(src, c, full)
		for c in LEDGE:
			_make(src, c, top)
		for c in DECOR:
			_make(src, c, PackedVector2Array())

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://Resources/Tower"))
	var err := ResourceSaver.save(ts, OUT)
	print("GEN: ", OUT, " err=", err, "  sources=", ts.get_source_count())
	quit()


func _make(src: TileSetAtlasSource, coord: Vector2i, poly: PackedVector2Array) -> void:
	src.create_tile(coord)
	if poly.is_empty():
		return
	var td := src.get_tile_data(coord, 0)
	td.add_collision_polygon(0)
	td.set_collision_polygon_points(0, 0, poly)
