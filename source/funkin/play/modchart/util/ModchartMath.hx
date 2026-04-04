package funkin.play.modchart.util;

import openfl.geom.Vector3D;
import openfl.geom.Matrix3D;
import openfl.Vector;
import funkin.play.notes.Strumline;
import openfl.Lib;
import flixel.math.FlxMath;

/**
 * most of these funcs were from stepmania
**/
class ModchartMath
{
  public static var ARROW_SIZE:Float = Strumline.NOTE_SPACING;
  public static var SCREEN_HEIGHT:Float = FlxG.height;

  public static final rad:Float = Math.PI / 180.0;
  public static final deg:Float = 180.0 / Math.PI;

  public static final ROWS_PER_BEAT:Int = 48;
  public static final BEATS_PER_MEASURE:Int = 4;

  public static final ROWS_PER_MEASURE:Int = ROWS_PER_BEAT * BEATS_PER_MEASURE;

  public static final MAX_NOTE_ROW:Int = 1 << 30;

  private static var next:Int = 159357;
  public static inline var randMax:Int = 32767;

  public static inline function srand(seed:Int):Void next = seed & 0xFFFFFFFF;

  public static inline function rand():Int
  {
    next = (next * 1103515245 + 12345) & 0xFFFFFFFF;
    return (next >> 16) & randMax;
  }

  inline public static function scale(x:Float, l1:Float, h1:Float, l2:Float, h2:Float):Float return ((x - l1) * (h2 - l2) / (h1 - l1) + l2);

  inline public static function clamp(n:Float, l:Float, h:Float):Float
  {
    if (n > h) n = h;
    if (n < l) n = l;
    return n;
  }

  inline public static function iClamp(n:Int, l:Int, h:Int):Int
  {
    if (n > h) n = h;
    if (n < l) n = l;
    return n;
  }

  inline public static function trunc(x:Float):Float
  {
    if (x >= 0) return Math.floor(x);
    else
      return Math.ceil(x);
  }

  inline public static function lerp(x:Float, l:Float, h:Float):Float return x * (h - l) + l;

  inline public static function mod(x:Float, y:Float):Float return x - Math.floor(x / y) * y;

  inline public static function BeatToNoteRow(beat:Float):Int return Math.round(beat * ROWS_PER_BEAT);

  inline public static function RowToNoteBeat(row:Int):Float return row / ROWS_PER_BEAT;

  inline public static function square(angle:Float)
  {
    var fAngle:Float = mod(angle, Math.PI * 2);
    if (fAngle < 0.01)
    {
      fAngle += Math.PI * 2;
    }
    return fAngle >= Math.PI ? -1.0 : 1.0;
  }

  public static inline function triangle(angle:Float)
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

  public static inline function getDirectionsBetweenTwoVectors(pos:Vector3D, pos2:Vector3D):Vector3D
  {
    var diff:Vector3D = pos2.subtract(pos);
    var angX:Float = Math.atan2(diff.y, diff.z);
    var angY:Float = Math.atan2(diff.z, diff.x);
    var angZ:Float = Math.atan2(diff.y, diff.x);
    return new Vector3D(angX, angY, angZ);
  }

  public static function processActor(fullPos:Vector3D, realPos:Vector3D, rotation:Vector3D, scalePos:Vector3D, skewPos:Vector3D, originVec:Vector3D,
      fov:Float, rotationOrder:String = 'zyx', offx:Float = 0, offy:Float = 0):Vector3D
  {
    var m:Matrix3D = translateMatrix(fullPos.x, fullPos.y, fullPos.z);
    rotateMatrix(m, rotation.x, rotation.y, rotation.z, rotationOrder);
    scaleMatrix(m, scalePos.x, scalePos.y, scalePos.z);
    skewMatrix(m, skewPos.x, skewPos.y);
    m.appendTranslation(offx, offy, 0);
    var pos:Vector3D = initPerspective(realPos, m, fov, FlxG.width, FlxG.height, ModchartMath.scale(skewPos.z, 0.1, 1.0, originVec.x, FlxG.width / 2),
      originVec.y);
    return pos;
  }

