extends KinematicBody2D

signal death

onready var jump_input_timer = $jump_input_timer
onready var coyote_timer = $coyote_timer
onready var hitstun_timer = $hitstun_timer
onready var hitbox = $hitbox
onready var hitbox_crouching = $hitbox_crouching
onready var hurtbox = $hurtbox
onready var hurtbox_left = $hurtbox/hurtbox_left
onready var hurtbox_right = $hurtbox/hurtbox_right
onready var hurtbox_up = $hurtbox/hurtbox_up
onready var hurtbox_kick_right = $hurtbox/hurtbox_kick_right
onready var hurtbox_kick_left = $hurtbox/hurtbox_kick_left
onready var hurtbox_fair_right = $hurtbox/hurtbox_fair_right
onready var hurtbox_fair_left = $hurtbox/hurtbox_fair_left
onready var hurtbox_upair = $hurtbox/hurtbox_upair
onready var hurtbox_dair = $hurtbox/hurtbox_dair
onready var sprite = $sprite

export var player_name = "p1"
export var shader_path = ""

export var SPEED = 150
export var PUNCH_COMBO_IMPULSE = 150
export var PUNCH_COMBO_DECCEL = 50
export var ACCEL = 20
export var DECCEL = 5
export var GRAVITY = 10
export var MAX_FALL_SPEED = 250
export var JUMP_IMPULSE = 250

const PUSH_FORCE_RAIDUS = 20
const PUSH_FORCE_STRENGTH = 100
const JUMP_INPUT_DURATION = 0.06
const COYOTE_TIME_DURATION = 0.06

var INPUT_LEFT
var INPUT_RIGHT
var INPUT_UP
var INPUT_DOWN
var INPUT_JUMP
var INPUT_ATTACK
var INPUT_SPECIAL

enum { ATTACK_NONE, ATTACK_PUNCH_ONE, ATTACK_PUNCH_TWO, ATTACK_PUNCH_THREE, ATTACK_PUNCH_UP, ATTACK_KICK, ATTACK_FAIR, ATTACK_UPAIR, ATTACK_DAIR }

var direction = 0
var facing_direction = 1
var grounded = false
var has_double_jump = false
var velocity = Vector2.ZERO
var crouching = false
var uplooking = false
var attack_state = ATTACK_NONE
var attack_input = false

var health = 100

var hurtbox_enabled = false
var hurtbox_ignores
var hurtbox_knockback
var hurtbox_angle
var hurtbox_damage

var hitstun_alt = false
var push_force = Vector2.ZERO

var input_allowed = false

func _ready():
    add_to_group("fighters")

    sprite.connect("animation_finished", self, "_on_animation_finished")

    hurtbox_ignores = [self]
    set_player()

func set_player():
    INPUT_LEFT = player_name + "_left"
    INPUT_RIGHT = player_name + "_right"
    INPUT_UP = player_name + "_up"
    INPUT_DOWN = player_name + "_down"
    INPUT_JUMP = player_name + "_jump"
    INPUT_ATTACK = player_name + "_attack"
    INPUT_SPECIAL = player_name + "_special"

    var shader = load(shader_path).duplicate(true)
    sprite.material = ShaderMaterial.new()
    sprite.material.shader = shader
    var player_number = int(player_name.substr(1, 1))
    sprite.material.set_shader_param("player", player_number)

func get_standing_y_extents():
    return $hitbox.shape.extents.y

func start_hurtbox(knockback, angle, damage):
    hurtbox_enabled = true
    hurtbox_ignores = [self]

    hurtbox_knockback = knockback
    if facing_direction == -1:
        hurtbox_angle = 180 - angle
    else:
        hurtbox_angle = angle
    hurtbox_damage = damage

    for child_hurtbox in hurtbox.get_children():
        child_hurtbox.disabled = true
    if [ATTACK_PUNCH_ONE, ATTACK_PUNCH_TWO, ATTACK_PUNCH_THREE].has(attack_state):
        if facing_direction == 1:
            hurtbox_right.disabled = false
        else:
            hurtbox_left.disabled = false
    elif attack_state == ATTACK_PUNCH_UP:
        hurtbox_up.disabled = false
    elif attack_state == ATTACK_KICK:
        if facing_direction == 1:
            hurtbox_kick_right.disabled = false
        else:
            hurtbox_kick_left.disabled = false
    elif attack_state == ATTACK_FAIR:
        if facing_direction == 1:
            hurtbox_fair_right.disabled = false
        else:
            hurtbox_fair_left.disabled = false
    elif attack_state == ATTACK_UPAIR:
        hurtbox_upair.disabled = false
    elif attack_state == ATTACK_DAIR:
        hurtbox_dair.disabled = false

