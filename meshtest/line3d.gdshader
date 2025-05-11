shader_type spatial;
render_mode cull_disabled, unshaded;

uniform sampler2D tex;
uniform vec3 c : source_color;
uniform float time_scale : hint_range(0.0, 20.0, 0.1) = 0.5;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	ALBEDO = vec3(normalize(UV), 0);
	ALPHA = 0.6;
	//ALBEDO = texture(tex, vec2(UV.x/3.0 + 2.0/6.0, UV.y - TIME*time_scale)).rgb * c;
	//ALPHA = clamp(texture(tex, vec2(UV.x/3.0 + 2.0/6.0, UV.y - TIME*time_scale)).w , 0.0, 1.0);
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