  public static function initPerspective(vec:Vector3D, m:Matrix3D, fovDegrees:Float, fWidth:Float, fHeight:Float, fVanishPointX:Float, fVanishPointY:Float)
  {
    var matrix:Array<Matrix3D> = __loadPerspective(fovDegrees, fWidth, fHeight, fVanishPointX, fVanishPointY);
    var proj:Matrix3D = matrix[0];
    m.append(matrix[1]); // modelView
    var p1:Vector3D = new Vector3D();
    m.transformVectorToOutput(vec, p1);
    var p2:Vector3D = new Vector3D();
    proj.transformVectorToOutput(p1, p2);
    p2.project();
    var b:Vector3D = new Vector3D((p2.x + 1) / 2 * fWidth, (p2.y + 1) / 2 * fHeight);
    return b;
  }

  inline public static function Quantize(f:Float, fRoundInterval:Float):Float
  {
    return Std.int((f + fRoundInterval / 2) / fRoundInterval) * fRoundInterval;
  }

  inline public static function fastSin(x:Float, clipValue:Float = 1):Float
  {
    if (clipValue < 0) return FlxMath.fastSin(x);
    if (clipValue > 1) return -clipValue;
    return clamp(FlxMath.fastSin(x), -(1 - clipValue), 1 - clipValue);
  }

  inline public static function fastCos(x:Float, clipValue:Float = 1):Float
  {
    if (clipValue < 0) return FlxMath.fastCos(x);
    if (clipValue > 1) return -clipValue;
    return clamp(FlxMath.fastCos(x), -(1 - clipValue), 1 - clipValue);
  }

  inline public static function fastCsc(x:Float, clipValue:Float = 1):Float
  {
    if (clipValue <= 0) return __fastCscNoClip(x);
    if (clipValue >= 1) return 0;
    return clamp(__fastCscNoClip(x), -(1 - clipValue) * 10, (1 - clipValue) * 10);
  }

  inline public static function fastTan(x:Float, clipValue:Float = 1):Float
  {
    if (clipValue <= 0) return __fastTanNoClip(x);
    if (clipValue >= 1) return 0;
    return clamp(__fastTanNoClip(x), -(1 - clipValue) * 10, (1 - clipValue) * 10);
  }

  public static function rotateMatrix(a:Matrix3D, rX:Float, rY:Float, rZ:Float, order:String = 'zyx'):Void
  {
    rX *= Math.PI / 180;
    rY *= Math.PI / 180;
    rZ *= Math.PI / 180;

    var cX:Float = FlxMath.fastCos(rX);
    var sX:Float = FlxMath.fastSin(rX);
    var cY:Float = FlxMath.fastCos(rY);
    var sY:Float = FlxMath.fastSin(rY);
    var cZ:Float = FlxMath.fastCos(rZ);
    var sZ:Float = FlxMath.fastSin(rZ);

    var mat:Matrix3D = new Matrix3D(new Vector<Float>( switch (order)
    {
      case 'zyx': [cZ * cY, cZ * sY * sX + sZ * cX, cZ * sY * cX + sZ * -sX, 0,
          -sZ * cY,
          -sZ * sY * sX
          + cZ * cX,
          -sZ * sY * cX
          + cZ * -sX, 0,
          -sY, cY * sX, cY * cX, 0, 0, 0, 0, 1];
      case 'xyz': [cZ * cY, -cZ * sY * cX + sZ * sX, cZ * sY * sX + sZ * cX, 0, sZ * cY, -sZ * sY * cX - cZ * sX, sZ * sY * sX
          - cZ * cX, 0, -sY, cY * cX, cY * sX, 0, 0, 0, 0, 1];
      case 'zxy': [cY * cZ + sY * sX * sZ, -cY * sZ + sY * sX * cZ, sY * cX, 0, cX * sZ, cX * cZ, -sX, 0, -sY * cZ + cY * sX * sZ, sY * sZ
          + cY * sX * cZ, cY * cX, 0, 0, 0, 0, 1];
      case 'xzy': [cY * cZ, -sZ, cY * sZ * cX + sY * sX, 0, cY * sZ, cZ, cY * sZ * sX - sY * cX, 0, -sY * cZ, 0, -sY * sZ * cX + cY * cX, 0, 0, 0, 0, 1];
      case 'yxz': [cZ * cY - sZ * sX * sY, -cZ * sY - sZ * sX * cY, -sZ * cX, 0, sZ * cY + cZ * sX * sY, -sZ * sY
          + cZ * sX * cY, cZ * cX, 0, cX * sY, cX * cY, -sX, 0, 0, 0, 0, 1];
      case 'yzx': [cZ * cY - sZ * sX * sY, -cZ * sY - sZ * sX * cY, -sZ * cX, 0, sZ * cY + cZ * sX * sY, -sZ * sY
          + cZ * sX * cY, cZ * cX, 0, cX * sY, cX * cY, -sX, 0, 0, 0, 0, 1];
      default:
        [cZ * cY, cZ * sY * sX + sZ * cX, cZ * sY * cX + sZ * -sX, 0,
          -sZ * cY,
          -sZ * sY * sX
          + cZ * cX,
          -sZ * sY * cX
          + cZ * -sX, 0,
          -sY, cY * sX, cY * cX, 0, 0, 0, 0, 1];
    }));
    a.prepend(mat);
  }

