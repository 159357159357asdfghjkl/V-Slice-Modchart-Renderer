package funkin.play.modchart.events;

typedef Ease = Float->Float;

class ModEases
{
  public static inline function instant(t:Float):Float
    return 1;

  public static inline function linear(t:Float):Float
    return t;

  public static inline function inQuad(t:Float):Float
    return t * t;

  public static inline function outQuad(t:Float):Float
    return -t * (t - 2);

  public static inline function inOutQuad(t:Float):Float
  {
    t = t * 2;

    if (t < 1) return 0.5 * t * t;
    else
      return 1 - 0.5 * (2 - t) * (2 - t);
  }

  public static inline function inCubic(t:Float):Float
    return t * t * t;

  public static inline function outCubic(t:Float):Float
    return 1 - (1 - t) * (1 - t) * (1 - t);

  public static inline function inOutCubic(t:Float):Float
  {
    t = t * 2;

    if (t < 1) return 0.5 * t * t * t;
    else
      return 1 - 0.5 * (2 - t) * (2 - t) * (2 - t);
  }

  public static inline function inQuart(t:Float):Float
    return t * t * t * t;

  public static inline function outQuart(t:Float):Float
    return 1 - (1 - t) * (1 - t) * (1 - t) * (1 - t);

  public static inline function inOutQuart(t:Float):Float
  {
    t = t * 2;

    if (t < 1) return 0.5 * t * t * t * t;
    else
      return 1 - 0.5 * (2 - t) * (2 - t) * (2 - t) * (2 - t);
  }

  public static inline function inQuint(t:Float):Float
    return t * t * t * t * t;

  public static inline function outQuint(t:Float):Float
    return 1 - (1 - t) * (1 - t) * (1 - t) * (1 - t) * (1 - t);

  public static inline function inOutQuint(t:Float):Float
  {
    t = t * 2;

    if (t < 1) return 0.5 * t * t * t * t * t;
    else
      return 1 - 0.5 * (2 - t) * (2 - t) * (2 - t) * (2 - t) * (2 - t);
  }

  public static inline function inExpo(t:Float):Float
    return Math.pow(1000, t - 1) - 0.001;

  public static inline function outExpo(t:Float):Float
    return 1.001 - Math.pow(1000, -t);

  public static inline function inOutExpo(t:Float):Float
  {
    t = t * 2;

    if (t < 1) return 0.5 * Math.pow(1000, t - 1) - 0.0005;
    else
      return 1.0005 - 0.5 * Math.pow(1000, 1 - t);
  }

  public static inline function inCirc(t:Float):Float
    return 1 - Math.sqrt(1 - t * t);

  public static inline function outCirc(t:Float):Float
    return Math.sqrt(-t * t + 2 * t);

  public static inline function inOutCirc(t:Float):Float
  {
    t = t * 2;

    if (t < 1) return 0.5 - 0.5 * Math.sqrt(1 - t * t);
    else
    {
      t = t - 2;
      return 0.5 + 0.5 * Math.sqrt(1 - t * t);
    }
  }

  public static inline function outBounce(t:Float):Float
  {
    if (t < 1 / 2.75)
    {
      return 7.5625 * t * t;
    }
    else if (t < 2 / 2.75)
    {
      t = t - 1.5 / 2.75;
      return 7.5625 * t * t + 0.75;
    }
    else if (t < 2.5 / 2.75)
    {
      t = t - 2.25 / 2.75;
      return 7.5625 * t * t + 0.9375;
    }
    else
    {
      t = t - 2.625 / 2.75;
      return 7.5625 * t * t + 0.984375;
    }
  }

  public static inline function inBounce(t:Float):Float
    return 1 - outBounce(1 - t);

  public static inline function inOutBounce(t:Float):Float
  {
    if (t < 0.5) return inBounce(t * 2) * 0.5;
    else
      return outBounce(t * 2 - 1) * 0.5 + 0.5;
  }

  public static inline function inSine(x:Float):Float
    return 1 - Math.cos(x * (Math.PI * 0.5));

  public static inline function outSine(x:Float):Float
    return Math.sin(x * (Math.PI * 0.5));

  public static inline function inOutSine(x:Float):Float
    return 0.5 - 0.5 * Math.cos(x * Math.PI);

  public static inline function outElastic(t:Float):Float
  {
    var a:Float = 1;
    var p:Float = 0.3;
    return a * Math.pow(2, -10 * t) * Math.sin((t - p / (2 * Math.PI) * Math.asin(1 / a)) * 2 * Math.PI / p) + 1;
  }

  public static inline function inElastic(t:Float):Float
    return 1 - outElastic(1 - t);

  public static inline function inOutElastic(t:Float):Float
    return t < 0.5 ? 0.5 * inElastic(t * 2) : 0.5 + 0.5 * outElastic(t * 2 - 1);

  public static inline function inBack(t:Float):Float
    return t * t * (1.70158 * t + t - 1.70158);

  public static inline function outBack(t:Float):Float
  {
    t = t - 1;
    return t * t * ((1.70158 + 1) * t + 1.70158) + 1;
  }

  public static inline function inOutBack(t:Float):Float
    return t < 0.5 ? 0.5 * inBack(t * 2) : 0.5 + 0.5 * outBack(t * 2 - 1);

  public static inline function bounce(t:Float):Float
    return 4 * t * (1 - t);

  public static inline function tri(t:Float):Float
    return 1 - Math.abs(2 * t - 1);

  public static inline function bell(t:Float):Float
    return inOutQuint(tri(t));

  public static inline function pop(t:Float):Float
    return 3.5 * (1 - t) * (1 - t) * Math.sqrt(t);

  public static inline function tap(t:Float):Float
    return 3.5 * t * t * Math.sqrt(1 - t);

  public static inline function pulse(t:Float):Float
    return t < .5 ? tap(t * 2) : -pop(t * 2 - 1);

  public static inline function spike(t:Float):Float
    return Math.exp(-10 * Math.abs(2 * t - 1));

  public static inline function inverse(t:Float):Float
    return t * t * (1 - t) * (1 - t) / (0.5 - t);

  public static inline function popElasticInternal(t:Float):Float
  {
    var damp:Float = 1.4;
    var count:Int = 6;
    return (Math.pow(1000, -(Math.pow(t, damp))) - 0.001) * Math.sin(count * Math.PI * t);
  }

  public static inline function tapElasticInternal(t:Float):Float
  {
    var damp:Float = 1.4;
    var count:Int = 6;
    return (Math.pow(1000, -(Math.pow((1 - t), damp))) - 0.001) * Math.sin(count * Math.PI * (1 - t));
  }

  public static inline function pulseElasticInternal(t:Float):Float
  {
    if (t < .5) return tapElasticInternal(t * 2);
    else
      return -popElasticInternal(t * 2 - 1);
  }

  public static inline function inSmoothStep(t:Float):Float
    return 2 * inOutSmoothStep(t / 2);

  public static inline function outSmoothStep(t:Float):Float
    return 2 * inOutSmoothStep(t / 2 + 0.5) - 1;

  public static inline function inOutSmoothStep(t:Float):Float
    return t * t * (t * -2 + 3);

  public static inline function inSmootherStep(t:Float):Float
    return 2 * inOutSmootherStep(t / 2);

  public static inline function outSmootherStep(t:Float):Float
    return 2 * inOutSmootherStep(t / 2 + 0.5) - 1;

  public static inline function inOutSmootherStep(t:Float):Float
    return t * t * t * (t * (t * 6 - 15) + 10);
}
