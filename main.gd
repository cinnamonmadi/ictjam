extends Node2D

var players = []

func _ready():
    for player in get_tree().get_nodes_in_group("fighters"):
        players.append(weakref(player))

func _draw():
    for i in range(players.size()):
        if not players[i].get_ref():
            return
        var health_pos = Vector2(5 + (i * 150), 5)
        var health_size = Vector2(int(100.0 * (players[i].get_ref().health / 100.0)), 10)
        draw_rect(Rect2(health_pos, health_size), Color(1.0, 1.0, 0.0))

func _process(_delta):
    update()
