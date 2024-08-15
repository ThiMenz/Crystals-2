class_name VisionDetector extends Area3D

@export var collisionShape:CollisionShape3D
var colliders:Dictionary = {} #Node3D, null

func get_closest_collider_to(pVec:Vector3) -> Node3D:
	var rClosestCollider:Node3D = null
	var tDist:float = 999999999999999.
	for coll:Node3D in colliders:
		var tiDist := pVec.distance_squared_to(coll.global_position)
		if tiDist < tDist:
			tDist = tiDist
			rClosestCollider = coll
	return rClosestCollider
	
func set_radius(pRadius:float):
	collisionShape.shape = collisionShape.shape.duplicate(true)
	collisionShape.shape.radius = pRadius
	
const enemyBaseAttkTypeToCollLayer:Dictionary = {
	EnemyBase.AttackType.CRYSTAL:4,
	EnemyBase.AttackType.BUILDING:3,
	EnemyBase.AttackType.PLAYER:2
}
func set_type(type:EnemyBase.AttackType):
	set_collision_mask_value(enemyBaseAttkTypeToCollLayer[type], true)

func is_colliding() -> bool:
	return len(colliders) != 0

func is_colliding_with(body:Node3D) -> bool:
	return colliders.has(body)

func _on_body_entered(body:Node3D):
	colliders[body] = null

func _on_body_exited(body:Node3D):
	colliders.erase(body)
