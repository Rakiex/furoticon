extends Node
class_name CardLib

# .............................................................................
# .............................................................................

static func has_furre_stats(global_number:int) -> bool:
	var t := CardData.BASE_TYPE[CardData.CARD_BASE[global_number]]
	return t == 0 or t == 5

static func has_owner_stats(global_number:int) -> bool:
	var t := CardData.BASE_TYPE[CardData.CARD_BASE[global_number]]
	return t == 4

static func has_alts(global_number:int) -> bool:
	return CardData.BASE_CARD[CardData.CARD_BASE[global_number]].size() > 1

static func has_cost(_g) -> bool:
	var _t = type(_g)
	if _t == 4 or _t == 5:
		return false
	return true

static func has_defines(global_number:int) -> bool:
	return CardData.BASE_DEFINE[CardData.CARD_BASE[global_number]].size() != 0

static func has_define(global_number:int, define:int) -> bool:
	return CardData.BASE_DEFINE[CardData.CARD_BASE[global_number]].has(define)

static func has_flavor(global_number:int) -> bool:
	return CardData.CARD_FLAVOR[global_number] != ''

# .............................................................................
# .............................................................................

static func is_furre(global_number:int) -> bool:
	return CardData.BASE_TYPE[CardData.CARD_BASE[global_number]] == 1

static func is_owner(global_number:int) -> bool:
	return CardData.BASE_TYPE[CardData.CARD_BASE[global_number]] == 4

static func is_token(global_number:int) -> bool:
	return CardData.BASE_TYPE[CardData.CARD_BASE[global_number]] == 5

# .............................................................................
# .............................................................................

static func get_alts(global_number:int) -> Array:
	return CardData.BASE_CARD[CardData.CARD_BASE[global_number]]

static func get_alt_index(global_number:int) -> int:
	return CardData.BASE_CARD[CardData.CARD_BASE[global_number]].find(global_number)

static func get_number(global_number:int) -> int:
	return CardData.CARD_NUMBER[global_number]

static func get_path_to_art(global_number:int) -> String:
	if global_number == -1:
		return "res://IndicationLabelL.png"
	## GRRRR...!!! BRATTY WEB EXPORTED .PCK FILE SIZE...!!! NEEDS CORRECTION !!!
	var folder_name := 'cards_small'
	if OS.has_feature("web"):
		folder_name = 'cards_small'
	## True-quality cards, which are too big for Web Export
	## Didn't want to pad the Github repo with them either, since they technically aren't used.
	elif DirAccess.dir_exists_absolute('res://cards/'):
		folder_name = 'cards'
	return "res://%s/%s.jpg" % [ folder_name, global_number ]

static func get_path_to_small_icon(global_number:int) -> String:
	if global_number == -1:
		return "res://card_icons/-1.jpg"
	if global_number < 1 or global_number > 1500:
		return "res://card_icons/1.jpg"
	return "res://card_icons/%s.jpg" % global_number

static func get_type_priority(global_number:int) -> int:
	match CardData.ENUM_TYPE[CardData.BASE_TYPE[CardData.CARD_BASE[global_number]]]:
		"Owner": return 0
		"Furre": return 1
		"Action": return 2
		"Treat": return 3
		"Haven": return 4
		"Token": return 5
		_: return 6

static func get_gender(global_number:int) -> int:
	return CardData.BASE_GENDER[CardData.CARD_BASE[global_number]]

static func get_gender_priority(global_number:int) -> int:
	match CardData.BASE_GENDER[CardData.CARD_BASE[global_number]]:
		1: return 0
		2: return 1
		4: return 2
		8: return 3
		3: return 4
		5: return 5
		9: return 6
		6: return 7
		10: return 8
		12: return 9
		7: return 10
		11: return 11
		13: return 12
		14: return 13
		15: return 14
		0: return 15
		_: return 16

static func get_gender_string(global_number:int) -> String:
	var g = CardData.BASE_GENDER[CardData.CARD_BASE[global_number]]
	var s = ''
	if g & 1: s += 'M'
	if g & 2: s += 'F'
	if g & 4: s += 'H'
	if g & 8: s += 'O'
	return s

static func gender_string(gender:int) -> String:
	match gender:
		0: return "genderless"
		1: return "male"
		2: return "female"
		4: return "herm"
		8: return "other"
		3: return "mf"
		5: return "mh"
		9: return "mo"
		6: return "fh"
		10: return "fo"
		12: return "ho"
		7: return "mfh"
		11: return "mfo"
		14: return "fho"
		15: return "mfho"
		_: return "genderless"


static func type(_g) -> int:
	return CardData.BASE_TYPE[CardData.CARD_BASE[_g]]

## Why the fuck did I do it like this
static func get_total_cost(_g:int) -> int:
	return get_action_cost(_g) + gp_cost(_g)
static func gp_cost(_g:int) -> int:
	var i = 0
	for x in get_gender_costs(_g):
		i += x
	return i
static func get_gender_costs(global_number:int) -> Array[int]:
	var gpc :int = CardData.BASE_GP[CardData.CARD_BASE[global_number]]
	var gpc_a :Array[int] = [0,0,0,0]
	for i in range(4):
		if gpc == 0: break
		gpc_a[i] = gpc % 10
		gpc /= 10
	return gpc_a
