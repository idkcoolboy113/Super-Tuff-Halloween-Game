extends CharacterBody2D

# candy name -> the sprite that appears in the basket
@onready var basket_items = {
	"KitKat": $HoldingKitKat,
	"Twix": $HoldingTwix,
	"Herbro": $HoldingHerbro,
}

@onready var golden_candy: Sprite2D = $HoldingGolden


func _ready() -> void:
	# coming back from a fight: don't respawn candy you already picked up
	for candy in GameState.collected:
		var node = get_parent().get_node_or_null(candy)
		if node:
			node.queue_free()

	# basket shows the candy you still have left
	for candy in basket_items:
		basket_items[candy].visible = GameState.ammo[candy] > 0
	golden_candy.visible = GameState.golden_candies > 0
	_update_candy_label()


# walls of the map (the visible screen is 1152 x 648)
const MIN_POS := Vector2(40, 50)
const MAX_POS := Vector2(1112, 600)


func _physics_process(delta):
	var input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_direction * 400
	move_and_slide()
	position = position.clamp(MIN_POS, MAX_POS)   # can't walk off the screen


func _on_pickup_area_area_entered(area):
	# touching the monster -> go to the green battle screen
	if area.is_in_group("Monster"):
		get_tree().change_scene_to_file("res://battle.tscn")
		return

	for candy in basket_items:
		if area.is_in_group(candy):
			area.queue_free()
			GameState.collected.append(candy)
			GameState.ammo[candy] += GameState.SHOTS_PER_CANDY
			basket_items[candy].show()
			_update_candy_label()
			return


func _update_candy_label() -> void:
	var text := "Candy " + str(GameState.total_ammo())
	if GameState.golden_candies > 0:
		text += "   Golden Candy x" + str(GameState.golden_candies)
	$CanvasLayer/CandyCountDisplay.text = text
