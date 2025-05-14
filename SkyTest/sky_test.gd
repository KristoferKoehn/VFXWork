@tool
extends Node3D

@export_tool_button("Picture") 
var button = _picture

var timelist : PackedFloat32Array =[1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0,
									1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0,
									1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0,
									1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
var time_acc := 0.1
# Called when the node enters the scene tree for the first time.
func _ready():
	timelist.append_array(timelist) #80
	timelist.append_array(timelist) #160
	timelist.append_array(timelist) #320
	timelist.append_array(timelist) #640
	timelist.append_array(timelist) #1280
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if time_acc > 1.0:
		time_acc = 0.10
	time_acc += delta
	timelist.remove_at(0)
	timelist.append(time_acc)
	$WorldEnvironment.environment.sky.sky_material.set("shader_parameter/seeds", timelist)

func _picture():
	var capture = EditorInterface.get_editor_viewport_3d(0).get_texture().get_image()
	var filename = "user://Screenshot-{0}.png"
	capture.save_png(filename)
