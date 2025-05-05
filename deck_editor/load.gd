extends NinePatchRect


const DeckEditor = preload("uid://bnlx0ny3kbh5p")
var deck_editor: DeckEditor

var fileCallback = JavaScriptBridge.create_callback(_on_file_select_callback)
var jsonCallback = JavaScriptBridge.create_callback(_json_callback)


func _ready() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.get_interface("window").getFileSelect(fileCallback)
		JavaScriptBridge.get_interface("window").getJSONSelect(jsonCallback)
	
	## For dragging the file onto the window to import it
	get_viewport().files_dropped.connect(_on_files_dropped)


## CSV
func _press_csv() -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var tscn = load("uid://dbnpii6vux4ie").instantiate()
		tscn.get_child(2).pressed.connect(func (): tscn.queue_free())
		get_tree().get_root().add_child(tscn)
		return
	
	## Three methods: OS.shell_open(path) ; FileDialog.popup_centered() ; DisplayServer.file_dialog_show()
	if not OS.has_feature("web"):
		DisplayServer.file_dialog_show("Choose an CSV file", "", "",
			true, DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, ["*.csv"], _on_file_dialog_file_selected)
	## All three prior do not work on web builds. Instead we have this javascript buttfuckery.
	else:
			JavaScriptBridge.get_interface("window").input.click()

## File selected from file explorer on web
func _on_file_select_callback(args) -> void:
	#set_deck_name(JavaScriptBridge.get_interface("window").csv_name)
	deck_editor.set_deck_name("Imported Deck") # dsfasdfsadfsdfsfsd
	import_csv(args[0].split("\n"))

## File selected from file explorer on standalone
func _on_file_dialog_file_selected(status,path,_idx):
	if status:
		## To make the import_csv func reusable for web-import, we chicanerize the lines into an array
		var file := FileAccess.open(path[0], FileAccess.READ)
		deck_editor.set_deck_name(Tool.get_file_name(path[0]))
		var text :PackedStringArray = file.get_as_text(true).split("\n")
		file.close()
		import_csv(text)

## File dropped onto the window
func _on_files_dropped(paths):
	for path in paths:
		if path.get_extension() == "csv":
			var file := FileAccess.open(path, FileAccess.READ)
			var text :PackedStringArray = file.get_as_text(true).split("\n")
			file.close()
			import_csv(text)
			return
		if path.get_extension() == "json":
			json_selected(1,[path],0)
			return


## JSON
func _press_json() -> void:
	
	if OS.has_feature("web"):
		JavaScriptBridge.get_interface("window").input_json.click()
		return
	
	DisplayServer.file_dialog_show("Choose a JSON file", "", "",
		true, DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, ["*.json"], json_selected)

func _json_callback(args) -> void:
	var dict = JSON.parse_string(args[0])
	deck_editor.set_deck_name(dict["name"])
	deck_editor.deck_owner_cid = dict["owner"]
	deck_editor.deck_card_cids = dict["cards"]
	deck_editor.deck_type = dict["type"]
	deck_editor.load_deck()

func json_selected(status,selected_paths,_selected_filter_index):
	if status:
		
		close()
		
		var file := FileAccess.open(selected_paths[0], FileAccess.READ)
		var dict = JSON.parse_string(file.get_as_text())
		file.close()
		deck_editor.set_deck_name(dict["name"])
		deck_editor.deck_owner_cid = dict["owner"]
		deck_editor.deck_card_cids = dict["cards"]
		deck_editor.deck_type = dict["type"]
		deck_editor.load_deck()


## PRECON
func _press_precon() -> void:
	var tscn = load('uid://cuo7v7bto1qew').instantiate()
	deck_editor.add_child(tscn)
	tscn.plate_selected.connect(load_precon)

func load_precon(idx:int):
	
	close()
	
	deck_editor.set_deck_name(DeckData.NAME[idx])
	
	# How convenient, that -1 represents "no owner" both in the data and in here
	deck_editor.deck_owner_cid = DeckData.OWNER[idx]
	
	# Also convenient, isn't it?
	deck_editor.deck_card_cids = DeckData.CARDS[idx]
	#printt(DeckData.CARDS[idx].size(), deck_card_cids.size())
	
	# Set Hidden image to the default
	deck_editor.deck_hidden_image = load("uid://s41kvt2kyp21")
	deck_editor.get_node('Overview/Hidden/Label').text = "Hidden"
	
	deck_editor.load_deck()


## Remove this scene and the parent (Tint)
func close() -> void:
	get_parent().hide()
	get_parent().queue_free()



## Construe the Global Numbers, and amounts, from the lines
func import_csv(text:PackedStringArray) -> void:
	
	var d := text[1].split(",", true, 2) # Deck Type, Card Count
	var ownr := card_global_number_from_line(text[3]) # Owner Card
	deck_editor.deck_owner_cid = ownr
	
	# Get the # of cards in the deck
	var number := int(d[1].split("/")[0])
	deck_editor.deck_card_cids.resize(number)
	
	# Set Hidden image to the default
	deck_editor.deck_hidden_image = load("res://hidden.jpg")
	deck_editor.get_node('Overview/Hidden/Label').text = "Hidden"
	
	var text_idx := 5
	var cnt := 0
	while cnt < number and text_idx < text.size():
		var line := text[text_idx]
		text_idx += 1
		
		## Get the #copies of this card in the deck
		var amount := int(line.split(",", true, 1)[0])
		if amount == 0:
			## The deck likely says it has more cards than it really does (this line was empty)
			#show_warning("Are you sure the quantities of each card in your deck adds " +
			#	"up to the total number it should have?")
			break
		
		## Get the global id of the card, and put it into the array for each copy of the card
		var gid = card_global_number_from_line(line)
		for i in amount:
			if cnt+i > number:
				## The deck likely has more cards than it says it does
				#show_warning("Are you sure the quantities of each card in your deck " +
				#	"does not exceed the total number it should have?")
				break
			deck_editor.deck_card_cids[cnt+i] = gid
		
		cnt += amount
	
	deck_editor.load_deck()
	close()

func card_global_number_from_line(line:String) -> int:
	## Motherfucking CARD NAMES WITH COMMAS IN THEM throw off attempts at simple ,-splitting
	## Further, a card can have multipe global ids, which will be ,-seperated and surrounded by "" too
	## > trawl until the 3rd comma, ignoring commas between "", and capture text until 4th comma
	## Return the rightmost global number, since most people will want the latest edition version
	var cnt := 0
	var num := ""
	var capture := false
	var ignore := false
	for i in line.length():
		
		if line[i] == "," and not ignore:
			cnt += 1
			if cnt == 3:
				capture = true
			elif cnt == 4:
				break
		elif line[i] == "\"":
			ignore = false if ignore else true
		elif capture:
			num += line[i]
	
	var find := num.find(" ")
	while find != -1:
		num = num.erase(find)
		find = num.find(" ")
	
	# Correct the N/A global numbers of the 1st Vanilla owners.
	var right := num.split(",")[-1]
	if right == "N/A":
		match line.split(",")[2]:
			"Master": right = "1495"
			"Mistress": right = "1496"
			"Mastress": right = "1497"
			"Dominator": right = "1498"
	return int(right)
