extends Node2D

enum item {START, OPTIONS, CREDITS, QUIT}

const REVEAL_DELAY := 3.5					# logo has finished rising by then
const DIM := Color(0.72, 0.66, 0.82, 1)	# tinted rather than faded - the artwork behind is busy
const LIT := Color(1, 1, 1, 1)

var confirmSound := preload("res://Audio/gui_sfx/menu_confirm.wav")
var moveSound := preload("res://Audio/gui_sfx/selectA.wav")

var selected := item.START
var accepting_input := false
var entries: Array = []

@onready var selector = $Selector
@onready var blinkTimer = $Selector/Timer
@onready var menusfx = $menusfx


func _ready():
	entries = [$Menu/Start, $Menu/Options, $Menu/Credits, $Menu/Quit]
	$Menu.visible = false
	selector.visible = false
	selected = clampi(Globals.titleSelection, 0, entries.size() - 1)

	$AnimationPlayer.play("Logo rise")
	if Globals.titleIntroPlayed:
		# returning from Credits - jump straight to the end of the rise
		$AnimationPlayer.seek(REVEAL_DELAY, true)
	else:
		Globals.titleIntroPlayed = true
		await get_tree().create_timer(REVEAL_DELAY).timeout

	$Menu.visible = true
	blinkTimer.start()
	accepting_input = true
	refresh()


func refresh():
	for i in entries.size():
		entries[i].modulate = LIT if i == selected else DIM
	selector.position.y = entries[selected].position.y


func _input(event):
	if not accepting_input or event == null:
		return
	if event.is_action_pressed("up"):
		move(-1)
	elif event.is_action_pressed("down"):
		move(1)
	elif event.is_action_pressed("jump"):
		confirm()


func move(dir: int):
	selected = wrapi(selected + dir, 0, entries.size())
	Globals.titleSelection = selected
	menusfx.stream = moveSound
	menusfx.play()
	refresh()


func confirm():
	accepting_input = false
	blinkTimer.wait_time = blinkTimer.wait_time / 8
	selector.visible = true
	menusfx.stream = confirmSound
	menusfx.play()
	await menusfx.finished

	match selected:
		item.START:
			$musicplayer.stop()
			# คัตซีนเล่นเฉพาะตอนเริ่มไต่ใหม่ และเฉพาะเมื่อผู้เล่นยังไม่ได้ปิดไว้
			if Settings.show_intro:
				get_tree().change_scene_to_file("res://Scenes/Intro.tscn")
			else:
				get_tree().change_scene_to_file("res://Scenes/Tower.tscn")
		item.OPTIONS:
			get_tree().change_scene_to_file("res://Scenes/Options.tscn")
		item.CREDITS:
			get_tree().change_scene_to_file("res://Scenes/Credits_scene.tscn")
		item.QUIT:
			get_tree().quit()


func _on_Timer_timeout():
	selector.visible = !selector.visible
