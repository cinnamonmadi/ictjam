extends KinematicBody2D

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

const SPEED = 120
const GRAVITY = 10
const MAX_FALL_SPEED = 250
const JUMP_IMPULSE = 250
const JUMP_INPUT_DURATION = 0.06
const COYOTE_TIME_DURATION = 0.06

export var player = 1
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

func _ready():
    add_to_group("fighters")

    sprite.connect("animation_finished", self, "_on_animation_finished")

    hurtbox_ignores = [self]
    set_player(player)

func set_player(number):
    var player_name = "p" + str(number)
    INPUT_LEFT = player_name + "_left"
    INPUT_RIGHT = player_name + "_right"
    INPUT_UP = player_name + "_up"
    INPUT_DOWN = player_name + "_down"
    INPUT_JUMP = player_name + "_jump"
    INPUT_ATTACK = player_name + "_attack"
    INPUT_SPECIAL = player_name + "_special"

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
    velocity.x = 150 * facing_direction
    if uplooking and attack_state == ATTACK_NONE:
        attack_state = ATTACK_PUNCH_UP
        start_hurtbox(80, 80, 10)
    elif crouching and attack_state == ATTACK_NONE:
        attack_state = ATTACK_KICK
        start_hurtbox(40, 5, 5)
    elif not grounded and attack_state == ATTACK_NONE:
        if Input.is_action_pressed(INPUT_UP):
            attack_state = ATTACK_UPAIR
            start_hurtbox(80, 80, 10)
        elif Input.is_action_pressed(INPUT_DOWN):
            attack_state = ATTACK_DAIR
            start_hurtbox(40, 80, 10)
        else:
            attack_state = ATTACK_FAIR
            start_hurtbox(40, 15, 5)
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
        start_hurtbox(80, 60, 10)
        sprite.play("punch_three")

func take_damage(facing, knockback, angle, damage):
    print("player " + str(player) + " takes damage")
    health -= damage

    facing_direction = facing * -1
    velocity = Vector2.RIGHT.rotated(deg2rad(-angle)) * knockback
    print("velocity is " + str(velocity))

    if hitstun_timer.is_stopped():
        hitstun_alt = false
    else:
        hitstun_alt = not hitstun_alt
    var hitstun_duration = (knockback * 0.4) / 60.0
    if hitstun_duration < 0.5:
        hitstun_duration = 0.5
    hitstun_timer.start(hitstun_duration)

    if health <= 0:
        queue_free()

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
    if crouching or uplooking or attack_state == ATTACK_KICK:
        velocity.x = 0
    elif hitstun_timer.is_stopped() and [ATTACK_NONE, ATTACK_FAIR, ATTACK_UPAIR, ATTACK_DAIR].has(attack_state):
        velocity.x = direction * SPEED
    elif attack_state != ATTACK_NONE:
        velocity.x -= 50 * facing_direction
        if (velocity.x > 0 and facing_direction == -1) or (velocity.x < 0 and facing_direction == 1):
            velocity.x = 0

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
    move_and_slide(velocity, Vector2(0, -1))

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