static func get_male_cost(global_number:int) -> int:
	if not has_cost(global_number): return 0
	return CardData.BASE_GP[CardData.CARD_BASE[global_number]] % 10
static func get_female_cost(global_number:int) -> int:
	if not has_cost(global_number): return 0
	return (CardData.BASE_GP[CardData.CARD_BASE[global_number]] / 10) % 10
static func get_herm_cost(global_number:int) -> int:
	if not has_cost(global_number): return 0
	return (CardData.BASE_GP[CardData.CARD_BASE[global_number]] / 100) % 10
static func get_other_cost(global_number:int) -> int:
	if not has_cost(global_number): return 0
	return (CardData.BASE_GP[CardData.CARD_BASE[global_number]] / 1000) % 10

static func get_stamina(global_number:int) -> int:
	return CardData.STAT_FURRE[CardData.BASE_STAT[CardData.CARD_BASE[global_number]]][0]

static func get_edition(global_number:int) -> int:
	return CardData.CARD_EDITION[global_number]

static func get_edition_priority(global_number:int) -> int:
	return CardData.CARD_EDITION[global_number]

static func get_edition_string(global_number:int) -> String:
	return CardData.ENUM_EDITION[CardData.CARD_EDITION[global_number]]

static func get_type_string(global_number:int) -> String:
	return CardData.ENUM_TYPE[CardData.BASE_TYPE[CardData.CARD_BASE[global_number]]]

static func get_skill_string(global_number:int) -> String:
	return CardData.BASE_SKILL[CardData.CARD_BASE[global_number]]

static func get_flavor(global_number:int) -> String:
	return CardData.CARD_FLAVOR[global_number]

static func get_action_cost(global_number:int) -> int:
	return CardData.BASE_AP[CardData.CARD_BASE[global_number]]

static func get_card_name(global_number:int) -> String:
	return CardData.BASE_NAME[CardData.CARD_BASE[global_number]]

static func get_artist_strings(global_number:int) -> Array:
	return CardData.CARD_ARTIST[global_number].map(
		func (x:int) -> String: return CardData.ENUM_ARTIST[x])

static func get_pleasure(global_number:int) -> Array:
	return CardData.STAT_FURRE[CardData.BASE_STAT[CardData.CARD_BASE[global_number]]].slice(1)
static func get_male_pleasure(global_number:int) -> int:
	return CardData.STAT_FURRE[CardData.BASE_STAT[CardData.CARD_BASE[global_number]]][1]
static func get_female_pleasure(global_number:int) -> int:
	return CardData.STAT_FURRE[CardData.BASE_STAT[CardData.CARD_BASE[global_number]]][2]
static func get_herm_pleasure(global_number:int) -> int:
	return CardData.STAT_FURRE[CardData.BASE_STAT[CardData.CARD_BASE[global_number]]][3]
static func get_other_pleasure(global_number:int) -> int:
	return CardData.STAT_FURRE[CardData.BASE_STAT[CardData.CARD_BASE[global_number]]][4]

static func get_rarity(global_number:int) -> int:
	return CardData.CARD_RARITY[global_number]

static func get_rarity_priority(global_number:int) -> int:
	match CardData.CARD_RARITY[global_number]:
		0: return 0
		1: return 1
		2: return 3
		3: return 2
		4: return 4
		_: return 5

static func get_rarity_string(global_number:int) -> String:
	return CardData.ENUM_RARITY[CardData.CARD_RARITY[global_number]]

static func get_defines(global_number:int) -> Array:
	return CardData.BASE_DEFINE[CardData.CARD_BASE[global_number]]

static func get_define_strings(global_number:int) -> Array:
	return CardData.BASE_DEFINE[CardData.CARD_BASE[global_number]].map(
		func (x:int) -> String: return CardData.ENUM_DEFINE[x])

static func string_to_define(define:String) -> int:
	return CardData.ENUM_DEFINE.find(define.to_lower().capitalize())

static func get_bonus_to_deck_size(x:int) -> int:
	return CardData.STAT_OWNER[CardData.BASE_STAT[CardData.CARD_BASE[x]]][0]
static func get_cards_in_starting_hand(x:int) -> int:
	return CardData.STAT_OWNER[CardData.BASE_STAT[CardData.CARD_BASE[x]]][1] if x != -1 else 7
static func get_maximum_cards_in_hand(x:int) -> int:
	return CardData.STAT_OWNER[CardData.BASE_STAT[CardData.CARD_BASE[x]]][2]
static func get_max_stamina_bonus(x:int) -> int:
	return CardData.STAT_OWNER[CardData.BASE_STAT[CardData.CARD_BASE[x]]][3]
static func get_ap_per_turn(x:int) -> int:
	return CardData.STAT_OWNER[CardData.BASE_STAT[CardData.CARD_BASE[x]]][4]
static func get_ap_to_draw(x:int) -> int:
	return CardData.STAT_OWNER[CardData.BASE_STAT[CardData.CARD_BASE[x]]][5]
static func get_ap_to_swing(x:int) -> int:
	return CardData.STAT_OWNER[CardData.BASE_STAT[CardData.CARD_BASE[x]]][6]
static func get_ap_to_put(x:int) -> int:
	return CardData.STAT_OWNER[CardData.BASE_STAT[CardData.CARD_BASE[x]]][7]
