extends CharacterBody3D

# --- Movement ---
@export var speed := 5.0
@export var jump_force := 4.5
@export var mouse_sensitivity := 0.002

# --- Realistic head-bob parameters ---
@export var bob_frequency := 6.0     # Steps per second
@export var bob_amplitude := 0.03    # Vertical movement
@export var tilt_amount := 0.5       # Degrees of head tilt
@export var sway_amount := 0.02      # Side-to-side motion

var bob_timer := 0.0
var original_camera_position := Vector3.ZERO
var was_in_air := false

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera_pivot := $CameraPivot
@onready var camera := $CameraPivot/Camera3D
@onready var crosshair := $UI/Crosshair

var mouse_locked := true


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_locked = true
	original_camera_position = camera_pivot.position


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
			if crosshair:
				crosshair.visible = true
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			if crosshair:
				crosshair.visible = false


func _physics_process(delta):
	# --- Gravity ---
	if not is_on_floor():
		velocity.y -= gravity * delta

	# --- Movement input ---
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	# --- Jump ---
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_force

	move_and_slide()

	# --- Landing bump ---
	if was_in_air and is_on_floor():
		camera_pivot.position.y = original_camera_position.y - 0.05  # brief dip
	was_in_air = not is_on_floor()

	# --- Realistic Head Bob ---
	var is_moving = direction.length() > 0.1 and is_on_floor()

	if is_moving:
		# Adjust bobbing speed based on movement velocity
		var movement_speed = Vector2(velocity.x, velocity.z).length()
		var speed_factor = clamp(movement_speed / speed, 0.5, 1.5)

		bob_timer += delta * bob_frequency * speed_factor
		var bob_offset_y = sin(bob_timer * 2.0) * bob_amplitude * speed_factor
		var bob_offset_x = sin(bob_timer) * sway_amount * speed_factor
		var tilt = sin(bob_timer) * tilt_amount * speed_factor

		# Apply smoothed bob offsets
		camera_pivot.position.y = lerp(camera_pivot.position.y, original_camera_position.y + bob_offset_y, delta * 10.0)
		camera_pivot.position.x = lerp(camera_pivot.position.x, original_camera_position.x + bob_offset_x, delta * 10.0)
		camera_pivot.rotation_degrees.z = lerp(camera_pivot.rotation_degrees.z, tilt, delta * 10.0)

	else:
		# Smoothly return to normal when stopping
		camera_pivot.position.y = lerp(camera_pivot.position.y, original_camera_position.y, delta * 8.0)
		camera_pivot.position.x = lerp(camera_pivot.position.x, original_camera_position.x, delta * 8.0)
		camera_pivot.rotation_degrees.z = lerp(camera_pivot.rotation_degrees.z, 0.0, delta * 8.0)
		bob_timer = 0.0
