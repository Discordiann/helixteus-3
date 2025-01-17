extends "Panel.gd"

var HP_icon = preload("res://Graphics/Icons/HP.png")
var atk_icon = preload("res://Graphics/Icons/atk.png")
var def_icon = preload("res://Graphics/Icons/def.png")
var inv_icon = preload("res://Graphics/Icons/Inventory.png")
var spd_icon = preload("res://Graphics/Icons/eva.png")
var tile_id:int = -1
var rover_has_items = false
var rover_over_id:int = -1
var probe_over_id:int = -1
var fighter_over_id:int = -1
var probe_time_bars:Array = []

func _ready():
	set_polygon(size)

func _input(event):
	super(event)
	if modulate.a == 1 and Input.is_action_just_released("X"):
		if rover_over_id != -1:
			game.rover_data[rover_over_id] = null
			rover_over_id = -1
			game.hide_adv_tooltip()
			refresh()
		elif probe_over_id != -1:
			if game.probe_data[probe_over_id].tier == 2:
				game.show_YN_panel("destroy_tri_probe", tr("DESTROY_TRI_PROBE"), [probe_over_id])
			else:
				game.probe_data[probe_over_id] = null
				probe_over_id = -1
				game.hide_tooltip()
				refresh()
		elif fighter_over_id != -1:
			game.fighter_data[fighter_over_id] = null
			fighter_over_id = -1
			game.hide_adv_tooltip()
			refresh()

func refresh():
	$Panel.visible = game.science_unlocked.has("FG")
	$Probes.visible = game.universe_data[game.c_u].lv >= 60
	var hbox = $Rovers/ScrollContainer/HBox
	var hbox2 = $Panel/GridContainer
	var hbox3 = $Probes/ScrollContainer/GridContainer
	for rov in hbox.get_children():
		rov.queue_free()
	for fgh in hbox2.get_children():
		fgh.queue_free()
	for probe in hbox3.get_children():
		probe.queue_free()
	probe_time_bars.clear()
	for i in len(game.rover_data):
		var rov = game.rover_data[i]
		if rov == null:
			continue
		#if rov.c_p == game.c_p or rov.ready:
		if rov.ready:
			var rover = TextureButton.new()
			rover.ignore_texture_size = true
			rover.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
			rover.custom_minimum_size = Vector2.ONE * 200
			if rov.get("MK", 1) == 2:
				rover.texture_normal = preload("res://Graphics/Cave/Rover2.png")
			elif rov.get("MK", 1) == 3:
				rover.texture_normal = preload("res://Graphics/Cave/Rover3.png")
			else:
				rover.texture_normal = preload("res://Graphics/Cave/Rover.png")
			hbox.add_child(rover)
			rover.connect("mouse_entered",Callable(self,"on_rover_enter").bind(rov, i))
			rover.connect("mouse_exited",Callable(self,"on_rover_exit"))
			rover.connect("pressed",Callable(self,"on_rover_press").bind(rov, i))
	for i in len(game.fighter_data):
		if game.fighter_data[i] == null:
			continue
		var fighter_info = game.fighter_data[i]
		var fighter = TextureButton.new()
		var fighter_num = Label.new()
		fighter_num.text = "x %s" % [fighter_info.number]
		fighter_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fighter_num.position = Vector2(110, 40)
		if fighter_info.tier == 0:
			fighter.texture_normal = preload("res://Graphics/Ships/Fighter.png")
		elif fighter_info.tier == 1:
			fighter.texture_normal = preload("res://Graphics/Ships/Fighter2.png")
		fighter.ignore_texture_size = true
		fighter.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		fighter.custom_minimum_size = Vector2(160, 60)
		fighter.add_child(fighter_num)
		hbox2.add_child(fighter)
		fighter.connect("mouse_entered",Callable(self,"on_fighter_enter").bind(fighter_info, i))
		fighter.connect("mouse_exited",Callable(self,"on_fighter_exit"))
		fighter.connect("pressed",Callable(self,"on_fighter_press").bind(i))
	var probe_num:int = 0
	for i in len(game.probe_data):
		if game.probe_data[i] == null:
			continue
		probe_num += 1
		var probe_info:Dictionary = game.probe_data[i]
		var probe = TextureButton.new()
		probe.texture_normal = load("res://Graphics/Ships/Probe%s.png" % probe_info.tier)
		probe.ignore_texture_size = true
		probe.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		probe.custom_minimum_size = Vector2(80, 80)
		hbox3.add_child(probe)
		probe.connect("mouse_entered",Callable(self,"on_probe_enter").bind(probe_info.tier, i))
		probe.connect("mouse_exited",Callable(self,"on_probe_exit"))
		probe.connect("pressed",Callable(self,"on_probe_press").bind(probe_info.tier))
		if probe_info.has("start_date"):
			var time_bar:Control = game.time_scene.instantiate()
			time_bar.scale *= 0.5
			time_bar.position = Vector2(30, 0)
			probe.add_child(time_bar)
			probe_time_bars.append({"node":time_bar, "i":i})
	$Probes/Label.text = "%s (%s / %s)" % [tr("PROBES"), probe_num, 500]
	for probe in game.probe_data:
		if probe and probe.has("start_date"):
			$Timer.start()
			_on_Timer_timeout()
			break

