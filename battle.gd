extends Node2D

const MONSTER_MAX_HP := 10         # how many candy hits it takes to kill him
const SHOOTER_SPEED := 350.0
const HP_BAR_WIDTH := 400.0
const CANDY_SHOT := preload("res://candy_shot.tscn")
const GOLDEN_TEXTURE := preload("res://golden_candy.png")
const CANDY_TEXTURES := {
	"KitKat": preload("res://KitKat game.png.png"),
	"Twix": preload("res://New Piskel-1.png (1).png"),
	"Herbro": preload("res://New Piskel-1.png (2).png"),
}

enum State { FIGHTING, WON, LOST, DEAD }

var state := State.FIGHTING
var monster_hp := MONSTER_MAX_HP
var time := 0.0
var flash_tween: Tween

@onready var shooter: Area2D = $Shooter
@onready var shooter_sprite: Sprite2D = $Shooter/Sprite2D
@onready var monster: Area2D = $Monster
@onready var monster_sprite: Sprite2D = $Monster/Sprite2D
@onready var shots: Node2D = $Shots
@onready var hp_fill: ColorRect = $UI/HpBar/Fill
@onready var ammo_label: Label = $UI/AmmoLabel
@onready var message_label: Label = $UI/MessageLabel
@onready var monster_label: Label = $UI/MonsterLabel


func _ready() -> void:
	_refresh_ui()


func _process(delta: float) -> void:
	time += delta
	if state != State.FIGHTING:
		return

	# monster floats up and down
	monster.position.y = 324.0 + sin(time * 1.2) * 120.0

	# aim with up / down
	var dir := Input.get_axis("ui_up", "ui_down")
	shooter.position.y = clampf(shooter.position.y + dir * SHOOTER_SPEED * delta, 90.0, 560.0)

	# out of candy and nothing still flying -> you lose
	if GameState.total_ammo() == 0 and shots.get_child_count() == 0:
		_lose()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E and state == State.FIGHTING:
			_shoot()
		elif event.keycode == KEY_R and state != State.FIGHTING:
			_leave()


func _shoot() -> void:
	var candy: String = GameState.take_ammo()
	if candy == "":
		return
	var shot := CANDY_SHOT.instantiate()
	shot.position = shooter.position + Vector2(100, 0)
	shots.add_child(shot)
	shot.setup(CANDY_TEXTURES[candy])
	shot.hit_monster.connect(_on_shot_hit_monster)
	shot.hit_player.connect(_on_shot_hit_player)
	_refresh_ui()


func _on_shot_hit_monster() -> void:
	if state != State.FIGHTING:
		return
	monster_hp -= 1
	_refresh_ui()

	if flash_tween:
		flash_tween.kill()
	monster_sprite.modulate = Color(1, 0.3, 0.3)
	flash_tween = create_tween()
	flash_tween.tween_property(monster_sprite, "modulate", Color.WHITE, 0.25)

	if monster_hp <= 0:
		_win()


# a missed candy bounced off the wall and hit you
func _on_shot_hit_player() -> void:
	if state != State.FIGHTING:
		return
	state = State.DEAD
	shooter.get_node("CollisionShape2D").set_deferred("disabled", true)
	shooter_sprite.modulate = Color(1, 0.3, 0.3)
	var die := create_tween()
	die.tween_property(shooter_sprite, "modulate:a", 0.0, 0.8)
	message_label.text = "GAME OVER\nYour own candy bounced back and got you!\nPress R to try again"


func _win() -> void:
	state = State.WON
	GameState.golden_candies += 1
	monster.get_node("CollisionShape2D").set_deferred("disabled", true)
	if flash_tween:
		flash_tween.kill()
	monster_sprite.modulate = Color(1, 0.3, 0.3)
	var fade := create_tween()
	fade.tween_property(monster_sprite, "modulate:a", 0.0, 0.8)
	message_label.text = "You defeated the monster!\nGolden Candy x%d\nPress R to continue" % GameState.golden_candies
	_drop_golden_candy()


# the golden candy pops out of the monster and floats where he used to be
func _drop_golden_candy() -> void:
	var golden := Sprite2D.new()
	golden.texture = GOLDEN_TEXTURE
	golden.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	golden.position = monster.position
	golden.scale = Vector2.ZERO
	add_child(golden)
	var pop := create_tween()
	pop.tween_property(golden, "scale", Vector2(6, 6), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var bob := create_tween().set_loops()
	bob.tween_property(golden, "position:y", golden.position.y - 20.0, 0.6).set_trans(Tween.TRANS_SINE)
	bob.tween_property(golden, "position:y", golden.position.y + 20.0, 0.6).set_trans(Tween.TRANS_SINE)


func _lose() -> void:
	state = State.LOST
	message_label.text = "Out of candy!\nPress R to try again"


func _leave() -> void:
	if state == State.WON:
		GameState.new_round()   # candy and monster come back so you can fight again
		get_tree().change_scene_to_file("res://cutscene.tscn")   # the car drives off the cliff, then GAME PASSED
		return
	GameState.reset()           # lose your ammo, candy comes back so you can try again
	get_tree().change_scene_to_file("res://node_2d.tscn")


func _refresh_ui() -> void:
	hp_fill.size.x = HP_BAR_WIDTH * float(monster_hp) / float(MONSTER_MAX_HP)
	monster_label.text = "Monster %d/%d" % [monster_hp, MONSTER_MAX_HP]
	ammo_label.text = "Candy ammo:  KitKat x%d   Twix x%d   Herbro x%d" % [
		GameState.ammo["KitKat"], GameState.ammo["Twix"], GameState.ammo["Herbro"]]
