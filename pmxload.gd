extends Node3D

enum Globals {
	TEXT_ENCODING,
	VEC4_COUNT,
	VERTEX_INDEX_SIZE,
	TEXTURE_INDEX_SIZE,
	MATERIAL_INDEX_SIZE,
	BONE_INDEX_SIZE,
	MORPH_INDEX_SIZE,
	RIGIDBODY_INDEX_SIZE,
}

enum FlagsBone {
	INDEXED_TAIL_POSITION = 0,
	ROTATABLE = 1,
	TRANSLATABLE = 2,
	VISIBLE = 3,
	ENABLED = 4,
	IK = 5,
	INHERIT_ROTATION = 8,
	INHERIT_TRANSLATION = 9,
	FIXED_AXIS = 10,
	LOCAL_COORDINATE = 11,
	PHYSICS_AFTER_DEFORM = 12,
	EXTERNAL_PARENT_DEFORM = 13,
}

func _ready():
	var file := FileAccess.open("res://test/Sour MEIKA Hime/Sour Hime.pmx", FileAccess.READ)
	if file.get_32() != 542657872:
		push_error("File sig invalid")
		return
	
	var version := file.get_float()
	var global_count := file.get_8()
	var globals := file.get_buffer(global_count)
	var model_name_jp := get_string(file, globals[Globals.TEXT_ENCODING])
	var model_name_en := get_string(file, globals[Globals.TEXT_ENCODING])
	var model_desc_jp := get_string(file, globals[Globals.TEXT_ENCODING])
	var model_desc_en := get_string(file, globals[Globals.TEXT_ENCODING])
	
	var arrays := []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	
	var vertex_count := file.get_32()
	for i in vertex_count:
		var vertex := Vector3(file.get_float(), file.get_float(), file.get_float())
		var normal := Vector3(file.get_float(), file.get_float(), file.get_float())
		var uv := Vector2(file.get_float(), file.get_float())
		vertices.push_back(vertex)
		normals.push_back(normal)
		uvs.push_back(uv)
		
		# stub
		for vec4 in globals[Globals.VEC4_COUNT]:
			for ii in 4: file.get_float()
		match file.get_8():
			0:  file.get_buffer(globals[Globals.BONE_INDEX_SIZE])
			1:
				file.get_buffer(globals[Globals.BONE_INDEX_SIZE])
				file.get_buffer(globals[Globals.BONE_INDEX_SIZE])
				file.get_float()
			2, 4:
				for ii in 4: file.get_buffer(globals[Globals.BONE_INDEX_SIZE])
				for ii in 4: file.get_float()
			3:
				file.get_buffer(globals[Globals.BONE_INDEX_SIZE])
				file.get_buffer(globals[Globals.BONE_INDEX_SIZE])
				for ii in 10: file.get_float()
		file.get_float()
	
	arrays[ArrayMesh.ARRAY_VERTEX] = PackedVector3Array()
	arrays[ArrayMesh.ARRAY_NORMAL] = PackedVector3Array()
	arrays[ArrayMesh.ARRAY_TEX_UV] = PackedVector2Array()
	var surface_count := file.get_32()
	for i in surface_count / 3:
		var idx1 := get_idx(file, globals[Globals.VERTEX_INDEX_SIZE], false)
		var idx2 := get_idx(file, globals[Globals.VERTEX_INDEX_SIZE], false)
		var idx3 := get_idx(file, globals[Globals.VERTEX_INDEX_SIZE], false)
		arrays[ArrayMesh.ARRAY_VERTEX].push_back(vertices[idx3])
		arrays[ArrayMesh.ARRAY_NORMAL].push_back(normals[idx3])
		arrays[ArrayMesh.ARRAY_TEX_UV].push_back(uvs[idx3])
		arrays[ArrayMesh.ARRAY_VERTEX].push_back(vertices[idx2])
		arrays[ArrayMesh.ARRAY_NORMAL].push_back(normals[idx2])
		arrays[ArrayMesh.ARRAY_TEX_UV].push_back(uvs[idx2])
		arrays[ArrayMesh.ARRAY_VERTEX].push_back(vertices[idx1])
		arrays[ArrayMesh.ARRAY_NORMAL].push_back(normals[idx1])
		arrays[ArrayMesh.ARRAY_TEX_UV].push_back(uvs[idx1])
	
	var textures := PackedStringArray()
	var texture_count := file.get_32()
	for i in texture_count:
		textures.push_back(get_string(file, globals[Globals.TEXT_ENCODING]))
	
	var materials := []
	var material_surfaces := []
	var material_count := file.get_32()
	for i in material_count:
		var name_jp := get_string(file, globals[Globals.TEXT_ENCODING])
		var name_en := get_string(file, globals[Globals.TEXT_ENCODING])
		
		var diffuse := Color(file.get_float(), file.get_float(), file.get_float(), file.get_float())
		var specular := Color(file.get_float(), file.get_float(), file.get_float())
		var specular_strength := file.get_float()
		var ambient := Color(file.get_float(), file.get_float(), file.get_float())
		var flags := file.get_8()
		var edge := Color(file.get_float(), file.get_float(), file.get_float(), file.get_float())
		var edge_scale := file.get_float()
		var texture_idx := get_idx(file, globals[Globals.TEXTURE_INDEX_SIZE], false)
		var environment_idx := get_idx(file, globals[Globals.TEXTURE_INDEX_SIZE], false)
		var environment_blend_mode := file.get_8()
		var toon_ref := file.get_8()
		var toon_val := file.get_8() - 20 if toon_ref else get_idx(file, globals[Globals.TEXTURE_INDEX_SIZE], false)
		var metadata := get_string(file, globals[Globals.TEXT_ENCODING])
		var num_surfaces := file.get_32()
		
		var mat := StandardMaterial3D.new()
		mat.resource_name = name_en
		mat.albedo_color = diffuse
		mat.roughness = -specular_strength
		mat.albedo_texture = load("res://test/Sour MEIKA Hime/%s" % textures[texture_idx].replace("\\", "/"))
		if diffuse.a < 1.0:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
		if mat.albedo_texture.get_image().detect_alpha() != Image.ALPHA_NONE:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
		materials.push_back(mat)
		material_surfaces.push_back(num_surfaces)
	
	var idxmap := {}
	var skeleton := SkeletonPMX3D.new()
	var bone_count := file.get_32()
	for i in bone_count:
		var name_jp := get_string(file, globals[Globals.TEXT_ENCODING])
		var name_en := get_string(file, globals[Globals.TEXT_ENCODING])
		var position := Vector3(file.get_float(), file.get_float(), file.get_float())
		var parent_bone := get_idx(file, globals[Globals.BONE_INDEX_SIZE], true)
		var layer := file.get_32()
		var flags := file.get_16()
		var tail
		if check_flag(flags, FlagsBone.INDEXED_TAIL_POSITION): tail = get_idx(file, globals[Globals.BONE_INDEX_SIZE], false)
		else: tail = Vector3(file.get_float(), file.get_float(), file.get_float())
		
		var bone_name := name_en.replace(":", "_").replace("/", "_")
		if bone_name.is_empty(): bone_name = "UnnamedBone"
		if skeleton.find_bone(bone_name) != -1:
			var num := 0
			var test_name := "%s.%d" % [bone_name, num]
			while skeleton.find_bone(test_name) != -1:
				num += 1
				test_name = "%s.%d" % [bone_name, num]
			bone_name = test_name
		var bone_idx := skeleton.get_bone_count()
		skeleton.add_bone(bone_name)
		idxmap[i] = bone_idx
		
		if parent_bone != -1: skeleton.set_bone_parent(bone_idx, idxmap[parent_bone])
		skeleton.set_bone_rest(bone_idx, Transform3D(Basis(), position))
		skeleton.set_bone_pose_position(bone_idx, position)
		if tail is Vector3:
			var leaf_bone_idx := skeleton.get_bone_count()
			skeleton.add_bone(bone_name + ".leaf")
			skeleton.set_bone_parent(leaf_bone_idx, bone_idx)
			skeleton.set_bone_rest(leaf_bone_idx, Transform3D(Basis(), tail))
			skeleton.set_bone_pose_position(leaf_bone_idx, tail)
		else:
			skeleton.inherit_map[bone_idx] = [ # TODO: make this use enum
				tail,
				check_flag(flags, FlagsBone.INHERIT_ROTATION),
				check_flag(flags, FlagsBone.INHERIT_TRANSLATION),
			]
			skeleton._on_bone_pose_changed(bone_idx)
		
		if check_flag(flags, FlagsBone.INHERIT_ROTATION) or check_flag(flags, FlagsBone.INHERIT_TRANSLATION):
			var idx := get_idx(file, globals[Globals.BONE_INDEX_SIZE], false)
			var influence := file.get_float()
		if check_flag(flags, FlagsBone.FIXED_AXIS):
			var axis := Vector3(file.get_float(), file.get_float(), file.get_float())
		if check_flag(flags, FlagsBone.LOCAL_COORDINATE):
			var x := Vector3(file.get_float(), file.get_float(), file.get_float())
			var z := Vector3(file.get_float(), file.get_float(), file.get_float())
		if check_flag(flags, FlagsBone.EXTERNAL_PARENT_DEFORM):
			var idx := get_idx(file, globals[Globals.BONE_INDEX_SIZE], false)
		if check_flag(flags, FlagsBone.IK):
			var target_idx := get_idx(file, globals[Globals.BONE_INDEX_SIZE], false)
			var loop_count := file.get_32()
			var limit_radian := file.get_float()
			var link_count := file.get_32()
			for ii in link_count:
				var idx := get_idx(file, globals[Globals.BONE_INDEX_SIZE], false)
				var has_limits := file.get_8()
				if has_limits == 1:
					var min := Vector3(file.get_float(), file.get_float(), file.get_float())
					var max := Vector3(file.get_float(), file.get_float(), file.get_float())
	
	var arraymesh := ArrayMesh.new()
	var start := 0
	for i in materials.size():
		var arrays_copy := []
		arrays_copy.resize(ArrayMesh.ARRAY_MAX)
		arrays_copy[ArrayMesh.ARRAY_VERTEX] = arrays[ArrayMesh.ARRAY_VERTEX].slice(start, start + material_surfaces[i])
		arrays_copy[ArrayMesh.ARRAY_NORMAL] = arrays[ArrayMesh.ARRAY_NORMAL].slice(start, start + material_surfaces[i])
		arrays_copy[ArrayMesh.ARRAY_TEX_UV] = arrays[ArrayMesh.ARRAY_TEX_UV].slice(start, start + material_surfaces[i])
		arraymesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays_copy)
		arraymesh.surface_set_material(i, materials[i])
		arraymesh.surface_set_name(i, materials[i].resource_name)
		start += material_surfaces[i]
	
	var instance := MeshInstance3D.new()
	instance.mesh = arraymesh
	skeleton.add_child(instance)
	instance.owner = skeleton
	
	var scene := PackedScene.new()
	scene.pack(skeleton)
	ResourceSaver.save(scene, "res://test/SourMEIKA_Hime.tscn")

func get_string(file: FileAccess, encoding: int) -> String:
	var length := file.get_32()
	var bytes := file.get_buffer(length)
	match encoding:
		0: return bytes.get_string_from_utf16()
		1: return bytes.get_string_from_utf8()
	push_error("Unknown text encoding")
	return ""

func get_idx(file: FileAccess, size: int, signed: bool) -> int:
	match size:
		1: return s8(file.get_8()) if signed else file.get_8()
		2: return s16(file.get_16()) if signed else file.get_16()
		4: return s32(file.get_32()) if signed else file.get_32()
	return -1 if signed else 0

func check_flag(flags: int, bit: int) -> bool:
	return (flags >> bit) & 1

func s8(unsigned: int) -> int:
	return (unsigned + (1 << 7)) % (1 << 8) - (1 << 7)

func s16(unsigned: int) -> int:
	return (unsigned + (1 << 15)) % (1 << 16) - (1 << 15)

func s32(unsigned: int) -> int:
	return (unsigned + (1 << 31)) % (1 << 32) - (1 << 31)
