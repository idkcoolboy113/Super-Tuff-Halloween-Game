extends Area2D

signal hit_monster
signal hit_player

const SPEED := 900.0          # flying toward the monster
const BOUNCE_SPEED := 700.0   # flying back after it hits the wall
const WALL_X := 1098.0        # where the right wall is (the candy's middle)

var bounced := false


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func setup(texture: Texture2D) -> void:
	$Sprite2D.texture = texture


func _process(delta: float) -> void:
	if bounced:
		position.x -= BOUNCE_SPEED * delta
		$Sprite2D.rotation -= 10.0 * delta
		if position.x < -300:
			queue_free()
	else:
		position.x += SPEED * delta
		$Sprite2D.rotation += 10.0 * delta
		if position.x >= WALL_X:
			# missed the monster and hit the wall -> bounces back, now dangerous
			bounced = true
			position.x = WALL_X
			$Sprite2D.modulate = Color(1.0, 0.4, 0.4)


func _on_area_entered(area: Area2D) -> void:
	if not bounced and area.is_in_group("Monster"):
		hit_monster.emit()
		queue_free()
	elif bounced and area.is_in_group("Shooter"):
		hit_player.emit()
		queue_free()
