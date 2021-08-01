extends AnimatedSprite

export var spawn_offset = Vector2.ZERO

func _ready():
    connect("animation_finished", self, "_on_animation_finished")
    position += spawn_offset
    play("default")

func _process(_delta):
    if frame >= 3:
        material = null

func _on_animation_finished():
    queue_free()
