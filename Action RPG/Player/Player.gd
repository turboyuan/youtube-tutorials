extends KinematicBody2D

const PlayerHurtSound = preload("res://Player/PlayerHurtSound.tscn")

#移动加速度
export var ACCELERATION = 500
#移速上限
export var MAX_SPEED = 80
#翻滚速度
export var ROLL_SPEED = 120
#摩擦力，影响停止移动后减速的快慢
export var FRICTION = 500

enum {
	MOVE,
	ROLL,
	ATTACK
}

var state = MOVE
#初始速度为0
var velocity = Vector2.ZERO
var roll_vector = Vector2.DOWN
var stats = PlayerStats

onready var animationPlayer = $AnimationPlayer
onready var animationTree = $AnimationTree
onready var animationState = animationTree.get("parameters/playback")
onready var swordHitbox = $HitboxPivot/SwordHitbox
onready var hurtbox = $Hurtbox
onready var blinkAnimationPlayer = $BlinkAnimationPlayer

func _ready():
	randomize()
	stats.connect("no_health", self, "queue_free")
	animationTree.active = true
	swordHitbox.knockback_vector = roll_vector

#每一帧都触发
func _physics_process(delta):
	match state:
		MOVE:
			move_state(delta)
		
		ROLL:
			roll_state()
		
		ATTACK:
			attack_state()
	
func move_state(delta):
	#用于记录输入的二维移动信息矢量，初始为0
	var input_vector = Vector2.ZERO
	#x轴上的操作方向结果，左右同时按是不动的
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	#y轴上的操作方向结果，上下同时按是不动的
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	#归一化，把矢量长度变成1单位
	input_vector = input_vector.normalized()
	
	#如果输入的矢量不是0
	if input_vector != Vector2.ZERO:
		roll_vector = input_vector
		swordHitbox.knockback_vector = input_vector
		animationTree.set("parameters/Idle/blend_position", input_vector)
		animationTree.set("parameters/Run/blend_position", input_vector)
		animationTree.set("parameters/Attack/blend_position", input_vector)
		animationTree.set("parameters/Roll/blend_position", input_vector)
		animationState.travel("Run")
		#速度值，以 acceleration * delta 的加速度向 input_vector * MAX_SPEED 的速度变化
		velocity = velocity.move_toward(input_vector * MAX_SPEED, ACCELERATION * delta)
	
	#如果输入的矢量是0，即没有操作
	else:
		animationState.travel("Idle")
		#速度值，以 friction * delta 的加速度向0矢量变化
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	
	#调用move function
	move()
	
	if Input.is_action_just_pressed("roll"):
		state = ROLL
	
	if Input.is_action_just_pressed("attack"):
		state = ATTACK

func roll_state():
	velocity = roll_vector * ROLL_SPEED
	animationState.travel("Roll")
	move()

func attack_state():
	velocity = Vector2.ZERO
	animationState.travel("Attack")

func move():
	#move_and_slide有很多参数，这里只递了1个参数，其他的均为默认值
	velocity = move_and_slide(velocity)

func roll_animation_finished():
	velocity = velocity * 0.8
	state = MOVE

func attack_animation_finished():
	state = MOVE

func _on_Hurtbox_area_entered(area):
	stats.health -= area.damage
	hurtbox.start_invincibility(0.6)
	hurtbox.create_hit_effect()
	var playerHurtSound = PlayerHurtSound.instance()
	get_tree().current_scene.add_child(playerHurtSound)
	
func _on_Hurtbox_invincibility_started():
	blinkAnimationPlayer.play("Start")

func _on_Hurtbox_invincibility_ended():
	blinkAnimationPlayer.play("Stop")
