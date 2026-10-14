extends CharacterBody2D


const SPEED = 300.0
@export_group("跳跃速度")
@export_range(-600,-200) var JUMP_VELOCITY = -400.0

@export_group("跳跃补偿力度")
@export_range(-500.0,0.0) var JUMP_BOOST  = -180.0

@export var max_jump_count = 2 # 最大跳跃次数

var remaining_jumps: int = 0 # 剩余可用跳跃次数

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		remaining_jumps=max_jump_count
	if Input.is_action_just_pressed("ui_accept") and remaining_jumps > 0:
		velocity.y = JUMP_VELOCITY
		remaining_jumps -= 1 # 消耗一次跳跃
		# 只有第一次跳跃开启长按加高窗口
		if remaining_jumps == max_jump_count -1:
			$Timer.start()
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		$Timer.start()
		
	if $Timer.time_left>0.0 and Input.is_action_pressed("ui_accept") and not is_on_floor():
		velocity.y += delta * JUMP_BOOST
	elif $Timer.time_left > 0.0 and not Input.is_action_pressed("ui_accept"):
		$Timer.stop()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction:Vector2 =  Vector2.ZERO
	direction.x=Input.get_action_strength("ui_right")-Input.get_action_strength("ui_left")
	
	if direction.x!=0:
		velocity.x = direction.x * SPEED
		
		var testsprite:AnimatedSprite2D = get_node("AnimatedSprite2D")
		if direction.x<0:
			testsprite.flip_h=true
		else:
			testsprite.flip_h=false
			
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	move_and_slide()
