package funkin.play.modchart.shaders;

import flixel.system.FlxAssets.FlxShader;

class ModchartHSVShader
{
  public var shader(default, null):ModchartHSVShaderFrag;
  public var hue(default, set):Float;
  public var saturation(default, set):Float;
  public var value(default, set):Float;
  public var ALPHA(default, set):Float = 1;
  public var GLOW(default, set):Float = 0;

  public function new()
  {
    shader = new ModchartHSVShaderFrag();
    shader._hue.value = [1];
    shader._sat.value = [1];
    shader._val.value = [1];
    shader.ALPHA.value = [1];
    shader.GLOW.value = [0];
  }

  function set_hue(value:Float):Float
  {
    shader._hue.value[0] = value;
    this.hue = value;

    return this.hue;
  }

  function set_saturation(value:Float):Float
  {
    shader._sat.value[0] = value;
    this.saturation = value;

    return this.saturation;
  }

  function set_value(value:Float):Float
  {
    shader._val.value[0] = value;
    this.value = value;

    return this.value;
  }

  function set_ALPHA(value:Float)
  {
    ALPHA = value;
    shader.ALPHA.value[0] = ALPHA;
    return ALPHA;
  }

  function set_GLOW(value:Float)
  {
    GLOW = value;
    shader.GLOW.value[0] = GLOW;
    return GLOW;
  }
}

class ModchartHSVShaderFrag extends FlxShader
{
  @:glFragmentSource('
  #pragma header

  uniform float _hue;
  uniform float _sat;
  uniform float _val;
  uniform float ALPHA;
  uniform float GLOW;
  vec3 normalizeColor(vec3 color)
  {
    return vec3(
        color[0] / 255.0,
        color[1] / 255.0,
        color[2] / 255.0
    );
  }

  vec3 rgb2hsv(vec3 c)
  {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
  }

  vec3 hsv2rgb(vec3 c)
  {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
  }

  void main() {
  vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);
  vec4 swagColor = vec4(rgb2hsv(vec3(color[0], color[1], color[2])), color[3]);
  swagColor.x *= _hue;
  swagColor.y *= _sat;
  swagColor.z *= _val;

  swagColor.z *= (_hue * 0.5) + 0.5;
  color = vec4(hsv2rgb(vec3(swagColor[0], swagColor[1], swagColor[2])), swagColor[3]);
  if(GLOW != 0.0){
	  color = mix(color, vec4(1.0,1.0,1.0,1.0), GLOW) * color.a;
	}
	color *= ALPHA;
	gl_FragColor = color;
  }
  ')
  public function new()
  {
    super();
  }
}
