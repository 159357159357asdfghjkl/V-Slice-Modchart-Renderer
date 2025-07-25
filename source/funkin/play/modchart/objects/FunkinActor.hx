package funkin.play.modchart.objects;

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
import funkin.play.modchart.util.ModchartMath;

class FunkinActor extends FunkinSprite
{
  public var skew(default, null):FlxPoint = FlxPoint.get();
  public var offsetX:Float = 0;
  public var offsetY:Float = 0;
  public var rotation:Vector3D = new Vector3D();
  public var SCALE:Vector3D = new Vector3D(1, 1);
  public var z:Float = 0;
  public var originVec:Vector3D;
  public var alphaValue:Float = 0;
  public var glow:Float = 0;

  public function new(?x:Float, ?y:Float)
  {
    super(0, 0);
  }

  override public function destroy():Void
  {
    skew = FlxDestroyUtil.put(skew);
    rotation = null;
    SCALE = null;
    super.destroy();
  }

  override function draw():Void
  {
    if (alpha == 0 || graphic == null || !exists || !visible) return;

    for (camera in cameras)
    {
      if (camera.exists && camera != null)
      {
        if (!camera.visible || camera.alpha == 0) continue;
        if (originVec == null) originVec = new Vector3D(FlxG.width / 2, FlxG.height / 2);
        var wid:Float = frame.frame.width;
        var h:Float = frame.frame.height;
        var topLeft:Vector3D = new Vector3D(-wid / 2, -h / 2);
        var topRight:Vector3D = new Vector3D(wid / 2, -h / 2);
        var bottomLeft:Vector3D = new Vector3D(-wid / 2, h / 2);
        var bottomRight:Vector3D = new Vector3D(wid / 2, h / 2);
        var scaledLT:Vector3D = ModchartMath.scaleVector3(topLeft, SCALE.x, SCALE.y, SCALE.z);
        var scaledRT:Vector3D = ModchartMath.scaleVector3(topRight, SCALE.x, SCALE.y, SCALE.z);
        var scaledLB:Vector3D = ModchartMath.scaleVector3(bottomLeft, SCALE.x, SCALE.y, SCALE.z);
        var scaledRB:Vector3D = ModchartMath.scaleVector3(bottomRight, SCALE.x, SCALE.y, SCALE.z);
        var skewedLT:Vector3D = ModchartMath.skewVector2(scaledLT, skew.x, skew.y);
        var skewedRT:Vector3D = ModchartMath.skewVector2(scaledRT, skew.x, skew.y);
        var skewedLB:Vector3D = ModchartMath.skewVector2(scaledLB, skew.x, skew.y);
        var skewedRB:Vector3D = ModchartMath.skewVector2(scaledRB, skew.x, skew.y);
        var rotatedLT:Vector3D = ModchartMath.rotateVector3(skewedLT, rotation.x, rotation.y, rotation.z);
        var rotatedRT:Vector3D = ModchartMath.rotateVector3(skewedRT, rotation.x, rotation.y, rotation.z);
        var rotatedLB:Vector3D = ModchartMath.rotateVector3(skewedLB, rotation.x, rotation.y, rotation.z);
        var rotatedRB:Vector3D = ModchartMath.rotateVector3(skewedRB, rotation.x, rotation.y, rotation.z);
        rotatedLT = ModchartMath.PerspectiveProjection(rotatedLT.add(new Vector3D(x, y, z - 1000)), originVec).subtract(new Vector3D(x, y, z));
        rotatedRT = ModchartMath.PerspectiveProjection(rotatedRT.add(new Vector3D(x, y, z - 1000)), originVec).subtract(new Vector3D(x, y, z));
        rotatedLB = ModchartMath.PerspectiveProjection(rotatedLB.add(new Vector3D(x, y, z - 1000)), originVec).subtract(new Vector3D(x, y, z));
        rotatedRB = ModchartMath.PerspectiveProjection(rotatedRB.add(new Vector3D(x, y, z - 1000)), originVec).subtract(new Vector3D(x, y, z));
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
        var colors:Array<Int> = [];
        for (i in 0...Std.int(vertices.length / 2) + 1)
          colors.push(flixel.util.FlxColor.fromRGBFloat(glow * 255 * (1 - glow), glow * 255 * (1 - glow), glow * 255 * (1 - glow), alphaValue));
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
}
