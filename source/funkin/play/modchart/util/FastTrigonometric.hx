package funkin.play.modchart.util;

/**
 * FastTrigonometric is a class that has many trigonometric functions
 * It uses look-up table method to make the calculation fast but less accurate
 * This class contains some functions that haxe/std/Math don't have
 * Besides fast trigonometric functions, there are also have default trigonometric functions
 * You can freely use it
 */
class FastTrigonometric
{
  static final PI:Float = 3.141592653589793;
  static var sine_table_size:Int = 1024;
  static var sine_index_mod:Int = sine_table_size * 2;
  static var sine_table_index_mult:Float = sine_index_mod / (PI * 2);
  static var sine_table:Array<Float> = [];
  static var table_is_inited:Bool = false;

  /**
   * Sine function but faster
   * @param x angle
   * @return Float
   */
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

  /**
   * Cosine function but faster
   * @param x  angle
   * @return Float
   */
  inline public static function fastCos(x:Float):Float
    return fastSin(x + 0.5 * PI);

  /**
   * Tangent function but faster
   * @param x angle
   * @return Float
   */
  inline public static function fastTan(x:Float):Float
    return fastSin(x) / fastCos(x);

  /**
   * Cotangent function but faster
   * @param x angle
   * @return Float
   */
  inline public static function fastCot(x:Float):Float
    return fastCos(x) / fastSin(x);

  /**
   * Secant function but faster
   * @param x angle
   * @return Float
   */
  inline public static function fastSec(x:Float):Float
    return 1 / fastCos(x);

  /**
   * Cosecant function but faster
   * @param x angle
   * @return Float
   */
  inline public static function fastCsc(x:Float):Float
    return 1 / fastSin(x);

  // DEFAULT FUNCTIONS

  /**
   * Default sine function, the same as `Math.sin`
   * @param x angle
   * @return Float
   */
  inline public static function sin(x:Float):Float
    return Math.sin(x);

  /**
   * Default cosine function, the same as `Math.cos`
   * @param x angle
   * @return Float
   */
  inline public static function cos(x:Float):Float
    return Math.cos(x);

  /**
   * Default tangent function, the same as `Math.tan`
   * @param x angle
   * @return Float
   */
  inline public static function tan(x:Float):Float
    return Math.tan(x);

  /**
   * Default cotangent function, more accurate than `fastCot` but less speed
   * @param x angle
   * @return Float
   */
  inline public static function cot(x:Float):Float
    return Math.cos(x) / Math.sin(x);

  /**
   * Default secant function, more accurate than `fastSec` but less speed
   * @param x angle
   * @return Float
   */
  inline public static function sec(x:Float):Float
    return 1 / Math.cos(x);

  /**
   * Default cosecant function, more accurate than `fastCsc` but less speed
   * @param x angle
   * @return Float
   */
  inline public static function csc(x:Float):Float
    return 1 / Math.sin(x);
}
