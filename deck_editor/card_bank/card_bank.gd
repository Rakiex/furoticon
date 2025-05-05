extends Control


const FIRST_CARD := 1
const LAST_CARD := 1500 + 1

var cards :Array = []
var filters = {}

@export var big_view :TextureRect = null
@export var deck :Node = null


# Capture [k:glyph v:text]
## Text-Based filters
const REGEX_ALPHABET_PATTERN := "(^(?<k>[-~]?%s):(?<v>.*)$)"
const REGEX_ALPHABET_GLYPHS :Array = [
	"c", # (C)ard (N)ame // (?=:.) would prevent filter until there is an actual value
	"a", # (A)rtist Name
	"s", # (S)kill Text
	"f", # (F)lavor Text
	#"k", # (K)eyword Skills
	"t", # (T)ype
	"d", # (D)efining Types
	"g", # (G)ender
	#"gp", # (G)ender (P)oint Cost
	"e", # (E)dition
	"r" # (R)arity
	]

# Capture [k:glyph c:comparator v:value]
## Number-Based filters
const REGEX_NUMERIC_PATTERN := "(^(?<k>[-~]?%s)[a-zA-Z]*(?<c>[<>=]|(<=)|(>=)|(=<)|(=>))(?<v>[0-9]+)$)"
const REGEX_NUMERIC_GLYPHS :Array = [ # Not PackedStringArray - then we'd have to convert to Array and back
	"de", # Bonus to (De)ck Size
	"ca", # (Ca)rds in Starting Hand
	"ma", # (Ma)ximum Cards in Hand
	"st", # Max (St)amina Bonus
	"tu", # AP per (T)urn
	"dr", # AP to (Dr)aw a Card
	"sw", # AP to (Sw)ing with a Furre
	"pu", # AP to (Pu)t Out with a Furre
	#"gpt", # Shortcut: (T)otal of all (GP) Costs
	#"pet", # Shortcut: (T)otal of all (PE) Values
	"gp", # Shortcut: All (GP) Costs
	"pe", # Shortcut: All (PE) Values - <Any> - Total
	"mp", # (M)ale (P)leasuring Experience
	"fp",
	"hp",
	"op",
	"n", # Local (N)umber
	"gn", # (G)lobal Number
	"ac", # (A)ction Cost
	"mc", # (M)ale GP Cost
	"fc",
	"hc",
	"oc",
	"sp", # (S)tamina
	"c", # (C)opies ` Returns cards whose number of copies from the same 'base' compare to <v>
	"d", # (D)efines ` Returns cards who number of defining types compare to <v>
	"en", # (E)dition Index
	"rn" # (R)arity Index
	]


const button_filters := {
	'Name': { 'Key': 'c', 'Value': 'get_card_name' },
	'ActionCost': { 'Key': 'ac', 'Value': 'get_action_cost' },
	'MaleCost': { 'Key': 'mc', 'Value': 'get_male_cost' },
	
	'Stamina': { 'Key': 'sp', 'Value': 'get_stamina' },
	'MalePE': { 'Key': 'mp', 'Value': 'get_male_pleasure' },
	'FemalePE': { 'Key': 'fp', 'Value': 'get_female_pleasure' },
	'HermPE': { 'Key': 'hp', 'Value': 'get_herm_pleasure' },
	'OtherkinPE': { 'Key': 'op', 'Value': 'get_other_pleasure' },
	
	'Genders': { 'Key': 'g', 'Value': 'get_gender' },
	'DeckBonus': { 'Key': 'de', 'Value': 'get_bonus_to_deck_size' },
	'StartHand': { 'Key': 'ca', 'Value': 'get_cards_in_starting_hand' },
	'MaxHand': { 'Key': 'ma', 'Value': 'get_maximum_cards_in_hand' },
	'MaxStamina': { 'Key': 'st', 'Value': 'get_max_stamina_bonus' },
	'TurnAction': { 'Key': 'tu', 'Value': 'get_ap_per_turn' },
	'DrawAction': { 'Key': 'dr', 'Value': 'get_ap_to_draw' },
	'SwingAction': { 'Key': 'sw', 'Value': 'get_ap_to_swing' },
	'PutAction': { 'Key': 'pu', 'Value': 'get_ap_to_put' },
	
	'Type': { 'Key': 't', 'Value': 'get_type_string' },
	'Define': { 'Key': 'd', 'Value': 'get_define_strings' },
	'Edition': { 'Key': 'e', 'Value': 'get_edition_string' },
	'Skill': { 'Key': 's', 'Value': 'get_skill_string' },
	'Flavor': { 'Key': 'f', 'Value': 'get_flavor' },
	'Artist': { 'Key': 'a', 'Value': 'get_artist_string' },
	'Number': { 'Key': 'n', 'Value': 'get_number' },
}