func on_rover_enter(rov:Dictionary, rov_id:int):
	rover_over_id = rov_id
	var st = "@i %s\n@i %s\n@i %s\n@i %s kg\n@i %s" % [Helper.format_num(rov.HP), Helper.format_num(rov.atk), Helper.format_num(rov.def), Helper.format_num(rov.weight_cap), Helper.clever_round(rov.spd)]
	if game.help.has("rover_shortcuts"):
		rover_has_items = false
		st += "\n%s\n%s (%s)" % [tr("CLICK_TO_USE_ROVER"), tr("PRESS_X_TO_DESTROY"), tr("NO_REFUNDS")]
		for inv in rov.inventory:
			if not inv.is_empty() and inv.type != "rover_weapons" and inv.type != "rover_mining" and inv.type != "":
				rover_has_items = true
				break
		game.help_str = "rover_shortcuts"
		if rover_has_items:
			st += "\n%s\n%s" % [tr("SHIFT_CLICK_TO_LOOT_ROVER"), tr("HIDE_SHORTCUTS")]
	game.show_adv_tooltip(st, [HP_icon, atk_icon, def_icon, inv_icon, spd_icon], 19)

func on_fighter_enter(fighter_info:Dictionary, fighter_id:int):
	fighter_over_id = fighter_id
	var st = "%s: %s" % [tr("FLEET_STRENGTH"), Helper.format_num(fighter_info.strength, true)]
	if game.help.has("rover_shortcuts"):
		st += "\n%s\n%s (%s)" % [tr("CLICK_TO_VIEW_GALAXY"), tr("PRESS_X_TO_DESTROY"), tr("NO_REFUNDS")]
	game.show_tooltip(st)

func on_probe_enter(tier:int, probe_id:int):
	probe_over_id = probe_id
	if tier == 0:
		game.show_tooltip(tr("CLICK_TO_VIEW_SC"))
	elif tier == 1:
		game.show_tooltip(tr("CLICK_TO_SEE_DISCOVERED_SC"))
	elif tier == 2:
		game.show_tooltip(tr("CLICK_TO_SEE_DISCOVERED_U"))

func on_probe_exit():
	probe_over_id = -1
	game.hide_tooltip()

func on_fighter_exit():
	fighter_over_id = -1
	game.hide_tooltip()

func on_fighter_press(i:int):
	_on_close_button_pressed()
	if game.fighter_data[i].tier == 0:
		game.switch_view("galaxy", {"fn":"set_to_fighter_coords", "fn_args":[i]})
	elif game.fighter_data[i].tier == 1:
		game.switch_view("cluster", {"fn":"set_to_fighter_coords", "fn_args":[i]})

