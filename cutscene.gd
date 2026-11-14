extends Node2D
# After you win: the car drives along the road, off the edge into the abyss,
# then "GAME PASSED!" shows up.

const DRIVE_SPEED := 380.0     # how fast the car drives
const EDGE_X := 800.0          # where the road ends (the cliff edge)
const GRAVITY := 1400.0
const NOSE_DIVE_SPEED := 1.1   # how fast the car tips forward (radians / second)
const MAX_TILT := 1.2

enum State { DRIVING, FALLING, ENDING, DONE }

var state := State.DRIVING
var fall_speed := 0.0

@onready var car: Sprite2D = $Car
@onready var fade: ColorRect = $UI/Fade
@onready var title: Label = $UI/Title
@onready var subtitle: Label = $UI/Subtitle
@onready var hint: Label = $UI/Hint


func _process(delta: float) -> void:
	match state:
		State.DRIVING:
			car.position.x += DRIVE_SPEED * delta
			# once the car's middle is past the edge, it starts to fall
			if car.position.x > EDGE_X:
				state = State.FALLING
		State.FALLING:
			car.position.x += DRIVE_SPEED * 0.6 * delta
			fall_speed += GRAVITY * delta
			car.position.y += fall_speed * delta
			car.rotation = minf(car.rotation + NOSE_DIVE_SPEED * delta, MAX_TILT)
			if car.position.y > 900:
				_show_ending()


func _show_ending() -> void:
	state = State.ENDING
	var t := create_tween()
	t.tween_property(fade, "color:a", 0.8, 0.8)
	t.tween_property(title, "modulate:a", 1.0, 0.6)
	t.tween_property(subtitle, "modulate:a", 1.0, 0.6)
	t.tween_callback(func(): state = State.DONE)
	t.tween_property(hint, "modulate:a", 1.0, 0.6)


func _unhandled_input(event: InputEvent) -> void:
	if state == State.DONE and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			get_tree().change_scene_to_file("res://node_2d.tscn")
