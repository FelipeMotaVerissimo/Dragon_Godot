extends CharacterBody2D
class_name Goku

enum State { IDLE, WALK, JUMP, CROUCH }
var state: State = State.IDLE

const SPEED = 150.0
const JUMP_VELOCITY = -300.0
const MAX_JUMPS = 2

var jump_count := 0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

var collision_scale: Vector2
var collision_position: Vector2


func _ready() -> void:
	collision_scale = collision.scale
	collision_position = collision.position
	go_to_idle()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	match state:
		State.IDLE:
			state_idle(delta)
		State.WALK:
			state_walk(delta)
		State.JUMP:
			state_jump(delta)
		State.CROUCH:
			state_crouch(delta)

	move_and_slide()


# ---------------- IDLE ----------------

func go_to_idle() -> void:
	state = State.IDLE
	velocity.x = 0
	anim.play("idle")
	return


func state_idle(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
		jump_count = 1
		go_to_jump()
		return

	if not is_on_floor():
		go_to_jump()
		return

	if Input.is_action_pressed("ui_down"):
		go_to_crouch()
		return

	var direction := Input.get_axis("left", "right")
	if direction:
		go_to_walk()
		return


# ---------------- WALK ----------------

func go_to_walk() -> void:
	state = State.WALK
	anim.play("walk")
	return


func state_walk(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
		jump_count = 1
		go_to_jump()
		return

	if not is_on_floor():
		go_to_jump()
		return

	if Input.is_action_pressed("ui_down"):
		go_to_crouch()
		return

	var direction := Input.get_axis("left", "right")
	if direction:
		anim.flip_h = direction < 0
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		go_to_idle()
		return


# ---------------- JUMP ----------------

func go_to_jump() -> void:
	state = State.JUMP
	anim.play("jump")
	return


func state_jump(delta: float) -> void:
	if Input.is_action_just_pressed("jump") and jump_count < MAX_JUMPS:
		velocity.y = JUMP_VELOCITY
		jump_count += 1

	var direction := Input.get_axis("left", "right")
	if direction:
		anim.flip_h = direction < 0
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	if is_on_floor():
		jump_count = 0
		if direction:
			go_to_walk()
		else:
			go_to_idle()
		return


# ---------------- CROUCH ----------------

func go_to_crouch() -> void:
	state = State.CROUCH
	velocity.x = 0
	collision.scale.y = collision_scale.y * 0.5
	collision.position.y = collision_position.y + 2  
	anim.play("Crouch")
	return


func state_crouch(delta: float) -> void:
	if not Input.is_action_pressed("ui_down"):
		collision.scale.y = collision_scale.y
		collision.position.y = collision_position.y
		go_to_idle()
		return
