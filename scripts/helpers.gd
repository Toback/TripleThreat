class_name Helpers

static func map(value: float, min1: float, max1: float, min2: float, max2: float, clamp: bool = false) -> float:
	# map value from one range to another
	var val: float = min2 + (max2 - min2) * (value - min1) / (max1 - min1)
	if clamp:
		return clamp(val, min(min2,max2), max(min2, max2))
	else:
		return val
		
static func get_snapped_direction(raw_dir: Vector2) -> Vector2:
	# If input doesn't meet a threshold, return zero vector
	if raw_dir.length() < 0.5:
		return Vector2.ZERO
	
	# Get angle in radians
	var angle := raw_dir.angle()
	
	# Snap to nearest 45° (PI/4 radians)
	var snapped_angle = round(angle / (PI/4.0)) * (PI/4.0)
	
	# Convert back to Vector2
	var vector = Vector2.RIGHT.rotated(snapped_angle).normalized()
	
	# Fix floating point drift (treat anything close to 0 as exactly 0)
	# Without this, is_on_floor() wasn't working correctly because
	# the player was lifting off the ground just barely
	if abs(vector.x) < 0.0001:
		vector.x = 0
	if abs(vector.y) < 0.0001:
		vector.y = 0
	
	return vector
