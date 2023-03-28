extends CharacterBody3D
class_name QmapbspTrenchbroomTestPlayer

@export var max_speed : float = 10
@export var max_air_speed : float = 0.5
@export var accel : float = 100
@export var fric : float = 8
@export var sensitivity : float = 0.0025
@export var stairstep := 0.6
@export var gravity : float = 20
@export var jump_up : float = 7.6

var noclip : bool = false

@onready var around : Node3D = $around
@onready var head : Node3D = $around/head
@onready var camera : Camera3D = $around/head/cam
@onready var staircast : ShapeCast3D = $staircast

var wishdir : Vector3
var wish_jump : bool = false
var auto_jump : bool = true
var smooth_y : float

func _ready() -> void :
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

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
	# test ceiling
	staircast.target_position.y = 0.66 + stairstep
	staircast.force_shapecast_update()
	if staircast.get_collision_count() == 0 :
		staircast.target_position.y = -stairstep - 0.1 # (?)
		staircast.force_shapecast_update()
		if staircast.get_collision_count() > 0 and staircast.get_collision_normal(0).y >= 0.8 :
			var height := staircast.get_collision_point(0).y - (global_position.y - 0.75)
			if height < stairstep :
				position.y += height * 1.25 # additional bonus
				smooth_y = -height
				around.position.y = -height + 0.688
				# 0.688 is an initial value of around.y
	
	move_and_slide()
	_coltest()
	
func _stairs(delta : float) :
	var w := (velocity / max_speed) * Vector3(2.0, 0.0, 2.0) * delta
	var ws := w * max_speed
	
	# stair stuffs
	var shape : BoxShape3D = staircast.shape
	shape.size = Vector3(
		1.0 + ws.length(), shape.size.y, 1.0 + ws.length()
	)
	
	staircast.position = Vector3(
		ws.x, 0.175 + stairstep - 0.75, ws.z
	)

func move_air(delta : float) -> void :
	accelerate(max_air_speed, delta)
	_stairs(delta)
	move_and_slide()
	_coltest()
	
func move_noclip(delta : float) -> void :
	friction(delta)
	accelerate(max_speed, delta)
	translate(velocity * delta)

func _physics_process(delta : float) -> void :
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED :
		return
		
	wishdir = (head if noclip else around).global_transform.basis * Vector3((
		Input.get_axis(&"trenchbroom_test_move_left", &"trenchbroom_test_move_right")
	), 0, (
		Input.get_axis(&"trenchbroom_test_move_forward", &"trenchbroom_test_move_back")
	)).normalized()
	
	if noclip :
		move_noclip(delta)
		return
	
	if auto_jump :
		wish_jump = Input.is_action_pressed(&"trenchbroom_test_jump")
	else :
		if !wish_jump and Input.is_action_just_pressed(&"trenchbroom_test_jump") :
			wish_jump = true
		if Input.is_action_just_released(&"trenchbroom_test_jump") :
			wish_jump = false
	
	
	if is_on_floor() :
		if wish_jump :
			velocity.y = jump_up
			move_air(delta)
			wish_jump = false
		else :
			velocity.y = 0
			move_ground(delta)
	else :
		velocity.y -= gravity * delta
		move_air(delta)
	
	if is_zero_approx(smooth_y) :
		smooth_y = 0.0
	else :
		smooth_y /= 1.5
		around.position.y = smooth_y + 0.688
		
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
		
	if Input.is_action_just_pressed(&'trenchbroom_test_toggle_noclip') :
		toggle_noclip()
	
	if event is InputEventMouseMotion :
		var r : Vector2 = event.relative * -1
		head.rotate_x(r.y * sensitivity)
		around.rotate_y(r.x * sensitivity)
		
		var hrot = head.rotation
		hrot.x = clampf(hrot.x, -PI/2, PI/2)
		head.rotation = hrot

#########################################

func toggle_noclip() :
	noclip = !noclip
