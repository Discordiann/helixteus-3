extends "Panel.gd"

var ids:Array
var bldg:String#You can mass-upgrade only one type of building
var costs:Dictionary
var path_selected:int = 1
var path_str:String

onready var path1 = $UpgradePanel/VBoxContainer/PathButtons/Path1
onready var path2 = $UpgradePanel/VBoxContainer/PathButtons/Path2
onready var path3 = $UpgradePanel/VBoxContainer/PathButtons/Path3
onready var next_lv = $UpgradePanel/VBoxContainer/Control2/NextLv
onready var current_lv = $UpgradePanel/VBoxContainer/Control2/CurrentLv
onready var next = $UpgradePanel/VBoxContainer/HBoxContainer2/Next
onready var current = $UpgradePanel/VBoxContainer/HBoxContainer2/Current
onready var cost_icons = $UpgradePanel/ScrollContainer/Costs
onready var upgrade_btn = $UpgradePanel/Upgrade

func _ready():
	set_polygon($UpgradePanel.rect_size)
	if game.tile_data[ids[0]].has("path_2"):
		path2.visible = true
	if game.tile_data[ids[0]].has("path_3"):
		path3.visible = true
	_on_Path1_pressed()
	path1.text = tr("PATH") + " 1"
	path2.text = tr("PATH") + " 2"
	path3.text = tr("PATH") + " 3"

func geo_seq(q:float, start_n:int, end_n:int):
	return max(0, pow(q, start_n) * (1 - pow(q, end_n - start_n)) / (1 - q))

func get_min_lv():
	var min_lv = INF
	for id in ids:
		var tile = game.tile_data[id]
		var lv_curr = tile[path_str]
		if lv_curr < min_lv:
			min_lv = lv_curr
	return min_lv

func update():
	costs = {"money":0, "energy":0, "lead":0, "copper":0, "iron":0, "aluminium":0, "time":0.0}
	var same_lv = true
	var first_tile = game.tile_data[ids[0]]
	bldg = first_tile.tile_str
	var first_tile_bldg_info = Data[path_str][bldg]
	var lv_to = next_lv.value
	var all_tiles_constructing = true
	for id in ids:
		var tile = game.tile_data[id]
		var lv_curr = tile[path_str]
		if lv_curr != first_tile[path_str]:
			same_lv = false
		if tile.is_constructing or tile[path_str] >= next_lv.value:
			continue
		all_tiles_constructing = false
		var base_costs = Data.costs[tile.tile_str]
		var base_metal_costs = Data[path_str][tile.tile_str].metal_costs
		costs.money += round(base_costs.money * geo_seq(1.25, lv_curr, lv_to))
		costs.time = round(base_costs.time * geo_seq(1.24, lv_curr, lv_to))
		if base_costs.has("energy"):
			costs.energy += round(base_costs.energy * geo_seq(1.2, lv_curr, lv_to))
		if lv_curr <= 10 and lv_to >= 11:
			#costs.lead += round(base_metal_costs.lead * geo_seq(1.2, max(0, lv_curr - 10), min(lv_to, 20) - 10))
			costs.lead += base_metal_costs.lead
		if lv_curr <= 20 and lv_to >= 21:
			costs.copper += base_metal_costs.copper
		if lv_curr <= 30 and lv_to >= 31:
			costs.iron += base_metal_costs.iron
		if lv_curr <= 40 and lv_to >= 41:
			costs.aluminium += base_metal_costs.aluminium
	if same_lv:
		current_lv.text = tr("LEVEL") + " %s" % [first_tile[path_str]]
		current.text = ""
		var curr_value = bldg_value(first_tile_bldg_info.value, first_tile[path_str], first_tile_bldg_info.pw)
		if first_tile_bldg_info.is_value_integer:
			curr_value = round(curr_value)
		var icon = []
		if Data.icons.has(bldg) and first_tile_bldg_info.desc.find("@i") != -1:
			icon.append(Data.icons[bldg])
		game.add_text_icons(current, ("[center]" + first_tile_bldg_info.desc) % [curr_value], icon, 20)
	else:
		costs.erase("time")
		current_lv.text = tr("VARYING_LEVELS")
		current.text = tr("VARIES")
	if all_tiles_constructing:
		game.popup(tr("SELECTED_BLDGS_UNDER_CONSTR"), 2)
		game.remove_upgrade_panel()
		return
	next.text = ""
	var next_value = bldg_value(first_tile_bldg_info.value, lv_to, first_tile_bldg_info.pw)
	if first_tile_bldg_info.is_value_integer:
		next_value = round(next_value)
	var icon2 = []
	if Data.icons.has(bldg) and first_tile_bldg_info.desc.find("@i") != -1:
		icon2.append(Data.icons[bldg])
	game.add_text_icons(next, ("[center]" + first_tile_bldg_info.desc) % [next_value], icon2, 20)
	var icons = Helper.put_rsrc(cost_icons, 32, costs)
	for icon in icons:
		if costs[icon.name] == 0:
			icon.rsrc.visible = false
	
