extends Node2D

onready var game = self.get_parent().get_parent()
onready var star_graphic = preload("res://Graphics/Stars/M.png")
onready var systems_id = game.galaxy_data[game.c_g]["systems"]

var stars

const DIST_MULT = 200.0

func _ready():
	var systems_info = []
	for i in systems_id:
		systems_info.append(game.system_data[i])
	for s_i in systems_info:
		var star = s_i["stars"][0]
		var star_btn = TextureButton.new()
		var system = Sprite.new()
		var star_texture = preload("res://Graphics/Stars/Star.png")
		star_btn.texture_normal = star_texture
		var w = int(star["class"][1]) / 10.0#weight for lerps
		var Y9 = Color(25, 0, 0, 255) / 255.0
		var Y0 = Color(66, 0, 0, 255) / 255.0
		var T0 = Color(117, 0, 0, 255) / 255.0
		var L0 = Color(189, 32, 23, 255) / 255.0
		var M0 = Color(255, 181, 108, 255) / 255.0
		var K0 = Color(255, 218, 181, 255) / 255.0
		var G0 = Color(255, 237, 227, 255) / 255.0
		var F0 = Color(249, 245, 255, 255) / 255.0
		var A0 = Color(213, 224, 255, 255) / 255.0
		var B0 = Color(162, 192, 255, 255) / 255.0
		var O0 = Color(140, 177, 255, 255) / 255.0
		var Q0 = Color(134, 255, 117, 255) / 255.0
		var R0 = Color(255, 151, 255, 255) / 255.0
		match star["class"][0]:
			"Y":
				star_btn.modulate = lerp(Y0, Y9, w)
			"T":
				star_btn.modulate = lerp(T0, Y0, w)
			"L":
				star_btn.modulate = lerp(L0, T0, w)
			"M":
				star_btn.modulate = lerp(M0, L0, w)
			"K":
				star_btn.modulate = lerp(K0, M0, w)
			"G":
				star_btn.modulate = lerp(G0, K0, w)
			"F":
				star_btn.modulate = lerp(F0, G0, w)
			"A":
				star_btn.modulate = lerp(A0, F0, w)
			"B":
				star_btn.modulate = lerp(B0, A0, w)
			"O":
				star_btn.modulate = lerp(O0, B0, w)
			"Q":
				star_btn.modulate = lerp(Q0, O0, w)
			"R":
				star_btn.modulate = lerp(R0, Q0, w)
			"Z":
				star_btn.modulate = Color(0.05, 0.05, 0.05, 1)
		self.add_child(system)
		system.add_child(star_btn)
		star_btn.connect("mouse_entered", self, "on_system_over", [s_i["id"]])
		star_btn.connect("mouse_exited", self, "on_system_out")
		star_btn.connect("pressed", self, "on_system_click", [s_i["id"]])
		star_btn.rect_position = Vector2(-600 / 2, -600 / 2)
		star_btn.rect_pivot_offset = Vector2(600 / 2, 600 / 2)
		var radius
		if star["size"] < 1:
			radius = pow(star["size"] / game.SYSTEM_SCALE_DIV, 0.4)
		else:
			radius = pow(star["size"] / game.SYSTEM_SCALE_DIV, 0.3)
		star_btn.rect_scale.x = radius
		star_btn.rect_scale.y = radius
		system.position = s_i["pos"]

func _process(delta):
	if Input.is_action_pressed('pause'):
		pass
	else:
		rotation += w * delta

#used for _draw() function
var moused_over
#stores the coords of a selected system
var system_pos:Vector2
#distance from Solar System to selected system
var system_distance
#circumference of system orbit
var orbit_length
#angular velocity of the galaxy spinning
const w = 0.1
#how many seconds to project into the future in terms of star position
var t = 10

func _draw():
	if moused_over == true:
		
		var r = system_pos.length()
		var th = system_pos.angle()
		var start_pos = Vector2(-15000, -15000)
		var end_pos = system_pos
		var end_pos_after_rotation = polar2cartesian(r, th + w * t) #thank you apple for this op line
		var spd = 1000 #Ship speed: spd pixels/sec
		var dist_total = (end_pos_after_rotation - start_pos).length()
		var dist_travelled = spd * t
		var percentage = dist_travelled / dist_total
		
		draw_line(start_pos, end_pos, Color(0, 0, 255, 1), 1)
		draw_line(start_pos, end_pos_after_rotation, Color(255, 0, 0, 1), 1)
		draw_line(start_pos, lerp(start_pos, end_pos_after_rotation, percentage), Color(0, 255, 0, 1), 1)
		
		#system orbit (yellow)
		draw_arc(Vector2.ZERO, (Vector2.ZERO - system_pos).length(), 0, 2*PI, 100, Color(1, 1, 0, 1), 1)

func on_system_over (id:int):
	moused_over = true
	var s_i = game.system_data[id]
	system_pos = s_i['pos']
	system_distance = (Vector2(-15000, -15000) - system_pos).length()
	game.show_tooltip(s_i["name"] + "\nPlanets: " + String(s_i["planet_num"]) + '\nDistance: ' + String(system_distance))
	update()
func on_system_out ():
	moused_over = false
	game.hide_tooltip()
	update()

func on_system_click (id:int):
	var view = self.get_parent()
	if not view.dragged:
		game.c_s = id
		game.switch_view("system")
	view.dragged = false

func _process(delta):
	rotation += w * delta