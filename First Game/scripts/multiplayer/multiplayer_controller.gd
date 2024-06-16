extends CharacterBody2D

const SPEED = 130.0
const JUMP_VELOCITY = -300.0

@onready var animated_sprite = $AnimatedSprite2D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

#var direction = 1
var do_jump = false
var _is_on_floor = true
var alive = true

#@onready var username_label = $Username
#var username = ""
@export var input: PlayerInput
@onready var rollback_synchronizer = $RollbackSynchronizer

@export var player_id := 1:
	set(id):
		player_id = id
		#input.set_multiplayer_authority(id)
		#%InputSynchronizer.set_multiplayer_authority(id)
		
		# TODO investigate if this can be moved to ready, added await process frame to allow this... but may not work as expected??
		input.set_multiplayer_authority(player_id)

func _ready():
	await get_tree().process_frame
	
	if multiplayer.get_unique_id() == player_id:
		$Camera2D.make_current()
	else:
		$Camera2D.enabled = false
	
	#input.set_multiplayer_authority(player_id)
	rollback_synchronizer.process_settings()

func _apply_animations(delta):
	# Flip the Sprite
	var direction = input.input_direction
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
	
	# Play animations
	if _is_on_floor:
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	else:
		animated_sprite.play("jump")

# QUESTION: Does this only run on authority? LIke we don't need a is server check?
func _rollback_tick(delta, tick, is_fresh):
	if multiplayer.is_server():
		_apply_movement_from_input_nf(delta)

func _apply_movement_from_input_nf(delta):
	
	#if not alive && is_on_floor():
		#_set_alive()
	#
	#_is_on_floor = is_on_floor()
		#
	# Add the gravity.
	_force_update_is_on_floor()
	_is_on_floor = is_on_floor()
	if not _is_on_floor:
		velocity.y += gravity * delta
	elif do_jump:
		print("juming")
		velocity.y = JUMP_VELOCITY
		do_jump = false
	elif not alive:
		_set_alive()
	# Handle jump.
	#if do_jump and is_on_floor():
		#velocity.y = JUMP_VELOCITY
		#do_jump = false

	# Get the input direction: -1, 0, 1
	var direction = input.input_direction#%InputSynchronizer.input_direction
	
	# Apply movement
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	velocity *= NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor
	
	#username = %InputSynchronizer.username

func _force_update_is_on_floor():
	var old_velocity = velocity
	velocity = Vector2.ZERO
	move_and_slide()
	velocity = old_velocity


func _apply_movement_from_input(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if do_jump and is_on_floor():
		velocity.y = JUMP_VELOCITY
		do_jump = false

	# Get the input direction: -1, 0, 1
	var direction = %InputSynchronizer.input_direction
	
	# Apply movement
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
	#username = %InputSynchronizer.username


func _physics_process(delta):
	#if multiplayer.is_server():
		#if not alive && is_on_floor():
			#_set_alive()
		#
		#_is_on_floor = is_on_floor()
		#_apply_movement_from_input(delta)
		
	if not multiplayer.is_server() || MultiplayerManager.host_mode_enabled:
		_apply_animations(delta)
		
		#if username_label && username != "":
			#username_label.set_text(username)

func mark_dead():
	print("Mark player dead!")
	alive = false
	$CollisionShape2D.set_deferred("disabled", true)
	$RespawnTimer.start()

func _respawn():
	print("Respawned!")
	position = MultiplayerManager.respawn_point
	$CollisionShape2D.set_deferred("disabled", false)

func _set_alive():
	print("alive again!")
	alive = true
	Engine.time_scale = 1.0





