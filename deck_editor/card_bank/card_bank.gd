extends Control


enum FilterType {
	ALPHABETIC,
	ALPHABETIC_LIST,
	NUMERIC,
	CUSTOM
}

const FIRST_CARD := 1
const LAST_CARD := 1500 + 1

var cards :Array = []
var filters = {}

@export var big_view :TextureRect = null
@export var deck :Node = null


var FILTERS = {
	#"k", # (K)eyword Skills
	#"gp", # (G)ender (P)oint Cost
	# For group values...<Any> <All> <Only One>,<Total>
	# Numeric comparisons (Greater/Less than) for things like Rarity, Edition...
	
	'gn': [func(i):return i, FilterType.NUMERIC, null],
	
	'c': [CardLib.get_card_name, FilterType.ALPHABETIC, null], # (C)ard Name 
	't': [CardLib.get_type_string, FilterType.ALPHABETIC, null], # (T)ype
	's': [CardLib.get_skill_string, FilterType.ALPHABETIC, null], # (S)kill Text
	'f': [CardLib.get_flavor, FilterType.ALPHABETIC, CardLib.has_flavor], # (F)lavor Text
	'e': [CardLib.get_edition_string, FilterType.ALPHABETIC, null], # (E)dition
	'r': [CardLib.get_rarity_string, FilterType.ALPHABETIC, null], # (R)arity
	'g': [CardLib.get_gender_string, FilterType.ALPHABETIC, null], # (G)ender
	
	'd': [CardLib.get_define_strings, FilterType.ALPHABETIC_LIST, CardLib.has_defines], # (D)efining Types
	'a': [CardLib.get_artist_strings, FilterType.ALPHABETIC_LIST, null], # (A)rtist Name
	# CardLib.get_defines(i).size()
	
	'n': [CardLib.get_number, FilterType.NUMERIC, null], # Local (N)umber
	'en': [CardLib.get_edition, FilterType.NUMERIC, null],
	'rn': [CardLib.get_rarity_priority, FilterType.NUMERIC, null],
	'tc': [CardLib.get_total_cost, FilterType.NUMERIC, CardLib.has_cost], # (T)otal (C)ost
	'ac': [CardLib.get_action_cost, FilterType.NUMERIC, CardLib.has_cost], # (A)ction (C)ost
	'gc': [CardLib.gp_cost, FilterType.NUMERIC, CardLib.has_cost], # Total (G)P (C)ost
	# Highest GP Cost? Lowest GP Cost?
	'mc': [CardLib.get_male_cost, FilterType.NUMERIC, CardLib.has_cost], # (M)ale GP (C)ost
	'fc': [CardLib.get_female_cost, FilterType.NUMERIC, CardLib.has_cost],
	'hc': [CardLib.get_herm_cost, FilterType.NUMERIC, CardLib.has_cost],
	'oc': [CardLib.get_other_cost, FilterType.NUMERIC, CardLib.has_cost],
	'sp': [CardLib.get_stamina, FilterType.NUMERIC, CardLib.has_furre_stats], # (S)tamina
	'pe': [func(i):return CardLib.get_pleasure(i).max(), FilterType.NUMERIC, CardLib.has_furre_stats], # Highest (PE)
	'mp': [CardLib.get_male_pleasure, FilterType.NUMERIC, CardLib.has_furre_stats], # (M)ale (P)leasuring Experience
	'fp': [CardLib.get_female_pleasure, FilterType.NUMERIC, CardLib.has_furre_stats],
	'hp': [CardLib.get_herm_pleasure, FilterType.NUMERIC, CardLib.has_furre_stats],
	'op': [CardLib.get_other_pleasure, FilterType.NUMERIC, CardLib.has_furre_stats],
	'de': [CardLib.get_bonus_to_deck_size, FilterType.NUMERIC, CardLib.is_owner],
	'ca': [CardLib.get_cards_in_starting_hand, FilterType.NUMERIC, CardLib.is_owner],
	'ma': [CardLib.get_maximum_cards_in_hand, FilterType.NUMERIC, CardLib.is_owner],
	'st': [CardLib.get_max_stamina_bonus, FilterType.NUMERIC, CardLib.is_owner],
	'tu': [CardLib.get_ap_per_turn, FilterType.NUMERIC, CardLib.is_owner],
	'dr': [CardLib.get_ap_to_draw, FilterType.NUMERIC, CardLib.is_owner],
	'sw': [CardLib.get_ap_to_swing, FilterType.NUMERIC, CardLib.is_owner],
	'pu': [CardLib.get_ap_to_put, FilterType.NUMERIC, CardLib.is_owner],
	
	'co': [func(i):return CardLib.get_alts(i).size(), FilterType.NUMERIC, null],
}

