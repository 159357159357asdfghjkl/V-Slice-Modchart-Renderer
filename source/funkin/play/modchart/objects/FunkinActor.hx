package funkin.play.modchart.objects;

import flixel.math.FlxPoint;
import openfl.geom.Matrix3D;
import flixel.FlxG;
import flixel.util.FlxDestroyUtil;
import openfl.Vector;
import openfl.geom.Vector3D;
import funkin.graphics.FunkinSprite;
import funkin.play.modchart.util.ModchartMath;
import openfl.geom.ColorTransform;

class FunkinActor extends FunkinSprite
{
  public var SKEW(default, null):FlxPoint = FlxPoint.get();
  public var pos:Vector3D = new Vector3D();
  public var rotation:Vector3D = new Vector3D();
  public var SCALE:Vector3D = new Vector3D(1, 1);
  public var originVec:Vector3D;
  public var diffuse:Vector3D = new Vector3D(1, 1, 1, 1);
  public var glow:Vector3D = new Vector3D(1, 1, 1, 0);
  public var _skew:Float = 0;
  public var rotationOrder:String = 'zyx';
  public var basePos:Vector3D = new Vector3D(); // for scripting
  public var baseRotation:Vector3D = new Vector3D(); // for scripting
  public var baseSkew:Vector3D = new Vector3D(); // for scripting
  public var baseScale:Vector3D = new Vector3D(1, 1, 1); // for scripting
  public var baseZoom:Vector3D = new Vector3D(1, 1, 1); // for scripting
  public var baseDiffuse:Vector3D = new Vector3D(1, 1, 1, 1); // for scripting
  public var pos2:FlxPoint = FlxPoint.get(); // for strum fade in / out, don't change
  public var fov:Float = 45;
  public var offsetX:Float = 0;
  public var offsetY:Float = 0;

  var vertices:Vector<Float> = new Vector<Float>();
  var indices:Vector<Int> = new Vector<Int>();
  var uvtData:Vector<Float> = new Vector<Float>();

  public function new(?x:Float, ?y:Float)
  {
    super(0, 0);
  }

  override public function destroy():Void
  {
    SKEW = FlxDestroyUtil.put(SKEW);
    pos2 = FlxDestroyUtil.put(pos2);
    rotation = null;
    SCALE = null;
    vertices = null;
    indices = null;
    uvtData = null;
    super.destroy();
  }

  function getPos(vec:Vector3D):Vector3D
  {
    var fullPos:Vector3D = pos.add(basePos);
    fullPos.x += pos2.x - origin.x;
    fullPos.y += pos2.y - origin.y;
    fullPos.x *= baseZoom.x;
    fullPos.y *= baseZoom.y;
    fullPos.z *= baseZoom.z;
    var rotation:Vector3D = this.rotation.add(baseRotation);
    var scalePos:Vector3D = SCALE.clone();
    scalePos.x *= baseScale.x * baseZoom.x;
    scalePos.y *= baseScale.y * baseZoom.y;
    scalePos.z *= baseScale.z * baseZoom.z;
    var skewPos:Vector3D = new Vector3D(baseSkew.x + SKEW.x, baseSkew.y + SKEW.y);
    var zPos:Vector3D = ModchartMath.processActor(fullPos, vec, rotation, scalePos, skewPos, originVec, fov, rotationOrder, origin.x * 2
      - offset.x
      + offsetX,
      origin.y * 2
      - offset.y
      + offsetY);
    return zPos;
  }

  @:noCompletion var _blank:Vector<Int> = new Vector<Int>(4, true, [0, 0, 0, 0]);

  @:access(flixel.FlxSprite)
  override public function draw():Void
  {
    if (alpha == 0 || graphic == null || !exists || !visible) return;
    var lowQuality:Bool = Preferences.framerate < 60;
    if (originVec == null) originVec = new Vector3D(FlxG.width / 2, FlxG.height / 2);
    var w:Float = _frame.frame.width;
    var h:Float = _frame.frame.height;
    var topLeft:Vector3D = new Vector3D(-w / 2, -h / 2, 0, 1);
    var topRight:Vector3D = new Vector3D(w / 2, -h / 2, 0, 1);
    var bottomLeft:Vector3D = new Vector3D(-w / 2, h / 2, 0, 1);
    var bottomRight:Vector3D = new Vector3D(w / 2, h / 2, 0, 1);
    topLeft = getPos(topLeft);
    topRight = getPos(topRight);
    bottomLeft = getPos(bottomLeft);
    bottomRight = getPos(bottomRight);
    vertices = new Vector<Float>(8, false, [topLeft.x, topLeft.y, topRight.x, topRight.y, bottomLeft.x, bottomLeft.y, bottomRight.x, bottomRight.y]);
    uvtData = new Vector<Float>(8, false,
      [frame.uv.left, frame.uv.top, frame.uv.right, frame.uv.top, frame.uv.left, frame.uv.bottom, frame.uv.right, frame.uv.bottom]);
    indices = new Vector<Int>(6, true, [0, 1, 2, 1, 2, 3]);

    for (camera in cameras)
    {
      if (camera.exists && camera != null)
      {
        if (!camera.visible || camera.alpha == 0) continue;
        getScreenPosition(_point, camera);
        var colorTransform = new ColorTransform();
        colorTransform.redMultiplier = diffuse.x * baseDiffuse.x * this.colorTransform.redMultiplier;
        colorTransform.greenMultiplier = diffuse.y * baseDiffuse.y * this.colorTransform.greenMultiplier;
        colorTransform.blueMultiplier = diffuse.z * baseDiffuse.z * this.colorTransform.blueMultiplier;
        colorTransform.alphaMultiplier = diffuse.w * baseDiffuse.w * this.alpha * camera.alpha * this.colorTransform.alphaMultiplier + glow.w;
        colorTransform.redOffset = glow.x * 255 * glow.w + this.colorTransform.redOffset;
        colorTransform.greenOffset = glow.y * 255 * glow.w + this.colorTransform.greenOffset;
        colorTransform.blueOffset = glow.z * 255 * glow.w + this.colorTransform.blueOffset;
        camera.drawTriangles(graphic, vertices, indices, uvtData, _blank, _point, blend, true, antialiasing, colorTransform,
          shader); // fucking color array has no use
      }
    }

    #if FLX_DEBUG
    if (FlxG.debugger.drawDebug) drawDebug();
    #end
  }
}
