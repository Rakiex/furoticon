extends Node


const HIDDEN_IMAGE_PATH = "uid://s41kvt2kyp21"

const CARD_WIDTH := 300
const CARD_HEIGHT := 420
const CARD_WIDTH_SMALL := CARD_WIDTH * 0.2 # 60
const CARD_HEIGHT_SMALL := CARD_HEIGHT * 0.2 # 84


var http_client := HTTPClient.new()

## 
var grid_time = 0
var test_export_time_start := 0

var canvas_columns := 0
var canvas_rows := 0

var progress := 0
#var columns := 7
var export_card_count := 0
var canvas :Image = null
#var canvas_offset :Vector2i
var progress_pixel_x := 0
var progress_index := -1
var progress_art_index := -1
var progress_art_size :Vector2i

var advance_grid_index := 0

# Commence creation of canvas the moment we have textures to add
# If an image is changed (say, edition is changed) put it back in the queue
# If the canvas isn't ready by the time of export, then have the load bar pop up

var work_background_grid := false # Currently process-loading the TextureRect grid
var work_background_canvas := false # Currently process-loading the export canvas

var deck_type :String = ""
## Deck Owner cid is seperate from the array, since a deck should only have one owner anyways
var deck_owner_cid := -1
## Cards of the deck; Indexes corresponds to place in the grid - except [0], which is the owner
var deck_card_cids :PackedInt32Array = []
## Because the "Hidden" image doesn't correspond to a card, we store the image itself
var deck_hidden_image :Texture2D = null

## { 'Index':int , 'Texture':Texture2D }
var canvas_image_draw_queue :Array[Dictionary] = []
## Since we like to start and stop middle of plotting pixels from a card's image onto the canvas
var progress_art :Image

## Myriad singleton-related vars.
var export_count := 0
var export_singleton := false
var export_singleton_memory := []
## To determine track the canvas index of cards, this is updated when generating a duplicate card.
var singleton_export_index_offset := 0
## Grid Cards that don't correspond to the canvas - aka copies in singleton - have null for their value.
var grid_index_to_canvas_index := {}

var clear_button_in_clear_mode := true
var undo_deck_type :String = ""
var undo_deck_owner_cid := -1
var undo_deck_card_cids :PackedInt32Array = []
var undo_deck_hidden_image :Texture2D = null


var hiddenCallback = JavaScriptBridge.create_callback(_hidden_callback)


@onready var container := $Deck/Grid
@onready var export_progress := $Port/SaveExport/ColorRect
@onready var cardbank := $CardBank


func _ready():
	
	## Only need Process on when assembling Grid or Canvas
	set_process(false)
	
	## If this is the web version, some shit needs to be done
	if OS.has_feature("web"):
		
		$Overview/Hidden.tooltip_text = "Left-Click if you want the last image to be the Backing.
		Right-Click here to set the last image back to the hidden image - the question mark."
		
		JavaScriptBridge.get_interface("window").getHiddenSelect(hiddenCallback)


func _process(delta:float) -> void:
	if work_background_grid: if not advance_grid(delta): return
	if work_background_canvas: if not progress_export(delta): return
	set_process(false)


func set_deck_name(x:String) -> void:
	$Overview/TextEdit.text = x
func get_deck_name() -> String:
	return $Overview/TextEdit.text


