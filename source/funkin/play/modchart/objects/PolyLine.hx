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
import openfl.geom.ColorTransform;
import funkin.play.notes.Strumline;
import funkin.play.modchart.Modchart;
import funkin.play.modchart.util.ModchartMath.RotateIndex;

/**
  a class to simulate notitg's arrowpath
  better than lineStyle
**/
class PolyLine extends FunkinSprite
{
  public var vertices:Vector<Float> = new Vector<Float>();
  public var uvtData:Vector<Float> = new Vector<Float>();
  public var indices:Vector<Int> = new Vector<Int>();
  public var column:Int = 0;

  // constants
  var mods:Modchart;
  var xoffArray:Array<Float>;
  var pn:Int;
  var parentStrumline:Strumline;

  public function new(?x:Float, ?y:Float, ?parent:Strumline)
  {
    super(0, 0);
    this.parentStrumline = parent;
    this.mods = parentStrumline?.mods ?? null;
    this.xoffArray = parentStrumline?.xoffArray ?? [];
    this.pn = parentStrumline?.modNumber ?? -1;
    this.makeGraphic(1, 1, 0xFFFFFFFF);
    this.antialiasing = true;
  }

  override public function destroy():Void
  {
    vertices = null;
    uvtData = null;
    indices = null;
    rotCache = skewCache = scaleCache = null;
    spPos = null;
    left = right = null;
    globalOffset = null;
    super.destroy();
  }

  public function setIndices(indices:Array<Int>):Void
  {
    if (this.indices.length == indices.length)
    {
      for (i in 0...indices.length)
      {
        this.indices[i] = indices[i];
      }
    }
    else
    {
      this.indices = new Vector<Int>(indices.length, false, indices);
    }
  }

  public function setVertices(vertices:Array<Float>):Void
  {
    if (this.vertices.length == vertices.length)
    {
      for (i in 0...vertices.length)
      {
        this.vertices[i] = vertices[i];
      }
    }
    else
    {
      this.vertices = new Vector<Float>(vertices.length, false, vertices);
    }
  }

  public function setUVTData(uvtData:Array<Float>):Void
  {
    if (this.uvtData.length == uvtData.length)
    {
      for (i in 0...uvtData.length)
      {
        this.uvtData[i] = uvtData[i];
      }
    }
    else
    {
      this.uvtData = new Vector<Float>(uvtData.length, false, uvtData);
    }
  }

  public var rotationOrder:RotateIndex = ZYX;

  var rotCache:Vector3D = new Vector3D();
  var scaleCache:Vector3D = new Vector3D(1, 1, 1);
  var skewCache:Vector3D = new Vector3D();
  var spPos:Vector3D = new Vector3D();
  var left:Vector3D = new Vector3D(1, 0, 0, 1);
  var right:Vector3D = new Vector3D(1, 0, 0, 1);
  var globalOffset:Vector3D = new Vector3D(Strumline.NOTE_SPACING / 2 - 1, Strumline.NOTE_SPACING * 0.75 - 1);

  function getPos(width:Float, time:Float):Array<Vector3D>
  {
    var conductorInUse:Conductor = parentStrumline.conductorInUse;
    time += conductorInUse.getTimeWithDelta();
    var ofs:Float = (mods.getValue('centeredpath') + mods.getValue('centeredpath$column')) * Strumline.NOTE_SPACING;
    var yOffset:Float = mods.GetYOffset(conductorInUse, time, parentStrumline.scrollSpeed, column, conductorInUse.getTimeWithDelta()) + ofs;
    var difference:Vector3D = parentStrumline.getDifference();
    var pos:Vector3D = new Vector3D(mods.GetXPos(column, yOffset, pn, xoffArray, false),
      mods.GetYPos(column, yOffset, xoffArray, parentStrumline.isDownscroll), mods.GetZPos(column, yOffset, xoffArray));
    var originVec:Vector3D = new Vector3D(difference.x, FlxG.height / 2);
    mods.modifyPos(pos, scaleCache, rotCache, skewCache, xoffArray, column);
    mods.modifyPosByValue(pos, scaleCache, rotCache, skewCache, column, new Vector3D(0, 0, 0), new Vector3D(0, 0, 0), new Vector3D(1, 1, 1));
    parentStrumline.getSplineAxisPos('pos', column, yOffset, 0, spPos);
    pos.incrementBy(spPos);
    pos.incrementBy(difference);
    left.x = -width / 2;
    right.x = -left.x;
    var zPos:Array<Vector3D> = ModchartMath.processActor(pos, [left, right], new Vector3D(0, 0, 0), new Vector3D(1, 1, 1), new Vector3D(0, 0, skewCache.z),
      originVec, parentStrumline.fov, rotationOrder);
    skewCache.z = 0;
    for (i in 0...2)
      zPos[i].incrementBy(globalOffset);
    return zPos;
  }

