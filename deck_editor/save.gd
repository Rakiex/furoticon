extends NinePatchRect


const DeckEditor = preload("uid://bnlx0ny3kbh5p")
var deck_editor: DeckEditor

var ext := ""
var export_path := ""


func _press_png():
	export_path = "Screenshot"
	ext = "image/png"
	save_to()

func _press_jpg():
	export_path = "Screenshot"
	ext = "image/jpeg"
	save_to()

func save_to():
	if deck_editor.work_background_canvas:
		return
	
	var stime := Time.get_ticks_msec()
	
	if OS.has_feature("web"):
		if ext == "image/png":
			JavaScriptBridge.download_buffer(deck_editor.canvas.save_png_to_buffer(), deck_editor.get_deck_name(), ext)
		else:
			JavaScriptBridge.download_buffer(deck_editor.canvas.save_jpg_to_buffer(), deck_editor.get_deck_name(), ext)
	else:
		if ext == "image/png":
			var _e := deck_editor.canvas.save_png("user://%s.png" % deck_editor.get_deck_name())
		else:
			var _e := deck_editor.canvas.save_jpg("user://%s.jpg" % deck_editor.get_deck_name())
	
	print("Image saved in %s seconds." % ((Time.get_ticks_msec() - stime) * 0.001))


func _press_json():
	
	var deck_object :Dictionary = {
		"name":deck_editor.get_deck_name(),
		"type":deck_editor.deck_type,
		"owner":deck_editor.deck_owner_cid,
		"cards":deck_editor.deck_card_cids
	}
	
	var bytes := JSON.stringify(deck_object, "\t").to_utf8_buffer()
	
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(bytes, deck_editor.get_deck_name(), "application/json")
	else:
		# OS.get_executable_path().get_base_dir() + "/aaaa.ogv"
		var file = FileAccess.open("user://%s.json" % deck_editor.get_deck_name(), FileAccess.WRITE)
		file.store_buffer(bytes)


func _press_tts_json() -> void:
	
	var back_url :String = $JSON2/Back.text
	
	var card := {
		'Name': "Card",
		'Transform': { 'posX': 0.0, 'posY': 0.0, 'posZ': 0.0,
			'rotX': 0.0, 'rotY': 0.0, 'rotZ': 0.0,
			'scaleX': 1.0, 'scaleY': 1.0, 'scaleZ': 1.0, },
		'Nickname': "",
		'Description': "",
		'ColorDiffuse': { 'r': 0.713235259, 'g': 0.713235259, 'b': 0.713235259, },
		'Locked': false,
		'Grid': true,
		'Snap': true,
		'Autoraise': true,
		'Sticky': true,
		'Tooltip': true,
		'CardID': 100, ## !
		'SidewaysCard': false,
		'LuaScript': "",
		'LuaScriptState': "",
		'ContainedObjects': [],
		'GUID': "0"
	}
	
	var tts_object :Dictionary = {
		'SaveName': "",
		'GameMode': "",
		'Date': "",
		'Table': "",
		'Sky': "",
		'Note': "",
		'Rules': "",
		'PlayerTurn': "",
		'LuaScript': "",
		'LuaScriptState': "",
		'ObjectStates': [ {
			'Name': "Deck",
			'Transform': { 'posX': 0.0, 'posY': 0.0, 'posZ': 0.0,
				'rotX': 0.0, 'rotY': 180.0, 'rotZ': 0.0,
				'scaleX': 1.0, 'scaleY': 1.0, 'scaleZ': 1.0, },
			'Nickname': "",
			'Description': "",
			'ColorDiffuse': { 'r': 0.713235259, 'g': 0.713235259, 'b': 0.713235259, },
			'Locked': false,
			'Grid': true,
			'Snap': true,
			'Autoraise': true,
			'Sticky': true,
			'Tooltip': true,
			'SidewaysCard': false,
			
			'DeckIDs': [], ## 100+
			
			'CustomDeck': { '1': {
					'FaceURL': $JSON2/Front.text, ## !
					'BackURL': "http://i.imgur.com/dR21fvu.jpg" if back_url == '' else back_url, ## !
					'NumWidth': deck_editor.canvas_columns, ## !
					'NumHeight': deck_editor.canvas_rows, ## !
					'BackIsHidden': false,
					'UniqueBack': false }},
			
			'LuaScript': "",
			'LuaScriptState': "",
		
			'ContainedObjects': [] ## !
		} ]
	}
	
	## Owner & Deck
	var count = deck_editor.deck_card_cids.size()
	if deck_editor.export_singleton:
		count = Tool.size_unique(deck_editor.deck_card_cids)
	
	var deckid := 100
	if deck_editor.deck_owner_cid != -1:
		count += 1
	for i in count:
		tts_object.ObjectStates[0].DeckIDs.append(deckid + i)
		var card_dupe := card.duplicate()
		card_dupe.CardID = deckid + i
		tts_object.ObjectStates[0].ContainedObjects.append(card_dupe)
	
	## File
	var bytes := JSON.stringify(tts_object, "\t").to_utf8_buffer()
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(bytes, deck_editor.get_deck_name(), "application/json")
	else:
		var file = FileAccess.open("user://%s.json" % deck_editor.get_deck_name(), FileAccess.WRITE)
		file.store_buffer(bytes)

func _on_front_text_changed(new_text: String) -> void:
	if new_text == "":
		$JSON2.disabled = true
	else:
		$JSON2.disabled = false
