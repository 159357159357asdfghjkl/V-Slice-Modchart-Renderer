package funkin.play.modchart.util;

import flixel.math.FlxPoint;
import openfl.geom.Matrix;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.math.FlxAngle;
import flixel.util.FlxDestroyUtil;
import openfl.Vector;
import openfl.geom.Vector3D;
import funkin.graphics.FunkinSprite;

/**
 * for note and receptor
 */
class FunkinActor extends FunkinSprite
{
  // flixel.addons.effects.FlxSkewedSprite
  public var skew(default, null):FlxPoint = FlxPoint.get();

  var _skewMatrix:Matrix = new Matrix();

  public var transformMatrix(default, null):Matrix = new Matrix();
  public var matrixExposed:Bool = false;
  public var offsetX:Float = 0;
  public var offsetY:Float = 0;
  public var rotation:Vector3D = new Vector3D();
  public var z:Float = 0;

  public function new(?x:Float, ?y:Float)
  {
    super(0, 0);
  }

  override public function destroy():Void
  {
    skew = FlxDestroyUtil.put(skew);
    _skewMatrix = null;
    transformMatrix = null;
    rotation = null;
    super.destroy();
  }

  override function drawComplex(camera:FlxCamera):Void
  {
    _frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
    _matrix.translate(-origin.x, -origin.y);
    _matrix.scale(scale.x, scale.y);

    if (matrixExposed)
    {
      _matrix.concat(transformMatrix);
    }
    else
    {
      if (bakedRotationAngle <= 0)
      {
        updateTrig();

        if (angle != 0) _matrix.rotateWithTrig(_cosAngle, _sinAngle);
      }

      updateSkewMatrix();
      _matrix.concat(_skewMatrix);
    }

    getScreenPosition(_point, camera).subtractPoint(offset);
    _point.addPoint(origin);
    if (isPixelPerfectRender(camera)) _point.floor();

    _matrix.translate(_point.x, _point.y);
    camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing, shader);
  }

  function updateSkewMatrix():Void
  {
    _skewMatrix.identity();

    if (skew.x != 0 || skew.y != 0)
    {
      _skewMatrix.b = Math.tan(skew.y * FlxAngle.TO_RAD);
      _skewMatrix.c = Math.tan(skew.x * FlxAngle.TO_RAD);
    }
  }

  override function draw():Void
  {
    // from troll engine but much worse
    if (alpha == 0 || graphic == null || !exists || !visible) return;
    for (camera in cameras)
    {
      if (camera.exists && camera != null)
      {
        if (!camera.visible || camera.alpha == 0) continue;
        var wid:Float = frame.frame.width * scale.x;
        var h:Float = frame.frame.height * scale.y;
        var topLeft:Vector3D = new Vector3D(-wid / 2, -h / 2);
        var topRight:Vector3D = new Vector3D(wid / 2, -h / 2);
        var bottomLeft:Vector3D = new Vector3D(-wid / 2, h / 2);
        var bottomRight:Vector3D = new Vector3D(wid / 2, h / 2);

        var rotatedLT:Vector3D = ModchartMath.rotateVector3(topLeft, rotation.x, rotation.y, rotation.z);
        var rotatedRT:Vector3D = ModchartMath.rotateVector3(topRight, rotation.x, rotation.y, rotation.z);
        var rotatedLB:Vector3D = ModchartMath.rotateVector3(bottomLeft, rotation.x, rotation.y, rotation.z);
        var rotatedRB:Vector3D = ModchartMath.rotateVector3(bottomRight, rotation.x, rotation.y, rotation.z);
        rotatedLT = ModchartMath.PerspectiveProjection(rotatedLT.add(new Vector3D(x, y, z - 1000))).subtract(new Vector3D(x, y, rotation.w));
        rotatedRT = ModchartMath.PerspectiveProjection(rotatedRT.add(new Vector3D(x, y, z - 1000))).subtract(new Vector3D(x, y, rotation.w));
        rotatedLB = ModchartMath.PerspectiveProjection(rotatedLB.add(new Vector3D(x, y, z - 1000))).subtract(new Vector3D(x, y, rotation.w));
        rotatedRB = ModchartMath.PerspectiveProjection(rotatedRB.add(new Vector3D(x, y, z - 1000))).subtract(new Vector3D(x, y, rotation.w));
        var vertices:Vector<Float> = new Vector<Float>(8, false, [
          width / 2 + rotatedLT.x,
          height / 2 + rotatedLT.y,
          width / 2 + rotatedRT.x,
          height / 2 + rotatedRT.y,
          width / 2 + rotatedLB.x,
          height / 2 + rotatedLB.y,
          width / 2 + rotatedRB.x,
          height / 2 + rotatedRB.y
        ]);
        var idx:Int = 0;
        while (idx < vertices.length)
        {
          vertices[idx] += offsetX;
          vertices[idx + 1] += offsetY;
          idx += 2;
        }
        var uvtData:Vector<Float> = new Vector<Float>(8, false, [
          frame.uv.x,
          frame.uv.y,
          frame.uv.width,
          frame.uv.y,
          frame.uv.x,
          frame.uv.height,
          frame.uv.width,
          frame.uv.height
        ]);
        var indices:Vector<Int> = new Vector<Int>(6, true, [0, 1, 2, 1, 2, 3]);
        getScreenPosition(_point, camera);
        camera.drawTriangles(graphic, vertices, indices, uvtData, null, _point, blend, true, antialiasing, colorTransform, shader);
      }
    }
    #if FLX_DEBUG
    if (FlxG.debugger.drawDebug) drawDebug();
    #end
  }

  override public function isSimpleRender(?camera:FlxCamera):Bool
  {
    if (FlxG.renderBlit)
    {
      return super.isSimpleRender(camera) && (skew.x == 0) && (skew.y == 0) && !matrixExposed;
    }
    else
    {
      return false;
    }
  }
}