func bldg_value(base_value, lv:int, pw:float = 1.15):
	return game.clever_round(base_value * pow((lv - 1) / 10 + 1, 1.4) * pow(pw, lv - 1), 3)

func _on_Path1_pressed():
	path_selected = 1
	path_str = "path_%s" % [path_selected]
	next_lv.min_value = get_min_lv() + 1
	Helper.set_btn_color(path1)
	update()

func _on_Path2_pressed():
	path_selected = 2
	path_str = "path_%s" % [path_selected]
	next_lv.min_value = get_min_lv() + 1
	Helper.set_btn_color(path2)
	update()

func _on_Path3_pressed():
	path_selected = 3
	path_str = "path_%s" % [path_selected]
	next_lv.min_value = get_min_lv() + 1
	Helper.set_btn_color(path3)
	update()


func _on_NextLv_value_changed(_value):
	update()


func _on_ScrollContainer_resized():
	$UpgradePanel.visible = false
	$UpgradePanel.visible = true


func _on_Upgrade_pressed():
	if game.c_v != "planet":
		return
	update()
	var bldg_info = Data[path_str][bldg]
	if game.check_enough(costs):
		game.deduct_resources(costs)
		for id in ids:
			var tile = game.tile_data[id]
			if tile.is_constructing or tile[path_str] >= next_lv.value:
				continue
			var curr_time = OS.get_system_time_msecs()
			var new_value = bldg_value(bldg_info.value, next_lv.value, bldg_info.pw)
			if bldg_info.is_value_integer:
				new_value = round(new_value)
			var base_costs = Data.costs[tile.tile_str]
			var cost_time = round(base_costs.time * geo_seq(1.24, tile[path_str], next_lv.value))
			var cost_money = round(base_costs.money * geo_seq(1.25, tile[path_str], next_lv.value))
			if tile.has("collect_date"):
				var prod_ratio
				if path_str == "path_1":
					prod_ratio = new_value / game.tile_data[id].path_1_value
				else:
					prod_ratio = 1.0
				var coll_date = tile.collect_date
				tile.collect_date = curr_time - (curr_time - coll_date) / prod_ratio + cost_time * 1000.0
			elif tile.tile_str == "MS":
				tile.mineral_cap_upgrade = new_value - tile.path_1_value
			if tile.has("start_date"):
				tile.start_date += cost_time * 1000
			if tile.has("overclock_mult"):
				tile.overclock_date += cost_time * 1000
			tile[path_str] = next_lv.value
			tile[path_str + "_value"] = new_value
			tile.construction_date = curr_time
			tile.XP = round(cost_money / 100.0)
			tile.construction_length = cost_time * 1000.0
			tile.is_constructing = true
			game.view.obj.add_time_bar(id, "bldg")
		game.remove_upgrade_panel()
	else:
		game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.2)


func _on_close_button_pressed():
	game.remove_upgrade_panel()