func check_hurtbox():
    if not hurtbox_enabled:
        return
    for body in hurtbox.get_overlapping_bodies():
        if body.is_in_group("fighters") and not body in hurtbox_ignores:
            body.take_damage(facing_direction, hurtbox_knockback, hurtbox_angle, hurtbox_damage)
            hurtbox_ignores.append(body)

func handle_input():
    if not input_allowed:
        return
    if Input.is_action_just_pressed(INPUT_LEFT):
        direction = -1
    if Input.is_action_just_pressed(INPUT_RIGHT):
        direction = 1
    if Input.is_action_just_released(INPUT_LEFT):
        if Input.is_action_pressed(INPUT_RIGHT):
            direction = 1
        else:
            direction = 0
    if Input.is_action_just_released(INPUT_RIGHT):
        if Input.is_action_pressed(INPUT_LEFT):
            direction = -1
        else:
            direction = 0
    uplooking = Input.is_action_pressed(INPUT_UP) and grounded and direction == 0
    crouching = Input.is_action_pressed(INPUT_DOWN) and grounded and attack_state == ATTACK_NONE
    if Input.is_action_just_pressed(INPUT_JUMP):
        if hitstun_timer.is_stopped():
            jump_input_timer.start(JUMP_INPUT_DURATION)
    if Input.is_action_just_pressed(INPUT_ATTACK):
        attack()

func attack():
    attack_input = false
    velocity.x = PUNCH_COMBO_IMPULSE * facing_direction
    if uplooking and attack_state == ATTACK_NONE:
        attack_state = ATTACK_PUNCH_UP
        start_hurtbox(200, 80, 10)
    elif crouching and attack_state == ATTACK_NONE:
        attack_state = ATTACK_KICK
        start_hurtbox(40, 5, 5)
    elif not grounded and attack_state == ATTACK_NONE:
        if Input.is_action_pressed(INPUT_UP):
            attack_state = ATTACK_UPAIR
            start_hurtbox(200, 80, 10)
        elif Input.is_action_pressed(INPUT_DOWN):
            attack_state = ATTACK_DAIR
            start_hurtbox(50, 80, 10)
        else:
            attack_state = ATTACK_FAIR
            start_hurtbox(150, 30, 5)
    elif attack_state == ATTACK_NONE:
        attack_state = ATTACK_PUNCH_ONE
        start_hurtbox(5, 0, 5)
        sprite.play("punch_one")
    elif attack_state == ATTACK_PUNCH_ONE:
        attack_state = ATTACK_PUNCH_TWO
        start_hurtbox(5, 0, 5)
        sprite.play("punch_two")
    elif attack_state == ATTACK_PUNCH_TWO:
        attack_state = ATTACK_PUNCH_THREE
        start_hurtbox(200, 45, 10)
        sprite.play("punch_three")
    if [ATTACK_PUNCH_ONE, ATTACK_PUNCH_TWO, ATTACK_PUNCH_THREE].has(attack_state):
        velocity.x = PUNCH_COMBO_IMPULSE * facing_direction

func take_damage(facing, knockback, angle, damage):
    health -= damage

    facing_direction = facing * -1
    velocity = Vector2.RIGHT.rotated(deg2rad(-angle)) * knockback

    if hitstun_timer.is_stopped():
        hitstun_alt = false
    else:
        hitstun_alt = not hitstun_alt
    var hitstun_duration = knockback / 400.0
    print(hitstun_duration)
    if hitstun_duration < 0.3:
        hitstun_duration = 0.3
    hitstun_timer.start(hitstun_duration)

    if health <= 0:
        health = 0
        emit_signal("death")
        queue_free()

func apply_push_force(source_force):
    push_force.x = source_force.x * PUSH_FORCE_STRENGTH
    push_force.y = 0

func _physics_process(_delta):
    handle_input()
    if crouching:
        hitbox.disabled = true
        hitbox_crouching.disabled = false
    else:
        hitbox.disabled = false
        hitbox_crouching.disabled = true
    if direction != 0:
        facing_direction = direction
    if attack_state != ATTACK_NONE and sprite.frame > 2:
        hurtbox_enabled = false
    check_hurtbox()
    move()
    update_sprite()

