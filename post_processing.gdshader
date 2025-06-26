shader_type canvas_item;
render_mode unshaded, skip_vertex_transform;
global uniform vec2 resolution;
global uniform float colordepth;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

void fragment() {
	vec2 uv = floor(SCREEN_UV*resolution) / resolution;
	vec3 color = texture(screen_texture, uv).rgb;
	vec3 quantized_color =  floor(color*colordepth) / colordepth;
	COLOR = vec4(quantized_color, 1.0);
}


//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
