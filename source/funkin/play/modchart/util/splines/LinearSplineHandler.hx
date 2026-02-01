package funkin.play.modchart.util.splines;

import funkin.play.modchart.util.ModchartMath;
import openfl.geom.Vector3D;

// expansion: splinetype_linear
class LinearSpline
{
  public var points:Array<Array<Float>> = [];

  public function new() {}

  function loop_space_difference(a:Float, b:Float, spatial_extent:Float):Float
  {
    final norm_diff:Float = a - b;
    if (spatial_extent == 0.0) return norm_diff;
    final plus_diff:Float = a - (b + spatial_extent);
    final minus_diff:Float = a - (b - spatial_extent);
    final abs_norm_diff:Float = Math.abs(norm_diff);
    final abs_plus_diff:Float = Math.abs(plus_diff);
    final abs_minus_diff:Float = Math.abs(minus_diff);
    if (abs_norm_diff < abs_plus_diff)
    {
      if (abs_norm_diff < abs_minus_diff) return norm_diff;
      if (abs_plus_diff < abs_minus_diff) return plus_diff;
      return minus_diff;
    }
    if (abs_plus_diff < abs_minus_diff) return plus_diff;
    return minus_diff;
  }

  public var spatial_extent:Float = 0.0;

  public function solve_looped():Void
  {
    if (check_minimum_size()) return;
    var last:Int = points.length;
    for (i in 0...last)
    {
      var next:Int = (i + 1) % last;
      points[i][1] = loop_space_difference(points[next][0], points[i][0], spatial_extent);
    }
  }

  public function solve_straight():Void
  {
    if (check_minimum_size()) return;
    var last:Int = points.length;
    for (i in 0...last - 1)
    {
      points[i][1] = points[i + 1][0] - points[i][0];
    }
    points[last - 1][1] = points[last - 2][1];
  }

  public function solve_polygonal():Void
  {
    solve_looped();
  }

  public function check_minimum_size():Bool
  {
    var last:Int = points.length;
    if (last < 2)
    {
      points[0][1] = 0.0;
      return true;
    }
    if (last == 2)
    {
      points[0][1] = loop_space_difference(points[1][0], points[0][0], spatial_extent);
      points[1][1] = loop_space_difference(points[0][0], points[1][0], spatial_extent);
      return true;
    }
    var a:Float = points[0][0];
    var all_points_identical:Bool = true;
    for (i in 0...last)
    {
      points[i][1] = 0.0;
      if (points[i][0] != a) all_points_identical = false;
    }
    return all_points_identical;
  }

  public function p_and_tfrac_from_t(t:Float, loop:Bool):Array<Float>
  {
    var p:Int = 0;
    var tfrac:Float = 0;
    if (loop)
    {
      var max_t:Float = points.length;
      t = ModchartMath.mod(t, max_t);
      if (t < 0.0) t += max_t;
      p = Std.int(t);
      tfrac = t - p;
    }
    else
    {
      var flort:Int = Std.int(t);
      if (flort < 0)
      {
        p = 0;
        tfrac = 0;
      }
      else if (flort >= points.length - 1)
      {
        p = points.length - 1;
        tfrac = 0;
      }
      else
      {
        p = flort;
        tfrac = t - p;
      }
    }
    return [p, tfrac];
  }

  public function evaluate(t:Float, loop:Bool):Float
  {
    if (points.length == 0) return 0.0;
    var p_tfrac:Array<Float> = p_and_tfrac_from_t(t, loop);
    var p:Int = Std.int(p_tfrac[0]);
    var tfrac:Float = p_tfrac[1];
    return points[p][0] + (points[p][1] * tfrac);
  }

  public function evaluate_derivative(t:Float, loop:Bool):Float
  {
    if (points.length == 0) return 0.0;
    var p_tfrac:Array<Float> = p_and_tfrac_from_t(t, loop);
    var p:Int = Std.int(p_tfrac[0]);
    return points[p][1];
  }

  public function set_point(i:Int, v:Float):Void
  {
    if (i >= points.length) throw "LinearSpline::set_point requires the index to be less than the number of points.";
    points[i][0] = v;
  }

