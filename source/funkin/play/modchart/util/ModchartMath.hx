package funkin.play.modchart.util;

import openfl.geom.Vector3D;
import funkin.play.notes.Strumline;

/**
 * These math functions is useful for modifiers.
 * You can also use it at other place
**/
class ModchartMath
{
  public static var ARROW_SIZE:Float = Strumline.NOTE_SPACING;
  public static var SCREEN_HEIGHT:Float = FlxG.height;

  public static final rad:Float = Math.PI / 180.0; // degree to radian
  public static final deg:Float = 180.0 / Math.PI; // radian to degree
  public static final ROWS_PER_BEAT:Int = 48;
  public static final BEATS_PER_MEASURE:Int = 4;

  public static final ROWS_PER_MEASURE:Int = ROWS_PER_BEAT * BEATS_PER_MEASURE;

  public static final MAX_NOTE_ROW:Int = 1 << 30;

  inline public static function scale(x:Float, l1:Float, h1:Float, l2:Float, h2:Float):Float
    return ((x - l1) * (h2 - l2) / (h1 - l1) + l2);

  inline public static function clamp(val:Float, low:Float, high:Float):Float
  {
    return Math.max((low), Math.min((val), (high)));
  }

  inline public static function iClamp(n:Int, l:Int, h:Int):Int
  {
    if (n > h) n = h;
    if (n < l) n = l;
    return n;
  }

  inline public static function lerp(x:Float, l:Float, h:Float):Float
    return x * (h - l) + l;

  inline public static function mod(x:Float, y:Float):Float
    return x - Math.floor(x / y) * y;

  inline public static function BeatToNoteRow(beat:Float):Int
    return Math.round(beat * ROWS_PER_BEAT);

  inline public static function RowToNoteBeat(row:Int):Float
    return row / ROWS_PER_BEAT;

  inline public static function square(angle:Float)
  {
    var fAngle:Float = mod(angle, Math.PI * 2);
    // Hack: This ensures the hold notes don't flicker right before they're hit.
    if (fAngle < 0.01)
    {
      fAngle += Math.PI * 2;
    }
    return fAngle >= Math.PI ? -1.0 : 1.0;
  }

  public static function triangle(angle:Float)
  {
    var fAngle:Float = mod(angle, Math.PI * 2.0);
    if (fAngle < 0.0)
    {
      fAngle += Math.PI * 2.0;
    }
    var result = fAngle * (1 / Math.PI);
    if (result < .5)
    {
      return result * 2.0;
    }
    else if (result < 1.5)
    {
      return 1.0 - ((result - .5) * 2.0);
    }
    else
    {
      return -4.0 + (result * 2.0);
    }
  }

  public static function PerspectiveProjection(vec3:Vector3D):Vector3D
  {
    var origin:Vector3D = new Vector3D(FlxG.width / 2, FlxG.height / 2);
    var zNear:Float = 0;
    var zFar:Float = 100;
    var zRange:Float = zNear - zFar;
    var FOV:Float = 90.0;
    var tanHalfFOV:Float = Math.tan(rad * (FOV / 2));
    var ar:Float = 1;
    var pos:Vector3D = new Vector3D(vec3.x, vec3.y, vec3.z / 1000).subtract(origin);
    if (pos.z > 0) pos.z = 0;
    var a:Float = (-zNear - zFar) / zRange;
    var b:Float = 2.0 * zFar * zNear / zRange;
    var newZPos:Float = a * -pos.z + b;
    var newXPos:Float = pos.x / (1 / tanHalfFOV * ar) / newZPos;
    var newYPos:Float = pos.y / (1 / tanHalfFOV) / newZPos;
    var vector:Vector3D = new Vector3D(newXPos, newYPos, newZPos).add(origin);
    return vector;
  }

  inline public static function Quantize(f:Float, fRoundInterval:Float):Float
  {
    return Std.int((f + fRoundInterval / 2) / fRoundInterval) * fRoundInterval;
  }

  // we only use these functions, others temporarily don't use
  inline public static function fastSin(x:Float):Float
    return FastTrigonometric.fastSin(x);

  inline public static function fastCos(x:Float):Float
    return FastTrigonometric.fastCos(x);

  inline public static function fastCsc(x:Float):Float
    return FastTrigonometric.fastCsc(x);

  inline public static function fastTan(x:Float):Float
    return FastTrigonometric.fastTan(x);

  public static function rotateVector3(out:Vector3D, rX:Float, rY:Float, rZ:Float):Vector3D
  {
    rX *= Math.PI / 180;
    rY *= Math.PI / 180;
    rZ *= Math.PI / 180;

    var cX:Float = fastCos(rX);
    var sX:Float = fastSin(rX);
    var cY:Float = fastCos(rY);
    var sY:Float = fastSin(rY);
    var cZ:Float = fastCos(rZ);
    var sZ:Float = fastSin(rZ);

    var mat:Array<Float> = [
      cZ * cY,
      cZ * sY * sX + sZ * cX,
      cZ * sY * cX + sZ * (-sX),
      0,
      (-sZ) * cY,
      (-sZ) * sY * sX + cZ * cX,
      (-sZ) * sY * cX + cZ * (-sX),
      0,
      -sY,
      cY * sX,
      cY * cX,
      0,
      0,
      0,
      0,
      1,
    ];
    var matToVec:Vector3D = new Vector3D(mat[0 * 4 + 0] * out.x + mat[1 * 4 + 0] * out.y + mat[2 * 4 + 0] * out.z,
      mat[0 * 4 + 1] * out.x + mat[1 * 4 + 1] * out.y + mat[2 * 4 + 1] * out.z, mat[0 * 4 + 2] * out.x + mat[1 * 4 + 2] * out.y + mat[2 * 4 + 2] * out.z);
    return matToVec;
  }
}
