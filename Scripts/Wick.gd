extends CharacterBody2D

"""
TODO


Ice inertia and movement multipliers need to be checked how they compare vs the original

charge state can get stuck if sliding over edge on ice

convert splat from y vel to moveInfo y

"""

const levelWidth = 480										#
const levelHeight = 360										#
var grounded := false										#
var onSlope := false										#
var onIce := false											#
var onSnow := false											#
var iceInertia := 0.05										# No idea how accurate, friction probably better term
var stunned : = true 										# Is the player stunned by hitting a wall mid jump
var noClip := false											# Debug cheat
var noCipSpeed : int = levelHeight*2						#
enum state {IDLE,WALKING,CHARGING,JUMPING,FALLING,SPLAT}	#
@export var currentState = state.SPLAT						#
var direction : String = "right"							# Probably unnecessary
var previous_y_vel = 0										#
var previous_floor_normal : Vector2 = Vector2(0,-1)			#
var moveSpeed := 84 										# 84 original
var moveSpeedIceMultiplier := 0.1							# Ice movespeed factor
var moveInfo : Vector2										#
var gravity : float = 800									# 800 original
var jumpPower : float = 0									#
const jumpHMultiplier = 2.3									#
const bounceMultiplier = 0.5								#
const bounceSoundThreshold = 40								#
var currentLevelY = 1										#
var currentLevelX = 1										#
@warning_ignore("integer_division")
var bounceVelocityThreshold := moveSpeed / 2				#
const splatThreshold = 550									#
@export var maxJump : float = 250							#
@export var minPower : float = 0.3							#
var jumpPowerStep := 3.0									#
@export var maxPower : float = 2							#
@export var maxSpeed : float = 600							#
@export var windVelocityMultiplier = 7
var windGroundMultiplier = 5

# --- LUMEN: การแก้อาการติดขอบ (GDD หัวข้อ 04) -------------------------------
# ระยะที่ยอมเลื่อนตัวแนวนอนเพื่อให้หัวรอดมุมเพดานไปได้ หน่วยพิกเซล
# 0 = ปิดสนิท คืนพฤติกรรมการชนแบบดั้งเดิมเป๊ะ
# 4 = ประมาณครึ่งหนึ่งของครึ่งความกว้างตัวละคร สูงกว่านี้จะเริ่มรู้สึกว่าตัวถูก "ดูด" เข้าช่อง
@export_range(0, 12, 1) var cornerCorrectionPixels : int = 4
# ระยะดันตัวออกจากผิวกำแพงหลังแฉลบ กันไม่ให้เฟรมถัดไปนับว่ายังชนอยู่
@export_range(0.0, 4.0, 0.25) var wallPushOut : float = 1.0
# เวลาห้ามแฉลบซ้ำ กันตัวสั่นติดกำแพงพร้อมเสียง bonk รัวเป็นชุด
@export_range(0.0, 0.2, 0.01) var bounceCooldownTime : float = 0.05
var _bounceCooldown : float = 0.0
# -----------------------------------------------------------------------------

var jump_pressing : bool
var left_pressing : bool
var right_pressing : bool

# Godot 3 move_and_slide() arguments are properties in Godot 4.
# Air movement used the engine defaults, ground movement passed
# stop_on_slope = true and floor_max_angle = 0.1 rad, so the two
# are applied per call in handle_movement().
const AIR_FLOOR_MAX_ANGLE := 0.785398						# Godot 3 default
const GROUND_FLOOR_MAX_ANGLE := 0.1							# was passed to move_and_slide()

@onready var sprite = $Sprite2D
@onready var collisionShape = $CollisionShape2D
@onready var audioPlayer = $AudioStreamPlayer
@onready var animationPlayer = $AnimationPlayer
@onready var idleTimer = $IdleTimer
@onready var splatTimer = $SplatTimer
@onready var velocityLine = $Line2D
@onready var mapCollisions = get_tree().get_nodes_in_group("map_collision")
@onready var jumpSound = load("res://Audio/Wick/Land/wick_jump.wav")
@onready var iceJumpSound = load("res://Audio/Wick/Ice/wick_jump.wav")
@onready var snowJumpSound = load("res://Audio/Wick/Snow/wick_jump.wav")
@onready var landingSound = load("res://Audio/Wick/Land/wick_land.wav")
@onready var iceLandingSound = load("res://Audio/Wick/Ice/wick_land.wav")
@onready var snowLandingSound = load("res://Audio/Wick/Snow/wick_land.wav")
@onready var splatSound = load("res://Audio/Wick/Land/wick_splat.wav")
@onready var bumpSound = load("res://Audio/Wick/Land/wick_bump.wav")
@onready var jumpParticle = preload("res://Entities/JumpParticle.tscn")
@onready var snowJumpParticle = preload("res://Entities/snowJumpParticle.tscn")
var motionPoints : PackedVector2Array


