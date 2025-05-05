shader_type canvas_item;

uniform vec4 tint;

void fragment() {
	float timer = fract(TIME * 0.02);
	float x_fer = fract(UV.x + timer);
	float y_fer = fract(UV.y - timer);
	vec2 new_uv = vec2(x_fer, y_fer);//mod(TIME, 2.0)*-1600.0 //UV.x - uv_mod

	vec4 texture_color = texture(TEXTURE, new_uv);
	vec4 rainbow = vec4(UV, 0.5, 1.0);

	 if (AT_LIGHT_PASS) {
		COLOR = texture_color;}
	else {
		COLOR = texture_color * rainbow;}
}

void vertex() {
	//VERTEX += vec2(10.0, 0.0);
	//VERTEX += vec2(cos(TIME)*100.0, sin(TIME)*100.0);

	//VERTEX += vec2(mod(TIME, 1.0)*-1600.0, mod(TIME, 1.0)*900.0);

//	float speed = 0.1;
//	//float position = fract(TIME * speed); //left to right
//	float position = 1.0 - fract(TIME * speed) * 2.0;
//	position = position + UV.y * 0.5;
//	VERTEX += vec2(position, position);
}