func load_deck() -> void:
	disable_export_buttons()
	change_undo_to_clear()
	
	if deck_hidden_image == null:
		deck_hidden_image = load(HIDDEN_IMAGE_PATH)
	
	## Reset Grid in case we already had shit in there
	#$ScrollContainer.position = Vector2(576,385)
	
	var count = deck_card_cids.size()
	
	
	canvas_image_draw_queue.clear()
	export_singleton_memory.clear()
	singleton_export_index_offset = 0
	grid_index_to_canvas_index.clear()
	
	## Remove all excess main deck card textures that may already be in the grid
	clear_grid(count)
	
	## Grid Size
	#var size_x :float = min(CARD_WIDTH_SMALL * count, CARD_WIDTH_SMALL * 7)
	#var size_y :float = min(2520*0.2, CARD_HEIGHT_SMALL * ceil(count/7.0))
	#$ScrollContainer.custom_minimum_size = Vector2(size_x,size_y)
	#var pos = $ScrollContainer.position
	#$ScrollContainer.position = Vector2(pos.x-size_x/2, pos.y-size_y/2)
	
	## adjust count to include the owner/hidden
	$Overview/Control/Total/Label2.text = str(count)
	var bonus = 1
	if deck_owner_cid != -1:
		bonus += 1
	count += bonus
	
	## Singleton mode
	export_count = count
	if export_singleton:
		var ugh := []
		for f in deck_card_cids:
			if not f in ugh:
				ugh.append(f)
		export_count = ugh.size() + bonus
	
	if count == 0:
		return
	$Overview/SortDeck.disabled = false
	$Overview/ClearDeck.disabled = false
	
	## Get to working on the export canvas right now, since we imported a .csv
	resize_canvas(export_count)
	work_background_canvas = true
	progress_index = -1
	
	if deck_owner_cid != -1:
		set_owner_card(CardLib.get_path_to_art(deck_owner_cid))
	else:
		$Overview/Owner.texture = load("res://IndicationLabelL.png")
	set_hidden_card(deck_hidden_image)
	
	var type_counts :Array[int] = [0,0,0,0]
	for i in deck_card_cids:
		var type := CardLib.get_type_string(i)
		if type == "Furre": type_counts[0] += 1
		if type == "Action": type_counts[1] += 1
		if type == "Treat": type_counts[2] += 1
		if type == "Haven": type_counts[3] += 1
	$Overview/Control/Furre/Label2.text = str(type_counts[0])
	$Overview/Control/Action/Label2.text = str(type_counts[1])
	$Overview/Control/Treat/Label2.text = str(type_counts[2])
	$Overview/Control/Haven/Label2.text = str(type_counts[3])
	
	## Load it in
	advance_grid_index = 0
	work_background_grid = true
	set_process(true)
	grid_time = Time.get_ticks_msec()


func set_owner_card(path:String) -> void:
	var image = load(path)
	
	## "Owner" is always the first card
	canvas_image_draw_queue.append({ 'Index':0 , 'Texture':image })
	grid_index_to_canvas_index['Owner'] = 0
	
	alter_queue(0, image)
	
	$Overview/Owner.texture = image


func set_hidden_card(image) -> void:
	
	## "Hidden" is always the last card
	var index := export_count-1
	#var texture = ImageTexture.create_from_image(image)
	canvas_image_draw_queue.append({ 'Index':index , 'Texture':image })
	grid_index_to_canvas_index['Hidden'] = index
	
	$Overview/Hidden.texture = image


func clear_grid(remain:int=0) -> void:
	for x in container.get_children().slice(remain):
		container.remove_child(x)
		x.queue_free()