func _ready():
	#currentState = state.SPLAT
	#splatTimer.start()
	up_direction = Vector2(0,-1)
	max_slides = 4
	floor_snap_length = 0.0
	# Godot 4 additions that have no Godot 3 equivalent, disabled to keep
	# the original collision response.
	floor_block_on_wall = false
	slide_on_ceiling = false
	#vec2 array for debug line2
	motionPoints.resize(2)

func _physics_process(delta):
	if _bounceCooldown > 0.0:
		_bounceCooldown -= delta
	velocity.x += WindManager.currentVelocity * windVelocityMultiplier
	check_grounded()
	if grounded and not onSlope:
		velocity.y = 0


	#Bounce off the walls and ceiling
	if not grounded:
			check_bounces()

	handle_states(delta)

	#Handle animations based in state
	handle_animations()

	# Handle inputs
	inputs(delta)

	#Apply gravity
	apply_gravity(delta)

	#LUMEN: หลบมุมเพดานก่อนจะขยับจริง ต้องมาก่อน handle_movement เสมอ
	corner_correct(delta)

	#Handle play movement
	handle_movement(delta)

	#Slope detection
	detect_slopes()

	previous_y_vel = velocity.y # needed to access previous frame y velocity for splat

	#DEBUG STUFF HeRE

	#for tilemap in get_tree().get_nodes_in_group("map_collision"):
	#	tilemap.visible = noClip

	motionPoints.set(0,Vector2(0,0))
	#motionPoints.set(1,Vector2(velocity.x,velocity.y-gravity*delta).normalized()*64) # VELOCITY
	#motionPoints.set(1,Vector2(get_floor_normal()).normalized()*64) # FLOOR NORMAL
	#motionPoints.set(1,(velocity.normalized()+get_floor_normal().normalized())*64)
	motionPoints.set(1,Vector2(WindManager.currentVelocity*windVelocityMultiplier*4,0)) # MOVE INFO
	velocityLine.points = motionPoints
	debug_label("Wind")

func debug_label(type):
	match type:
		"Velocity":
			$Label.text = str(floor(velocity.x)) + ", " +str(floor(velocity.y))
		"Position":
			$Label.text = str(int(position.x)) + ", "+str(int(position.y))
		"State":
			$Label.text = state.keys()[currentState]
		"Slope":
			$Label.text = str(previous_floor_normal)
		"Noclip":
			$Label.text = str(noClip)
		"Level":
			var cam = get_tree().get_root().get_node("/root/World/Camera2D")
			$Label.text = "Level: "+str(cam.currentLevelY) + "y, "+str(cam.currentLevelX) + "x"
		"onIce":
			$Label.text = str(onIce)
		"Wind":
			$Label.text = str(WindManager.currentVelocity)

func move_right():
	if currentState != state.SPLAT:
		sprite.flip_h = false
		direction = "right"
	if not onSnow:
		currentState = state.WALKING
		if not onIce :
			velocity.x = moveSpeed
		else:
			velocity.x = lerp(velocity.x,moveSpeed+39.0,moveSpeedIceMultiplier)

func move_left():
	if currentState != state.SPLAT:
		sprite.flip_h = true
		direction = "left"
	if not onSnow:
		currentState = state.WALKING
		direction = "left"
		sprite.flip_h = true
		if not onIce:
			velocity.x = -moveSpeed
		else:
			velocity.x = lerp(velocity.x,-moveSpeed-39.0,moveSpeedIceMultiplier)

func inputs(delta):

	left_pressing = Input.is_action_pressed("left")
	right_pressing = Input.is_action_pressed("right")
	jump_pressing = Input.is_action_pressed("jump")
	noClip = Input.is_action_pressed("noclip")

	if noClip:
		var noclip_speed = noCipSpeed*delta
		if Input.is_action_pressed("ui_left"):
			position.x -= noclip_speed
		if Input.is_action_pressed("ui_right"):
			position.x += noclip_speed
		if Input.is_action_pressed("ui_up"):
			position.y -= noclip_speed
		if Input.is_action_pressed("ui_down"):
			position.y += noclip_speed
	else:
		if jump_pressing and grounded and canMove():
			currentState = state.CHARGING
			if not onIce:
				if onSnow:
					velocity.x = 0
				else:
					velocity.x = 0 + WindManager.currentVelocity * windGroundMultiplier
			else:
				velocity.x = lerp(velocity.x,0.0,iceInertia)
			jumpPower += jumpPowerStep*delta

			#Jump when max power
			if jumpPower >= maxPower:
				if left_pressing:
					jump(clamp(jumpPower,minPower, maxPower),-1)
				elif right_pressing:
					jump(clamp(jumpPower, minPower, maxPower),1)
				else:
					jump(clamp(jumpPower, minPower, maxPower),0)

		if currentState == state.CHARGING and !jump_pressing and grounded :
			if left_pressing:
				jump(clamp(jumpPower,minPower, maxPower),-1)
			elif right_pressing:
				jump(clamp(jumpPower, minPower, maxPower),1)
			else:
				jump(clamp(jumpPower, minPower, maxPower),0)
		if (right_pressing and grounded and currentState != state.JUMPING and canMove())  and not (left_pressing or jump_pressing):
			move_right()
		if (left_pressing and grounded and currentState != state.JUMPING and canMove()) and not (right_pressing or jump_pressing):
			move_left()

