extends CharacterBody3D

@export var speed := 5.0
@export var jump_force := 4.5
@export var mouse_sensitivity := 0.002

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera_pivot := $CameraPivot
@onready var camera := $CameraPivot/Camera3D
@onready var crosshair := $UI/Crosshair

var mouse_locked := true

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_locked = true


func _unhandled_input(event):
	# Mouse look
	if event is InputEventMouseMotion and mouse_locked:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		camera_pivot.rotation_degrees.x = clamp(camera_pivot.rotation_degrees.x, -89, 89)

	# ESC toggles mouse lock and crosshair visibility
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		mouse_locked = !mouse_locked
		if mouse_locked:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			if crosshair: crosshair.visible = true
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			if crosshair: crosshair.visible = false


func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Input direction (WASD or ui_up/down/left/right)
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Move relative to where camera/player is facing
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	# Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_force

	move_and_slide()
