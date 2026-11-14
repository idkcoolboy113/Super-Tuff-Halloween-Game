extends Node
# Autoload: keeps your candy between the main map and the battle screen.

const CANDY_TYPES := ["KitKat", "Twix", "Herbro"]
const SHOTS_PER_CANDY := 5   # one candy pickup = this many shots

var ammo := {"KitKat": 0, "Twix": 0, "Herbro": 0}
var collected: Array = []   # candy already picked up on the map
var golden_candies := 0     # one for every time you beat the monster


func total_ammo() -> int:
	var total := 0
	for candy in ammo:
		total += ammo[candy]
	return total


func _ready() -> void:
	# WASD works the same as the arrow keys
	_add_key("ui_left", KEY_A)
	_add_key("ui_right", KEY_D)
	_add_key("ui_up", KEY_W)
	_add_key("ui_down", KEY_S)


func _add_key(action: String, keycode: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action, event)


# Uses up one candy and tells you which kind it was ("" if you have none)
func take_ammo() -> String:
	for candy in CANDY_TYPES:
		if ammo[candy] > 0:
			ammo[candy] -= 1
			return candy
	return ""


# After beating the monster: candy and monster come back (golden candies and leftover ammo stay)
func new_round() -> void:
	collected.clear()


# After losing: lose your ammo and everything respawns (golden candies stay)
func reset() -> void:
	for candy in ammo:
		ammo[candy] = 0
	collected.clear()
