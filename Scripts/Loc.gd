extends Node

## LUMEN — ระบบภาษา (autoload)
##
## ใช้:  Loc.t("story_01")   คืนข้อความตามภาษาที่เลือกอยู่
## เปลี่ยนภาษา:  Loc.set_lang("en")  แล้วสัญญาณ changed จะยิงให้ UI รีเฟรชเอง
##
## เก็บทุกข้อความไว้ที่เดียว ไม่กระจายไปตามซีน เพราะเวลาเพิ่มภาษาที่สาม
## จะได้แก้ไฟล์เดียวจบ และหาข้อความที่ยังไม่ได้แปลได้ด้วย audit()

signal changed

const LANGS := ["th", "en"]
const LANG_NAMES := {"th": "ไทย", "en": "English"}

var lang: String = "th"

# ------------------------------------------------------------------------------
# th = ไทย · en = อังกฤษ
# คีย์ story_XX คือบทที่โผล่ระหว่างไต่ · end_XX คือฉากจบ · ที่เหลือคือ UI
# ------------------------------------------------------------------------------
const STRINGS := {
	# ---------- เมนู ----------
	"menu_continue": {"th": "ไต่ต่อ", "en": "CONTINUE"},
	"menu_new": {"th": "เริ่มการไต่ใหม่", "en": "NEW ASCENT"},
	"menu_options": {"th": "ตั้งค่า", "en": "OPTIONS"},
	"menu_credits": {"th": "เครดิต", "en": "CREDITS"},
	"menu_quit": {"th": "ออกจากเกม", "en": "QUIT"},
	"menu_back": {"th": "กลับ", "en": "BACK"},

	# ---------- ตั้งค่า ----------
	"opt_title": {"th": "ตั้งค่า", "en": "OPTIONS"},
	"opt_tab_video": {"th": "ภาพ", "en": "VIDEO"},
	"opt_tab_audio": {"th": "เสียง", "en": "AUDIO"},
	"opt_tab_game": {"th": "เกม", "en": "GAME"},
	"opt_language": {"th": "ภาษา", "en": "Language"},
	"opt_window": {"th": "ขนาดหน้าต่าง", "en": "Window size"},
	"opt_window_2x": {"th": "หน้าต่าง 2 เท่า (960x720)", "en": "Windowed 2x (960x720)"},
	"opt_window_max": {"th": "ขยายเต็มหน้าต่าง", "en": "Maximized"},
	"opt_window_full": {"th": "เต็มจอ", "en": "Fullscreen"},
	"opt_glow": {"th": "คุณภาพแสงฟุ้ง", "en": "Glow quality"},
	"opt_glow_off": {"th": "ปิด", "en": "Off"},
	"opt_glow_low": {"th": "ต่ำ", "en": "Low"},
	"opt_glow_high": {"th": "สูง", "en": "High"},
	"opt_glow_hint": {"th": "ตัวกินสเปกมากที่สุดในเกม ลดตัวนี้ก่อนถ้าเฟรมตก", "en": "The heaviest effect in the game. Lower this first if the framerate drops."},
	"opt_shake": {"th": "จอสั่น", "en": "Screen shake"},
	"opt_master": {"th": "เสียงรวม", "en": "Master"},
	"opt_music": {"th": "เพลง", "en": "Music"},
	"opt_sfx": {"th": "เอฟเฟกต์", "en": "Sound effects"},
	"opt_altitude": {"th": "แสดงระดับความสูง", "en": "Show altitude"},
	"opt_falls": {"th": "นับจำนวนครั้งที่ตก", "en": "Count falls"},
	"opt_story": {"th": "แสดงบทระหว่างไต่", "en": "Story captions"},
	"opt_on": {"th": "เปิด", "en": "On"},
	"opt_off": {"th": "ปิด", "en": "Off"},

	"opt_intro": {"th": "วิดีโอเปิดเรื่อง", "en": "Intro cutscene"},

	# ---------- วิดีโอเปิดเรื่อง ----------
	"intro_01": {
		"th": "โลกนี้ไม่เคยมีดวงอาทิตย์\nมีแต่ลูเมน ดวงไฟที่ถูกจุดค้างไว้บนยอดหอคอย",
		"en": "This world never had a sun.\nOnly Lumen — a light kept burning at the top of the tower."},
	"intro_02": {
		"th": "สามร้อยปีมันส่องให้ทั้งเมือง\nแล้ววันหนึ่งมันก็ดับ",
		"en": "For three hundred years it lit the whole city.\nThen one day it went out."},
	"intro_03": {
		"th": "ทุกปีมีคนหนึ่งคนได้ถ่านไฟติดมือขึ้นไป\nสี่สิบคนแล้วที่ไม่มีใครกลับลงมา",
		"en": "Each year one person is given an ember and sent up.\nForty of them. Not one has come back down."},
	"intro_skip": {"th": "กดปุ่มใดก็ได้เพื่อข้าม", "en": "Press any key to skip"},

	# ---------- บทระหว่างไต่ ----------
	"story_01": {
		"th": "โลกนี้ไม่เคยมีดวงอาทิตย์\nมีแต่ลูเมน ดวงไฟที่ถูกจุดค้างไว้บนยอดหอคอย",
		"en": "This world never had a sun.\nOnly Lumen — a light kept burning at the top of the tower."},
	"story_02": {
		"th": "สามร้อยปีมันส่องให้ทั้งเมือง\nแล้ววันหนึ่งมันก็ดับ",
		"en": "For three hundred years it lit the whole city.\nThen one day it went out."},
	"story_03": {
		"th": "ตะเกียงใบนี้สลักไว้ว่า #12 — 340 เมตร\nมีคนมาถึงตรงนี้ก่อนคุณ",
		"en": "This lantern is carved: #12 — 340m.\nSomeone reached this far before you."},
	"story_04": {
		"th": "บันไดพวกนี้มีคนสร้างไว้ให้คนที่ตามมา\nพวกเขาคิดว่าจะมีคนตามมาอีกหลายคน",
		"en": "Someone built these stairs for whoever came next.\nThey thought many more would come."},
	"story_05": {
		"th": "ภาพบนผนังเล่าวันที่ลูเมนถูกจุดครั้งแรก\nคุณเห็นได้เท่าที่ไฟในมือส่องถึง",
		"en": "The mural tells of the night Lumen was first lit.\nYou see only as much as your ember reaches."},
	"story_06": {
		"th": "มีชื่อสลักอยู่สี่สิบชื่อ\nไม่มีชื่อไหนถูกขีดฆ่าว่ากลับลงมาแล้ว",
		"en": "Forty names are carved here.\nNot one is crossed out as having returned."},
	"story_07": {
		"th": "เตาหลอมยังเดินอยู่ ทั้งที่ไม่มีใครดูแลมาสามร้อยปี\nมันไม่ได้รอลูเมน มันรอเชื้อเพลิง",
		"en": "The furnace still runs, untended for three centuries.\nIt was never waiting for Lumen. It was waiting for fuel."},
	"story_08": {
		"th": "ไอเย็นพ่นตามจังหวะไฟกะพริบ\nนับให้ดี ไฟสว่างสุดเมื่อไหร่คือตอนที่มันพ่น",
		"en": "The vents fire in time with the blinking light.\nCount carefully — brightest means it is about to blow."},
	"story_09": {
		"th": "ตะเกียงใบสุดท้ายเขียนว่า #38 — 1,612 เมตร\nเหนือจากนี้ไม่มีใครเคยไปถึง",
		"en": "The last lantern reads: #38 — 1,612m.\nAbove this, no one has ever been."},
	"story_10": {
		"th": "ลมแรงจนแทบยืนไม่อยู่\nแต่ข้างล่าง หน้าต่างในเมืองเริ่มติดไฟทีละดวง",
		"en": "The wind nearly takes you off the ledge.\nBut below, the city's windows are lighting up one by one."},
	"story_11": {
		"th": "ลมหยุดสนิท เสียงหายไปหมด\nเหลือแต่เสียงหายใจของคุณกับเสียงไฟในมือ",
		"en": "The wind stops. Every sound is gone.\nOnly your breathing, and the ember in your hand."},
	"story_12": {
		"th": "ถ่านในมือแทบไม่เหลือแสงแล้ว\nแต่ยอดหอคอยอยู่ตรงหน้า",
		"en": "The ember in your hand has almost nothing left.\nBut the top of the tower is right there."},

	# ---------- ฉากจบ ----------
	"end_01": {
		"th": "คุณมาถึงห้องตะเกียง",
		"en": "You reach the lantern chamber."},
	"end_02": {
		"th": "เตาเปิดอยู่ ว่างเปล่า\nไม่มีเชื้อเพลิงเหลืออยู่เลยแม้แต่ชิ้นเดียว",
		"en": "The cradle stands open. Empty.\nThere is no fuel left in it at all."},
	"end_03": {
		"th": "มีแต่ที่ว่าง\nขนาดเท่าคนหนึ่งคน",
		"en": "Only a space.\nExactly the size of a person."},
	"end_04": {
		"th": "ผู้ถือไส้ตะเกียงสี่สิบคนก่อนหน้าคุณ\nไม่มีใครหายไประหว่างทาง",
		"en": "The forty wick-bearers before you\nnever went missing on the climb."},
	"end_05": {
		"th": "พวกเขามาถึงที่นี่ทุกคน\nและทุกคนเข้าใจว่าต้องทำอะไร",
		"en": "Every one of them arrived here.\nAnd every one understood what had to be done."},
	"end_06": {
		"th": "แสงที่คุณเห็นตลอดทางขึ้นมา\nคือพวกเขา",
		"en": "The light you climbed past all the way up\nwas them."},
	"end_07": {
		"th": "คุณก้าวเข้าไป",
		"en": "You step in."},
	"end_08": {
		"th": "ข้างล่าง หน้าต่างดวงแรกติดไฟ",
		"en": "Below, the first window lights."},
	"end_09": {
		"th": "แล้วก็ดวงที่สอง",
		"en": "Then the second."},
	"end_10": {
		"th": "ผู้ถือไส้ตะเกียงคนที่สี่สิบเอ็ด",
		"en": "The forty-first wick-bearer."},
	"end_title": {"th": "LUMEN", "en": "LUMEN"},
	"end_sub": {"th": "ไต่สู่แสงสว่าง", "en": "Climb toward the Light"},
	"end_stat_falls": {"th": "ตกลงมา %d ครั้ง", "en": "%d falls"},
	"end_stat_time": {"th": "ใช้เวลา %s", "en": "Time %s"},
	"end_prompt": {"th": "กดปุ่มกระโดดเพื่อกลับสู่หน้าหลัก", "en": "Press jump to return to the title"},
}


func _ready() -> void:
	if get_node_or_null("/root/Settings") != null:
		lang = Settings.language
	if not LANGS.has(lang):
		lang = "th"


func t(key: String) -> String:
	var row: Dictionary = STRINGS.get(key, {})
	if row.is_empty():
		push_warning("Loc: ไม่มีคีย์ '%s'" % key)
		return key
	return row.get(lang, row.get("en", key))


func set_lang(new_lang: String) -> void:
	if not LANGS.has(new_lang) or new_lang == lang:
		return
	lang = new_lang
	if get_node_or_null("/root/Settings") != null:
		Settings.language = lang
		Settings.save_settings()
	changed.emit()


func next_lang() -> void:
	set_lang(LANGS[(LANGS.find(lang) + 1) % LANGS.size()])


func lang_name() -> String:
	return LANG_NAMES.get(lang, lang)


## หาคีย์ที่แปลไม่ครบ — เรียกจากคอนโซลตอนเพิ่มข้อความใหม่
func audit() -> void:
	for key in STRINGS:
		for l in LANGS:
			if not STRINGS[key].has(l) or String(STRINGS[key][l]).is_empty():
				print("Loc: ขาด '%s' ในภาษา %s" % [key, l])
