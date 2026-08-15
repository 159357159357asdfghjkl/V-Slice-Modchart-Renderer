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
    clearout();
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

  public var rotationOrder:String = 'zyx';

  var spPos:Vector3D = new Vector3D();
  var spZoom:Vector3D = new Vector3D();
  var spSkew:Vector3D = new Vector3D();
  var left:Vector3D = new Vector3D(1, 0, 0, 1);
  var right:Vector3D = new Vector3D(1, 0, 0, 1);
  var globalOffset:Vector3D = new Vector3D(Strumline.NOTE_SPACING / 2 - 1, Strumline.NOTE_SPACING * 0.75 - 1);

  function clearout():Void
  {
    spZoom = spSkew = spPos = left = right = globalOffset = null;
  }

  function getPos(width:Float, time:Float):Array<Vector3D>
  {
    var conductorInUse:Conductor = parentStrumline.conductorInUse;
    time += conductorInUse.getTimeWithDelta();
    var speed:Float = parentStrumline.scrollSpeed;
    var isDownscroll:Bool = parentStrumline.isDownscroll;
    var ofs:Float = (mods.getValue('centeredpath') + mods.getValue('centeredpath$column')) * Strumline.NOTE_SPACING;
    var yOffset:Float = mods.GetYOffset(conductorInUse, time, speed, column, conductorInUse.getTimeWithDelta()) + ofs;
    var difference:Vector3D = parentStrumline.getDifference();
    var pos:Vector3D = new Vector3D(mods.GetXPos(column, yOffset, pn, xoffArray, false), mods.GetYPos(column, yOffset, pn, xoffArray, isDownscroll),
      mods.GetZPos(column, yOffset, pn, xoffArray));
    var originVec:Vector3D = new Vector3D(difference.x, FlxG.height / 2);
    var strumPos:Vector3D = new Vector3D(mods.GetXPos(column, ofs, pn, xoffArray, false), mods.GetYPos(column, ofs, pn, xoffArray, isDownscroll),
      mods.GetZPos(column, ofs, pn, xoffArray));
    var effect:Float = 1 - (mods.getValue('straightholds'));
    var noteYOffset:Float = mods.GetYOffset(conductorInUse, conductorInUse.getTimeWithDelta(), speed, column, conductorInUse.getTimeWithDelta()) + ofs;
    var notePos:Vector3D = new Vector3D(mods.GetXPos(column, noteYOffset, pn, xoffArray, true),
      mods.GetYPos(column, noteYOffset, pn, xoffArray, isDownscroll), mods.GetZPos(column, noteYOffset, pn, xoffArray));
    var timeDiff:Float = mods.baseHoldSize;
    var yOffset2:Float = mods.GetYOffset(conductorInUse, time + timeDiff, speed, column, conductorInUse.getTimeWithDelta() + timeDiff) + ofs;
    var pos4:Vector3D = new Vector3D(mods.GetXPos(column, yOffset2, pn, xoffArray, false), mods.GetYPos(column, yOffset2, pn, xoffArray, isDownscroll),
      mods.GetZPos(column, yOffset2, pn, xoffArray));
    var angles:Vector3D = ModchartMath.getDirectionsBetweenTwoVectors(pos, pos4);
    var pos2:Vector3D = notePos.clone();
    var pos3:Vector3D = strumPos.clone();
    pos2.x *= effect;
    pos2.z *= effect;
    pos3.x *= effect;
    pos3.z *= effect;
    pos.x *= effect;
    pos.z *= effect;
    var offset:Vector3D = new Vector3D(pos2.x - notePos.x, 0, pos2.z - notePos.z);
    if (yOffset <= 0)
    {
      offset.x = pos3.x - strumPos.x;
      offset.z = pos3.z - strumPos.z;
    }
    var noteBeat:Float = Conductor.instance.currentBeatTime;
    var rotation:Vector3D = new Vector3D(mods.GetRotationX(column, yOffset, true, angles.x), mods.GetRotationY(column, yOffset, true, angles.y),
      (mods.GetRotationZ(column, yOffset, noteBeat, true, angles.z)));
    var fullPos:Vector3D = pos;
    var scale:Array<Float> = mods.GetScale(column, yOffset, pn);
    var scalePos:Vector3D = new Vector3D(scale[0], scale[1], scale[4]);
    var skewPos:Vector3D = new Vector3D(scale[2], scale[3]);
    mods.modifyPos(fullPos, scalePos, rotation, skewPos, xoffArray, column);
    var zoom2:Vector3D = parentStrumline.zoom2;
    var zoom1:Vector3D = parentStrumline.zoom;
    var newZoom:Vector3D = new Vector3D(zoom1.x * zoom2.x, zoom1.y * zoom2.y, zoom1.z * zoom2.z);
    if (mods.getValue('spiralholds') != 0) rotation.z += angles.z * ModchartMath.deg - 90;
    mods.modifyPosByValue(fullPos, scalePos, rotation, skewPos, column, parentStrumline.rotation.add(parentStrumline.rotation2),
      parentStrumline.skew.add(parentStrumline.skew2), newZoom);
    parentStrumline.getSplineAxisPos('pos', column, yOffset, 0, spPos);
    parentStrumline.getSplineAxisPos('zoom', column, yOffset, 0, spZoom);
    var realSpZoom:Float = 1 - 0.5 * spZoom.x;
    parentStrumline.getSplineAxisPos('skew', column, yOffset, 0, spSkew);
    fullPos.incrementBy(spPos);
    fullPos.incrementBy(difference);
    scalePos.scaleBy(realSpZoom);
    skewPos.x += spSkew.x;
    left.x = -width / 2;
    right.x = -left.x;
    var zPos:Array<Vector3D> = ModchartMath.processActor(fullPos, [left, right], rotation, scalePos, skewPos, originVec, parentStrumline.fov, rotationOrder);
    zPos[0].decrementBy(offset);
    zPos[0].incrementBy(globalOffset);
    zPos[1].decrementBy(offset);
    zPos[1].incrementBy(globalOffset);
    return zPos;
  }

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
    setVertices(verticesArray);
    setUVTData(uvtDataArray);
    setIndices(indicesArray);
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