@onready var dynagrid := $DynamicGrid
@onready var filterbox := $Filters
@onready var CardTotal := $Total


func _ready() -> void:
	
	resize_grid()
	
	## Grid Setup
	var atlas_image = load('uid://dbxbojueoo57q')
	var trect := TextureRect.new()
	trect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	dynagrid.entry_created.connect(_entry_created.bind(atlas_image))
	dynagrid.entry_refreshed.connect(_entry_refreshed)
	
	cards = range(FIRST_CARD,LAST_CARD)
	dynagrid.fill_grid(trect, LAST_CARD-1)
	CardTotal.text = str(LAST_CARD-1)
	
	var filter = $Filters/Filter
	filter.became_empty.connect(_filter_empty.bind(filter))
	filter.became_valid_filter.connect(_filter_valid.bind(filter))
	filter.changed.connect(_filter_changed.bind(filter))
	
	## Button Filters on the Card View
	for x in big_view.get_child(0).get_children():
		if x is Button:
			x.pressed.connect(_button_filter_press.bind(str(x.name)))
		else:
			## I'm getting lazier and lazier
			for y in x.get_children():
				if y is Button:
					y.pressed.connect(_button_filter_press.bind(str(y.name)))


func resize_grid() -> void:
	var filters_size = filterbox.get_child_count() * 35.0
	dynagrid.position.y = filters_size
	dynagrid.size.y = size.y - filters_size
	dynagrid.reset_scroll()


func create_filter() -> void:
	var new_filter = preload('uid://n7i4ny7kw54r').instantiate()
	filterbox.add_child(new_filter)
	new_filter.became_empty.connect(_filter_empty.bind(new_filter))
	new_filter.became_valid_filter.connect(_filter_valid.bind(new_filter))
	new_filter.changed.connect(_filter_changed.bind(new_filter))


func _filter_empty(filter) -> void:
	## Leave the last Filter box there
	if filterbox.get_child_count() == 1:
		return
	filter.hide()
	filter.get_parent().remove_child(filter)
	filter.queue_free()
	resize_grid()


func _filter_valid(filter) -> void:
	create_filter()
	resize_grid()


func _filter_changed(filter) -> void:
	filters[filter] = [filter.pre, filter.tag, filter.op, Tool.scrub(filter.param), filter.alpha]
	apply_filters()


func _entry_created(entry:Control, _data_index:int, atlas_image) -> void:
	entry.mouse_entered.connect(card_mouse_entered.bind(entry))
	entry.gui_input.connect(card_gui_input.bind(entry))
	
	var atlas := AtlasTexture.new()
	atlas.atlas = atlas_image
	atlas.region.size.x = 45.0
	atlas.region.size.y = 63.0
	entry.texture = atlas


## Update atlas texture to show the correct card, based on index.
func _entry_refreshed(entry:Control, data_index:int) -> void:
	var atlas_index = cards[data_index] - 1
	var row = (atlas_index) / 10
	var column = (atlas_index) % 10
	entry.texture.region.position.x = 45.0 * column
	entry.texture.region.position.y = 63.0 * row