func apply_gravity(delta):
	if not noClip:
		velocity.y += gravity * delta
		if currentState == state.JUMPING and velocity.y > 0:
			currentState = state.FALLING
		if velocity.y > maxSpeed and not grounded:
			velocity.y = maxSpeed
	else:
		# reset vel in noclip
		velocity = Vector2.ZERO

func handle_movement(_delta):
	if not noClip:
		#AIR MOVEMENT
		if currentState == state.FALLING or currentState == state.JUMPING:
			# was move_and_slide_with_snap(velocity,Vector2(0,0),Vector2(0,-1))
			# snap was zero, so no snapping is applied here either
			floor_stop_on_slope = false
			floor_max_angle = AIR_FLOOR_MAX_ANGLE
			move_and_slide()
			moveInfo = velocity
			#print(moveInfo)
		else:
		#GROUND MOVEMENT
			# was move_and_slide(velocity,Vector2(0,-1),true,4,0.1,true)
			floor_stop_on_slope = true
			floor_max_angle = GROUND_FLOOR_MAX_ANGLE
			move_and_slide()

func handle_states(delta):
	#Falling when on slope
	if not noClip:

		if (currentState == state.WALKING or currentState == state.CHARGING or currentState == state.IDLE or currentState == state.JUMPING) and onSlope:
			currentState = state.FALLING

		#Instant Inertia when walking
		if currentState == state.IDLE or currentState == state.WALKING:
			stunned = false
			if grounded:
				if not onIce:
					if onSnow:
						velocity.x = 0
					else:
						velocity.x = 0 + WindManager.currentVelocity * windGroundMultiplier
				else:
					velocity.x = lerp(velocity.x,0.0,iceInertia)

		#Fix multi splat stun ( fixed? cant remember)
		if currentState == state.SPLAT and grounded:
			if splatTimer.is_stopped():
				stunned = false

		#Stop walking when not moving
		if currentState == state.WALKING:
			if not (left_pressing or right_pressing):
				currentState = state.IDLE

		#Start falling after walking off a ledge
		if (currentState == state.WALKING or currentState == state.IDLE or currentState == state.CHARGING) and not grounded:
			currentState = state.FALLING

		if currentState == state.SPLAT and grounded and not onSlope:
			if not onIce:
				if onSnow:
					velocity.x = 0
				else:
					velocity.x = 0 + WindManager.currentVelocity * windGroundMultiplier
			else:
				velocity.x = lerp(velocity.x,0.0,iceInertia)
		#On landing decide between normal and splat
		if currentState == state.FALLING and grounded and not onSlope:
			if(abs(previous_y_vel) > splatThreshold):
				currentState = state.SPLAT
				audioPlayer.stream = splatSound
				audioPlayer.play()
				splatTimer.start()
				stunned = true
			else:
				currentState = state.IDLE
				if onIce:
					audioPlayer.stream = iceLandingSound
					audioPlayer.play()
				elif onSnow:
					audioPlayer.stream = snowLandingSound
					audioPlayer.play()
				else:
					audioPlayer.stream = landingSound
					audioPlayer.play()
	else:
		currentState = state.IDLE

func detect_slopes():
	if get_floor_normal() != Vector2(0,0) and get_floor_normal() != Vector2(0,-1):
		onSlope = true
		velocity = moveInfo # needed to make slopes apply the correct velocity
		#print(str(get_floor_normal()) + "Slope Detected")
	elif get_floor_normal() != Vector2(0,0):
		onSlope = false
	previous_floor_normal = get_floor_normal()

