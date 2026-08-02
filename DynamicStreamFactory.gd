class_name DynamicStreamFactory
extends Node

# ==============================================================================
# 🌟 核心通用工厂函数 (闭包复用模板)
# ==============================================================================
static func create_motion_stream(
	input_provider: Callable,
	speed: float,
	anim_frames: Array[int],
	anim_name: String
) -> Dictionary:
	
	# --- A. 构建物理位移闭包 ---
	var vector_supplier = func() -> Array[Vector3]:
		var input_dir: Vector2 = Vector2.ZERO
		if input_provider and input_provider.is_valid():
			var raw_res = input_provider.call()
			if raw_res is Vector2:
				input_dir = raw_res
				
		# 抗浮点数偏差
		if input_dir.length_squared() <= 0.001:
			return []
			
		var step_2d = input_dir.normalized() * speed
		return [Vector3(step_2d.x, step_2d.y, 0.0)]

	# --- B. 构建动画字典闭包 ---
	# 🌟 使用引用数组，确保闭包多次 call() 时索引正常自增
	var anim_index_ref: Array[int] = [0]
	var total_frames: int = anim_frames.size()
	
	var anim_supplier = func() -> Array[Dictionary]:
		if total_frames == 0:
			return []
			
		var input_dir: Vector2 = Vector2.ZERO
		if input_provider and input_provider.is_valid():
			var raw_res = input_provider.call()
			if raw_res is Vector2:
				input_dir = raw_res
		
		var is_moving: bool = input_dir.length_squared() > 0.001
		
		if is_moving:
			var current_idx: int = anim_index_ref[0]
			var frame_idx: int = anim_frames[current_idx]
			
			# 推进索引并更新引用
			anim_index_ref[0] = (current_idx + 1) % total_frames
			
			return [{
				"name": anim_name,
				"frame": frame_idx
			}]
		else:
			return []

	return {
		"vector_supplier": vector_supplier,
		"anim_supplier": anim_supplier,
		"anim_name": anim_name
	}


# ==============================================================================
# 🚀 对外暴露的具体动作接口 (极为干净简洁)
# ==============================================================================

## 构建【走路 Walk】流 (速度较慢)
static func create_walk_stream(
	input_provider: Callable, 
	speed: float = 2.375, 
	anim_frames: Array[int] = [0, 3, 6, 9, 12, 15, 18, 21], 
	anim_name: String = "walk"
) -> Dictionary:
	return create_motion_stream(input_provider, speed, anim_frames, anim_name)


## 构建【跑步 Run】流 (速度更快，帧序列可能更密或不同)
static func create_run_stream(
	input_provider: Callable, 
	speed: float = 3.0, 
	anim_frames: Array[int] = [0, 3, 6, 9], 
	anim_name: String = "run"
) -> Dictionary:
	return create_motion_stream(input_provider, speed, anim_frames, anim_name)
