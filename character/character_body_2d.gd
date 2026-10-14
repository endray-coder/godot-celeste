extends CharacterBody2D

const SPEED = 300.0
@export_group("跳跃速度")
@export_range(-600,-200) var JUMP_VELOCITY = -400.0

@export_group("跳跃补偿力度")
@export_range(-500.0,0.0) var JUMP_BOOST = -180.0

@export var max_jump_count = 2
var remaining_jumps: int = 0

# ===== 冲刺参数 =====
@export var MAX_DASHES = 1
@export var DASH_SPEED = 600.0      # 200 太小了，建议 600+
@export var DASH_DURATION = 0.2     # 冲刺持续时间（秒）
var remaining_dashes: int = 0
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO


func _physics_process(delta: float) -> void:
	# --- 重力 ---
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		remaining_jumps = max_jump_count
		remaining_dashes = MAX_DASHES   # 落地恢复冲刺次数

	# --- 跳跃 ---
	if Input.is_action_just_pressed("jump") and remaining_jumps > 0:
		velocity.y = JUMP_VELOCITY
		remaining_jumps -= 1
		if remaining_jumps == max_jump_count - 1:
			$Timer.start()

	if $Timer.time_left > 0.0 and Input.is_action_pressed("jump") and not is_on_floor():
		velocity.y += delta * JUMP_BOOST
	elif $Timer.time_left > 0.0 and not Input.is_action_pressed("jump"):
		$Timer.stop()

	# --- 输入方向（补上 y 轴）---
	var direction: Vector2 = Vector2.ZERO
	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	# --- 冲刺状态处理 ---
	if is_dashing:
		dash_timer -= delta
		velocity = dash_direction * DASH_SPEED   # 强制覆盖速度，忽略重力
		if dash_timer <= 0.0:
			is_dashing = false
			# 冲刺结束保留一点惯性（可选）
			velocity *= 0.5
	else:
		# 正常水平移动
		if direction.x != 0:
			velocity.x = direction.x * SPEED
			var sprite: AnimatedSprite2D = $AnimatedSprite2D
			sprite.flip_h = direction.x < 0
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

		# 触发冲刺
		if Input.is_action_just_pressed("dash") and remaining_dashes > 0:
			remaining_dashes -= 1
			is_dashing = true
			dash_timer = DASH_DURATION
			# 有输入就用输入方向，否则朝面向方向
			if direction == Vector2.ZERO:
				dash_direction = Vector2(-1 if $AnimatedSprite2D.flip_h else 1, 0)
			else:
				dash_direction = direction.normalized()

	move_and_slide()
