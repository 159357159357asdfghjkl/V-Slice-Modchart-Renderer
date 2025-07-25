package funkin.play.modchart.util;

class Trigonometric
{
  static final PI:Float = 3.141592653589793;
  static var sine_table_size:Int = 1024;
  static var sine_index_mod:Int = sine_table_size * 2;
  static var sine_table_index_mult:Float = sine_index_mod / (PI * 2);
  static var sine_table:Array<Float> = [];
  static var table_is_inited:Bool = false;

  inline public static function fastSin(x:Float):Float
  {
    if (table_is_inited == false)
    {
      for (i in 0...sine_table_size)
      {
        var angle:Float = i * PI / sine_table_size;
        sine_table[i] = Math.sin(angle);
      }
      table_is_inited = true;
    }
    if (x == 0) return 0;
    var index:Float = x * sine_table_index_mult;
    while (index < 0)
      index += sine_index_mod;
    var first_index:Int = Std.int(index);
    var second_index:Int = (first_index + 1) % sine_index_mod;
    var remainder:Float = index - first_index;
    first_index %= sine_index_mod;
    var first:Float = 0.0;
    var second:Float = 0.0;
    if (first_index >= sine_table_size) first = -sine_table[first_index - sine_table_size];
    else
      first = sine_table[first_index];
    if (second_index >= sine_table_size) second = -sine_table[second_index - sine_table_size];
    else
      second = sine_table[second_index];
    var result:Float = remainder * (second - first) + first;
    return result;
  }

  inline public static function fastCos(x:Float):Float
    return fastSin(x + 0.5 * PI);

  inline public static function fastTan(x:Float):Float
    return fastSin(x) / fastCos(x);

  inline public static function fastCot(x:Float):Float
    return fastCos(x) / fastSin(x);

  inline public static function fastSec(x:Float):Float
    return 1 / fastCos(x);

  inline public static function fastCsc(x:Float):Float
    return 1 / fastSin(x);

  inline public static function sin(x:Float):Float
    return Math.sin(x);

  inline public static function cos(x:Float):Float
    return Math.cos(x);

  inline public static function tan(x:Float):Float
    return Math.tan(x);

  inline public static function cot(x:Float):Float
    return Math.cos(x) / Math.sin(x);

  inline public static function sec(x:Float):Float
    return 1 / Math.cos(x);

  inline public static function csc(x:Float):Float
    return 1 / Math.sin(x);

  inline public static function sinh(x:Float):Float
    return (Math.exp(x) - Math.exp(-x)) / 2;

  inline public static function cosh(x:Float):Float
    return (Math.exp(x) + Math.exp(-x)) / 2;

  inline public static function tanh(x:Float):Float
    return sinh(x) / cosh(x);

  inline public static function coth(x:Float):Float
    return cosh(x) / sinh(x);

  inline public static function sech(x:Float):Float
    return 1 / cosh(x);

  inline public static function csch(x:Float):Float
    return 1 / sinh(x);

  inline public static function asin(x:Float):Float
    return Math.asin(x);

  inline public static function acos(x:Float):Float
    return Math.acos(x);

  inline public static function atan(x:Float):Float
    return Math.atan(x);

  inline public static function acot(x:Float):Float
    return Math.atan(1 / x);

  inline public static function asec(x:Float):Float
    return Math.acos(1 / x);

  inline public static function acsc(x:Float):Float
    return Math.asin(1 / x);
}