## Sets canvas area to fit a grid of cards that (best) fits within TTS deck-import constraints.
## Said constraints being: 70 cards max, 10 columns max, 7 rows max.
## It tries to find the dimensions that lead to the least number of "blank" grid entries,
## and the dimension closest to that of a square.
func resize_canvas(card_count:int):
	test_export_time_start = Time.get_ticks_msec()
	
	export_card_count = card_count
	
	## Too many cards for TTS? Give up for now.
	if card_count > 70:
		return
	
	var dimension_options :Array[Array] = [] # [Column, Row, Distance, Leftover]
	var lowest_mod := 10
	var lowest_distance := 10
	var canvas_extra :int = 0
	
	# Issue with 
	## Of course I'd write "Issue with", then months later have no fucking clue what the full context is.
	if card_count < 4:
		canvas_columns = card_count
		canvas_rows = 1
	else:
		## Starting from the "Max Columns Possible" downward, check to see how each Column count compares.
		## If it finds an entry with less blanks, Clear everything up to then
		## If it finds an entry that is more square (and meets prior blank comp), Clear everything up to then
		for i in range(10, 0, -1):
			var rows :int = int(ceil(card_count/float(i)))
			var distance :int = abs(i-rows)
			var leftover :int = i*rows % card_count
			
			## Can't fit into a TTS deck object
			if rows > 7:
				continue
			
			if leftover < lowest_mod:
				lowest_mod = leftover
				dimension_options.clear()
			elif leftover > lowest_mod:
				continue
			
			if distance < lowest_distance:
				lowest_distance = distance
				dimension_options.clear()
			elif distance > lowest_distance:
				continue
			
			dimension_options.append([i, rows,distance,leftover])
		
		## Use the earliest (thus, highest column) entry (array can't be empty, so don't worry)
		canvas_columns = dimension_options[0][0]
		canvas_rows = dimension_options[0][1]
		canvas_extra = dimension_options[0][3]
	
	## Canvas dimensions
	var width :int = CARD_WIDTH * canvas_columns
	var height :int = CARD_HEIGHT * canvas_rows
	if canvas == null:
		canvas = Image.create(width, height, false, Image.FORMAT_RGB8)
		canvas.fill(Color.BLACK)
	else:
		## If we had a (bigger) canvas already, we do something to prevent previous cards in blank spots
		## and by do something I mean crop it to one column/row less before the true crop
		if canvas_extra > 0 and (canvas.get_width() > width or canvas.get_height() > height):
			canvas.crop(width - CARD_WIDTH, height - CARD_HEIGHT)
		canvas.crop(width, height)
	
	$TTSInfo.show()
	$TTSInfo/Label.text = "Width:%s\nHeight:%s\nNumber:%s" % [canvas_columns,canvas_rows,card_count-1]


func advance_grid(delta:float) -> bool:
	
	## We'll need this to know when the loops has taken too much time this frame
	var stime := Time.get_ticks_msec()
	
	var count = deck_card_cids.size()
	
	while advance_grid_index < count:
		var global := deck_card_cids[advance_grid_index]
		
		## Generate the card.
		var c := generate_grid_card(global, advance_grid_index)
		c.set_name("%s-%s" % [CardLib.get_card_name(global),advance_grid_index])
		
		advance_grid_index += 1
		
		## Now seems like a good time to take a break...
		var frametick = ((Time.get_ticks_msec() - stime) * 0.001)
		if frametick > delta*0.05: ## Feels real off at 0.9
			return false
	
	work_background_grid = false
	
	print("Grid generated in %s seconds." % ((Time.get_ticks_msec() - grid_time) * 0.001))
	
	return true


