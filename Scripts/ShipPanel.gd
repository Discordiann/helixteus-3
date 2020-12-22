extends "Panel.gd"


func _ready():
	set_polygon($Background.rect_size)
	$GridContainer/Panel1.show_weapon_XPs = false

func _on_close_button_pressed():
	game.toggle_panel(self)

func refresh():
	$GridContainer/Panel1.refresh()

func _on_CheckBox_toggled(button_pressed):
	$GridContainer/Panel1.show_weapon_XPs = button_pressed
	$GridContainer/Panel1.set_visibility()