extends Camera2D

"""
TODO
	FIX levelX going over 1
	LEVELLABEL FADE IN/OUT
"""

var target
var levelHeight = 360
var levelWidth = 480
var currentLevelY = 1.0
var currentLevelX = 1
var goalY = -15367
var percentageToEnd = 0
var _previouslvl = 0
#var _previousName = "Camp"
var currentName = ""


# LUMEN: ป้ายบอกสถานะย้ายไปอยู่บน CanvasLayer "HUD" แล้ว
# เพราะ CanvasModulate ของระบบแสงย้อมทุกอย่างที่อยู่เลเยอร์เดียวกับฉาก
@onready var levelLabel: Label = get_node_or_null("../HUD/LevelLabel")
@onready var percentageLabel: Label = get_node_or_null("../HUD/PercentageLabel")


func _ready():
	target = get_node("../Wick")
	if levelLabel:
		levelLabel.text = currentName

func _process(_delta):
	var target_y = int(abs(target.position.y - levelHeight))-16# feet pos
	var target_x = int(target.position.x - levelWidth)
	@warning_ignore("integer_division")
	var level_y = int(target_y / levelHeight) + 1
	@warning_ignore("integer_division")
	var level_x = int(target_x / levelWidth) + 1
	currentLevelY = level_y
	currentLevelX = level_x

	if _previouslvl != currentLevelY:
		#LEVEL CHANGED
		#print(WindManager.currentVelocity)
		Globals.currentLevel = currentLevelY
		currentName =  Globals.levelname(currentLevelY)
		if levelLabel:
			levelLabel.text = str(currentName)


	percentageToEnd = abs(((target.position.y-16)-levelHeight)/goalY)*100
	if percentageLabel:
		percentageLabel.text = str(percentageToEnd).pad_decimals(2) + "%"

	#SNAP CAMERA POSITION TO LEVEL
	self.position.y = levelHeight/2.0+(((currentLevelY * levelHeight)-levelHeight)*-1)
	self.position.x = levelWidth/2.0+(((currentLevelX*levelWidth)-levelWidth))

	_previouslvl = currentLevelY