func move():
    # Apply user input
    var should_apply_push_force = true
    if crouching or uplooking or attack_state == ATTACK_KICK:
        velocity.x = 0
    elif hitstun_timer.is_stopped():
        var is_punch_combo = [ATTACK_PUNCH_ONE, ATTACK_PUNCH_TWO, ATTACK_PUNCH_THREE].has(attack_state)

        # set accelerate
        var accel = 0
        if not is_punch_combo:
            velocity.x += direction * ACCEL
            accel = direction * ACCEL

        # set deccelerate
        var deccel_direction = 0
        if velocity.x < 0:
            deccel_direction = 1
        elif velocity.x > 0:
            deccel_direction = -1
        var deccel = DECCEL
        if [ATTACK_PUNCH_ONE, ATTACK_PUNCH_TWO, ATTACK_PUNCH_THREE].has(attack_state):
            deccel = PUNCH_COMBO_DECCEL
        deccel *= deccel_direction

        # apply net acceleration
        velocity.x += accel + deccel

        # check bounds
        if (facing_direction == 1 and velocity.x < 0) or (facing_direction == -1 and velocity.x > 0) and grounded:
            velocity.x = 0
        if abs(velocity.x) > SPEED:
            velocity.x = SPEED * direction

    # Apply gravity
    velocity.y += GRAVITY
    if velocity.y > MAX_FALL_SPEED:
        velocity.y = MAX_FALL_SPEED

    # Grounded checks
    var was_grounded = grounded
    grounded = is_on_floor()
    if grounded:
        has_double_jump = true
        if [ATTACK_FAIR, ATTACK_UPAIR, ATTACK_DAIR].has(attack_state):
            attack_state = ATTACK_NONE
            sprite.play("idle")
    if was_grounded and not grounded:
        coyote_timer.start(COYOTE_TIME_DURATION)
    var can_single_jump = grounded or not coyote_timer.is_stopped()
    if (can_single_jump or has_double_jump) and not jump_input_timer.is_stopped():
        if not can_single_jump:
            has_double_jump = false
        jump_input_timer.stop()
        jump()
    if grounded and velocity.y >= 5:
        velocity.y = 5
    if velocity.y > MAX_FALL_SPEED:
        velocity.y = MAX_FALL_SPEED

    # Perform movement
    var _linear_velocity = move_and_slide(velocity + push_force, Vector2(0, -1))
    push_force = Vector2.ZERO
    if should_apply_push_force:
        for fighter in get_tree().get_nodes_in_group("fighters"):
            if fighter == self:
                continue
            var distance_to_fighter = position.distance_to(fighter.position)
            if distance_to_fighter <= PUSH_FORCE_RAIDUS:
                var push_force_percent = distance_to_fighter / PUSH_FORCE_RAIDUS
                fighter.apply_push_force(position.direction_to(fighter.position) * push_force_percent)
        for i in get_slide_count():
            var collision = get_slide_collision(i)
            if collision.collider.is_in_group("fighters"):
                collision.collider.apply_push_force(position.direction_to(collision.collider.position))

func jump():
    self.velocity.y = -JUMP_IMPULSE
    grounded = false

func update_sprite():
    if not hitstun_timer.is_stopped() and not hitstun_alt:
        sprite.play("hurt_one")
    elif not hitstun_timer.is_stopped() and hitstun_alt:
        sprite.play("hurt_two")
    elif attack_state == ATTACK_PUNCH_ONE:
        sprite.play("punch_one")
    elif attack_state == ATTACK_PUNCH_TWO:
        sprite.play("punch_two")
    elif attack_state == ATTACK_PUNCH_THREE:
        sprite.play("punch_three")
    elif attack_state == ATTACK_PUNCH_UP:
        sprite.play("punch_up")
    elif attack_state == ATTACK_KICK:
        sprite.play("kick")
    elif attack_state == ATTACK_FAIR:
        sprite.play("fair")
    elif attack_state == ATTACK_UPAIR:
        sprite.play("upair")
    elif attack_state == ATTACK_DAIR:
        sprite.play("dair")
    elif not grounded and velocity.y < 0:
        sprite.play("jump")
    elif not grounded and velocity.y > 0:
        sprite.play("fall")
    elif crouching:
        sprite.play("crouch")
    elif uplooking:
        sprite.play("uplook")
    elif direction == 0:
        sprite.play("idle")
    else:
        sprite.play("run")
    if crouching:
        sprite.z_index = -1
    else:
        sprite.z_index = 0
    if (facing_direction == 1 and sprite.flip_h) or (facing_direction == -1 and not sprite.flip_h):
        sprite.flip_h = not sprite.flip_h

func _on_animation_finished():
    if [ATTACK_PUNCH_ONE, ATTACK_PUNCH_TWO].has(attack_state):
        if attack_input:
            attack()
        else:
            attack_state = ATTACK_NONE
            sprite.play("idle")
    elif [ATTACK_PUNCH_THREE, ATTACK_PUNCH_UP, ATTACK_KICK, ATTACK_FAIR, ATTACK_UPAIR, ATTACK_DAIR].has(attack_state):
        attack_state = ATTACK_NONE
        sprite.play("idle")
