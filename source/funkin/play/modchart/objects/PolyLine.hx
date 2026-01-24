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

/**
  a class to simulate notitg's arrowpath
  better than lineStyle
  uvtData and indices will be given automatically when vertices is not empty
**/
class PolyLine extends FunkinSprite
{
  public var vertices:Vector<Float> = new Vector<Float>();

  public function new(?x:Float, ?y:Float)
  {
    super(0, 0);
    this.makeGraphic(1, 1, 0xFFFFFFFF);
    this.antialiasing = true;
  }

  override public function destroy():Void
  {
    vertices = null;
    super.destroy();
  }

  var indices:Vector<Int> = new Vector<Int>();
  var uvtData:Vector<Float> = new Vector<Float>();

  override public function draw():Void
  {
    if (alpha == 0 || graphic == null || !exists || !visible || vertices == null || vertices.length == 0) return;

    for (camera in cameras)
    {
      if (camera.exists && camera != null)
      {
        if (!camera.visible || camera.alpha == 0) continue;

        var subdivisions:Int = Std.int(((vertices.length - 1 - 1) / 2 - 1) / 2);
        for (a in 0...subdivisions + 1)
        {
          var i:Int = a * 2;
          uvtData[i * 2] = 0;
          uvtData[i * 2 + 1] = 1;
          uvtData[(i + 1) * 2] = 1;
          uvtData[(i + 1) * 2 + 1] = 0;
        }
        for (i in 0...subdivisions * 2)
        {
          indices.push(i);
          indices.push(i + 1);
          indices.push(i + 2);
        }
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
