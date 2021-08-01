extends Node2D

enum { MENU_START, MENU_SELECT, MENU_READY, MENU_FIGHT, MENU_GG }

onready var fighter_scenes = [load("res://fighters/trex/trex.tscn"), load("res://fighters/tri/tri.tscn")]
onready var fighter_icons = [load("res://menu/trex.png"), load("res://menu/tri.png")]

var all_locked = false
var player_names = []
var player_selections = []
var player_locked = []
var player_colors = []
var players = []
var player_colors_list = [Color(1.0, 0.0, 0.0), Color(0.0, 0.0, 1.0), Color(1.0, 0.0, 1.0), Color(1.0, 1.0, 0.0)]

onready var start_menu = $start_menu
onready var start_label = $start_menu/start_label
onready var start_label_timer = $start_menu/start_label_timer
onready var select_menu = $select_menu
onready var select_icons = $select_menu/fighter_icons
onready var general = $general
onready var general_label = $general/general_label_hbox/general_label
onready var general_timer = $general/general_timer
onready var spawn_points = $spawn_points.get_children()
onready var player_box_container = $select_menu/player_boxes
onready var player_boxes = $select_menu/player_boxes.get_children()
onready var general_box_container = $general/health_boxes
onready var general_boxes = $general/health_boxes.get_children()

var state

var ready_countdown = 3

func _ready():
    start_label_timer.connect("timeout", self, "_on_start_label_timeout")
    general_timer.connect("timeout", self, "_on_general_timeout")
    set_state(MENU_START)

func set_state(new_state):
    state = new_state

    start_menu.visible = false
    start_label.visible = false
    start_label_timer.stop()

    select_menu.visible = false

    general.visible = false

    player_box_container.visible = false
    general_box_container.visible = false

    if state == MENU_START:
        player_names = []
        players = []
        player_selections = []
        start_menu.visible = true
        start_label.visible = true
        start_label_timer.start(0.5)
    elif state == MENU_SELECT:
        for player in players:
            if player.get_ref():
                player.get_ref().queue_free()
        players = []
        select_menu.visible = true
        general.visible = true
        all_locked = false
        for icon in select_icons.get_children():
            icon.stretch_mode = 1
            icon.rect_size = Vector2(44, 44)
        for i in range(player_names.size()):
            player_locked[i] = false
        player_box_container.visible = true
        update_player_boxes()
    elif state == MENU_READY:
        spawn_players()
        general.visible = true
        ready_countdown = 4
        general_label.text = ""
        general_timer.start(0.5)
        general_box_container.visible = true
        update_general_boxes()
    elif state == MENU_FIGHT:
        general.visible = true
        for player in players:
            if player.get_ref():
                player.get_ref().input_allowed = true
        general_box_container.visible = true

func add_player(number):
    player_names.append("p" + str(number))
    player_selections.append(0)
    player_locked.append(false)
    for color in player_colors_list:
        if not color in player_colors:
            player_colors.append(color)
            break

func remove_player(index):
    player_names.remove(index)
    player_selections.remove(index)
    player_locked.remove(index)
    player_colors.remove(index)

func spawn_player(index):
    var spawn_point = spawn_points[index].position
    var new_fighter = fighter_scenes[player_selections[index]].instance()
    new_fighter.player_name = player_names[index]
    new_fighter.position = spawn_point + Vector2(0, -new_fighter.get_standing_y_extents())
    new_fighter.player_number = index + 1
    new_fighter.connect("death", self, "_on_player_death")
    get_parent().add_child(new_fighter)

func update_player_boxes():
    for i in range(player_boxes.size()):
        update_player_box(i)

func update_player_box(number):
    if [MENU_READY, MENU_FIGHT, MENU_GG].has(state):
        if number < player_names.size():
            player_boxes[number].get_child(1).text = "PLAYER " + str(number + 1)
            player_boxes[number].get_child(2).visible = false
        return
    if number < player_names.size():
        if player_locked[number]:
            player_boxes[number].get_child(1).text = "READY!"
        else:
            player_boxes[number].get_child(1).text = "PLAYER " + str(number + 1)
        player_boxes[number].get_child(2).texture = fighter_icons[player_selections[number]]
        player_boxes[number].get_child(2).visible = true
    else:
        player_boxes[number].get_child(1).text = "PRESS START"
        player_boxes[number].get_child(2).visible = false