func on_probe_press(tier:int):
	_on_close_button_pressed()
	if tier == 0:
		game.switch_view("universe")
	else:
		game.switch_view("dimension")

func on_rover_exit():
	rover_over_id = -1
	rover_has_items = false
	game.hide_adv_tooltip()

func on_rover_press(rov:Dictionary, rov_id:int):
	if Input.is_action_pressed("shift"):
		if rover_has_items:
			var remaining:bool = false
			for i in len(rov.inventory):
				if rov.inventory[i].is_empty():
					continue
				if rov.inventory[i].type != "rover_weapons" and rov.inventory[i].type != "rover_mining":
					if rov.inventory[i].name == "minerals":
						rov.inventory[i].num = Helper.add_minerals(rov.inventory[i].num).remainder
						if rov.inventory[i].num <= 0:
							rov.inventory[i].clear()
						else:
							remaining = true
					elif rov.inventory[i].name == "money":
						game.money += rov.inventory[i].num
						rov.inventory[i].clear()
					else:
						var remainder:int = game.add_items(rov.inventory[i].name, rov.inventory[i].num)
						if remainder > 0:
							remaining = true
							rov.inventory[i].num = remainder
						else:
							rov.inventory[i].clear()
			if remaining:
				game.popup(tr("NOT_ENOUGH_INV_SPACE_COLLECT"), 2)
			else:
				game.popup(tr("ITEMS_COLLECTED"), 1.5)
			game.HUD.refresh()
	elif game.c_v == "planet" and game.item_to_use.type == "":
		if tile_id == -1:
			game.view.obj.rover_selected = rov_id
			game.put_bottom_info(tr("CLICK_A_CAVE_TO_EXPLORE"), "enter_cave")
			game.toggle_panel(self)
		else:
			game.c_t = tile_id
			tile_id = -1
			game.rover_id = rov_id
			if game.tile_data[game.c_t].has("cave") or game.tile_data[game.c_t].has("diamond_tower"):
				game.switch_view("cave")
			else:
				game.switch_view("ruins")
			game.toggle_panel(self)
	elif game.item_to_use.type == "cave":
		var ok:bool = false
		for i in len(rov.inventory):
			if rov.inventory[i].has("name") and rov.inventory[i].name == game.item_to_use.name:
				rov.inventory[i].num += game.item_to_use.num
				ok = true
				break
			if not rov.inventory[i].has("name"):
				rov.inventory[i].type = "consumable"
				rov.inventory[i].name = game.item_to_use.name
				rov.inventory[i].num = game.item_to_use.num
				ok = true
				break
		if ok:
			game.remove_items(game.item_to_use.name, game.item_to_use.num)
			game.item_to_use.num = 0
			game.update_item_cursor()
			game.popup(tr("ITEMS_SENT_TO_ROVER"), 2.0)
		else:
			game.popup(tr("ROVERS_INV_FULL"), 2.0)

func _on_close_button_pressed():
	game.toggle_panel(self)


func _on_Timer_timeout():
	if not visible:
		return
	var curr_time = Time.get_unix_time_from_system()
	var refresh:bool = false
	for dict in probe_time_bars:
		var i = dict.i
		var probe = game.probe_data[i]
		var bar = dict.node
		if not probe.has("start_date"):
			continue
		var start_date = probe.start_date
		var length = probe.explore_length
		var progress = (curr_time - start_date) / float(length)
		bar.get_node("TimeString").text = Helper.time_to_str(length - curr_time + start_date)
		bar.get_node("Bar").value = progress
		if progress >= 1:
			if probe.tier == 0:
				game.u_i.cluster_data[probe.obj_to_discover].visible = true
				game.popup(tr("CLUSTER_DISCOVERED_BY_PROBE"), 3)
				refresh = true
			game.probe_data[i] = null
	if refresh:
		refresh()
	await get_tree().process_frame
	$Timer.start()
