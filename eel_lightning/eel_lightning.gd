@tool
extends Node2D

@export var line: Line2D
@export var front_particle: GPUParticles2D
@export var back_particle: GPUParticles2D

var delta_accumulation = 0.0;
var iteration = 0;

func _ready() -> void:
	var t : Timer = Timer.new()
	add_child(t)
	t.start(1)
	var lambda = func iter() -> void:
		iteration += 1
	t.timeout.connect(lambda)
	pass

func _process(delta: float) -> void:
	delta_accumulation += delta
		
	front_particle.position = line.get_point_position(iteration % (line.points.size() - 1))
	back_particle.position = line.get_point_position((iteration + (line.points.size() - 1)/2) % (line.points.size() - 1))
	pass
