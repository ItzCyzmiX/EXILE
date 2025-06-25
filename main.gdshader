shader_type canvas_item;

uniform float PIXEL_SIZE = 3.;

void fragment() {

	vec2 screen_size = 1. / SCREEN_PIXEL_SIZE;

	int x = int(UV.x * screen_size.x / PIXEL_SIZE);
	int y = int(UV.y * screen_size.y / PIXEL_SIZE);

	if (x % 3 == 0 || y % 3 == 0) {

		COLOR = vec4(0, 0, 0, 1);

	} else if (x % 3 == 1) {

		if (y % 3 == 1) {
			COLOR = vec4(COLOR.r, 0, 0, 1);
		} else {
			COLOR = vec4(0, COLOR.g, 0, 1);
		}

	} else {

		if (y % 3 == 1) {
			COLOR = vec4(0, 0, COLOR.b, 1);
		} else {
			COLOR = vec4(0, 0, 0, 1);
		}
	}
}