  var lastSubdivision:Int = -2000;
  var subdivisionChanged:Bool = false;

  function updateClipping():Void
  {
    if (parentStrumline == null) return;
    var alpha:Float = mods.getValue('arrowpath${column}') + mods.getValue('arrowpath');
    alpha = ModchartMath.clamp(alpha, 0, 1) * this.alpha * parentStrumline.alpha;
    this.colorTransform.alphaMultiplier = alpha;
    if (alpha <= 0) return;
    var grain:Float = mods.getValue('arrowpathgranulate');
    if (grain == 0) grain = 4;
    var scrollSpeed:Float = parentStrumline.scrollSpeed * Constants.PIXELS_PER_MS;
    if (scrollSpeed < 0.01) scrollSpeed = 0.01;
    var roughness:Float = mods.baseHoldSize * (1 / scrollSpeed);
    var backLength:Float = parentStrumline.pathSizeBack / scrollSpeed;
    backLength *= (1 + mods.getValue('arrowpathdrawsizeback'));
    var frontLength:Float = parentStrumline.pathSizeFront / scrollSpeed;
    frontLength *= (1 + mods.getValue('arrowpathdrawsize'));
    var subdivisions:Int = Math.round((backLength + frontLength) / (roughness * grain));
    if (grain < 0) subdivisions = Math.round((backLength + frontLength) / (1 / (roughness * Math.abs(grain))));
    if (subdivisions != lastSubdivision) subdivisionChanged = true;
    lastSubdivision = subdivisions;
    var size:Float = 1 + mods.getValue('arrowpathsize') + mods.getValue('arrowpathsize$column');
    var verticesArray:Array<Float> = [];
    var uvtDataArray:Array<Float> = [];
    var indicesArray:Array<Int> = [];
    for (a in 0...subdivisions + 1)
    {
      var i:Int = a * 2;
      var time:Float = (backLength + frontLength) / subdivisions * a - backLength;
      var pos:Array<Vector3D> = getPos(size, time);
      verticesArray[i * 2] = pos[0].x;
      verticesArray[i * 2 + 1] = pos[0].y;
      verticesArray[(i + 1) * 2] = pos[1].x;
      verticesArray[(i + 1) * 2 + 1] = pos[1].y;
      if (subdivisionChanged)
      {
        uvtDataArray[i * 2] = 0;
        uvtDataArray[i * 2 + 1] = 1;
        uvtDataArray[(i + 1) * 2] = 1;
        uvtDataArray[(i + 1) * 2 + 1] = 0;
        if (a == subdivisions) break;
        indicesArray[a * 6 + 0] = i + 1;
        indicesArray[a * 6 + 1] = i + 2;
        indicesArray[a * 6 + 2] = i + 0;
        indicesArray[a * 6 + 3] = i + 1;
        indicesArray[a * 6 + 4] = i + 3;
        indicesArray[a * 6 + 5] = i + 2;
      }
    }
    setVertices(verticesArray);
    if (subdivisionChanged)
    {
      setUVTData(uvtDataArray);
      setIndices(indicesArray);
    }
    subdivisionChanged = false;
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);
    x = y = 0;
    updateClipping();
  }

  override public function draw():Void
  {
    if (alpha == 0 || graphic == null || !visible || vertices == null || parentStrumline == null || !alive) return;

    for (camera in cameras)
    {
      if (camera.exists && camera != null)
      {
        if (!camera.visible || camera.alpha == 0) continue;

        getScreenPosition(_point, camera).subtract(offset);
        #if !flash
        camera.drawTriangles(graphic, vertices, indices, uvtData, null, _point, blend, false, antialiasing, colorTransform, shader);
        #else
        camera.drawTriangles(graphic, vertices, indices, uvtData, null, _point, blend, false, antialiasing);
        #end
      }
    }

    #if FLX_DEBUG
    if (FlxG.debugger.drawDebug) drawDebug();
    #end
  }
}