  public function set_coefficients(i:Int, b:Float):Void
  {
    if (i >= points.length) throw "LinearSpline: point index must be less than the number of points.";
    points[i][1] = b;
  }

  public function get_coefficients(i:Int):Float
  {
    if (i >= points.length) throw "LinearSpline: point index must be less than the number of points.";
    return points[i][1];
  }

  public function set_point_and_coefficients(i:Int, a:Float, b:Float):Void
  {
    set_coefficients(i, b);
    points[i][0] = a;
  }

  public function get_point_and_coefficients(i:Int):Array<Float>
  {
    return [points[i][0], get_coefficients(i)];
  }

  public function resize(s:Int):Void
  {
    var oldSize:Int = points.length;
    points.resize(s);
    for (i in oldSize...s)
    {
      points[i] = [0.0, 0.0];
    }
  }

  public function size():Int
  {
    return points.length;
  }

  public function empty():Bool
  {
    return points.length == 0;
  }
}

class LinearSplineN
{
  public function new() {}

  public var splines:Array<LinearSpline> = [];
  public var owned_by_actor:Bool = false;

  var loop:Bool = false;
  var polygonal:Bool = false;
  var dirty:Bool = true;

  public function weighted_average(out:LinearSplineN, from:LinearSplineN, to:LinearSplineN, between:Float):Void
  {
    if ((out.dimension() == from.dimension() && to.dimension() == from.dimension()) == false) throw "Cannot tween splines of different dimensions.";
    if (between >= 0.5)
    {
      out.set_loop(to.get_loop());
      out.set_polygonal(to.get_polygonal());
    }
    else
    {
      out.set_loop(from.get_loop());
      out.set_polygonal(from.get_polygonal());
    }
    final from_size:Int = from.size();
    final to_size:Int = to.size();
    var out_size:Int = to_size;
    var limit:Int = to_size;
    if (from_size < to_size)
    {
      out_size = from_size + Std.int((to_size - from_size) * between);
    }
    else if (to_size < from_size)
    {
      limit = from_size;
      out_size = to_size + Std.int((from_size - to_size) * between);
    }
    out_size = ModchartMath.iClamp(out_size, 0, limit);
    out.resize(out_size);
    for (spli in 0...out.splines.length)
    {
      for (p in 0...out_size)
      {
        var fc:Array<Float> = [0.0, 0.0];
        var tc:Array<Float> = [0.0, 0.0];
        if (p < from_size)
        {
          fc = from.splines[spli].get_point_and_coefficients(p);
        }
        if (p < to_size)
        {
          tc = to.splines[spli].get_point_and_coefficients(p);
        }
        else
        {
          for (i in 0...2)
            tc[i] = fc[i];
        }
        if (p >= from_size)
        {
          for (i in 0...2)
            fc[i] = tc[i];
        }
        var oc:Array<Float> = [0.0, 0.0];
        for (i in 0...2)
          oc[i] = ModchartMath.lerp(between, fc[i], tc[i]);
        out.splines[spli].set_point_and_coefficients(p, oc[0], oc[1]);
      }
    }
  }

  public function solve():Void
  {
    if (!dirty) return;
    if (polygonal)
    {
      for (spline in splines)
        spline.solve_polygonal();
    }
    else
    {
      for (spline in splines)
        spline.solve_looped();
    }
    dirty = false;
  }

  public function evaluate(t:Float, v:Dynamic):Void
  {
    if (v is Array && v[0] is Float)
    {
      for (spline in splines)
        v.push(spline.evaluate(t, loop));
    }
    if (v is Vector3D)
    {
      if (splines.length != 3) throw 'Assertion failed';
      v.x = splines[0].evaluate(t, loop);
      v.y = splines[1].evaluate(t, loop);
      v.z = splines[2].evaluate(t, loop);
    }
  }

  public function evaluate_derivative(t:Float, v:Dynamic):Void
  {
    if (v is Array && v[0] is Float)
    {
      for (spline in splines)
        v.push(spline.evaluate_derivative(t, loop));
    }
    if (v is Vector3D)
    {
      if (splines.length != 3) throw 'Assertion failed';
      v.x = splines[0].evaluate_derivative(t, loop);
      v.y = splines[1].evaluate_derivative(t, loop);
      v.z = splines[2].evaluate_derivative(t, loop);
    }
  }