func card_mouse_entered(card:TextureRect) -> void:
	if big_view != null:
		var hover_global = cards[ dynagrid.dataindex(card) ]
		big_view.texture = load( CardLib.get_path_to_art( hover_global ) )
		big_view.get_child(0).global = hover_global


func card_gui_input(event:InputEvent, trect:TextureRect) -> void:
	if event is InputEventMouseButton:
		
		if event.pressed:
			
			## Left Mouse - Add to Deck (if we didn't drag the scroll bar)
			if event.button_index == 1:
				dynagrid.scroll_touch_tracker = dynagrid.Scroll.value
			
			## Middle Mouse - Debug Print whatever I wanted to see today
			elif event.button_index == 3:
				print( cards[ dynagrid.dataindex(trect) ] )
		
		else:
			## Left Mouse - Add to Deck (if we didn't drag the scroll bar)
			if event.button_index == 1:
				if dynagrid.scroll_touch_tracker == dynagrid.Scroll.value:
					deck.add_card( cards[ dynagrid.dataindex(trect) ] )


func apply_filters() -> void:
	
	var filtered_cards = []
	for i in range(FIRST_CARD,LAST_CARD):
		
		var add := true
		var or_cond := false
		var or_match := false
		
		for f in filters.values():
			var negate := false
			var or_filter := false
			
			var pre :String = f[0]
			var key :String = f[1]
			
			## Negate
			if pre == "-":
				negate = true
			
			## Option
			if pre == "~":
				or_cond = true
				or_filter = true
			
			## Alphabetical Filter
			if f[4] == 0:
				
				var find :int = -1
				var text :String = f[3]
				if text.length() == 0:
					continue
				
				match key:
					"c": find = Tool.scrub(CardLib.get_card_name(i)).find(text)
					"a": find = Tool.scrub(CardLib.get_artist_string(i)).find(text)
					"t": find = Tool.scrub(CardLib.get_type_string(i)).find(text)
					"d": find = CardLib.get_define_strings(i).map(
						func (x:String) -> int:
							return Tool.scrub(x).find(text)).max() if CardLib.has_defines(i) else -1
					"s": find = Tool.scrub(CardLib.get_skill_string(i)).find(text)
					"f": find = Tool.scrub(CardLib.get_flavor(i)).find(text)
					#"g": find = "gender":if CardLib.get_gender(i) != f[1]: add = false
					"g":
						## This on is a doozy
						#var gender_id = CardLib.get_gender(i)
						var gender_string = CardLib.get_gender_string(i)
						# Presume the search is for "Male" cards...
						if text[0] == 'm':
							## We don't want to include "feMALE" cards by mistake...
							if gender_string.find('female') != -1:
								## The only case where male and female are in the same string is where male- exists.
								find = -1 if not gender_string.find('male-') == 0 else 0
							else:
								find = gender_string.find(text)
						else:
							find = gender_string.find(text)
					"e": find = Tool.scrub(CardLib.get_edition_string(i)).find(text)
					"r": find = Tool.scrub(CardLib.get_rarity_string(i)).find(text)
					_: find = -1
				
				if or_filter:
					if find != -1:
						or_match = true
					continue
				
				if find != -1:
					if negate:
						add = false
					continue
				if not negate:
					add = false
				continue
			
			## Numerical Filter
			var num := 0
			var con :String = f[2]
			var val :int = int(f[3])
			
			## Find the number to compare to
			match key:
				"n": num = CardLib.get_number(i)
				"gn": num = i
				"ac": num = CardLib.get_action_cost(i)
				"sp":
					## Even if this is negated or optioned, we want to exclude non-furres with this filter
					if not CardLib.has_furre_stats(i): add = false; continue
					num = CardLib.get_stamina(i)
				"en": num = CardLib.get_edition(i)
				"rn": num = CardLib.get_rarity_priority(i)
				## GP Cost
				"gp": num = CardLib.get_gender_cost(i).max()
				"mc": num = CardLib.get_male_cost(i)
				"fc": num = CardLib.get_female_cost(i)
				"hc": num = CardLib.get_herm_cost(i)
				"oc": num = CardLib.get_other_cost(i)
				## Pleasure
				"pe":
					if not CardLib.has_furre_stats(i): add = false; continue
					num = CardLib.get_pleasure(i).max()
				"mp":
					if not CardLib.has_furre_stats(i): add = false; continue
					num = CardLib.get_male_pleasure(i)
				"fp":
					if not CardLib.has_furre_stats(i): add = false; continue
					num = CardLib.get_female_pleasure(i)
				"hp":
					if not CardLib.has_furre_stats(i): add = false; continue
					num = CardLib.get_herm_pleasure(i)
				"op":
					if not CardLib.has_furre_stats(i): add = false; continue
					num = CardLib.get_other_pleasure(i)
				# Copies/Alts
				"co": num = CardLib.get_alts(i).size()
				# Defines
				#"de": num = CardLib.get_defines(i).size()
				## Owner
				"de":
					if not CardLib.is_owner(i): add = false; continue
					num = CardLib.get_bonus_to_deck_size(i)
				"ca":
					if not CardLib.is_owner(i): add = false; continue
					num = CardLib.get_cards_in_starting_hand(i)
				"ma":
					if not CardLib.is_owner(i): add = false; continue
					num = CardLib.get_maximum_cards_in_hand(i)
				"st":
					if not CardLib.is_owner(i): add = false; continue
					num = CardLib.get_max_stamina_bonus(i)
				"tu":
					if not CardLib.is_owner(i): add = false; continue
					num = CardLib.get_ap_per_turn(i)
				"dr":
					if not CardLib.is_owner(i): add = false; continue
					num = CardLib.get_ap_to_draw(i)
				"sw":
					if not CardLib.is_owner(i): add = false; continue
					num = CardLib.get_ap_to_swing(i)
				"pu":
					if not CardLib.is_owner(i): add = false; continue
					num = CardLib.get_ap_to_put(i)
			
			# "Or" conditions don't apply to the "add" var
			var pre_check_add_for_or := add
			
			if negate:
				match con:
					"<": if num < val: add = false
					">": if num > val: add = false
					"=": if num == val: add = false
					"<=","=<": if num <= val: add = false
					">=","=>": if num >= val: add = false
			else:
				match con:
					"<": if num >= val: add = false
					">": if num <= val: add = false
					"=": if num != val: add = false
					"<=","=<": if num > val: add = false
					">=","=>": if num < val: add = false
			
			if or_filter:
				if add:
					or_match = true
				add = pre_check_add_for_or
		
		if or_cond and or_match and add:
			filtered_cards.append(i)
		elif not or_cond and add:
			filtered_cards.append(i)
	
	cards = filtered_cards
	dynagrid.set_card_bank(0, cards.size())
	CardTotal.text = str(cards.size())


func _on_filter_help_pressed() -> void:
	var tscn = load('uid://c2mfs1p8piec6').instantiate()
	tscn.get_child(1).pressed.connect(func (): tscn.queue_free())
	get_tree().get_root().add_child(tscn)


func _button_filter_press(bname: String) -> void:
	#print(button_filters[bname])
	var empty_filter = $Filters.get_children()[-1]
	var clib = CardLib.new()
	var global = big_view.get_child(0).global
	var val = clib.call(button_filters[bname].Value, global)
	if val is Array:
		val = val[0]
	if not val is String:
		val = str(val)
	empty_filter.set_all('+', button_filters[bname].Key, '=', val)


func add_filter(a, b, c ,d) -> void:
	var empty_filter = $Filters.get_children()[-1]
	empty_filter.set_all(a, b, c, d)
