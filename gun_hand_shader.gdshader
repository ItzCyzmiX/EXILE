shader_type canvas_item;

uniform sampler2D mask_texture; // Viewport texture
uniform sampler2D sprite_texture;

void fragment() {
	vec4 sprite_color = texture(sprite_texture, UV);
	vec4 text_color = texture(mask_texture, UV);

	// Use the sprite's alpha to mask the text
	float mask = sprite_color.a;
	COLOR.rgb = text_color.rgb * mask;
	COLOR.a = text_color.a * mask;
}
