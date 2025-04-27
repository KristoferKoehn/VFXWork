shader_type canvas_item;

uniform sampler2D lightning : filter_nearest;
uniform vec4 color : source_color;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	float a_var = -pow((UV.x * 2.0 - 1.0),4) + 1.0;
	float p_var = -pow((mod(UV.x + TIME * 3.0, 1.0) * 2.0 - 1.0),2.0) + 1.0;
	COLOR = texture(lightning, mod(UV + TIME * vec2(2,0), vec2(1.0,1.0))) * color * 2.0;
	COLOR.a *= a_var * p_var * clamp(sin(TIME * 3.0) + 0.5, 0.1, 1);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
