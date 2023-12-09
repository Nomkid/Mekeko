class_name PMXSkeleton3D
extends Skeleton3D

enum {
	FROM_BONE,
	ROTATION,
	POSITION,
}

@export var inherit_map := {}

func _ready():
	bone_pose_changed.connect(self._on_bone_pose_changed)

func _on_bone_pose_changed(bone_idx: int):
	if inherit_map.has(bone_idx):
		var inherit: Array = inherit_map[bone_idx]
		#if inherit[ROTATION]: set_bone_pose_rotation(bone_idx, get_bone_pose_rotation(inherit[FROM_BONE]))
		#if inherit[POSITION]: set_bone_pose_position(bone_idx, get_bone_pose_position(inherit[FROM_BONE]))