func update_general_boxes():
    for i in range(4):
        if i < player_names.size():
            general_boxes[i].get_child(0).text = "PLAYER " + str(i + 1)
        else:
            general_boxes[i].get_child(0).text = ""

func spawn_players():
    for i in range(player_names.size()):
        spawn_player(i)
    players = []
    for player in get_tree().get_nodes_in_group("fighters"):
        players.append(weakref(player))

func player_input(number, name):
    return "p" + str(number) + "_" + name

func _process(_delta):
    if state == MENU_START:
        for i in range(1, 5):
            if Input.is_action_just_pressed(player_input(i, "start")):
                add_player(i)
                set_state(MENU_SELECT)
                break
            elif Input.is_action_just_pressed(player_input(i, "special")):
                get_tree().quit()
    elif state == MENU_SELECT:
        for i in range(1, 5):
            if Input.is_action_just_pressed(player_input(i, "start")) and not ("p" + str(i)) in player_names:
                add_player(i)
        var removed_players = []
        for i in range(player_names.size()):
            var player_right = player_names[i] + "_right"
            var player_left = player_names[i] + "_left"
            var player_back = player_names[i] + "_special"
            var player_select = player_names[i] + "_attack"
            var player_start = player_names[i] + "_start"
            if all_locked and Input.is_action_just_pressed(player_start):
                set_state(MENU_READY)
            if Input.is_action_just_pressed(player_right) or Input.is_action_just_pressed(player_left):
                if not player_locked[i]:
                    player_selections[i] = (player_selections[i] + 1) % 2
            if Input.is_action_just_pressed(player_select):
                player_locked[i] = true
            if Input.is_action_just_pressed(player_back):
                if player_locked[i]:
                    player_locked[i] = false
                else:
                    removed_players.append(i)
        for removed_player in removed_players:
            remove_player(removed_player)
        update_player_boxes()
        if player_names.size() == 0:
            set_state(MENU_START)
    update()

func _draw():
    if state == MENU_SELECT:
        draw_select_rects()
        all_locked = true
        for locked in player_locked:
            if not locked:
                all_locked = false
                break
        if all_locked:
            general_label.text = "PRESS START TO BEGIN"
        else:
            general_label.text = "CHOOSE YOUR FIGHTER"
    if [MENU_READY, MENU_FIGHT, MENU_GG].has(state):
        draw_health_bars()

func draw_select_rects():
    var origin = select_icons.rect_position + Vector2(0, -2)
    var size = Vector2(48, 48)
    var step = Vector2(48, 0)
    for i in range(player_names.size()):
        draw_rect(Rect2(origin + (player_selections[i] * step), size), player_colors[i], false, 2)

func draw_health_bars():
    for i in range(players.size()):
        if not general_boxes[i].visible:
            return
        var health = 0
        if players[i].get_ref():
            health = players[i].get_ref().health
        if health < 0:
            health = 0
        var health_box_pos = general_boxes[i].get_global_transform_with_canvas().get_origin()
        var health_pos = health_box_pos + Vector2(5, 25)
        var health_size = Vector2(int(100.0 * (health / 100.0)), 10)
        draw_rect(Rect2(health_pos - Vector2(1, 1), Vector2(102, 12)), Color(1.0, 1.0, 1.0), false, 2)
        draw_rect(Rect2(health_pos, health_size), Color(1.0, 0.0, 0.0))
        draw_rect(Rect2(health_pos + Vector2(health_size.x, 0), Vector2(100 - health_size.x, health_size.y)), Color(0.0, 0.0, 0.0))

func _on_start_label_timeout():
    start_label.visible = not start_label.visible

func _on_general_timeout():
    if state == MENU_READY:
        ready_countdown -= 1
        if ready_countdown > 0:
            general_label.text = str(ready_countdown)
        else:
            general_label.text = "GO"
            set_state(MENU_FIGHT)
        general_timer.start(1)
    elif state == MENU_FIGHT:
        general_label.text = ""
    elif state == MENU_GG:
        set_state(MENU_SELECT)

func _on_player_death():
    var player_count = 0
    var first_player_found = 0
    for i in range(players.size()):
        if players[i].get_ref() and players[i].get_ref().health > 0:
            player_count += 1
            first_player_found = i + 1
    if player_count == 1:
        general_label.text = "PLAYER " + str(first_player_found) + " WINS"
        general_timer.start(3)
        state = MENU_GG
