extends CharacterBody2D

const SPEED = 300.0
@export_group("跳跃速度")
@export_range(-600,-200) var JUMP_VELOCITY = -400.0

@export_group("跳跃补偿力度")
@export_range(-500.0,0.0) var JUMP_BOOST = -180.0

@export var max_jump_count = 2
var remaining_jumps: int = 0
var screen_size = get_viewport_rect ().size
# ===== 冲刺参数 =====
@export var MAX_DASHES = 1
@export var DASH_SPEED = 600.0      
@export var DASH_DURATION = 0.2     # 冲刺持续时间（秒）
var remaining_dashes: int = 0
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO

@export_group("蹬墙跳")
@export var WALL_JUMP_PUSH: float = 300.0   # 蹬墙水平推力
@export var WALL_JUMP_LOCK: float = 0.15    # 蹬墙后水平输入锁定时间（秒）
var wall_jump_lock_timer: float = 0.0

# 踩楼梯高度
@export var MAX_STEP_HEIGHT:float = 32.0

func _physics_process(delta: float) -> void:
	# --- 重力 ---
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		remaining_jumps = max_jump_count
		remaining_dashes = MAX_DASHES   # 落地恢复冲刺次数
	if wall_jump_lock_timer > 0.0:
		wall_jump_lock_timer -= delta
	# --- 跳跃 ---
	if Input.is_action_just_pressed("jump"):
		if not is_on_floor() and is_on_wall():   # 蹬墙跳
			var wall_normal := get_wall_normal()
			velocity.x = wall_normal.x*WALL_JUMP_PUSH
			velocity.y = JUMP_VELOCITY
			remaining_jumps = max_jump_count - 1
			wall_jump_lock_timer = WALL_JUMP_LOCK
		elif remaining_jumps > 0:
			velocity.y= JUMP_VELOCITY
			remaining_jumps -= 1
			if remaining_jumps == max_jump_count - 1:
				$JumpBoostTimer.start()
	
	if $JumpBoostTimer.time_left > 0.0 and Input.is_action_pressed("jump") and not is_on_floor():
		velocity.y += delta * JUMP_BOOST
	elif $JumpBoostTimer.time_left > 0.0 and not Input.is_action_pressed("jump"):
		$JumpBoostTimer.stop()

	# --- 输入方向（补上 y 轴）---
	var direction: Vector2 = Vector2.ZERO
	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	
	# ---走台阶方向---
	var facing = sign(direction.x)
	$RayStepBottom.scale.x = facing
	$RayStepTop.scale.x = facing
	# --- 冲刺状态处理 ---
	if is_dashing:
		dash_timer -= delta
		velocity = dash_direction * DASH_SPEED   # 强制覆盖速度，忽略重力
		if dash_timer <= 0.0:
			is_dashing = false
			# 冲刺结束保留一点惯性（可选）
			velocity *= 0.5
	else:
		if wall_jump_lock_timer <= 0.0:
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
	
	if is_on_floor() and not is_dashing:
		var dir_x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		if dir_x != 0:
			
			
			# 射线更新，强制刷新碰撞信息
			$RayStepBottom.force_raycast_update()
			$RayStepTop.force_raycast_update()

			if $RayStepBottom.is_colliding() and not $RayStepTop.is_colliding():
				print("检测台阶，抬升！")
				# 向上移动台阶高度，使用move_and_collide，不要直接改global_position
				move_and_collide(Vector2(0, -MAX_STEP_HEIGHT))
	
	
	move_and_slide()