func progress_export(delta:float) -> bool: # maybe name this "write to canvas" or so instead
	
	## We'll need this to know when the loops has taken too much time this frame
	var stime := Time.get_ticks_msec()
	
	export_progress.show()
	export_progress.goal = export_card_count
	export_progress.value = 0
	
	## Doing a bunch of shit, stopping when we're about to stagger the program
	#print(canvas_image_draw_queue)
	while not canvas_image_draw_queue.is_empty():
		
		## We need to set the next image to transcribe
		if progress_index != canvas_image_draw_queue[0].Index:
			progress_index = canvas_image_draw_queue[0].Index
			
			## "This will fetch the texture data from the GPU, which might cause performance problems when overused.
			## Avoid calling get_image() every frame, especially on large textures."
			## - oops
			progress_art = canvas_image_draw_queue[0].Texture.get_image()
			#print(progress_art)
			progress_art_size = Vector2i(progress_art.get_width(), progress_art.get_height())
			
			## Resize images that are too big.
			## Since the inbuilt images will all be resized before compilation,
			## This only serves to prevent sadness from a user-chosen card backing.
			## Aside - it seems even Lanczos resizing doesn't have much impact on time. Neat.
			## Not neat - the tests show that lists with resizes complete FASTER, something must be wrong.
			if progress_art_size.x > CARD_WIDTH or progress_art_size.y > CARD_HEIGHT:
				progress_art.resize(CARD_WIDTH,CARD_HEIGHT, Image.INTERPOLATE_LANCZOS)
				progress_art_size.x = CARD_WIDTH
				progress_art_size.y = CARD_HEIGHT
		
		## Plop the image into it's designated spot on the canvas, one column at a time
		var canvas_offset :Vector2i = Vector2i(
			CARD_WIDTH * (progress_index%canvas_columns),
			CARD_HEIGHT * (progress_index/canvas_columns))
		
		while progress_pixel_x < progress_art_size.x:
			#printt(progress_art_size, progress_pixel_x, canvas_offset, canvas.get_size())
			
			## Fill a column in a grid entry
			for y in progress_art_size.y:
				var pixel :Color = progress_art.get_pixel(progress_pixel_x,y)
				canvas.set_pixel(progress_pixel_x+canvas_offset.x, y+canvas_offset.y, pixel)
			
			## Proceed to next column
			progress_pixel_x += 1
			
			## Now seems like a good time to take a break...
			var frametick = ((Time.get_ticks_msec() - stime) * 0.001)
			## At 0.9x, my pc staggers every few frames - every few frames is not noticable, and is fast
			if frametick > delta*0.5:
				#$Export/ColorRect/ProgressBar/Frametick.text = str("%s (%s)" % [frametick,delta])
				export_progress.value = export_card_count - canvas_image_draw_queue.size()
				return false
		
		## Next!
		progress_pixel_x = 0
		canvas_image_draw_queue.pop_front()
		#export_grid_index += 1
	
	export_progress.hide()
	
	## We're done
	progress_index = -1
	enable_export_buttons()
	work_background_canvas = false
	
	## ~2s for 42c deck; Perhaps this would be faster if done through C#, but then no web export...
	print("Canvas generated in %s seconds." % ((stime - test_export_time_start) * 0.001))
	
	return true


func enable_export_buttons() -> void:
	$Port/SaveExport.disabled = false
	
func disable_export_buttons() -> void:
	$Port/SaveExport.disabled = true

## Make, or overwrite, a TextureRect to represent a card in the deck
func generate_grid_card(global:int, index:int) -> TextureRect:
	var path := CardLib.get_path_to_art(global)
	var image = load(path)
	var trect :TextureRect
	
	if export_singleton and export_singleton_memory.has(global):
		## Everything after needs its Index bumped down by 1
		singleton_export_index_offset -= 1
		grid_index_to_canvas_index[index] = -1
	else:
		export_singleton_memory.append(global)
		
		var deck_index := index + singleton_export_index_offset
		
		## Owner is at idx 0, but 'index' starts at 0 (index of GridContainer), so offset it by 1 here
		if deck_owner_cid != -1:
			deck_index += 1
		
		grid_index_to_canvas_index[index] = deck_index
		canvas_image_draw_queue.append({ 'Index':deck_index , 'Texture':image })
	
	## The index we want doesn't already have a trect at it, so make a new one
	if container.get_child_count() <= index:
		trect = TextureRect.new()
		trect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		trect.texture = image
		trect.mouse_entered.connect(card_mouse_entered.bind(index))
		trect.custom_minimum_size = Vector2(CARD_WIDTH_SMALL,CARD_HEIGHT_SMALL)
		trect.gui_input.connect(card_gui_input.bind(trect))
		trect.tooltip_text = """Left-Click to remove this card from the deck.
			\nRight-Click to add another copy of this card, to the right of it.
			\nMouse-Wheel to change the edition of this card. (and all copies of it)"""
		container.add_child(trect)
	## Overwrite existing square
	else:
		trect = container.get_child(index)
		trect.texture = image
		for c in trect.mouse_entered.get_connections():
			trect.mouse_entered.disconnect(c.callable)
		for c in trect.gui_input.get_connections():
			trect.gui_input.disconnect(c.callable)
		trect.mouse_entered.connect(card_mouse_entered.bind(index))
		trect.gui_input.connect(card_gui_input.bind(trect))
	
	return trect


func card_mouse_entered(index:int) -> void:
	$Card.texture = load( CardLib.get_path_to_art( deck_card_cids[index] ) )


func add_card(global:int) -> void:
	if CardLib.is_owner(global):
		deck_owner_cid = global
		load_deck()
		return
	deck_card_cids.append(global)
	load_deck()


