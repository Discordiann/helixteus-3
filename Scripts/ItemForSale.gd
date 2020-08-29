extends Control

onready var game = get_node("/root/Game")
export var item_name:String = ""
var item_desc:String = ""
var money_cost:float = 0.0

func _ready():
	$VBoxContainer/ItemTexture.texture = load("res://Graphics/Items/" + item_name + ".png")
	$VBoxContainer/MoneyCost/Text.text = String(money_cost)

func _on_Button_pressed():
	game.shop_panel.set_item_info(item_name, item_desc, money_cost)
