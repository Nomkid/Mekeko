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
		var idx1 := get_idx(file, globals[Globals.VERTEX_INDEX_SIZE])
		var idx2 := get_idx(file, globals[Globals.VERTEX_INDEX_SIZE])
		var idx3 := get_idx(file, globals[Globals.VERTEX_INDEX_SIZE])
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
		var texture_idx := get_idx(file, globals[Globals.TEXTURE_INDEX_SIZE])
		var environment_idx := get_idx(file, globals[Globals.TEXTURE_INDEX_SIZE])
		var environment_blend_mode := file.get_8()
		var toon_ref := file.get_8()
		var toon_val := file.get_8() - 20 if toon_ref else get_idx(file, globals[Globals.TEXTURE_INDEX_SIZE])
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
	ResourceSaver.save(arraymesh, "res://test/SourMEIKA_Hime.res")

func get_string(file: FileAccess, encoding: int) -> String:
	var length := file.get_32()
	var bytes := file.get_buffer(length)
	return bytes.get_string_from_utf16()

func get_idx(file: FileAccess, size: int) -> int:
	match size:
		1: return file.get_8()
		2: return file.get_16()
		4: return file.get_32()
	return -1