func remove_card_at_index(idx:int) -> void:
	
	## Remove from grid
	var trect = container.get_child(idx)
	container.remove_child(trect)
	trect.queue_free()
	
	## Remove from data
	deck_card_cids.remove_at(idx)
	
	## Cards further in the deck need to be re-drawn to the canvas
	#card_textures.remove_at(idx)
	#for i in range(idx,container.get_child_count()):
		#alter_queue(i)
	
	## Actually, we'll have to resize the canvas, so just start over
	load_deck()


func card_gui_input(event:InputEvent, trect:TextureRect) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			
			## Trect's index should be equal to the corresponding card's index in the deck
			var idx = trect.get_index()
			var global := deck_card_cids[idx]
			
			## Left Mouse - Remove from Deck
			if event.button_index == 1:
				remove_card_at_index(idx)
			## Right Mouse - Add another
			elif event.button_index == 2:
				deck_card_cids.insert(idx, global)
				load_deck()
				return
			
			## From here on, we only care about cards with alts
			if not CardLib.has_alts(global):
				return
			
			get_viewport().set_input_as_handled()
			
			var dir := -1
			
			## Wheel Up - Edition Earlier; Wheel Down - Edition Later
			if event.button_index == 4 or event.button_index == 5:
				if event.button_index == 5: dir = 1
				
				var arr :Array = CardLib.get_alts(global)
				var i := CardLib.get_alt_index(global)
				
				i = wrapi(i+dir, 0, arr.size())
				var img := load(CardLib.get_path_to_art(arr[i]))
				
				## Just this one
				if Input.is_key_pressed(KEY_SHIFT):
					deck_card_cids[idx] = arr[i]
					trect.texture = img
					alter_queue(grid_index_to_canvas_index[idx], img)
				
				## ...or All that share this base
				else:
					var nodename := trect.get_name().split("-", 1)[0]
					var n := 0
					for x in container.get_children():
						if x.get_name().begins_with(nodename):
							x.texture = img
							deck_card_cids[n] = arr[i]
							alter_queue(grid_index_to_canvas_index[n], img)
						n += 1
				card_mouse_entered(idx)


## Put the image at images[idx] back into the queue.
func alter_queue(idx:int, img) -> void:
	
	## Happens when a grid card is a copy, in singleton mode - it doesn't belong in the queue.
	if idx == -1:
		return
	
	for x in canvas_image_draw_queue:
		if x.Index == idx:
			x.Texture = img
			
			## Just reset drawing if this was the current uh...thing to draw.
			if progress_index == idx:
				progress_pixel_x = 0
			
			## Done.
			return
	
	canvas_image_draw_queue.append({ 'Index':idx , 'Texture':img })
	set_process(true)
	work_background_canvas = true
	disable_export_buttons()


func _enter_owner():
	if deck_owner_cid == -1:
		return
	$Card.texture = $Overview/Owner.texture


func _press_owner():
	
	## Add Owner Filter
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		cardbank.add_filter('+', 't', '=', 'Owner')
		return
	
	## Remove Owner
	deck_owner_cid = -1
	$Overview/Owner.texture = load("uid://dxyfm0irggcn2")
	load_deck()


func _enter_hidden():
	#$Card.texture = $Overview/Hidden.texture
	return


func _press_hidden():
	if OS.has_feature("web"):
		
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			deck_hidden_image = load("uid://s41kvt2kyp21")
			$Overview/Hidden/Label.text = "Hidden"
			load_deck()
			return
		
		deck_hidden_image = load("uid://blpk6ykqdyyuf")
		$Overview/Hidden/Label.text = "Backing"
		load_deck()
		
		return
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		deck_hidden_image = load("uid://s41kvt2kyp21")
		$Overview/Hidden/Label.text = "Hidden"
		load_deck()
		return
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		deck_hidden_image = load("uid://blpk6ykqdyyuf")
		$Overview/Hidden/Label.text = "Backing"
		load_deck()
		return
	
	if OS.has_feature("web"):
		JavaScriptBridge.get_interface("window").input_hidden.click()
		return
	
	DisplayServer.file_dialog_show("Choose an Image file", "", "",
		true, DisplayServer.FILE_DIALOG_MODE_OPEN_FILE,
		["*.png, *.jpg, *.jpeg ; Supported Images"], hidden_image_file_selected)

