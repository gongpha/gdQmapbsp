extends CharacterBody3D
class_name QmapbspQuakePlayer

# THESE VALUES WERE APPROXIMATELY MEASURED
# TO MATCH AN ORIGINAL AS CLOSE AS POSSIBLE >/\<

# my definition is 32 units/1 meter

var viewer : QmapbspQuakeViewer

@export var max_speed : float = 10
@export var max_air_speed : float = 0.5
@export var max_liquid_speed : float = 5
@export var accel : float = 100
@export var fric : float = 8
@export var sensitivity : float = 0.0025
@export var stairstep := 0.6
@export var stairstep_liquid := 1.25
@export var step_buffer := 1.125 # multiplier
@export var gravity : float = 20
@export var gravity_liquid : float = 15
@export var jump_up : float = 7.6
@export var jump_up_liquid : float = 1.9
@export var max_time_submerged : float = 5

var noclip : bool = false

@onready var col : CollisionShape3D = $col
@onready var around : Node3D = $around
@onready var head : Node3D = $around/head
@onready var camera : Camera3D = $around/head/cam
@onready var staircast : ShapeCast3D = $staircast
@onready var sound : AudioStreamPlayer3D = $sound
@onready var space_state := get_world_3d().direct_space_state

var wishdir : Vector3
var wish_jump : bool = false
var auto_jump : bool = true
var smooth_y : float
var time_submerged : float = 0
var fluid : QmapbspQuakeFluidVolume
var low_level := PhysicsPointQueryParameters3D.new()
var mid_level := PhysicsPointQueryParameters3D.new()
var eye_level := PhysicsPointQueryParameters3D.new()
var s_level : int = 0

# audio paths, naming convention: s_type + "_audio
const jump_audio = [ &"player/plyrjmp8.wav" ]
const axe_pain_audio = [ &"player/axhit1.wav" ]
const pain_audio = [ &"player/pain1.wav", &"player/pain2.wav", &"player/pain3.wav", &"player/pain4.wav", &"player/pain5.wav", &"player/pain6.wav" ]
const water_pain_audio = [ &"player/drown1.wav", &"player/drown2.wav" ]
const lava_pain_audio = [ &"player/lburn1.wav", &"player/lburn2.wav" ]
const slime_pain_audio = [ &"player/lburn1.wav", &"player/lburn2.wav" ] # the same as lava
const tele_death_audio = [ &"player/teledth1.wav" ]
const death_audio = [ &"player/death1.wav",  &"player/death2.wav",  &"player/death3.wav",  &"player/death4.wav",  &"player/death5.wav" ]
const water_death_audio = [ &"player/h2odeath.wav" ]
const gib_death_audio = [ &"player/gib.wav", &"player/udeath.wav" ]
const air_gasp_audio = [ &'player/gasp1.wav', &'player/gasp2.wav']
	
# cache some values:
var _p_size : Vector3 # player
var _p_height : float
var _p_half_height : float
var _p_low_pos_diff : Vector3
var _sc_size : Vector3 # stair check
var _sc_height : float
var _sc_half_height : float
var _sc_pos : Vector3
var _head_height : float # eye-level
	
	
func _ready() :
	# player height
	_p_size = col.shape.size
	_p_height = _p_size.y
	_p_half_height = _p_height / 2
	_p_low_pos_diff = Vector3(0, _p_half_height, 0) # foot/bottom level
	# staircast height
	_sc_pos = staircast.position
	_sc_size = staircast.shape.size
	_sc_height = _sc_size.y
	_sc_half_height = _sc_height / 2
	# around (head container)
	_head_height = around.position.y
	# setup query points
	low_level.set_collide_with_areas(true)
	low_level.set_collide_with_bodies(false)
	low_level.set_collision_mask(pow(2, 3-1)) # 3rd layer is LIQUID
	mid_level.set_collide_with_areas(true)
	mid_level.set_collide_with_bodies(false)
	mid_level.set_collision_mask(pow(2, 3-1)) # 3rd layer is LIQUID
	eye_level.set_collide_with_areas(true)
	eye_level.set_collide_with_bodies(false)
	eye_level.set_collision_mask(pow(2, 3-1)) # 3rd layer is LIQUID
	
	
