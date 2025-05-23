shader_type canvas_item;
render_mode unshaded;

uniform vec3 background : source_color;
uniform vec3 color : source_color;

// Author: @patriciogv ( patriciogonzalezvivo.com ) - 2015
// Title: IChing

const float TWO_PI = 6.28318530718;

float shape(vec2 st, float N){
    st = st*2.-1.;
    float a = atan(st.x,st.y)+PI;
    float r = TWO_PI/N;
    return abs(cos(floor(.5+a/r)*r-a)*length(st));
}

float box(vec2 st, vec2 size){
    return shape(st*size,4.);
}

float rect(vec2 _st, vec2 _size){
    _size = vec2(0.5)-_size*0.5;
    vec2 uv = smoothstep(_size,_size+vec2(1e-4),_st);
    uv *= smoothstep(_size,_size+vec2(1e-4),vec2(1.0)-_st);
    return uv.x*uv.y;
}

float hex(vec2 st, float a, float b, float c, float d, float e, float f){
    st = st*vec2(2.,6.);

    vec2 fpos = fract(st);
    vec2 ipos = floor(st);

    if (ipos.x == 1.0) fpos.x = 1.-fpos.x;
    if (ipos.y < 1.0){
        return mix(box(fpos, vec2(0.84,1.)),box(fpos-vec2(0.03,0.),vec2(1.)),a);
    } else if (ipos.y < 2.0){
        return mix(box(fpos, vec2(0.84,1.)),box(fpos-vec2(0.03,0.),vec2(1.)),b);
    } else if (ipos.y < 3.0){
        return mix(box(fpos, vec2(0.84,1.)),box(fpos-vec2(0.03,0.),vec2(1.)),c);
    } else if (ipos.y < 4.0){
        return mix(box(fpos, vec2(0.84,1.)),box(fpos-vec2(0.03,0.),vec2(1.)),d);
    } else if (ipos.y < 5.0){
        return mix(box(fpos, vec2(0.84,1.)),box(fpos-vec2(0.03,0.),vec2(1.)),e);
    } else if (ipos.y < 6.0){
        return mix(box(fpos, vec2(0.84,1.)),box(fpos-vec2(0.03,0.),vec2(1.)),f);
    }
    return 0.0;
}

float hex2(vec2 st, float N){
    float b[6];
    float refragment = floor(mod(N,64.));
    for(int i = 0; i < 6; i++){
        b[i] = 0.0;
        b[i] = step(1.0,mod(refragment,2.));
        refragment = ceil(refragment/2.);
    }
    return hex(st,b[0],b[1],b[2],b[3],b[4],b[5]);
}

float random (in vec2 _st) { return fract(sin(dot(_st.xy, vec2(12.9898,78.233)))* 43758.5453123);}

void fragment(){
    vec2 st = FRAGCOORD.xy/(1.0/SCREEN_PIXEL_SIZE).xy;
    st.y *= (1.0/SCREEN_PIXEL_SIZE).y/(1.0/SCREEN_PIXEL_SIZE).x;

    st *= 10.0;
    vec2 fpos = fract(st);
    vec2 ipos = floor(st);

    float t = TIME*5.0;
    float df = 1.0;
    df = hex2(fpos,ipos.x+ipos.y+t*random(ipos))+(1.0-rect(fpos,vec2(0.7)));

    COLOR = vec4(mix(color,background,step(0.7,df)),0.8);
}