func jump(power,dir):

	if power < minPower: power = minPower
	if onIce:
		audioPlayer.stream = iceJumpSound
		audioPlayer.play()
	elif onSnow:
		audioPlayer.stream = snowJumpSound
		audioPlayer.play()
	else:
		audioPlayer.stream = jumpSound
		audioPlayer.play()
	currentState = state.JUMPING
	velocity.y = 0
	if onSnow:
		var newJumpParticle = snowJumpParticle.instantiate(PackedScene.GEN_EDIT_STATE_DISABLED)
		newJumpParticle.position = position
		get_tree().get_root().get_node("World").add_child(newJumpParticle)
	else:
		var newJumpParticle = jumpParticle.instantiate(PackedScene.GEN_EDIT_STATE_DISABLED)
		newJumpParticle.position = position
		get_tree().get_root().get_node("World").add_child(newJumpParticle)




	velocity.y -= maxJump * power
	if dir == 0:
		if not onIce:
			velocity.x = 0
	elif dir == -1:
		velocity.x = dir*moveSpeed*jumpHMultiplier
		sprite.flip_h = true
	else:
		velocity.x = dir*moveSpeed*jumpHMultiplier
		sprite.flip_h = false
	jumpPower = 0

func check_grounded():
	if $GroundedArea.overlaps_body(mapCollisions[0]) and (get_floor_normal() != Vector2(0,0)):
		grounded = true
	else: grounded = false

func corner_correct(delta):
	# LUMEN (GDD 04): ถ้าหัวจะไปเฉี่ยวมุมเพดานพลาดแค่ไม่กี่พิกเซล
	# ให้เลื่อนตัวแนวนอนหลบให้ผ่านไปเลย แทนที่จะกินโมเมนตัมทั้งก้อนแล้วร่วง
	if cornerCorrectionPixels <= 0 or noClip:
		return
	if velocity.y >= 0.0:
		return												# ทำเฉพาะตอนพุ่งขึ้น
	var step := Vector2(0.0, velocity.y * delta)
	if not test_move(global_transform, step):
		return												# ไม่ติดอะไร ปล่อยผ่าน
	for px in range(1, cornerCorrectionPixels + 1):
		for dir in [1.0, -1.0]:
			if not test_move(global_transform.translated(Vector2(dir * px, 0.0)), step):
				position.x += dir * px
				return

func check_bounces():
	# LUMEN: velocity.bounce() ต้องการเวกเตอร์ที่ normalize ได้
	# ถ้าความเร็วเป็นศูนย์พอดี normalized() คืน (0,0) แล้วเอนจินจะพ่น error รัวทุกเฟรม
	# เจอตอนตัวละครนิ่งสนิทแล้วยังซ้อนกับ BounceArea อยู่
		if velocity.is_zero_approx():
			return
	# Side bounces
		if $BounceArea.overlaps_body(mapCollisions[0]) and not grounded and _bounceCooldown <= 0.0:
			var intoWall := signf(velocity.x)
			if abs(velocity.x) > bounceVelocityThreshold:
				velocity.x = velocity.bounce(velocity.normalized()).x*bounceMultiplier
			else: velocity.x = velocity.bounce(velocity.normalized()).x
			stunned = true
			_bounceCooldown = bounceCooldownTime
			# LUMEN (GDD 04): ดันตัวออกจากผิวกำแพง ไม่งั้นเฟรมถัดไปยังจมอยู่ใน
			# ระยะคอลลิชันเดิม แล้วจะกลับทิศซ้ำเป็นชุด ตัวสั่นพร้อมเสียง bonk รัว
			if intoWall != 0.0:
				position.x -= intoWall * wallPushOut
			if abs(velocity.x) > bounceSoundThreshold and not onSlope:
				audioPlayer.stream = bumpSound
				audioPlayer.play()
		# Head bounces
		if $HeadBounceArea.overlaps_body(mapCollisions[0]):
			# FIND A WAY TO DETECT THE NORMAL OF THE TILE BOUNCED OFF OF FOR SLOPED UPPER CORNERS

			velocity.y = velocity.bounce(velocity.normalized()).y*bounceMultiplier*0.6
			if abs(velocity.x) > bounceVelocityThreshold: velocity.x *= bounceMultiplier
			if abs(velocity.y) > bounceSoundThreshold:
				audioPlayer.stream = bumpSound
				audioPlayer.play()

func handle_animations():
	match(currentState):
		state.IDLE:
			animationPlayer.play("Idle")
		state.WALKING:
			animationPlayer.play("walk")
		state.FALLING:
			if stunned:
				animationPlayer.play(("air_collide"))
			else:
				animationPlayer.play("falling")
		state.CHARGING:
			animationPlayer.play("jump_start")
		state.JUMPING:
			if stunned:
				animationPlayer.play(("air_collide"))
			else:
				animationPlayer.play("jump_release")
		state.SPLAT:
			animationPlayer.play("splat")

func canJump():
	if grounded and not stunned: # add a check for quicksand when implemented
		return true
	else:
		return false

func canMove():
	if grounded and not stunned and not onSlope:
		return true
	else:
		return false

func _on_SplatTimer_timeout():
	stunned = false
