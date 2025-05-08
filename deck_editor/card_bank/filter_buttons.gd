@tool
extends Control


signal button_created(button: Button)

const FOLDER_PATH := "res://deck_editor/card_bank/button_positions/%s.json"

@export var global := 0


func recur(node: Control, dict: Dictionary, keys: Array) -> void:
	for x in node.get_children():
		var nam = String(x.name)
		if nam in keys:
			var val = dict[nam]
			var pos = (val.Pos.substr(1,val.Pos.length()-1)).split(', ')
			var siz = (val.Size.substr(1,val.Size.length()-1)).split(', ')
			x.position = Vector2( float(pos[0]), float(pos[1]) )
			x.size = Vector2( float(siz[0]), float(siz[1]) )
			x.visible = val.Show
		else:
			#printt('filter_bank.gd', 'set_global()', "Whoops, no key for node %s." % nam)
			x.hide()
		recur(x, dict, keys)


func _ready() -> void:
	if Engine.is_editor_hint(): return
	
	#replace_key(); return
	
	## Start hidden so nothing is immediately clickable
	hide()
	
	## Remove the grey panes (helpful in the editor, fugly on the eyes)
	theme.set_stylebox('normal', 'Button', StyleBoxEmpty.new())


func set_global(g):
	global = g
	show()
	
	var type := CardLib.get_type_string(global)
	var edition := CardLib.get_edition(global)
	var layout := CardData.CARD_LAYOUT[global]
	
	var edition_string := ''
	var type_string := ''
	var layout_string := ''
	
	edition_string = str(edition)
	match type:
		'Furre': type_string = '_furre'
		'Token': type_string = '_furre'
		'Owner': type_string = '_owner'
	match layout:
		3: layout_string = '_large'
		4: layout_string = '_full'
	
	var path := edition_string + type_string + layout_string
	while not FileAccess.file_exists(FOLDER_PATH % path):
		
		## First try setting layout to Normal
		# ! Causes large/full cards that would line up with a prior edition, to instead go to that ed's normal layout
		if layout_string != '':
			layout_string = ''
			path = edition_string + type_string + layout_string
			continue
		
		## Then try reducing edition
		edition -= 1
		edition_string = str(edition)
		path = edition_string + type_string + layout_string
		
		if edition == -1:
			path = '0'
			break
	
	var file := FileAccess.open(FOLDER_PATH % path, FileAccess.READ)
	var dict = JSON.parse_string(file.get_as_text())
	file.close()
	
	var keys = dict.keys()
	recur(self, dict, keys)
	
	## Undo any changes we may have done above
	type = CardLib.get_type_string(global)
	edition = CardLib.get_edition(global)
	layout = CardData.CARD_LAYOUT[global]
	
	
	if not CardLib.has_cost(global):
		$ActionCost.hide()
		$MaleCost.hide()
	else:
		## "1st Vanilla" cards have the Name on the same line as the variable-length AP/GP Costs.
		if edition == 0:
			$Name.size.x = CardLib.get_card_name(global).length() * 7.0
		
		var gp = CardLib.get_gender_costs(global)
		var index = 0
		var gender = 0
		for node in $GenderCost.get_children():
			if gp[gender] == 0:
				node.hide()
			else:
				node.show()
				node.position.y = 0.0
				node.size.y = $GenderCost.size.y
				node.size.x = $GenderCost.size.x * gp[gender]
				index += gp[gender]
				node.position.x = -(index-1) * $GenderCost.size.x
			gender += 1
		
		if CardLib.get_action_cost(global) == 0:
			$ActionCost.hide()
		else:
			$ActionCost.show()
			## "1st Vanilla" cards have the AP Cost's position relative to the GP Cost's length.
			if edition == 0:
				$ActionCost.position.x = $GenderCost.position.x - (index * $GenderCost.size.x)
	
	## Defining Types
	$Define.hide()
	for x in $Type.get_children():
		$Type.remove_child(x)
		x.queue_free()
	var defines = CardLib.get_define_strings(global)
	if defines.size() != 0:
		var xoff :float = $Type.size.x + 5.0
		for i in defines.size():
			var btn = $Type.duplicate()
			$Type.add_child(btn)
			btn.name = 'Define-' + str(i)
			btn.position = Vector2(xoff, 0.0)
			button_created.emit(btn)
			xoff += btn.size.x
	
	if not CardLib.has_furre_stats(global):
		$Furre.hide()
	if not CardLib.has_owner_stats(global):
		$Owner.hide()
	
	if CardLib.get_skill_string(global) == '':
		$Skill.hide()
	if CardLib.get_flavor(global) == '':
		$Flavor.hide()
	## 'Full Art' cards don't show skills or flavor.
	if layout == 4:
		$Skill.hide()
		$Flavor.hide()



func replace_key() -> void:
	var folder = "res://deck_editor/card_bank/button_positions/"
	var files = DirAccess.get_files_at(folder)
	files.remove_at( files.find('layouts.json') )
	for path in files:
		var file := FileAccess.open(folder + path, FileAccess.READ_WRITE)
		var dict = JSON.parse_string(file.get_as_text())
		if 'MaleCost' in dict:
			dict['GenderCost'] = dict['MaleCost']
			dict.erase('MaleCost')
		var bytes := JSON.stringify(dict, "\t").to_utf8_buffer()
		file.store_buffer(bytes)
		file.close()
