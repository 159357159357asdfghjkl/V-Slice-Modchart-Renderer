package funkin.play.modchart.util;

import openfl.geom.Vector3D;
import funkin.play.notes.Strumline;
import openfl.Lib;

/**
 * most of these funcs were from stepmania
**/
class ModchartMath
{
  public static var ARROW_SIZE:Float = Strumline.NOTE_SPACING;
  public static var SCREEN_HEIGHT:Float = FlxG.height;

  public static final rad:Float = Math.PI / 180.0; // degree to radian
  public static final deg:Float = 180.0 / Math.PI; // radian to degree

  public static final FLT_MAX_x32:Float = 3.4028234663852886e+38;
  public static final FLT_MIN_x32:Float = 1.1754943508222875e-38;

  public static final ROWS_PER_BEAT:Int = 48;
  public static final BEATS_PER_MEASURE:Int = 4;

  public static final ROWS_PER_MEASURE:Int = ROWS_PER_BEAT * BEATS_PER_MEASURE;

  public static final MAX_NOTE_ROW:Int = 1 << 30;

  inline public static function scale(x:Float, l1:Float, h1:Float, l2:Float, h2:Float):Float // same as FlxMath.remapToRange
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

  inline public static function trunc(x:Float):Float
  {
    if (x >= 0) return Math.floor(x);
    else
      return Math.ceil(x);
  }

  inline public static function lerp(x:Float, l:Float, h:Float):Float // FlxMath.lerp but x is the first argument
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

  public static function PerspectiveProjection(vec3:Vector3D, ?origin:Vector3D):Vector3D
  {
    if (origin == null) origin = new Vector3D(FlxG.width / 2, FlxG.height / 2);
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
    var newXPos:Float = pos.x * (1 / tanHalfFOV * ar) / newZPos;
    var newYPos:Float = pos.y * (1 / tanHalfFOV) / newZPos;
    var vector:Vector3D = new Vector3D(newXPos, newYPos, newZPos).add(origin);
    return vector;
  }

  public static function initPerspective(vec:Vector3D, m:Array<Array<Float>>, fovDegrees:Float, fWidth:Float, fHeight:Float, fVanishPointX:Float,
      fVanishPointY:Float)
  {
    var matrix:Array<Array<Array<Float>>> = __loadPerspective(fovDegrees, fWidth, fHeight, fVanishPointX, fVanishPointY);
    var projection:Array<Array<Float>> = matrix[0];
    var modelView:Array<Array<Float>> = multiply(matrix[1], m);
    var a:Vector3D = transform(transform(vec, modelView), projection);
    if (a.w != 0.0)
    {
      a.x /= a.w;
      a.y /= a.w;
      a.z /= a.w;
      var b:Vector3D = new Vector3D((a.x + 1) / 2 * fWidth, (a.y + 1) / 2 * fHeight);
      return b;
    }
    return null;
  }

  inline public static function Quantize(f:Float, fRoundInterval:Float):Float
  {
    return Std.int((f + fRoundInterval / 2) / fRoundInterval) * fRoundInterval;
  }

  // we only use these functions, others temporarily don't use
  // add clip thing
  inline public static function fastSin(x:Float, clipValue:Float = 1):Float
  {
    if (clipValue <= 0) return Trigonometric.fastSin(x);
    if (clipValue >= 1) return -clipValue;
    return clamp(Trigonometric.fastSin(x), -(1 - clipValue), 1 - clipValue);
  }

  inline public static function fastCos(x:Float, clipValue:Float = 1):Float
  {
    if (clipValue <= 0) return Trigonometric.fastCos(x);
    if (clipValue >= 1) return -clipValue;
    return clamp(Trigonometric.fastCos(x), -(1 - clipValue), 1 - clipValue);
  }

  inline public static function fastCsc(x:Float, clipValue:Float = 1):Float
  {
    if (clipValue <= 0) return Trigonometric.fastCsc(x);
    if (clipValue >= 1) return 0;
    return clamp(Trigonometric.fastCsc(x), -(1 - clipValue) * 10, (1 - clipValue) * 10);
  }

  inline public static function fastTan(x:Float, clipValue:Float = 1):Float
  {
    if (clipValue <= 0) return Trigonometric.fastTan(x);
    if (clipValue >= 1) return 0;
    return clamp(Trigonometric.fastTan(x), -(1 - clipValue) * 10, (1 - clipValue) * 10);
  }

