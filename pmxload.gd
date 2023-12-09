extends Node3D

func _ready():
	var scene := load("res://test/Sour MEIKA Hime/Sour Hime.pmx")
	ResourceSaver.save(scene, "res://test/SourMEIKA_Hime.tscn")
