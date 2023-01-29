extends CharacterBody3D
class_name QmapbspPlayer

# THESE VALUES WERE APPROXIMATELY MEASURED
# TO MATCH AN ORIGINAL AS CLOSE AS POSSIBLE >/\<

# my definition is 32 units/1 meter

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
@onready var camera : Camera3D = $around/head/camera
@onready var staircast : ShapeCast3D = $staircast

var wishdir : Vector3
var wish_jump : bool = false
var auto_jump : bool = true
var smooth_y : float

func accelerate(in_speed : float, delta : float) -> void :
	velocity += wishdir * (
		clamp(in_speed - velocity.dot(wishdir), 0, accel * delta)
	)

func friction(delta : float) -> void :
	var speed : float = velocity.length()
	var svec : Vector3
	if speed > 0 :
		svec = velocity * max(speed - (
			fric * speed * delta
		), 0) / speed
	if speed < 0.1 :
		svec = Vector3()
	velocity = svec

func move_ground(delta : float) -> void :
	friction(delta)
	accelerate(max_speed, delta)
	
	var w := wishdir * delta
	var ws := w * max_speed
	
	# stair stuffs
	
	staircast.position = Vector3(
		ws.x, 0.175 + stairstep - 0.75, ws.z
	)
	staircast.target_position.y = -stairstep
	
	if staircast.get_collision_count() > 0 :
		var height := staircast.get_collision_point(0).y - (global_position.y - 0.75)
		if height < stairstep :
			position.y += height * 1.25 # additional bonus
			smooth_y = -height
			around.position.y = -height + 0.688
			# 0.688 is an initial value of around.y
	
	move_and_slide()

func move_air(delta : float) -> void :
	accelerate(max_air_speed, delta)
	move_and_slide()
	
func move_noclip(delta : float) -> void :
	friction(delta)
	accelerate(max_speed, delta)
	translate(velocity * delta)

func _physics_process(delta : float) -> void :
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED :
		return
		
	
		
	wishdir = (head if noclip else around).global_transform.basis * Vector3((
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
		hrot.x = clamp(hrot.x, -PI/2, PI/2)
		head.rotation = hrot

#########################################

func toggle_noclip() :
	noclip = !noclip