func _hidden_callback(args) -> void:
	print("HEY")
	print(args)
	hidden_image_file_selected(1,args,0)
func hidden_image_file_selected(status,selected_paths,_selected_filter_index):
	if status:
		var path :String = selected_paths[0]
		var data :PackedByteArray = FileAccess.get_file_as_bytes(path)
		
		#var image = Image.create_from_data(CARD_WIDTH, CARD_HEIGHT, false, Image.FORMAT_RGB8, data)
		var image = Image.new()
		if path.get_extension() == "png":
			image.load_png_from_buffer(data)
		else:
			image.load_jpg_from_buffer(data)
		
		var texture := ImageTexture.create_from_image(image)
		deck_hidden_image = texture
		$Overview/Hidden.texture = texture
		load_deck()
		$Card.texture = texture


func _press_back():
	var main_menu= load("res://scene/main.tscn").instantiate()
	get_tree().get_root().add_child(main_menu)
	queue_free()


func _press_load() -> void:
	var tint = load('uid://c3i00xi8xhaao').instantiate()
	var scene = load('uid://dr4i2ysmbehj4').instantiate()
	scene.deck_editor = self
	tint.add_child(scene)
	add_child(tint)


func _press_save() -> void:
	var tint = load('uid://c3i00xi8xhaao').instantiate()
	var scene = load('uid://dke7jc2rk2pfk').instantiate()
	scene.deck_editor = self
	tint.add_child(scene)
	add_child(tint)


func _toggle_singleton() -> void:
	export_singleton = $Port/Singleton.button_pressed
	load_deck()


func _press_sort():
	var arr :Array = Array(deck_card_cids)
	arr.sort_custom(_sort_card)
	deck_card_cids = PackedInt32Array(arr)
	load_deck()

static func _sort_card(a,b) -> bool:
	## Owners - Furres - Actions - Treats - Havens - Tokens
	var a_t := CardLib.get_type_priority(a)
	var b_t := CardLib.get_type_priority(b)
	if a_t < b_t: return true ## a is higher type
	elif a_t > b_t: return false ## b is higher type
	## Male - Female - Herm - Other
	var a_g := CardLib.get_gender_priority(a)
	var b_g := CardLib.get_gender_priority(b)
	if a_g < b_g: return true ## a is higher gender
	elif a_g > b_g: return false ## b is higher gender
	## Card Name
	var a_n := CardLib.get_card_name(a)
	var b_n := CardLib.get_card_name(b)
	if a_n < b_n: return true ## a is higher name
	elif a_n > b_n: return false ## b is higher name
	## Edition
	var a_e := CardLib.get_edition_priority(a)
	var b_e := CardLib.get_edition_priority(b)
	if a_e < b_e: return true ## a is higher edition
	elif a_e > b_e: return false ## b is higher edition
	return true ## a before b


func _press_clear():
	if clear_button_in_clear_mode:
		clear_deck()
		$Overview/ClearDeck.text = "Undo"
		clear_button_in_clear_mode = false
	else:
		undo_clear()

func clear_deck():
	undo_deck_owner_cid = deck_owner_cid
	undo_deck_card_cids = deck_card_cids.duplicate()
	undo_deck_type = deck_type
	undo_deck_hidden_image = deck_hidden_image
	
	deck_owner_cid = -1
	deck_card_cids.clear()
	deck_type = "Normal"
	load_deck()

func undo_clear():
	deck_owner_cid = undo_deck_owner_cid
	deck_card_cids = undo_deck_card_cids
	deck_type = undo_deck_type
	deck_hidden_image = undo_deck_hidden_image
	load_deck()

func change_undo_to_clear():
	$Overview/ClearDeck.text = "Clear"
	clear_button_in_clear_mode = true
