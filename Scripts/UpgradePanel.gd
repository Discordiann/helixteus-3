extends "Panel.gd"

var ids:Array = []
var planet:Dictionary#Only for terraformed planets
var bldg:String#You can mass-upgrade only one type of building
var costs:Dictionary
var path_selected:int = 1
var path_str:String
var auto_speedup:bool = false

onready var path1 = $UpgradePanel/PathButtons/Path1
onready var path2 = $UpgradePanel/PathButtons/Path2
onready var path3 = $UpgradePanel/PathButtons/Path3
onready var next_lv = $UpgradePanel/NextLv
onready var current_lv = $UpgradePanel/CurrentLv
onready var next = $UpgradePanel/Next
onready var current = $UpgradePanel/Current
onready var cost_icons = $UpgradePanel/ScrollContainer/Costs
onready var upgrade_btn = $UpgradePanel/Upgrade

func _ready():
	set_polygon($UpgradePanel.rect_size)
	if not planet.empty():
		path2.visible = Data.path_2.has(planet.bldg.name)
		path3.visible = Data.path_3.has(planet.bldg.name)
		$UpgradePanel/AutoSpeedup.visible = false
		$UpgradePanel/AutoSpeedup.pressed = true
		auto_speedup = true
		_on_Path1_pressed()
	else:
		if game.tile_data[ids[0]].bldg.has("path_2"):
			path2.visible = true
		if game.tile_data[ids[0]].bldg.has("path_3"):
			path3.visible = true
		$UpgradePanel/AutoSpeedup.visible = game.lv >= 30
		$UpgradePanel/AutoSpeedup.pressed = $UpgradePanel/AutoSpeedup.visible
		if game.tile_data[ids[0]].bldg.has("path_1"):
			_on_Path1_pressed()
		else:
			game.popup(tr("NO_UPGRADE"), 1.5)
			game.remove_upgrade_panel()
	path1.text = tr("PATH") + " 1"
	path2.text = tr("PATH") + " 2"
	path3.text = tr("PATH") + " 3"

func geo_seq(q:float, start_n:int, end_n:int):
	return max(0, pow(q, start_n) * (1 - pow(q, end_n - start_n)) / (1 - q))

func get_min_lv():
	if planet.empty():
		var min_lv = INF
		for id in ids:
			var tile = game.tile_data[id]
			var lv_curr = tile.bldg[path_str]
			if lv_curr < min_lv:
				min_lv = lv_curr
		return min_lv
	else:
		return planet.bldg[path_str]

func calc_costs(tile_bldg:String, lv_curr:int, num:int = 1):
	var lv_to:int = next_lv.value
	var base_costs = Data.costs[tile_bldg]
	var base_metal_costs = Data[path_str][tile_bldg].metal_costs
	costs.money += round(base_costs.money * geo_seq(1.25, lv_curr, lv_to) * num)
	costs.time = round(base_costs.time * geo_seq(1.24, lv_curr, lv_to))
	if auto_speedup:
		costs.money += costs.time * 10 * num
		costs.time = 0
	if base_costs.has("energy"):
		costs.energy += round(base_costs.energy * geo_seq(1.2, lv_curr, lv_to) * num)
	if lv_curr <= 10 and lv_to >= 11:
		costs.lead += base_metal_costs.lead * num
	if lv_curr <= 20 and lv_to >= 21:
		costs.copper += base_metal_costs.copper * num
	if lv_curr <= 30 and lv_to >= 31:
		costs.iron += base_metal_costs.iron * num
	if lv_curr <= 40 and lv_to >= 41:
		costs.aluminium += base_metal_costs.aluminium * num
	if lv_curr <= 50 and lv_to >= 51:
		costs.silver += base_metal_costs.silver * num
	if lv_curr <= 60 and lv_to >= 61:
		costs.gold += base_metal_costs.gold * num
	if lv_curr <= 71 and lv_to >= 71 and base_metal_costs.has("platinum"):
		costs.platinum += base_metal_costs.platinum * num

