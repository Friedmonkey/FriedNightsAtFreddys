# ProtoController v1.0 by Brackeys
# CC0 License
# Intended for rapid prototyping of first-person games.
# Happy prototyping!

extends CharacterBody3D

@export var footstep_sounds: Array[AudioStream] = []

## Can we move around?
@export var can_move : bool = true
## Are we affected by gravity?
@export var has_gravity : bool = true
## Can we press to jump?
@export var can_jump : bool = true
## Can we hold to run?
@export var can_sprint : bool = false
## Can we press to enter freefly mode (noclip)?
@export var can_freefly : bool = false

@export var respawn_location : Node3D
@export var max_health : int = 8
@export var health : int = 8

@export_group("Speeds")
## Look around rotation speed.
@export var look_speed : float = 0.002
## Normal speed.
@export var base_speed : float = 7.0
## Speed of jump.
@export var jump_velocity : float = 4.5
## How fast do we run?
@export var sprint_speed : float = 10.0
## How fast do we freefly?
@export var freefly_speed : float = 25.0

@export_group("Input Actions")
## Name of Input Action to move Left.
@export var input_left : String = "ui_left"
## Name of Input Action to move Right.
@export var input_right : String = "ui_right"
## Name of Input Action to move Forward.
@export var input_forward : String = "ui_up"
## Name of Input Action to move Backward.
@export var input_back : String = "ui_down"
## Name of Input Action to Jump.
@export var input_jump : String = "ui_accept"
## Name of Input Action to Sprint.
@export var input_sprint : String = "sprint"
## Name of Input Action to toggle freefly mode.
@export var input_freefly : String = "freefly"

signal player_moved(position: Vector3)

var mouse_captured : bool = false
var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = false
var stuck : bool = false
var fire_level : int = 0

var step_timer := 0.8
var step_interval := 0.35

var seated : bool = false
var gettingUpFromSeat : bool = false
var currentSeat : Node3D = null

signal on_player_died

## IMPORTANT REFERENCES
@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider

@onready var footstep_player := $footstep
@onready var screenTransition: AnimationPlayer = $Transition/Animator
@onready var fire_effect := $Fire/flame
@onready var burn_timer : Timer = $Fire/burn_timer

@onready var hurt_sound := $hurt
@onready var burn_sound := $Fire/burn
@onready var vignette: TextureRect = $hurt_overlay/TextureRect
@onready var interaction: Node3D = $Head/Interaction

@onready var shakeable_camera: Area3D = $Head/ShakeableCamera
func set_shake_intensity(intensity: float):
	shakeable_camera.overalShakeIntensity = intensity

func _ready() -> void:
	check_input_mappings()
	self.transform = respawn_location.transform
	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x
	screenTransition.animation_finished.connect(_transition_animation_finished)
	burn_timer.timeout.connect(_on_burn_tick)
	screenTransition.play("fade_in")

func sit(seat: Node3D, offset: Vector3):
	seated = true
	
	if seat != null:
		global_position = seat.to_global(offset)
		currentSeat = seat

func stand():
	if !seated || gettingUpFromSeat:
		return
	
	if currentSeat != null:
		var offset := Vector3.ZERO
		if currentSeat.has_method("SeatGetExitOffset"):
			offset = currentSeat.SeatGetExitOffset()
		global_position = currentSeat.to_global(offset)
		gettingUpFromSeat = true
		ForceInteract(currentSeat)
		gettingUpFromSeat = false
		currentSeat = null
	seated = false

func ForceInteract(obj: Node3D):
	interaction.handleInteraction(obj)

func set_ablaze(intensity: int):
	fire_level = intensity
	fire_effect.set_intensity(fire_level)
		
	if fire_level > 0:
		if (!burn_timer.is_stopped()):
			_on_burn_tick() # we cut the timer short
			burn_timer.stop()
		burn_timer.start()

func burn(damage_amount: int):
	if fire_level <= 0:
		burn_timer.stop()
		return
	burn_sound.play()
	
	damage(damage_amount, "fire")
	
	fire_level -= 1
	fire_effect.set_intensity(fire_level)
	
	if fire_level <= 0:
		burn_timer.stop()

func damage(amount: int, cause: String = "blood"):
	health -= amount
	health = clamp(health, 0, max_health)
	_update_vignette()
	hurt_sound.play()
	if health <= 0:
		kill(cause)

func kill(cause: String):
	if (screenTransition.is_playing()):
		return
	# Reset fire
	fire_level = 0
	fire_effect.set_intensity(0)
	burn_timer.stop()
	
	#reset health
	health = max_health
	_update_vignette()
	
	var death_anim = "death_"+cause
	if !screenTransition.has_animation(death_anim):
		death_anim = "death_blood"
		push_warning("No death animation for \""+death_anim+"\" using death_blood as fallback.")
	stuck = true
	screenTransition.play(death_anim)

func player_died():
	# Reset player position/rotation
	self.transform = respawn_location.transform
	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x

	stuck = false
	on_player_died.emit()
	screenTransition.play("fade_in")

