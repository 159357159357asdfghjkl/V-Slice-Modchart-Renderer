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
  public var pos:Vector3D = new Vector3D();
  public var offsetX:Float = 0;
  public var offsetY:Float = 0;
  public var rotation:Vector3D = new Vector3D();
  public var SCALE:Vector3D = new Vector3D(1, 1);
  public var z:Float = 0;
  public var originVec:Vector3D;
  public var diffuse:Vector3D = new Vector3D(1, 1, 1, 1);
  public var glow:Vector3D = new Vector3D(1, 1, 1, 0);

  var vertices:Vector<Float> = new Vector<Float>();
  var indices:Vector<Int> = new Vector<Int>();
  var uvtData:Vector<Float> = new Vector<Float>();

  public function new(?x:Float, ?y:Float)
  {
    super(0, 0);
  }

  override public function destroy():Void
  {
    skew = FlxDestroyUtil.put(skew);
    rotation = null;
    SCALE = null;
    vertices = null;
    indices = null;
    uvtData = null;
    super.destroy();
  }

  function getPos(vec:Vector3D)
  {
    var m:Array<Array<Float>> = ModchartMath.translateMatrix(pos.x, pos.y, pos.z);
    var rotate:Array<Array<Float>> = ModchartMath.rotateMatrix(m, rotation.x, rotation.y, rotation.z);
    var scale:Array<Array<Float>> = ModchartMath.scaleMatrix(rotate, SCALE.x, SCALE.y, SCALE.z);
    var skew:Array<Array<Float>> = ModchartMath.skewMatrix(scale, skew.x, skew.y);
    var persp:Vector3D = ModchartMath.initPerspective(vec, skew, 45, FlxG.width, FlxG.height, ModchartMath.scale(0, 0.1, 1.0, originVec.x, FlxG.width / 2),
      originVec.y);
    if (persp == null) return null;
    return persp;
  }

  override public function draw():Void
  {
    if (alpha == 0 || graphic == null || !exists || !visible) return;

    for (camera in cameras)
    {
      if (camera.exists && camera != null)
      {
        if (!camera.visible || camera.alpha == 0) continue;
        if (originVec == null) originVec = new Vector3D(FlxG.width / 2, FlxG.height / 2);
        var w:Float = frame.frame.width;
        var h:Float = frame.frame.height;
        var topLeft:Vector3D = new Vector3D(-w / 2, -h / 2, 0, 1);
        var topRight:Vector3D = new Vector3D(w / 2, -h / 2, 0, 1);
        var bottomLeft:Vector3D = new Vector3D(-w / 2, h / 2, 0, 1);
        var bottomRight:Vector3D = new Vector3D(w / 2, h / 2, 0, 1);
        topLeft = getPos(topLeft);
        topRight = getPos(topRight);
        bottomLeft = getPos(bottomLeft);
        bottomRight = getPos(bottomRight);
        vertices = new Vector<Float>(8, false, [
          width / 2 + topLeft.x,
          height / 2 + topLeft.y,
          width / 2 + topRight.x,
          height / 2 + topRight.y,
          width / 2 + bottomLeft.x,
          height / 2 + bottomLeft.y,
          width / 2 + bottomRight.x,
          height / 2 + bottomRight.y
        ]);
        var idx:Int = 0;
        while (idx < vertices.length)
        {
          vertices[idx] += offsetX;
          vertices[idx + 1] += offsetY;
          idx += 2;
        }
        uvtData = new Vector<Float>(8, false, [
          frame.uv.x,
          frame.uv.y,
          frame.uv.width,
          frame.uv.y,
          frame.uv.x,
          frame.uv.height,
          frame.uv.width,
          frame.uv.height
        ]);
        indices = new Vector<Int>(6, true, [0, 1, 2, 1, 2, 3]);
        getScreenPosition(_point, camera);
        colorTransform.redMultiplier = diffuse.x;
        colorTransform.greenMultiplier = diffuse.y;
        colorTransform.blueMultiplier = diffuse.z;
        colorTransform.alphaMultiplier = diffuse.w;
        colorTransform.redOffset = glow.x * 255 * glow.w;
        colorTransform.greenOffset = glow.y * 255 * glow.w;
        colorTransform.blueOffset = glow.z * 255 * glow.w;
        camera.drawTriangles(graphic, vertices, indices, uvtData, null, _point, blend, true, antialiasing, colorTransform, shader);
      }
    }

    #if FLX_DEBUG
    if (FlxG.debugger.drawDebug) drawDebug();
    #end
  }
}
