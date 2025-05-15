@tool
extends Node3D

@export_tool_button("Picture") 
var button = _picture
var exposing = false
@export
var Max_Exposure : int = 10
var frames_exposed : int = 0

@export
var viewport : Viewport = EditorInterface.get_editor_viewport_3d(0)
var images : Array[Image] = []

var timelist : PackedFloat32Array =[]
var time_acc := 0.1


# Called when the node enters the scene tree for the first time.
func _ready():
	for r in 1280:
		timelist.append(0.001 + randf())
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if time_acc > 1000.0:
		time_acc = 0.10
	time_acc += delta
	timelist.remove_at(timelist.size() -1)
	timelist.insert(0, time_acc)
	$WorldEnvironment.environment.sky.sky_material.set("shader_parameter/seeds", timelist)
	
	if exposing:
		frames_exposed = frames_exposed + 1
		images.append(viewport.get_texture().get_image())
		print("Image Captured:", frames_exposed)
	
	if frames_exposed == Max_Exposure:
		var i : Image = Image.create_empty(images[0].get_width(),images[0].get_height(), false, images[0].get_format())
		for x in range(images[0].get_width()):
			for y in range(images[0].get_height()):
				var px = Color()
				for j in Max_Exposure:
					px += images[j].get_pixel(x, y)
				px = px * (1.0 / (Max_Exposure))
				i.set_pixel(x, y, px)
		var filename = "user://Screenshot " + str(Time.get_ticks_msec()) + ".png"
		i.save_png(filename)
		exposing = false
		frames_exposed = 0
		images.clear()
		print("DONE")

func _picture():
	exposing = true
	viewport.get_camera_3d().transform = EditorInterface.get_editor_viewport_3d(0).get_camera_3d().transform