func update():
	auto_speedup = $UpgradePanel/AutoSpeedup.pressed
	costs = {"money":0, "energy":0, "lead":0, "copper":0, "iron":0, "aluminium":0, "silver":0, "gold":0, "platinum":0, "time":0.0}
	var same_lv = true
	var first_tile
	var first_tile_bldg_info
	var lv_to = next_lv.value
	var all_tiles_constructing = true
	var num:int = 1
	if planet.empty():
		first_tile = game.tile_data[ids[0]].bldg
		bldg = first_tile.name
		first_tile_bldg_info = Data[path_str][bldg]
		for id in ids:
			var tile = game.tile_data[id]
			var tile_bldg:String = tile.bldg.name
			var lv_curr = tile.bldg[path_str]
			if lv_curr != first_tile[path_str]:
				same_lv = false
			if tile.bldg.is_constructing or tile.bldg[path_str] >= next_lv.value:
				continue
			all_tiles_constructing = false
			calc_costs(tile_bldg, lv_curr, 1)
	else:
		first_tile = planet.bldg
		bldg = first_tile.name
		num = 1 if bldg in ["GH", "MM"] else planet.tile_num
		first_tile_bldg_info = Data[path_str][bldg]
		all_tiles_constructing = false
		calc_costs(planet.bldg.name, planet.bldg[path_str], planet.tile_num)
	var rsrc_icon = [Data.desc_icons[bldg][path_selected - 1]] if Data.desc_icons.has(bldg) and Data.desc_icons[bldg] else []
	if same_lv:
		current_lv.text = tr("LEVEL") + " %s" % [first_tile[path_str]]
		current.text = ""
		var curr_value = bldg_value(first_tile_bldg_info.value, first_tile[path_str], first_tile_bldg_info.pw) * first_tile.IR_mult
		if bldg == "SP" and path_selected == 1:
			curr_value = bldg_value(Helper.get_SP_production(game.planet_data[game.c_p].temperature, first_tile_bldg_info.value), first_tile[path_str], first_tile_bldg_info.pw) * first_tile.IR_mult
		elif bldg == "AE" and path_selected == 1:
			curr_value = bldg_value(Helper.get_AE_production(game.planet_data[game.c_p].pressure, first_tile_bldg_info.value), first_tile[path_str], first_tile_bldg_info.pw)
		if first_tile_bldg_info.is_value_integer:
			curr_value = round(curr_value)
		else:
			curr_value = Helper.clever_round(curr_value, 3)
		if not planet.empty():
			curr_value *= num
		game.add_text_icons(current, ("[center]" + first_tile_bldg_info.desc) % [Helper.format_num(curr_value)], rsrc_icon, 20)
	else:
		costs.erase("time")
		current_lv.text = tr("VARYING_LEVELS")
		current.text = tr("VARIES")
	if all_tiles_constructing:
		game.popup(tr("SELECTED_BLDGS_UNDER_CONSTR"), 2)
		game.remove_upgrade_panel()
		return
	next.text = ""
	var next_value = bldg_value(first_tile_bldg_info.value, lv_to, first_tile_bldg_info.pw) * first_tile.IR_mult
	if bldg == "SP" and path_selected == 1:
		next_value = bldg_value(Helper.get_SP_production(game.planet_data[game.c_p].temperature, first_tile_bldg_info.value), lv_to, first_tile_bldg_info.pw) * first_tile.IR_mult
	elif bldg == "AE" and path_selected == 1:
		next_value = bldg_value(Helper.get_AE_production(game.planet_data[game.c_p].pressure, first_tile_bldg_info.value), lv_to, first_tile_bldg_info.pw)
	if first_tile_bldg_info.is_value_integer:
		next_value = round(next_value)
	else:
		next_value = Helper.clever_round(next_value, 3)
	if not planet.empty():
		next_value *= num
	game.add_text_icons(next, ("[center]" + first_tile_bldg_info.desc) % [Helper.format_num(next_value)], rsrc_icon, 20)
	var icons = Helper.put_rsrc(cost_icons, 32, costs, true, true)
	for icon in icons:
		if costs[icon.name] == 0:
			icon.rsrc.visible = false

func bldg_value(base_value, lv:int, pw:float = 1.15):
	return Helper.clever_round(base_value * pow((lv - 1) / 10 + 1, pw) * pow(pw, lv - 1), 3)

func _on_Path1_pressed():
	path_selected = 1
	path_str = "path_%s" % [path_selected]
	next_lv.min_value = get_min_lv() + 1
	Helper.set_btn_color(path1)
	next_lv.allow_greater = true
	update()