  public static function rotateVec3(v:Vector3D, rX:Float, rY:Float, rZ:Float):Vector3D
  {
    rX *= Math.PI / 180;
    rY *= Math.PI / 180;
    rZ *= Math.PI / 180;

    var cX:Float = FlxMath.fastCos(rX);
    var sX:Float = FlxMath.fastSin(rX);
    var cY:Float = FlxMath.fastCos(rY);
    var sY:Float = FlxMath.fastSin(rY);
    var cZ:Float = FlxMath.fastCos(rZ);
    var sZ:Float = FlxMath.fastSin(rZ);

    return new Vector3D(cZ * cY * v.x
      + -sZ * cY * v.y + -sY * v.z, (cZ * sY * sX + sZ * cX) * v.x
      + (-sZ * sY * sX + cZ * cX) * v.y
      + cY * sX * v.z,
      (cZ * sY * cX + sZ * -sX) * v.x
      + (-sZ * sY * cX + cZ * -sX) * v.y
      + cY * cX * v.z, v.w);
  }

  public static function translateMatrix(x:Float, y:Float, z:Float):Matrix3D
  {
    var mat:Matrix3D = new Matrix3D();
    mat.appendTranslation(x, y, z);
    return mat;
  }

  public static function skewMatrix(a:Matrix3D, sx:Float, sy:Float):Void
  {
    var mat:Matrix3D = new Matrix3D();
    mat.rawData[4] = sx;
    mat.rawData[1] = sy;
    a.prepend(mat);
  }

  public static function skewVec3(v:Vector3D, sx:Float, sy:Float):Vector3D
  {
    return new Vector3D(v.x + v.y * sx, v.y + v.x * sy, v.z, v.w);
  }

  public static function scaleMatrix(a:Matrix3D, sx:Float, sy:Float, sz:Float):Void
  {
    a.prependScale(sx, sy, sz);
  }

  public static function scaleVec3(v:Vector3D, sx:Float, sy:Float, sz:Float):Vector3D
  {
    return new Vector3D(sx * v.x, sy * v.y, sz * v.z, v.w);
  }

  inline public static function weierstrassSin(x:Float):Float
  {
    return FlxMath.fastSin(Math.PI * x) + 0.5 * FlxMath.fastSin(Math.PI * 7 * x) + 0.25 * FlxMath.fastSin(Math.PI * 49 * x)
      + 0.125 * FlxMath.fastSin(Math.PI * 343 * x);
  }

  inline public static function weierstrassCos(x:Float):Float
  {
    return FlxMath.fastCos(Math.PI * x) + 0.5 * FlxMath.fastCos(Math.PI * 7 * x) + 0.25 * FlxMath.fastCos(Math.PI * 49 * x)
      + 0.125 * FlxMath.fastCos(Math.PI * 343 * x);
  }

  inline public static function weierstrassTan(x:Float):Float
  {
    return __fastTanNoClip(Math.PI * x) + 0.5 * __fastTanNoClip(Math.PI * 7 * x) + 0.25 * __fastTanNoClip(Math.PI * 49 * x)
      + 0.125 * __fastTanNoClip(Math.PI * 343 * x);
  }

  inline public static function weierstrassCsc(x:Float):Float
  {
    return __fastCscNoClip(Math.PI * x) + 0.5 * __fastCscNoClip(Math.PI * 7 * x) + 0.25 * __fastCscNoClip(Math.PI * 49 * x)
      + 0.125 * __fastCscNoClip(Math.PI * 343 * x);
  }

  public static function getCurrentAccuracy(sicks:Null<Int>, goods:Null<Int>, bads:Null<Int>, shits:Null<Int>, misses:Null<Int>):Float
  {
    if (sicks == null && goods == null && bads == null && shits == null && misses == null || sicks == 0 && goods == 0 && bads == 0 && shits == 0 && misses == 0)
      return 0;
    return FlxMath.roundDecimal((sicks * 100 + goods * 65) / (sicks + goods + bads + shits + misses), 2);
  }

