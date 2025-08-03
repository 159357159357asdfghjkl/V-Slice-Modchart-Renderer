package funkin.play.modchart.shaders;

import flixel.system.FlxAssets.FlxShader;

class ModchartHSVShader
{
  public var shader(default, null):ModchartHSVShaderFrag;
  public var hue(default, set):Float;
  public var saturation(default, set):Float;
  public var value(default, set):Float;
  public var glow(default, set):Float;
  public var diffuser(default, set):Float;
  public var diffuseg(default, set):Float;
  public var diffuseb(default, set):Float;
  public var diffusea(default, set):Float;
  public var glowdiffuser(default, set):Float;
  public var glowdiffuseg(default, set):Float;
  public var glowdiffuseb(default, set):Float;
  public var glowdiffusea(default, set):Float;

  public function new()
  {
    shader = new ModchartHSVShaderFrag();
    shader._hue.value = [1.0];
    shader._sat.value = [1.0];
    shader._val.value = [1.0];
    shader.glow.value = [0.0];
    shader.diffuser.value = [1.0];
    shader.glowdiffuser.value = [1.0];
    shader.diffuseg.value = [1.0];
    shader.glowdiffuseg.value = [1.0];
    shader.diffuseb.value = [1.0];
    shader.glowdiffuseb.value = [1.0];
    shader.diffusea.value = [1.0];
    shader.glowdiffusea.value = [1.0];
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

  function set_glow(value:Float)
  {
    glow = value;
    shader.glow.value[0] = glow;
    return glow;
  }

  function set_diffuser(value:Float)
  {
    diffuser = value;
    shader.diffuser.value[0] = value;
    return diffuser;
  }

  function set_diffuseg(value:Float)
  {
    diffuseg = value;
    shader.diffuseg.value[0] = value;
    return diffuseg;
  }

  function set_diffuseb(value:Float)
  {
    diffuseb = value;
    shader.diffuseb.value[0] = value;
    return diffuseb;
  }

  function set_diffusea(value:Float)
  {
    diffusea = value;
    shader.diffusea.value[0] = value;
    return diffusea;
  }

  function set_glowdiffuser(value:Float)
  {
    glowdiffuser = value;
    shader.glowdiffuser.value[0] = value;
    return glowdiffuser;
  }

  function set_glowdiffuseg(value:Float)
  {
    glowdiffuseg = value;
    shader.glowdiffuseg.value[0] = value;
    return glowdiffuseg;
  }

  function set_glowdiffuseb(value:Float)
  {
    glowdiffuseb = value;
    shader.glowdiffuseb.value[0] = value;
    return glowdiffuseb;
  }

  function set_glowdiffusea(value:Float)
  {
    glowdiffusea = value;
    shader.glowdiffusea.value[0] = value;
    return glowdiffusea;
  }
}

class ModchartHSVShaderFrag extends FlxShader
{
  @:glFragmentSource('
  #pragma header

  uniform float _hue;
  uniform float _sat;
  uniform float _val;
  uniform float glow;
  uniform float diffuser;
  uniform float diffuseg;
  uniform float diffuseb;
  uniform float diffusea;
  uniform float glowdiffuser;
  uniform float glowdiffuseg;
  uniform float glowdiffuseb;
  uniform float glowdiffusea;

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
  if(glow != 0.0){
	  color = mix(color, vec4(glowdiffuser,glowdiffuseg,glowdiffuseb,glowdiffusea), glow) * color.a;
	}
  color *= vec4(diffuser,diffuseg,diffuseb,diffusea);
	gl_FragColor = color;
  }
  ')
  public function new()
  {
    super();
  }
}