  inline public static function transform(v:Vector3D, a:Array<Array<Float>>):Vector3D
  {
    return new Vector3D(a[0][0] * v.x + a[1][0] * v.y + a[2][0] * v.z + a[3][0] * v.w, a[0][1] * v.x + a[1][1] * v.y + a[2][1] * v.z + a[3][1] * v.w,
      a[0][2] * v.x + a[1][2] * v.y + a[2][2] * v.z + a[3][2] * v.w, a[0][3] * v.x + a[1][3] * v.y + a[2][3] * v.z + a[3][3] * v.w);
  }

  inline public static function multiply(a:Array<Array<Float>>, b:Array<Array<Float>>):Array<Array<Float>>
  {
    return [
      [
        b[0][0] * a[0][0] + b[0][1] * a[1][0] + b[0][2] * a[2][0] + b[0][3] * a[3][0],
        b[0][0] * a[0][1] + b[0][1] * a[1][1] + b[0][2] * a[2][1] + b[0][3] * a[3][1],
        b[0][0] * a[0][2] + b[0][1] * a[1][2] + b[0][2] * a[2][2] + b[0][3] * a[3][2],
        b[0][0] * a[0][3] + b[0][1] * a[1][3] + b[0][2] * a[2][3] + b[0][3] * a[3][3]
      ],
      [
        b[1][0] * a[0][0] + b[1][1] * a[1][0] + b[1][2] * a[2][0] + b[1][3] * a[3][0],
        b[1][0] * a[0][1] + b[1][1] * a[1][1] + b[1][2] * a[2][1] + b[1][3] * a[3][1],
        b[1][0] * a[0][2] + b[1][1] * a[1][2] + b[1][2] * a[2][2] + b[1][3] * a[3][2],
        b[1][0] * a[0][3] + b[1][1] * a[1][3] + b[1][2] * a[2][3] + b[1][3] * a[3][3]
      ],
      [
        b[2][0] * a[0][0] + b[2][1] * a[1][0] + b[2][2] * a[2][0] + b[2][3] * a[3][0],
        b[2][0] * a[0][1] + b[2][1] * a[1][1] + b[2][2] * a[2][1] + b[2][3] * a[3][1],
        b[2][0] * a[0][2] + b[2][1] * a[1][2] + b[2][2] * a[2][2] + b[2][3] * a[3][2],
        b[2][0] * a[0][3] + b[2][1] * a[1][3] + b[2][2] * a[2][3] + b[2][3] * a[3][3]
      ],
      [
        b[3][0] * a[0][0] + b[3][1] * a[1][0] + b[3][2] * a[2][0] + b[3][3] * a[3][0],
        b[3][0] * a[0][1] + b[3][1] * a[1][1] + b[3][2] * a[2][1] + b[3][3] * a[3][1],
        b[3][0] * a[0][2] + b[3][1] * a[1][2] + b[3][2] * a[2][2] + b[3][3] * a[3][2],
        b[3][0] * a[0][3] + b[3][1] * a[1][3] + b[3][2] * a[2][3] + b[3][3] * a[3][3]
      ]
    ];
  }

  public static function rotateMatrix(a:Array<Array<Float>>, rX:Float, rY:Float, rZ:Float):Array<Array<Float>>
  {
    rX *= Math.PI / 180;
    rY *= Math.PI / 180;
    rZ *= Math.PI / 180;

    var cX:Float = Trigonometric.fastCos(rX);
    var sX:Float = Trigonometric.fastSin(rX);
    var cY:Float = Trigonometric.fastCos(rY);
    var sY:Float = Trigonometric.fastSin(rY);
    var cZ:Float = Trigonometric.fastCos(rZ);
    var sZ:Float = Trigonometric.fastSin(rZ);

    var mat:Array<Array<Float>> = [
      [cZ * cY, cZ * sY * sX + sZ * cX, cZ * sY * cX + sZ * (-sX), 0],
      [(-sZ) * cY, (-sZ) * sY * sX + cZ * cX, (-sZ) * sY * cX + cZ * (-sX), 0],
      [-sY, cY * sX, cY * cX, 0],
      [0, 0, 0, 1],
    ];
    var m:Array<Array<Float>> = multiply(a, mat);
    return m;
  }

  public static function rotateVec3(a:Vector3D, rX:Float, rY:Float, rZ:Float):Vector3D
  {
    rX *= Math.PI / 180;
    rY *= Math.PI / 180;
    rZ *= Math.PI / 180;

    var cX:Float = Trigonometric.fastCos(rX);
    var sX:Float = Trigonometric.fastSin(rX);
    var cY:Float = Trigonometric.fastCos(rY);
    var sY:Float = Trigonometric.fastSin(rY);
    var cZ:Float = Trigonometric.fastCos(rZ);
    var sZ:Float = Trigonometric.fastSin(rZ);

    var mat:Array<Array<Float>> = [
      [cZ * cY, cZ * sY * sX + sZ * cX, cZ * sY * cX + sZ * (-sX), 0],
      [(-sZ) * cY, (-sZ) * sY * sX + cZ * cX, (-sZ) * sY * cX + cZ * (-sX), 0],
      [-sY, cY * sX, cY * cX, 0],
      [0, 0, 0, 1],
    ];
    var m:Vector3D = transform(a, mat);
    return m;
  }