  public static inline function sigmoid(x:Float):Float return 1.0 / (1.0 + Math.exp(-x));

  @:noCompletion private static function __loadPerspective(fovDegrees:Float, fWidth:Float, fHeight:Float, fVanishPointX:Float,
      fVanishPointY:Float):Array<Matrix3D>
  {
    if (fovDegrees == 0)
    {
      var l:Float = 0;
      var r:Float = fWidth;
      var b:Float = fHeight;
      var t:Float = 0;
      var zn:Float = -1000;
      var zf:Float = 1000;
      return [new Matrix3D(new Vector<Float>([2 / (r - l), 0, 0, 0, 0, -2 / (t - b), 0, 0, 0, 0, -2 / (zf - zn), 0,
        -(r + l) / (r - l),
        -(t + b) / (t - b),
        -(zf + zn) / (zf - zn), 1])), new Matrix3D()];
    }
    else
    {
      clamp(fovDegrees, 0.1, 179.9);
      var fovRadians:Float = fovDegrees / 180 * Math.PI;
      var theta:Float = fovRadians / 2;
      var fDistCameraFromImage:Float = fWidth / 2 / Math.tan(theta);
      fVanishPointX = scale(fVanishPointX, 0, fWidth, fWidth, 0);
      fVanishPointY = scale(fVanishPointY, 0, fHeight, fHeight, 0);
      fVanishPointX -= fWidth / 2;
      fVanishPointY -= fHeight / 2;
      var l:Float = (fVanishPointX - fWidth / 2) / fDistCameraFromImage;
      var r:Float = (fVanishPointX + fWidth / 2) / fDistCameraFromImage;
      var b:Float = (fVanishPointY + fHeight / 2) / fDistCameraFromImage;
      var t:Float = (fVanishPointY - fHeight / 2) / fDistCameraFromImage;
      var zn:Float = 1;
      var zf:Float = fDistCameraFromImage + 1000;
      var A:Float = (r + l) / (r - l);
      var B:Float = (t + b) / (t - b);
      var C:Float = -1 * (zf + zn) / (zf - zn);
      var D:Float = -1 * (2 * zf * zn) / (zf - zn);
      var persp:Array<Matrix3D> = [new Matrix3D(new Vector<Float>([2 * zn / (r - l), 0, 0, 0, 0, -2 * zn / (t - b), 0, 0, A, B, C, -1, 0, 0, D, 0])), __lookAt(-fVanishPointX +
        fWidth / 2, -fVanishPointY + fHeight / 2, fDistCameraFromImage, -fVanishPointX + fWidth / 2, -fVanishPointY + fHeight / 2, 0, 0.0,
        1.0, 0.0)];
      return persp;
    }
  }

  @:noCompletion private static function __lookAt(eyex:Float, eyey:Float, eyez:Float, centerx:Float, centery:Float, centerz:Float, upx:Float, upy:Float,
      upz:Float):Matrix3D
  {
    var Z:Vector3D = new Vector3D(eyex - centerx, eyey - centery, eyez - centerz);
    Z.normalize();
    var Y:Vector3D = new Vector3D(upx, upy, upz);
    var X:Vector3D = new Vector3D(Y.y * Z.z - Y.z * Z.y, -Y.x * Z.z + Y.z * Z.x, Y.x * Z.y - Y.y * Z.x);
    Y = new Vector3D(Z.y * X.z - Z.z * X.y, -Z.x * X.z + Z.z * X.x, Z.x * X.y - Z.y * X.x);
    X.normalize();
    Y.normalize();
    var mat:Matrix3D = new Matrix3D(new Vector<Float>([X.x, Y.x, Z.x, 0, X.y, Y.y, Z.y, 0, X.z, Y.z, Z.z, 0, 0, 0, 0, 1]));
    var mat2:Matrix3D = translateMatrix(-eyex, -eyey, -eyez);
    mat2.append(mat);
    return mat2;
  }

  @:noCompletion inline private static function __fastTanNoClip(a:Float) return FlxMath.fastSin(a) / FlxMath.fastCos(a);

  @:noCompletion inline private static function __fastCscNoClip(a:Float) return 1 / FlxMath.fastSin(a);
}
