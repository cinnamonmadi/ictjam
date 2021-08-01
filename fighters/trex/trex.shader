shader_type canvas_item;

float max(float a, float b){

	if(a >= b){

		return a;

	}else{

		return b;
	}
}

float max3(float a, float b, float c){

	float ab_max = max(a, b);
	if(ab_max >= c){

		return ab_max;

	}else{

		return c;
	}
}

float min(float a, float b){

	if(a <= b){

		return a;

	}else{

		return b;
	}
}

float min3(float a, float b, float c){

	float ab_min = min(a, b);
	if(ab_min <= c){

		return ab_min;

	}else{

		return c;
	}
}

float hue_clamp(float h){

	if(h < 0.0){

		return 0.0;

	}else if(h >= 360.0){

		return 359.9;

	}else{

		return h;
	}
}

vec3 to_hsv(vec3 rgb){

	float rp = rgb.r / 255.0;
	float gp = rgb.g / 255.0;
	float bp = rgb.b / 255.0;
	float cmax = max3(rp, gp, bp);
	float cmin = min3(rp, gp, bp);
	float delta = cmax - cmin;

	float h = 0.0;
	if(delta == rp){
		h = 60.0 * float(int((gp - bp) / delta) % 6);
	}else if(delta == gp){
		h = 60.0 * (((bp - rp) / delta) + 2.0);
	}else if(delta == bp){
		h = 60.0 * (((rp - gp) / delta) + 4.0);
	}

	float s = 0.0;
	if(cmax != 0.0){

		s = delta / cmax;
	}

	float v = cmax;

	return vec3(h, s, v);
}

vec3 to_rgb(vec3 hsv){

	float h = hsv.r;
	float s = hsv.g;
	float v = hsv.b;

	float c = v * s;
	float x = c * float(1 - abs((int(h / 60.0) % 2) - 1));
	float m = v - c;

	vec3 prime;
	if(h >= 300.0){
		prime = vec3(c, 0.0, x);
	}else if(h >= 240.0){
		prime = vec3(x, 0.0, c);
	}else if(h >= 180.0){
		prime = vec3(0.0, x, c);
	}else if(h >= 120.0){
		prime = vec3(0.0, c, x);
	}else if(h >= 60.0){
		prime = vec3(x, c, 0.0);
	}else{
		prime = vec3(c, x, 0.0);
	}

	return vec3((prime.r + m), (prime.g + m), (prime.b + m));
}

uniform int player = 1;

float map_hue(float h){

    if(player == 1){

        return h;

    }else if(player == 2){

		return h + 240.0;

	}else if(player == 3){

		return h + 300.0;

	}else{

		return h + 60.0;
	}
}

void fragment(){

	COLOR = texture(TEXTURE, UV);
    if(COLOR.a != 0.0){

	   float cmax = max3(COLOR.r, COLOR.g, COLOR.b);
	   if(cmax == COLOR.r){

		    vec3 hsv = to_hsv(vec3(COLOR.r * 255.0, COLOR.g * 255.0, COLOR.b * 255.0));
		    vec3 rgb = to_rgb(vec3(hue_clamp(map_hue(hsv.r)), hsv.g, hsv.b));
	        COLOR = vec4(rgb.r, rgb.g, rgb.b, COLOR.a);
        }
    }
}
