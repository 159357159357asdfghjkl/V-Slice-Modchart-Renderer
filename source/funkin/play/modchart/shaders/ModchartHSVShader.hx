package funkin.play.modchart.shaders;

import flixel.system.FlxAssets.FlxShader;

class ModchartHSVShader
{
  public var shader(default, null):ModchartHSVShaderGLSL;
  public var hue(default, set):Float;
  public var saturation(default, set):Float;
  public var value(default, set):Float;
  public var glow(default, set):Float;
  public var diffuser(default, set):Float;
  public var diffuseg(default, set):Float;
  public var diffuseb(default, set):Float;
  public var a(default, set):Float;
  public var glowdiffuser(default, set):Float;
  public var glowdiffuseg(default, set):Float;
  public var glowdiffuseb(default, set):Float;

  public function new()
  {
    shader = new ModchartHSVShaderGLSL();
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
    shader.a.value = [1.0];
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

  function set_a(value:Float)
  {
    a = value;
    shader.a.value[0] = value;
    return a;
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
}

class ModchartHSVShaderGLSL extends FlxShader
{
  @:glVertexSource('
  #pragma header

  attribute float _hue;
  attribute float _sat;
  attribute float _val;
  attribute float glow;
  attribute float a;
  attribute float diffuser;
  attribute float diffuseg;
  attribute float diffuseb;
  attribute float glowdiffuser;
  attribute float glowdiffuseg;
  attribute float glowdiffuseb;
  varying float _hue2;
  varying float _sat2;
  varying float _val2;
  varying float glow2;
  varying float a2;
  varying float diffuser2;
  varying float diffuseg2;
  varying float diffuseb2;
  varying float glowdiffuser2;
  varying float glowdiffuseg2;
  varying float glowdiffuseb2;

  void main()
  {
    #pragma body
    _hue2 = _hue;
    _sat2 = _sat;
    _val2 = _val;
    glow2 = glow;
    a2 = a;
    diffuser2 = diffuser;
    diffuseg2 = diffuseg;
    diffuseb2 = diffuseb;
    glowdiffuser2 = glowdiffuser;
    glowdiffuseg2 = glowdiffuseg;
    glowdiffuseb2 = glowdiffuseb;
  }
  ')
  @:glFragmentSource('
  #pragma header

  varying float _hue2;
  varying float _sat2;
  varying float _val2;
  varying float glow2;
  varying float a2;
  varying float diffuser2;
  varying float diffuseg2;
  varying float diffuseb2;
  varying float glowdiffuser2;
  varying float glowdiffuseg2;
  varying float glowdiffuseb2;

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

	vec4 modchartTexture2D(sampler2D bitmap, vec2 coord)
	{
		vec4 color = texture2D(bitmap, coord);
		if (isTexture)
			color.rgb *= color.a;
		if (!(hasTransform || openfl_HasColorTransform))
			return color;
		if (color.a == 0.0)
			return vec4(0.0, 0.0, 0.0, 0.0);
		if (openfl_HasColorTransform || hasColorTransform)
		{
			color = vec4 (color.rgb / color.a, color.a);
			vec4 mult = vec4(openfl_ColorMultiplierv.rgb, 1.0);
      vec4 off = openfl_ColorOffsetv;
  		color = clamp (off + (color * mult), 0.0, 1.0);
      color *= vec4(diffuser2,diffuseg2,diffuseb2,1.0);
      //color += vec4(glowdiffuser2,glowdiffuseg2,glowdiffuseb2,glow2);
      color *= a2;
			if (color.a == 0.0)
				return vec4 (0.0, 0.0, 0.0, 0.0);
			return vec4 (color.rgb * color.a * openfl_Alphav, color.a * openfl_Alphav);
		}
		return color * openfl_Alphav;
	}

  void main() {
    vec4 color = /*flixel_texture2D(bitmap, openfl_TextureCoordv);*/ modchartTexture2D(bitmap, openfl_TextureCoordv);
    vec4 swagColor = vec4(rgb2hsv(vec3(color[0], color[1], color[2])), color[3]);
    swagColor.x *= _hue2;
    swagColor.y *= _sat2;
    swagColor.z *= _val2;
    swagColor.z *= (_hue2 * 0.5) + 0.5;
    color = vec4(hsv2rgb(vec3(swagColor[0], swagColor[1], swagColor[2])), swagColor[3]);
	  gl_FragColor = color;
  }
  ')
  public function new()
  {
    super();
  }
}
