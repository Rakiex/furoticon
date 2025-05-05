extends Node
class_name DeckLib


static func get_precon_data(did:int) -> Dictionary:
	var d :Dictionary = {
		"name": DeckData.NAME[did],
		"owner": DeckData.OWNER[did],
		"cards": DeckData.CARDS[did],
		"type": DeckData.TYPE[did]
	}
	return d


static func get_owner_from_dict(d:Dictionary) -> int:
	return d["owner"]


static func get_cards_from_dict(d:Dictionary) -> Array[int]:
	var a :Array[int] = []
	a.assign(d["cards"])
	return a