func hurt(type: StringName, amount: int, duration: float) :
	# TODO: apply damage, flush out hurt types, etc.
	match type :
		&'water' :
			_play_sound(&'water_pain')
		&'lava' :
			_play_sound(&'lava_pain')
		&'slime' :
			_play_sound(&'slime_pain')
		_ : 
			print('UKNOWN HURT TYPE!')


func teleport_to(dest : Node3D, play_sound : bool = false) :
	global_position = dest.global_position
	var old := around.rotation
	around.rotation = dest.rotation
	old = around.rotation - old
	velocity = velocity.rotated(Vector3.UP, old.y)
	if play_sound :
		var p := AudioStreamPlayer3D.new()
		p.stream = (
			viewer.hub.load_audio('misc/r_tele%d.wav' % (randi() % 5 + 1))
		)
		p.finished.connect(func() : p.queue_free())
		viewer.add_child(p)
		p.global_position = global_position
		p.play()


func accelerate(in_speed : float, delta : float) -> void :
	velocity += wishdir * (
		clampf(in_speed - velocity.dot(wishdir), 0, accel * delta)
	)


func friction(delta : float) -> void :
	var speed : float = velocity.length()
	var svec : Vector3
	if speed > 0 :
		svec = velocity * maxf(speed - (
			fric * speed * delta
		), 0) / speed
	if speed < 0.1 :
		svec = Vector3()
	velocity = svec


func move_ground(delta : float) -> void :
	friction(delta)
	accelerate(max_speed, delta)
	_stairs(delta)
	move_and_slide()
	_coltest()
	_ceiling_test()
	
	
func move_air(delta : float) -> void :
	accelerate(max_air_speed, delta)
	_stairs(delta)
	move_and_slide()
	_coltest()
	
	
func move_liquid(delta : float) -> void :
	friction(delta)
	accelerate(max_liquid_speed, delta)
	_stairs(delta)
	move_and_slide()
	_coltest()
	_ceiling_test()
	
	
func move_noclip(delta : float) -> void :
	friction(delta)
	accelerate(max_speed, delta)
	translate(velocity * delta)
	

func _ceiling_test() :
	staircast.target_position.y = _sc_height
	staircast.force_shapecast_update()
	if staircast.get_collision_count() == 0 :
		staircast.target_position.y = -(_p_height - _sc_height)
		staircast.force_shapecast_update()
		if staircast.get_collision_count() > 0 and staircast.get_collision_normal(0).y >= 0.8 :
			var height := staircast.get_collision_point(0).y - (global_position.y - _p_half_height)
			if (height < stairstep) or (fluid and height < stairstep_liquid) : # step-over
				position.y += height * step_buffer
				smooth_y = -height * step_buffer # applied in _physics_process


func _stairs(delta : float) :
	var w := (velocity / max_speed) * Vector3(2.0, 0.0, 2.0) * delta
	var ws := w * max_speed
	
	# increase size in horizontal movement direction
	var shape : BoxShape3D = staircast.shape
	shape.size = Vector3(
		_sc_size.x + ws.length(), _sc_height, _sc_size.z + ws.length()
	)
	
	staircast.target_position = Vector3(
		ws.x, 0, ws.z
	)


func _physics_process(delta : float) -> void :
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED :
		return
		
	wishdir = (head if noclip or fluid else around).global_transform.basis * Vector3((
		Input.get_axis(&"q1_move_left", &"q1_move_right")
	), 0, (
		Input.get_axis(&"q1_move_forward", &"q1_move_back")
	)).normalized()
	
	if noclip :
		move_noclip(delta)
		return
	
	if auto_jump :
		wish_jump = Input.is_action_pressed(&"q1_jump")
	else :
		if !wish_jump and Input.is_action_just_pressed(&"q1_jump") :
			wish_jump = true
		if Input.is_action_just_released(&"q1_jump") :
			wish_jump = false
	
	# entered liquid volume
	if fluid : _process_liquid_hurt(delta)
	
	if _can_swim() : # half-way in liquid
		# slighly trash movement ;)
		if wish_jump :
			velocity.y = jump_up_liquid
		# apply gravity if not moving horizontally
		if not (wishdir.x > 0 or wishdir.z > 0 or wish_jump) :
			velocity.y -= gravity_liquid * delta
		move_liquid(delta)
	else :
		if is_on_floor() :
			if wish_jump :
				_play_sound(&'jump')
				velocity.y = jump_up
				move_air(delta)
				wish_jump = false
			else :
				velocity.y = 0
				move_ground(delta)
		else :
			velocity.y -= gravity * delta
			move_air(delta)
	
	if is_zero_approx(smooth_y) : smooth_y = 0.0
	else :
		smooth_y /= step_buffer
		around.position.y = smooth_y + _head_height
		
		
