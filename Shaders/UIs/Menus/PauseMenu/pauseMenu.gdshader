shader_type canvas_item;
// this parameter gets the game screen for the background
uniform sampler2D screenTex: hint_screen_texture;
// Moderate blur keeps the paused world readable without creating a doubled image.
uniform float blurAmount: hint_range(0, 10) = 1.6;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec4 col = vec4(0.0);
	int samples = 2;
	float count = 0.0;
	
	for (int x = -samples; x <= samples; x++){
		for(int y = -samples; y<= samples; y++){
			vec2 offset = uv + vec2(float(x),float(y)) * 0.0012 * blurAmount;
			col += texture(screenTex, offset);
			count += 1.0;
		}
	}
	
	COLOR = col/count;
}
