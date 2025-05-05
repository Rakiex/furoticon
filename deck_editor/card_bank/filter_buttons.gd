@tool
extends Control


const FOLDER_PATH := "res://deck_editor/card_bank/button_positions/%s.json"


@export var global := 0:
	set(_a):
		global = _a
		
		show()
		
		var type := CardLib.get_type_string(global)
		var edition := CardLib.get_edition(global)
		
		var path := ''
		var suffix := ''
		match type:
			'Furre': suffix = '_furre'
			'Owner': suffix = '_owner'
		if edition == 0:
			path = '1'
		elif type == 'Owner' and edition > 2:
			path = '5'
		else:
			path = '2'
		#match edition:
			#0: path += '1'
			#1,2: path += '2'
			#_: path += '5'
		path += suffix
		
		var file := FileAccess.open(FOLDER_PATH % path, FileAccess.READ)
		var dict = JSON.parse_string(file.get_as_text())
		file.close()
		
		var keys = dict.keys()
		recur(self, dict, keys)


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
	
	hide()
	
	## Remove the grey panes (helpful in the editor, fugly on the eyes)
	theme.set_stylebox('normal', 'Button', StyleBoxEmpty.new())