  public static function translateMatrix(x:Float, y:Float, z:Float):Array<Array<Float>>
  {
    return [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [x, y, z, 1]];
  }

  public static function skewMatrix(a:Array<Array<Float>>, sx:Float, sy:Float):Array<Array<Float>>
  {
    var mat:Array<Array<Float>> = [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]];
    mat[1][0] = sx;
    mat[0][1] = sy;
    var m:Array<Array<Float>> = multiply(a, mat);
    return m;
  }

  public static function scaleMatrix(a:Array<Array<Float>>, sx:Float, sy:Float, sz:Float):Array<Array<Float>>
  {
    var mat:Array<Array<Float>> = [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]];
    mat[0][0] = sx;
    mat[1][1] = sy;
    mat[2][2] = sz;
    var m:Array<Array<Float>> = multiply(a, mat);
    return m;
  }

  // funny stuff
  public static function getCurrentAccuracy(sicks:Null<Int>, goods:Null<Int>, bads:Null<Int>, shits:Null<Int>, misses:Null<Int>):Float
  {
    if (sicks == null && goods == null && bads == null && shits == null && misses == null || sicks == 0 && goods == 0 && bads == 0 && shits == 0 && misses == 0)
      return 0;
    var tempMult:Float = 1.0;
    for (_ in 0...2)
      tempMult *= 10.0;
    return Math.ffloor((sicks * 100 + goods * 65) / (sicks + goods + bads + shits + misses) * tempMult) / tempMult;
  }

  private static function __loadPerspective(fovDegrees:Float, fWidth:Float, fHeight:Float, fVanishPointX:Float, fVanishPointY:Float):Array<Array<Array<Float>>>
  {
    if (fovDegrees == 0)
    {
      var l:Float = 0;
      var r:Float = fWidth;
      var b:Float = fHeight;
      var t:Float = 0;
      var zn:Float = -1000;
      var zf:Float = 1000;
      return [
        [
          [2 / (r - l), 0, 0, 0],
          [0, -2 / (t - b), 0, 0],
          [0, 0, -2 / (zf - zn), 0],
          [-(r + l) / (r - l), -(t + b) / (t - b), -(zf + zn) / (zf - zn), 1]
        ]
      ];
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
      var persp:Array<Array<Array<Float>>> = [
        [
          [2 * zn / (r - l), 0, 0, 0],
          [0, -2 * zn / (t - b), 0, 0],
          [A, B, C, -1],
          [0, 0, D, 0]
        ],
        __lookAt(-fVanishPointX
          + fWidth / 2,
          -fVanishPointY
          + fHeight / 2, fDistCameraFromImage,
          -fVanishPointX
          + fWidth / 2,
          -fVanishPointY
          + fHeight / 2,
          0, 0.0, 1.0, 0.0)
      ];
      return persp;
    }
  }

  private static function __lookAt(eyex:Float, eyey:Float, eyez:Float, centerx:Float, centery:Float, centerz:Float, upx:Float, upy:Float,
      upz:Float):Array<Array<Float>>
  {
    var Z:Vector3D = new Vector3D(eyex - centerx, eyey - centery, eyez - centerz);
    Z.normalize();
    var Y:Vector3D = new Vector3D(upx, upy, upz);
    var X:Vector3D = new Vector3D(Y.y * Z.z - Y.z * Z.y, -Y.x * Z.z + Y.z * Z.x, Y.x * Z.y - Y.y * Z.x);
    Y = new Vector3D(Z.y * X.z - Z.z * X.y, -Z.x * X.z + Z.z * X.x, Z.x * X.y - Z.y * X.x);
    X.normalize();
    Y.normalize();
    var mat:Array<Array<Float>> = [[X.x, Y.x, Z.x, 0], [X.y, Y.y, Z.y, 0], [X.z, Y.z, Z.z, 0], [0, 0, 0, 1]];
    var mat2:Array<Array<Float>> = [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [-eyex, -eyey, -eyez, 1]];
    var ret:Array<Array<Float>> = multiply(mat, mat2);
    return ret;
  }
}