func _can_swim() -> bool :
	if not fluid : return false
	# check that both low-level (feet) and mid-level (waist) are in liquid at the same time
	return _check_submerged_level(1) && _check_submerged_level(2)


func _play_sound(s_type: StringName, force: bool = false) :
	if not force and sound.is_playing() : return
	
	# access by convention: s_type + "_audio"
	var psnd = get("%s_audio" % s_type).pick_random()
	if psnd.is_empty() : return
	sound.stream = viewer.hub.load_audio(psnd)
	sound.play()


func _coltest() :
	for i in get_slide_collision_count() :
		var k := get_slide_collision(i)
		for j in k.get_collision_count() :
			var obj := k.get_collider(j)
			if obj.has_method(&'_player_touch') :
				obj._player_touch(self, k.get_position(j), k.get_normal(j))
				return
		
		
func _input(event : InputEvent) -> void :
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED :
		return
		
	if Input.is_action_just_pressed(&'q1_toggle_noclip') :
		toggle_noclip()
	
	if event is InputEventMouseMotion :
		var r : Vector2 = event.relative * -1
		head.rotate_x(r.y * sensitivity)
		around.rotate_y(r.x * sensitivity)
		
		var hrot = head.rotation
		hrot.x = clampf(hrot.x, -PI/2, PI/2)
		head.rotation = hrot


func _check_submerged_level(level : int) -> bool :
	if not fluid : return false
	
	match level :
		1 :
			low_level.position = global_position - _p_low_pos_diff
			if space_state.intersect_point(low_level) : 
				return true 
			else : 
				return false
		2 : 
			mid_level.position = global_position
			if space_state.intersect_point(mid_level) : 
				return true 
			else : 
				return false
		3 :
			eye_level.position = around.global_position
			if space_state.intersect_point(eye_level) : 
				return true 
			else : 
				return false
		_ :
			return false


# return highest level of 0, 1, 2, 3 levels (none, low, halfway, eye-level)
func _get_submerged_level() -> int :
	# setup query points position
	low_level.position = global_position - _p_low_pos_diff
	mid_level.position = global_position
	eye_level.position = around.global_position
	# query space
	if space_state.intersect_point(eye_level) : return 3
	elif space_state.intersect_point(mid_level) : return 2
	elif space_state.intersect_point(low_level) : return 1
	else : return 0


func _process_liquid_hurt(delta) :
	if not fluid : return
	
	var prev_s_level = s_level
	s_level = _get_submerged_level()
	
	# was fully submersed, now coming up for air
	if prev_s_level == 3 and s_level < 3 :
		# play gasping sound only if ~drowning
		if (max_time_submerged - time_submerged) < 1:
			_play_sound(&'air_gasp', true)
	
	match fluid.liquid_type() :
		&'water' :  
			if s_level == 3 : time_submerged += 1 * delta
			else : time_submerged = 0
			if time_submerged > max_time_submerged : # delay
				time_submerged -= 1 # apply effect every 1 second
				hurt(&'water', fluid.damage(), fluid.duration())
		&'lava' : 
			if s_level > 0 : time_submerged += 1 * delta
			else : time_submerged = 0
			if time_submerged > 0 :
				time_submerged -= 1 # apply effect every 1 second
				hurt(&'lava', fluid.damage() * s_level, fluid.duration())
		&'slime' : 
			if s_level > 0 : time_submerged += 1 * delta
			else : time_submerged = 0
			if time_submerged > 0 :
				time_submerged -= 1 # apply effect every 1 second
				hurt(&'slime', fluid.damage() * s_level, fluid.duration())


# Events

func _fluid_enter(f : QmapbspQuakeFluidVolume) :
	fluid = f


func _fluid_exit(f : QmapbspQuakeFluidVolume) :
	if f == fluid : fluid = null
	time_submerged = 0
	# TODO: apply damage for "duration" time after exit

#########################################

func toggle_noclip() :
	noclip = !noclip
