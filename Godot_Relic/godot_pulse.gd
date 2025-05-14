@tool # Optional: Allows the script to run in the editor
extends PointLight2D

@export var min_energy: float = 0.5 # The minimum energy (brightness) of the light
@export var max_energy: float = 1.5 # The maximum energy (brightness) of the light
@export var pulse_speed: float = 1.0 # How fast the light pulsates (cycles per second)

var _time: float = 0.0 # Renamed from 'private var _time'

func _ready():
	# Ensure min_energy is not greater than max_energy
	if min_energy > max_energy:
		var temp = min_energy
		min_energy = max_energy
		max_energy = temp
		printerr("PointLight2D Pulsate: min_energy was greater than max_energy. Values have been swapped.")

func _process(delta: float):
	_time += delta * pulse_speed

	# Calculate the sine wave (-1 to 1)
	var sin_wave: float = sin(_time * TAU) # TAU is 2 * PI, for a full cycle

	# Map the sine wave from [-1, 1] to [0, 1]
	var normalized_sin: float = (sin_wave + 1.0) / 2.0

	# Lerp between min_energy and max_energy based on the normalized sine wave
	energy = lerp(min_energy, max_energy, normalized_sin)

	# If you also want to pulsate the texture scale (if you are using a texture for the light)
	# You might want different min/max scale values and potentially a different speed
	# texture_scale = lerp(min_scale, max_scale, normalized_sin)

	# If you want to pulsate the color (e.g., its alpha value for fading)
	# var start_color = Color(1,1,1,0.5)
	# var end_color = Color(1,1,1,1)
	# color = start_color.lerp(end_color, normalized_sin)