func _on_Path2_pressed():
	path_selected = 2
	path_str = "path_%s" % [path_selected]
	next_lv.min_value = get_min_lv() + 1
	Helper.set_btn_color(path2)
	next_lv.allow_greater = true
	update()

func _on_Path3_pressed():
	path_selected = 3
	path_str = "path_%s" % [path_selected]
	next_lv.min_value = get_min_lv() + 1
	Helper.set_btn_color(path3)
	if Data.path_3[bldg].has("cap"):
		next_lv.max_value = Data.path_3[bldg].cap
		next_lv.allow_greater = false
	update()


func _on_NextLv_value_changed(_value):
	update()


func _on_ScrollContainer_resized():
	$UpgradePanel.visible = false
	$UpgradePanel.visible = true


func _on_Upgrade_pressed():
	if game.c_v != "planet" and planet.empty() or game.c_v != "system" and not planet.empty():
		return
	update()
	var bldg_info = Data[path_str][bldg]
	var curr_time = OS.get_system_time_msecs()
	if game.check_enough(costs):
		game.deduct_resources(costs)
		if planet.empty():
			for id in ids:
				var tile = game.tile_data[id]
				if tile.bldg.is_constructing or tile.bldg[path_str] >= next_lv.value:
					continue
				var new_value = bldg_value(bldg_info.value, next_lv.value, bldg_info.pw)
				var base_costs = Data.costs[tile.bldg.name]
				var cost_time = round(base_costs.time * geo_seq(1.24, tile.bldg[path_str], next_lv.value))
				if auto_speedup:
					cost_time = 1
				var cost_money = round(base_costs.money * geo_seq(1.25, tile.bldg[path_str], next_lv.value))
				if tile.bldg.has("collect_date"):
					var prod_ratio
					if path_str == "path_1":
						prod_ratio = new_value / tile.bldg.path_1_value
					else:
						prod_ratio = 1.0
					var coll_date = tile.bldg.collect_date
					tile.bldg.collect_date = curr_time - (curr_time - coll_date) / prod_ratio + cost_time * 1000.0
				elif tile.bldg.name == "MS":
					tile.bldg.mineral_cap_upgrade = new_value - tile.bldg.path_1_value
				if tile.bldg.has("start_date"):
					tile.bldg.start_date += cost_time * 1000
				if tile.bldg.has("overclock_mult"):
					tile.bldg.overclock_date += cost_time * 1000
				tile.bldg[path_str] = next_lv.value
				tile.bldg[path_str + "_value"] = new_value
				tile.bldg.construction_date = curr_time
				tile.bldg.XP = round(cost_money / 100.0)
				tile.bldg.construction_length = cost_time * 1000.0
				tile.bldg.is_constructing = true
				game.view.obj.add_time_bar(id, "bldg")
			if not game.objective.empty() and game.objective.type == game.ObjectiveType.UPGRADE:
				game.objective.current += 1
		else:
			var new_value = bldg_value(bldg_info.value, next_lv.value, bldg_info.pw)
			var base_costs = Data.costs[planet.bldg.name]
			var cost_money = base_costs.money * geo_seq(1.25, planet.bldg[path_str], next_lv.value) * planet.tile_num
			if planet.bldg.name == "MS":
				game.mineral_capacity += (new_value - planet.bldg.path_1_value) * planet.tile_num
			if planet.bldg.has("collect_date"):
				var prod_ratio
				if path_str == "path_1":
					prod_ratio = new_value / planet.bldg.path_1_value
				else:
					prod_ratio = 1.0
				var coll_date = planet.bldg.collect_date
				planet.bldg.collect_date = curr_time - (curr_time - coll_date) / prod_ratio
			planet.bldg[path_str] = next_lv.value
			planet.bldg[path_str + "_value"] = new_value
			game.xp += round(cost_money / 100.0)
			game.view.obj.refresh_planets()
		game.HUD.refresh()
		game.remove_upgrade_panel()
	else:
		game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.2)

func _on_close_button_pressed():
	game.remove_upgrade_panel()

func _on_AutoSpeedup_mouse_entered():
	game.show_tooltip(tr("AUTO_SPEEDUP_DESC"))

func _on_AutoSpeedup_pressed():
	update()


func _on_AutoSpeedup_mouse_exited():
	game.hide_tooltip()


func _on_Control_tree_exited():
	queue_free()
