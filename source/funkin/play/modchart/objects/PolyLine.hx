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
import openfl.geom.Matrix3D;

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
  public var parentStrumline:Strumline;

  public function new(?x:Float, ?y:Float)
  {
    super(0, 0);
    this.makeGraphic(1, 1, 0xFFFFFFFF);
    this.antialiasing = true;
  }

  override public function destroy():Void
  {
    vertices = null;
    uvtData = null;
    indices = null;
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

  function getPosWithOffset(xoff:Float = 0, yoff:Float = 0, time:Float):Vector3D
  {
    var conductorInUse:Conductor = parentStrumline.conductorInUse;
    time += conductorInUse.getTimeWithDelta();
    var speed:Float = parentStrumline.scrollSpeed;
    var isDownscroll:Bool = parentStrumline.isDownscroll;
    var pn:Int = parentStrumline.modNumber;
    var mods:Modchart = parentStrumline.mods;
    var reversedOff:Float = FlxG.height - parentStrumline.defaultHeight - Constants.STRUMLINE_Y_OFFSET * 2;
    var xoffArray:Array<Float> = parentStrumline.xoffArray;
    var ofs:Float = (mods.getValue('centeredpath') + mods.getValue('centeredpath$column')) * Strumline.NOTE_SPACING;
    var yOffset:Float = mods.GetYOffset(conductorInUse, time, speed, column, conductorInUse.getTimeWithDelta()) + ofs;
    var difference:Vector3D = parentStrumline.getDifference();
    var pos:Vector3D = new Vector3D(mods.GetXPos(column, yOffset, pn, xoffArray, false),
      mods.GetYPos(column, yOffset, pn, xoffArray, isDownscroll, reversedOff), mods.GetZPos(column, yOffset, pn, xoffArray));
    var originVec:Vector3D = new Vector3D(difference.x, FlxG.height / 2);
    var strumPos:Vector3D = new Vector3D(mods.GetXPos(column, ofs, pn, xoffArray, false), mods.GetYPos(column, ofs, pn, xoffArray, isDownscroll, reversedOff),
      mods.GetZPos(column, ofs, pn, xoffArray));
    if (mods.getValue('fixeffect') != 0)
    {
      originVec.incrementBy(strumPos);
      originVec.x -= xoffArray[column];
      originVec.y += 2 * Strumline.NOTE_SPACING;
    }
    var effect:Float = 1 - (mods.getValue('straightholds'));
    var noteYOffset:Float = mods.GetYOffset(conductorInUse, conductorInUse.getTimeWithDelta(), speed, column, conductorInUse.getTimeWithDelta()) + ofs;
    var notePos:Vector3D = new Vector3D(mods.GetXPos(column, noteYOffset, pn, xoffArray, true),
      mods.GetYPos(column, noteYOffset, pn, xoffArray, isDownscroll, reversedOff), mods.GetZPos(column, noteYOffset, pn, xoffArray));
    var timeDiff:Float = mods.baseHoldSize;
    var yOffset2:Float = mods.GetYOffset(conductorInUse, time + timeDiff, speed, column, conductorInUse.getTimeWithDelta() + timeDiff) + ofs;
    var pos4:Vector3D = new Vector3D(mods.GetXPos(column, yOffset2, pn, xoffArray, false),
      mods.GetYPos(column, yOffset2, pn, xoffArray, isDownscroll, reversedOff), mods.GetZPos(column, yOffset2, pn, xoffArray));
    var diff:Vector3D = pos4.subtract(pos);
    var ang:Float = Math.atan2(diff.y, diff.x);
    var angOrientX:Float = Math.atan2(diff.y, diff.z);
    var angOrientY:Float = Math.atan2(diff.z, diff.x);
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
    var rotation:Vector3D = new Vector3D(mods.GetRotationX(column, yOffset, true, angOrientX), mods.GetRotationY(column, yOffset, true, angOrientY),
      (mods.GetRotationZ(column, yOffset, noteBeat, true, ang)));
    var fullPos:Vector3D = pos;
    var realPos:Vector3D = new Vector3D(xoff, yoff, 0, 1);
    var scale:Array<Float> = mods.GetScale(column, yOffset, pn);
    var zoom:Float = mods.GetZoom(column, yOffset, pn);
    var scalePos:Vector3D = new Vector3D(scale[0] * zoom, scale[1] * zoom, scale[4]);
    var skewPos:Vector3D = new Vector3D(scale[2], scale[3]);
    mods.modifyPos(fullPos, scalePos, rotation, skewPos, xoffArray, reversedOff, column);
    var newZoom:Vector3D = parentStrumline.zoom.clone();
    var zoom2:Vector3D = parentStrumline.zoom2;
    newZoom.x *= zoom2.x;
    newZoom.y *= zoom2.y;
    newZoom.z *= zoom2.z;
    mods.modifyPosByValue(fullPos, scalePos, rotation, skewPos, column, parentStrumline.rotation.add(parentStrumline.rotation2),
      parentStrumline.skew.add(parentStrumline.skew2), newZoom);
    var spPos:Vector3D = new Vector3D();
    parentStrumline.getSplineAxisPos('pos', column, noteBeat, 0, spPos);
    var spZoom:Vector3D = new Vector3D();
    parentStrumline.getSplineAxisPos('zoom', column, noteBeat, 0, spZoom);
    var realSpZoom:Float = 1 - 0.5 * spZoom.x;
    var spSkew:Vector3D = new Vector3D();
    parentStrumline.getSplineAxisPos('skew', column, noteBeat, 0, spSkew);
    fullPos.incrementBy(difference);
    var order:Int = Std.int(mods.getValue('rotationorder'));
    var rotationOrder:String = 'zyx';
    if (order == 0) rotationOrder = 'zyx';
    else if (order == 1) rotationOrder = 'zxy';
    else if (order == 2) rotationOrder = 'yzx';
    else if (order == 3) rotationOrder = 'yxz';
    else if (order == 4) rotationOrder = 'xyz';
    else if (order == 5) rotationOrder = 'xzy';
    var m:Matrix3D = ModchartMath.translateMatrix(fullPos.x + spPos.x, fullPos.y + spPos.y, fullPos.z + spPos.z);
    var rotate:Matrix3D = ModchartMath.rotateMatrix(m, rotation.x, rotation.y, rotation.z, rotationOrder);
    var scaleMat:Matrix3D = ModchartMath.scaleMatrix(rotate, scalePos.x * realSpZoom, scalePos.y * realSpZoom, scalePos.z * realSpZoom);
    var skew:Matrix3D = ModchartMath.skewMatrix(scaleMat, skewPos.x + spSkew.x, skewPos.y);
    var zPos:Vector3D = ModchartMath.initPerspective(realPos, skew, parentStrumline.fov, FlxG.width, FlxG.height,
      ModchartMath.scale(skewPos.z, 0.1, 1.0, originVec.x, FlxG.width / 2), originVec.y);
    zPos.decrementBy(offset);
    zPos.x += Strumline.NOTE_SPACING / 2 - 1;
    zPos.y += Strumline.NOTE_SPACING * 0.75 - 1;
    return zPos;
  }

  function updateClipping():Void
  {
    var mods:Modchart = parentStrumline.mods;
    var alpha:Float = mods.getValue('arrowpath${column}') + mods.getValue('arrowpath');
    alpha = ModchartMath.clamp(alpha, 0, 1) * this.alpha * parentStrumline.alpha;
    this.colorTransform.alphaMultiplier = alpha;
    if (alpha <= 0) return;
    var grain:Float = mods.getValue('arrowpathgranulate');
    if (grain == 0) grain = 4;
    var roughness:Float = mods.baseHoldSize;
    var scrollSpeed:Float = parentStrumline.scrollSpeed * Constants.PIXELS_PER_MS;
    var backLength:Float = parentStrumline.pathSizeBack / scrollSpeed;
    backLength *= (1 + mods.getValue('arrowpathdrawsizeback'));
    var frontLength:Float = parentStrumline.pathSizeFront / scrollSpeed;
    frontLength *= (1 + mods.getValue('arrowpathdrawsize'));
    var subdivisions:Int = Math.round((backLength + frontLength) / (roughness * grain));
    if (grain < 0) subdivisions = Math.round((backLength + frontLength) / (roughness / 1 + Math.abs(grain)));
    var size:Float = 1 + mods.getValue('arrowpathsize') + mods.getValue('arrowpathsize$column');
    var verticesArray:Array<Float> = [];
    var uvtDataArray:Array<Float> = [];
    var indicesArray:Array<Int> = [];
    x = y = 0;
    for (a in 0...subdivisions + 1)
    {
      var i:Int = a * 2;
      var left:Vector3D = getPosWithOffset(-size / 2, -size / 2, (backLength + frontLength) / subdivisions * a - backLength);
      var right:Vector3D = getPosWithOffset(size / 2, size / 2, (backLength + frontLength) / subdivisions * a - backLength);
      verticesArray[i * 2] = left.x;
      verticesArray[i * 2 + 1] = left.y;
      verticesArray[(i + 1) * 2] = right.x;
      verticesArray[(i + 1) * 2 + 1] = right.y;
      uvtDataArray[i * 2] = 0;
      uvtDataArray[i * 2 + 1] = 1;
      uvtDataArray[(i + 1) * 2] = 1;
      uvtDataArray[(i + 1) * 2 + 1] = 0;
      if (a == subdivisions) break;
      indicesArray.push(i + 1);
      indicesArray.push(i + 2);
      indicesArray.push(i + 0);
      indicesArray.push(i + 1);
      indicesArray.push(i + 3);
      indicesArray.push(i + 2);
    }
    setVertices(verticesArray);
    setUVTData(uvtDataArray);
    setIndices(indicesArray);
  }

  override public function update(elapsed:Float)
  {
    super.update(elapsed);
    updateClipping();
  }

  override public function draw():Void
  {
    if (alpha == 0 || graphic == null || !visible || vertices == null || parentStrumline == null) return;

    for (camera in cameras)
    {
      if (camera.exists && camera != null)
      {
        if (!camera.visible || camera.alpha == 0) continue;

        getScreenPosition(_point, camera).subtractPoint(offset);
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
