extends KinematicBody2D

onready var game = self.get_parent()
var obj_scene
var obj

#Variables for smoothly moving the tiles
var acceleration = 90
var max_speed = 1000
var friction = 150
var velocity = Vector2.ZERO

#Variables for zooming smoothly
const ZOOM_FACTOR = 1.1
var zooming = ""
var progress = 0
var mouse_position = Vector2.ZERO

func add_obj(obj_str:String, pos:Vector2, sc:float):
	obj_scene = load("res://Scenes/" + obj_str + ".tscn")
	obj = obj_scene.instance()
	self.add_child(obj)
	self.position = pos
	self.scale = Vector2(sc, sc)
	dragged = false

func remove_obj(obj_str:String):
	match obj_str:
		"planet":
			game.planet_data[game.c_p]["view"]["pos"] = self.position
			game.planet_data[game.c_p]["view"]["zoom"] = self.scale.x
		"system":
			game.system_data[game.c_s]["view"]["pos"] = self.position
			game.system_data[game.c_s]["view"]["zoom"] = self.scale.x
		"galaxy":
			game.galaxy_data[game.c_g]["view"]["pos"] = self.position
			game.galaxy_data[game.c_g]["view"]["zoom"] = self.scale.x
	self.remove_child(obj)
	obj_scene = null
	obj = null

#Executed every tick
func _physics_process(_delta):
	#Moving tiles code
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_left") - Input.get_action_strength("ui_right")
	input_vector.y = Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")
	input_vector = input_vector.normalized()
	if input_vector != Vector2.ZERO:
		velocity = velocity.move_toward(input_vector * max_speed, acceleration)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction)
	velocity = move_and_slide(velocity)
	
	#Zooming animation
	if zooming == "in":
		_zoom_at_point(-ease(progress, 0.1) * (ZOOM_FACTOR - 1) + ZOOM_FACTOR)
		progress += 0.03
	if zooming == "out":
		_zoom_at_point(ease(progress, 0.1) * (1 - 1 / ZOOM_FACTOR) + 1 / ZOOM_FACTOR)
		progress += 0.03
	if progress >= 1:
		zooming = ""
		progress = 0

#Dragging variables
var dragged = false
var drag_position = Vector2.ZERO
var drag_initial_position = Vector2.ZERO
var drag_delta = Vector2.ZERO

#Executed once the receives any kind of input
func _input(event):
	#if the input is from the mouse
	if event is InputEventMouse:
		if event.is_action_released("scroll_down"):
			zooming = "out"
			progress = 0
		elif event.is_action_released("scroll_up"):
			zooming = "in"
			progress = 0
		if Input.is_action_just_pressed("left_click"):
			drag_initial_position = event.position
			drag_position = event.position
		if Input.is_action_pressed("left_click"):
			drag_delta = event.position - drag_position
			if (event.position - drag_initial_position).length() > 2:
				dragged = true
			move_and_collide(drag_delta)
			drag_position = event.position
		mouse_position = event.position
		get_node("../FPS").text = String(to_local(mouse_position))

#Zooming code
func _zoom_at_point(zoom_change):
	scale = scale * zoom_change
	var delta_x = (mouse_position.x - global_position.x) * (zoom_change - 1)
	var delta_y = (mouse_position.y - global_position.y) * (zoom_change - 1)
	global_position.x -= delta_x
	global_position.y -= delta_y