  public function set_point(i:Int, v:Array<Float>):Void
  {
    if (v.length != splines.length) throw "LinearSplineN::set_point requires the passed point to be the same dimension as the spline.";
    for (n in 0...splines.length)
      splines[n].set_point(i, v[n]);
    dirty = true;
  }

  public function set_coefficients(i:Int, b:Array<Float>):Void
  {
    if (b.length != splines.length) throw "LinearSplineN: coefficient vector must be the same dimension as the spline.";
    for (n in 0...splines.length)
      splines[n].set_coefficients(i, b[n]);
    dirty = true;
  }

  public function get_coefficients(i:Int, b:Array<Float>):Void
  {
    if (b.length != splines.length) throw "LinearSplineN: coefficient vector must be the same dimension as the spline.";
    for (n in 0...splines.length)
    {
      b[n] = splines[n].get_coefficients(i);
    }
  }

  public function set_spatial_extent(i:Int, extent:Float):Void
  {
    if (i >= splines.length) throw "LinearSplineN: index of spline to set extent of is out of range.";
    splines[i].spatial_extent = extent;
    dirty = true;
  }

  public function get_spatial_extent(i:Int):Float
  {
    if (i >= splines.length) throw "LinearSplineN: index of spline to set extent of is out of range.";
    return splines[i].spatial_extent;
  }

  public function resize(s:Int):Void
  {
    for (spline in splines)
      spline.resize(s);
    dirty = true;
  }

  public function size():Int
  {
    if (splines.length > 0) return splines[0].size();
    return 0;
  }

  public function empty():Bool
  {
    return splines.length == 0 || splines[0].empty();
  }

  public function redimension(d:Int):Void
  {
    splines.resize(d);
    for (i in 0...splines.length)
    {
      if (splines[i] == null) splines[i] = new LinearSpline();
    }
    dirty = true;
  }

  public function dimension():Int
  {
    return splines.length;
  }

  public function set_loop(b:Bool):Void
  {
    dirty = true;
    loop = b;
  }

  public function get_loop():Bool
  {
    return loop;
  }

  public function set_polygonal(b:Bool):Void
  {
    dirty = true;
    polygonal = b;
  }

  public function get_polygonal():Bool
  {
    return polygonal;
  }

  public function set_dirty(b:Bool):Void
  {
    dirty = b;
  }

  public function get_dirty():Bool
  {
    return dirty;
  }
}

class LinearSplineHandler
{
  public var spline:LinearSplineN;

  public var subtract_song_beat_from_curr:Bool = true;

  public function new()
  {
    spline = new LinearSplineN();
  }

  public function BeatToTValue(song_beat:Float, note_beat:Float)
  {
    var relative_beat:Float = note_beat;
    if (subtract_song_beat_from_curr)
    {
      relative_beat -= song_beat;
      return relative_beat;
    }
    return relative_beat;
  }

  public function EvalForBeat(song_beat:Float, note_beat:Float, ret:Vector3D)
  {
    var t_value:Float = BeatToTValue(song_beat, note_beat);
    spline.evaluate(t_value, ret);
  }

  public function EvalDerivForBeat(song_beat:Float, note_beat:Float, ret:Vector3D)
  {
    var t_value:Float = BeatToTValue(song_beat, note_beat);
    spline.evaluate_derivative(t_value, ret);
  }

  public function EvalForReceptor(song_beat:Float, ret:Vector3D)
  {
    var t_value:Float = 0.0;
    if (!subtract_song_beat_from_curr)
    {
      t_value = song_beat;
    }
    spline.evaluate(t_value, ret);
  }

  public function MakeWeightedAverage(out:LinearSplineHandler, from:LinearSplineHandler, to:LinearSplineHandler, between:Float)
  {
    if (between >= 0.5) out.subtract_song_beat_from_curr = to.subtract_song_beat_from_curr;
    else
      out.subtract_song_beat_from_curr = from.subtract_song_beat_from_curr;
    spline.weighted_average(out.spline, from.spline, to.spline, between);
  }
}