# ^ Sort (Maybe doesn't make too much sense as a pre-code...)
# ~ Or
# +
# -
# -~ Exlusive-Or (Cards that only match one, but no more, of filters using it)
# # Count? (Or just have a number somewhere that lists all cards in bank, which will accomplish the same thing)

# >
# >=
# =
# <=
# <

## A smart man would've simply named the buttons after the tags instead. Alas.
const button_filters := {
	'Name': 'c',
	'Type': 't',
	'Edition': 'e',
	'Skill': 's',
	'Flavor': 'f',
	'Genders': 'g',
	
	'Artist': 'a',
	'Define': 'd',
	
	'ActionCost': 'ac',
	'MaleCost': 'mc',
	'FemaleCost': 'fc',
	'HermCost': 'hc',
	'OtherCost': 'oc',
	
	'Stamina': 'sp',
	'MalePE': 'mp',
	'FemalePE': 'fp',
	'HermPE': 'hp',
	'OtherkinPE': 'op',
	
	'DeckBonus': 'de',
	'StartHand': 'ca',
	'MaxHand': 'ma',
	'MaxStamina': 'st',
	'TurnAction': 'tu',
	'DrawAction': 'dr',
	'SwingAction': 'sw',
	'PutAction': 'pu',
	
	'Number': 'n',
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
	filter.bank = self
	filter.removed.connect(_filter_removed.bind(filter))
	filter.became_empty.connect(_filter_empty.bind(filter))
	filter.became_valid_filter.connect(_filter_valid.bind(filter))
	filter.changed.connect(_filter_changed.bind(filter))
	
	## Button Filters on the Card View
	for x in big_view.get_child(0).get_children():
		if x is Button:
			x.pressed.connect(_button_filter_press.bind(x))
		else:
			## I'm getting lazier and lazier
			for y in x.get_children():
				if y is Button:
					y.pressed.connect(_button_filter_press.bind(y))
	big_view.get_child(0).button_created.connect(func(btn): 
		btn.pressed.connect(_button_filter_press.bind(btn))
	)


func resize_grid() -> void:
	var filters_size = filterbox.get_child_count() * 35.0
	
	dynagrid.position.y = filters_size
	
	var dynasize = dynagrid.size
	dynasize.y = size.y - filters_size
	dynagrid.resize(dynasize)


func create_filter() -> void:
	var new_filter = preload('uid://n7i4ny7kw54r').instantiate()
	new_filter.bank = self
	filterbox.add_child(new_filter)
	new_filter.removed.connect(_filter_removed.bind(new_filter))
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
	var tag = filter.tag
	
	if not tag in FILTERS:
		filters.erase(filter)
		apply_filters()
		return
	
	var type = FILTERS[tag][1]
	filter.set_type(type)
	
	var pre = filter.pre
	#if pre == '@':
		#pass
	
	filters[filter] = [pre, tag, filter.op, Tool.scrub(filter.param)]
	apply_filters()


func _filter_removed(filter) -> void:
	if filter in filters:
		filters.erase(filter)
		_filter_empty(filter)
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
		big_view.get_child(0).set_global(hover_global)


func card_gui_input(event:InputEvent, trect:TextureRect) -> void:
	if event is InputEventMouseButton:
		
		if event.pressed:
			
			## Left Mouse - Add to Deck (if we didn't drag the scroll bar)
			if event.button_index == 1:
				dynagrid.scroll_touch_tracker = dynagrid.Scroll.value
			
			## Middle Mouse - Debug Print whatever I wanted to see today
			elif event.button_index == 3:
				print( cards[ dynagrid.dataindex(trect) ] )
				#print( dynagrid.dataindex(trect) )
		
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
			
			var pre :String = f[0]
			var key :String = f[1]
			var text :String = f[3]
			var check = FILTERS[key][2]
			
			var negate := false
			var or_filter := false
			
			## Negate
			if pre == "-":
				negate = true
			
			if check:
				## Empty Negate filters mean "Exclude anything that passes the first check"
				if negate and text == '':
					if check.call(i):
						add = false
						continue
					else:
						continue
				if not check.call(i):
					add = false
					continue
			
			## Sort - only cares about excluding non-applicable cards, so continue right now
			if pre == '^' or pre == 'v':
				continue
			
			## Option
			elif pre == "~":
				or_cond = true
				or_filter = true
			
			## Alphabetical Filter
			var find :int = -1
			if text.length() == 0:
				continue
			
			var method = FILTERS[key][0]
			var type = FILTERS[key][1]
			
			var operator_check := false
			
			match type:
				
				FilterType.ALPHABETIC:
					find = ( Tool.scrub( method.call(i) ) ).find(text)
				
				FilterType.ALPHABETIC_LIST:
					var list = method.call(i)
					find = list.map(
						func (x:String) -> int: return Tool.scrub(x).find(text)
							).max() if not list.is_empty() else -1
				
				FilterType.CUSTOM:
					find = method.call(i, text)
				
				FilterType.NUMERIC:
					operator_check = true
					
					## Numerical Filter
					var num :int = method.call(i)
					var con :String = f[2]
					var val :int = int(f[3])
					
					find = 1
					if negate:
						match con:
							"<": if num < val: find = -1
							">": if num > val: find = -1
							"=": if num == val: find = -1
							"<=","=<": if num <= val: find = -1
							">=","=>": if num >= val: find = -1
					else:
						match con:
							"<": if num >= val: find = -1
							">": if num <= val: find = -1
							"=": if num != val: find = -1
							"<=","=<": if num > val: find = -1
							">=","=>": if num < val: find = -1
			
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
		
		if or_cond and or_match and add:
			filtered_cards.append(i)
		elif not or_cond and add:
			filtered_cards.append(i)
	
	for f in filters.values():
		if f[0] != '^' and f[0] != 'v':
			continue
		var method = FILTERS[f[1]][0]
		var type = FILTERS[f[1]][1]
		var reverse = f[0] == 'v'
		if type == FilterType.NUMERIC or type == FilterType.ALPHABETIC:
			filtered_cards.sort_custom(func(a,b):
				if reverse:
					return method.call(a) > method.call(b)
				return method.call(a) < method.call(b)
				)
		## Sort based on whatever is first
		elif type == FilterType.ALPHABETIC_LIST:
			filtered_cards.sort_custom(func(a,b):
				var am = method.call(a)
				#if am.size() == 0: return reverse
				var bm = method.call(b)
				#if bm.size() == 0: return not reverse
				if reverse:
					return am[0] > bm[0]
				return am[0] < bm[0]
				)
	
	cards = filtered_cards
	dynagrid.set_card_bank(0, cards.size())
	CardTotal.text = str(cards.size())


func _press_help() -> void:
	var tscn = load('uid://c2mfs1p8piec6').instantiate()
	tscn.get_child(1).pressed.connect(func (): tscn.queue_free())
	get_tree().get_root().add_child(tscn)


func _button_filter_press(node: Button) -> void:
	var bname = str(node.name)
	var split = bname.split('-')
	var splitidx := 0
	printt(bname, split)
	if split.size() != 1:
		splitidx = int(split[1])
	var left_name = split[0]
	
	var global = big_view.get_child(0).global
	var key = button_filters[left_name]
	
	var val = FILTERS[key][0].call(global)
	var pre = '+'
	
	if val is Array:
		if not val.is_empty():
			val = val[splitidx]
		else:
			pre = '-'
			val = ''
	if not val is String:
		val = str(val)
	
	var empty_filter = $Filters.get_children()[-1]
	empty_filter.set_all(pre, key, '=', val)


func add_filter(a, b, c ,d) -> void:
	var empty_filter = $Filters.get_children()[-1]
	empty_filter.set_all(a, b, c, d)