func _update_vignette():
	# health_ratio = 0.0 (dead) → 1.0 (full health)
	var health_ratio = float(health) / float(max_health)
	
	# Maximum alpha for vignette in 0–255
	var max_alpha = 50
	
	# Compute alpha in 0–255 directly, integer only
	var alpha = int((1.0 - health_ratio) * max_alpha)
	#var alpha = int(pow(1.0 - health_ratio, 2) * max_alpha)
	
	if (health == 1):
		alpha = 65
	
	# Apply to vignette (Godot expects 0.0–1.0)
	vignette.self_modulate.a = alpha / 255.0

func _on_burn_tick():
	burn(1)

func _unhandled_input(event: InputEvent) -> void:
	# Mouse capturing
	if (stuck):
		return
		
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		capture_mouse()
	if Input.is_key_pressed(KEY_ESCAPE):
		release_mouse()
	
	# Look around
	if mouse_captured and event is InputEventMouseMotion:
		rotate_look(event.relative)
	
	# Toggle freefly mode
	if can_freefly and Input.is_action_just_pressed(input_freefly):
		if not freeflying:
			enable_freefly()
		else:
			disable_freefly()

func _physics_process(delta: float) -> void:
	if (stuck):
		return
	
	if seated:
		if can_jump && Input.is_action_just_pressed(input_jump):
			stand()
		return
	# If freeflying, handle freefly and nothing else
	if can_freefly and freeflying:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var motion := (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		motion *= freefly_speed * delta
		move_and_collide(motion)
		return
	
	# Apply gravity to velocity
	if has_gravity:
		if not is_on_floor():
			velocity += get_gravity() * delta

	# Apply jumping
	if can_jump:
		if Input.is_action_just_pressed(input_jump) and is_on_floor():
			velocity.y = jump_velocity

	# Modify speed based on sprinting
	if can_sprint and Input.is_action_pressed(input_sprint):
			move_speed = sprint_speed
	else:
		move_speed = base_speed

	# Apply desired movement to velocity
	if can_move:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var move_dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if move_dir:
			velocity.x = move_dir.x * move_speed
			velocity.z = move_dir.z * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
	else:
		velocity.x = 0
		velocity.y = 0
		
	# Use velocity to actually move
	handle_floor(delta)
	move_and_slide()
	emit_signal("player_moved", global_position)

func handle_floor(delta: float):
	if is_on_floor():
		# Check horizontal movement only (ignore Y velocity)
		var horizontal_speed := Vector2(velocity.x, velocity.z).length()
		
		if horizontal_speed > 0.1:
			step_timer -= delta
			
			if step_timer <= 0.0:
				play_footstep_sound()
				
				# Optional: make footsteps scale with speed
				var speed_ratio := horizontal_speed / base_speed
				step_timer = step_interval / max(speed_ratio, 0.1)
		else:
			step_timer = 0.0
	else:
		step_timer = 0.0


func play_footstep_sound():
	var sound = footstep_sounds[randi() % footstep_sounds.size()]
	footstep_player.stream = sound
	footstep_player.play()
	
## Rotate us to look around.
## Base of controller rotates around y (left/right). Head rotates around x (up/down).
## Modifies look_rotation based on rot_input, then resets basis and rotates by look_rotation.
func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * look_speed
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))
	look_rotation.y -= rot_input.x * look_speed
	transform.basis = Basis()
	rotate_y(look_rotation.y)
	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)

func _transition_animation_finished(anim_name: String):
	if anim_name.begins_with("death_"):
		player_died()

func enable_freefly():
	collider.disabled = true
	freeflying = true
	velocity = Vector3.ZERO

func disable_freefly():
	collider.disabled = false
	freeflying = false


func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true


func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false


## Checks if some Input Actions haven't been created.
## Disables functionality accordingly.
func check_input_mappings():
	if can_move and not InputMap.has_action(input_left):
		push_error("Movement disabled. No InputAction found for input_left: " + input_left)
		can_move = false
	if can_move and not InputMap.has_action(input_right):
		push_error("Movement disabled. No InputAction found for input_right: " + input_right)
		can_move = false
	if can_move and not InputMap.has_action(input_forward):
		push_error("Movement disabled. No InputAction found for input_forward: " + input_forward)
		can_move = false
	if can_move and not InputMap.has_action(input_back):
		push_error("Movement disabled. No InputAction found for input_back: " + input_back)
		can_move = false
	if can_jump and not InputMap.has_action(input_jump):
		push_error("Jumping disabled. No InputAction found for input_jump: " + input_jump)
		can_jump = false
	if can_sprint and not InputMap.has_action(input_sprint):
		push_error("Sprinting disabled. No InputAction found for input_sprint: " + input_sprint)
		can_sprint = false
	if can_freefly and not InputMap.has_action(input_freefly):
		push_error("Freefly disabled. No InputAction found for input_freefly: " + input_freefly)
		can_freefly = false
