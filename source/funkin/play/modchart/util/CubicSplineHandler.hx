package funkin.play.modchart.util;

import funkin.play.modchart.util.ModchartMath;
import flixel.math.FlxMath;
import openfl.geom.Vector3D;
import funkin.play.notes.Strumline;

// from stepmania
// it's hard to port this
// expansion: linear/cosine interpolation
class CubicSpline
{
  public var points:Array<Array<Float>> = [];

  public function new()
  {
  }

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

  /** (-inf, 0] Linear
   *  (0, 1] Cosine
   *  (1, +inf) Cubic
  **/
  public var splineMode:Float = 0;

  public var splineOffset:Float = 0;

  public var spatial_extent:Float = 0.0;

  var solution_cache:SplineSolutionCache = new SplineSolutionCache();

  public function solve_looped():Void
  {
    if (check_minimum_size()) return;
    var last:Int = points.length;
    var results:Array<Float> = [];
    var diagonals:Array<Float> = [];
    for (i in 0...last)
    {
      results.push(0.0);
      diagonals.push(0.0);
    }
    var multiples:Array<Float> = [];
    solution_cache.solve_diagonals_looped(diagonals, multiples);
    results[0] = 3 * loop_space_difference(points[1][0], points[last - 1][0], spatial_extent);
    prep_inner(last, results);
    results[last - 1] = 3 * loop_space_difference(points[0][0], points[last - 2][0], spatial_extent);
    for (i in 0...last - 1)
      results[i + 1] -= results[i] * multiples[i];
    var next_mult:Int = last - 1;
    var i:Int = last - 2;
    while (i > 0)
    {
      results[i - 1] -= results[i] * multiples[next_mult];
      ++next_mult;
      --i;
    }

    results[last - 1] -= results[0] * multiples[next_mult];
    ++next_mult;

    var end:Int = last - 1;
    for (i in 0...end)
    {
      results[i] -= results[end] * multiples[next_mult];
      ++next_mult;
    }
    set_results(last, diagonals, results);
  }

  public function solve_straight():Void
  {
    if (check_minimum_size()) return;
    var last:Int = points.length;
    var results:Array<Float> = [];
    var diagonals:Array<Float> = [];
    for (i in 0...last)
    {
      results.push(0.0);
      diagonals.push(0.0);
    }
    var multiples:Array<Float> = [];
    solution_cache.solve_diagonals_straight(diagonals, multiples);
    results[0] = 3 * (points[1][0] - points[0][0]);
    prep_inner(last, results);
    results[last - 1] = 3 * loop_space_difference(points[last - 1][0], points[last - 2][0], spatial_extent);
    for (i in 0...last - 1)
      results[i + 1] -= results[i] * multiples[i];
    var next_mult:Int = last - 1;
    var i:Int = last - 1;
    while (i > 0)
    {
      results[i - 1] -= results[i] * multiples[next_mult];
      ++next_mult;
      --i;
    }
    set_results(last, diagonals, results);
  }

  public function solve_polygonal():Void
  {
    if (check_minimum_size()) return;
    var last:Int = points.length - 1;
    for (i in 0...last)
      points[i][1] = loop_space_difference(points[i + 1][0], points[i][0], spatial_extent);
    points[last][1] = loop_space_difference(points[0][0], points[last][0], spatial_extent);
  }

  public function check_minimum_size():Bool
  {
    var last:Int = points.length;
    if (last < 2)
    {
      points[0][1] = points[0][2] = points[0][3] = 0.0;
      return true;
    }
    if (last == 2)
    {
      points[0][1] = loop_space_difference(points[1][0], points[0][0], spatial_extent);
      points[0][2] = points[0][3] = 0.0;
      points[1][1] = loop_space_difference(points[0][0], points[1][0], spatial_extent);
      points[1][2] = points[1][3] = 0.0;
      return true;
    }
    var a:Float = points[0][0];
    var all_points_identical:Bool = true;
    for (i in 0...last)
    {
      points[i][1] = points[i][2] = points[i][3] = 0.0;
      if (points[i][0] != a) all_points_identical = false;
    }
    return all_points_identical;
  }

  public function prep_inner(last:Int, results:Array<Float>):Void
  {
    for (i in 1...last - 1)
      results[i] = 3 * loop_space_difference(points[i + 1][0], points[i - 1][0], spatial_extent);
  }

  public function set_results(last:Int, diagonals:Array<Float>, results:Array<Float>):Void
  {
    for (i in 0...last)
      results[i] /= diagonals[i];
    for (i in 0...last)
    {
      var next:Int = (i + 1) % last;
      var diff:Float = loop_space_difference(points[next][0], points[i][0], spatial_extent);
      points[i][1] = results[i];
      points[i][2] = (3 * diff) - (2 * results[i]) - results[next];
      points[i][3] = (2 * -diff) + results[i] + results[next];
      if (Math.isNaN(points[i][1])) points[i][1] = 0.0;
      if (Math.isNaN(points[i][2])) points[i][2] = 0.0;
      if (Math.isNaN(points[i][3])) points[i][3] = 0.0;
    }
  }

  public function p_and_tfrac_from_t(t:Float, loop:Bool):Array<Float>
  {
    var p:Int = 0;
    var tfrac:Float = 0;
    var t:Float = t + splineOffset;
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
      else if (Std.int(flort) >= points.length - 1)
      {
        p = points.length - 1;
        tfrac = 0;
      }
      else
      {
        p = Std.int(flort);
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
    var next:Float = points[(p + 1) % points.length][0];
    var diff:Float = loop_space_difference(next, points[p][0], spatial_extent);
    if (splineMode > 1)
    {
      var tsq:Float = tfrac * tfrac;
      var tcub:Float = tsq * tfrac;
      return points[p][0] + (points[p][1] * tfrac) + (points[p][2] * tsq) + (points[p][3] * tcub);
    }
    else if (splineMode > 0 && splineMode <= 1)
    {
      var cosFactor:Float = (1.0 - Math.cos(tfrac * Math.PI)) / 2.0;
      return points[p][0] + diff * cosFactor;
    }
    else
    {
      return points[p][0] + diff * tfrac;
    }
  }

  public function evaluate_derivative(t:Float, loop:Bool):Float
  {
    if (points.length == 0) return 0.0;
    var p_tfrac:Array<Float> = p_and_tfrac_from_t(t, loop);
    var p:Int = Std.int(p_tfrac[0]);
    var tfrac:Float = p_tfrac[1];
    var next:Float = points[(p + 1) % points.length][0];
    var diff:Float = loop_space_difference(next, points[p][0], spatial_extent);
    if (splineMode > 1)
    {
      var tsq:Float = tfrac * tfrac;
      return points[p][1] + (2.0 * points[p][2] * tfrac) + (3.0 * points[p][3] * tsq);
    }
    else if (splineMode > 0 && splineMode <= 1)
    {
      var current:Float = points[p][0];
      var sinFactor:Float = (Math.PI * FlxMath.fastSin(tfrac * Math.PI)) / 2.0;
      return diff * sinFactor;
    }
    else
    {
      return diff;
    }
  }

  public function evaluate_second_derivative(t:Float, loop:Bool):Float
  {
    if (points.length == 0) return 0.0;
    var p_tfrac:Array<Float> = p_and_tfrac_from_t(t, loop);
    var p:Int = Std.int(p_tfrac[0]);
    var tfrac:Float = p_tfrac[1];
    var next:Float = points[(p + 1) % points.length][0];
    var diff:Float = loop_space_difference(next, points[p][0], spatial_extent);
    if (splineMode > 1)
    {
      return (2.0 * points[p][2]) + (6.0 * points[p][3] * tfrac);
    }
    else if (splineMode > 0 && splineMode <= 1)
    {
      var cosFactor:Float = (Math.PI * Math.PI * FlxMath.fastCos(tfrac * Math.PI)) / 2.0;
      return diff * cosFactor;
    }
    else
    {
      return 0.0;
    }
  }

  public function evaluate_third_derivative(t:Float, loop:Bool):Float
  {
    if (points.length == 0) return 0.0;
    var p_tfrac:Array<Float> = p_and_tfrac_from_t(t, loop);
    var p:Int = Std.int(p_tfrac[0]);
    var tfrac:Float = p_tfrac[1];
    var next:Float = points[(p + 1) % points.length][0];
    var diff:Float = loop_space_difference(next, points[p][0], spatial_extent);
    if (splineMode > 1)
    {
      return 6.0 * points[p][3];
    }
    else if (splineMode > 0 && splineMode <= 1)
    {
      var sinFactor:Float = (Math.PI * Math.PI * Math.PI * FlxMath.fastSin(tfrac * Math.PI)) / 2.0;
      return -diff * sinFactor;
    }
    else
    {
      return 0.0;
    }
  }

  public function set_point(i:Int, v:Float):Void
  {
    if (i >= points.length) throw "CubicSpline::set_point requires the index to be less than the number of points.";
    points[i][0] = v;
  }

  public function set_coefficients(i:Int, b:Float, c:Float, d:Float):Void
  {
    if (i >= points.length) throw "CubicSpline: point index must be less than the number of points.";
    points[i][1] = b;
    points[i][2] = c;
    points[i][3] = d;
  }

  public function add_point(i:Int, v:Float):Void
  {
    if (i >= points.length) throw "CubicSpline::add_point requires the index to be less than the number of points.";
    points[i][0] += v;
  }

  public function add_coefficients(i:Int, b:Float, c:Float, d:Float):Void
  {
    if (i >= points.length) throw "CubicSpline: point index must be less than the number of points.";
    points[i][1] += b;
    points[i][2] += c;
    points[i][3] += d;
  }

  public function get_coefficients(i:Int):Array<Float>
  {
    if (i >= points.length) throw "CubicSpline: point index must be less than the number of points.";
    return [points[i][1], points[i][2], points[i][3]];
  }

  public function set_point_and_coefficients(i:Int, a:Float, b:Float, c:Float, d:Float):Void
  {
    set_coefficients(i, b, c, d);
    points[i][0] = a;
  }

  public function get_point_and_coefficients(i:Int):Array<Float>
  {
    var coefficients:Array<Float> = get_coefficients(i);
    coefficients.unshift(points[i][0]);
    return coefficients;
  }

  public function resize(s:Int):Void
  {
    var oldSize:Int = points.length;
    points.resize(s);
    for (i in oldSize...s)
    {
      points[i] = [0.0, 0.0, 0.0, 0.0];
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

class CubicSplineN
{
  public function new()
  {
  }

  public var splines:Array<CubicSpline> = [];
  public var owned_by_actor:Bool = false;

  var loop:Bool = false;
  var polygonal:Bool = false;
  var dirty:Bool = true;

  public function weighted_average(out:CubicSplineN, from:CubicSplineN, to:CubicSplineN, between:Float):Void
  {
    if (!(out.dimension() == from.dimension() && to.dimension() == from.dimension())) throw "Cannot tween splines of different dimensions.";
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
        var fc:Array<Float> = [0.0, 0.0, 0.0, 0.0];
        var tc:Array<Float> = [0.0, 0.0, 0.0, 0.0];
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
          for (i in 0...4)
            tc[i] = fc[i];
        }
        if (p >= from_size)
        {
          for (i in 0...4)
            fc[i] = tc[i];
        }
        var oc:Array<Float> = [0.0, 0.0, 0.0, 0.0];
        for (i in 0...4)
          oc[i] = ModchartMath.lerp(between, fc[i], tc[i]);
        out.splines[spli].set_point_and_coefficients(p, oc[0], oc[1], oc[2], oc[3]);
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
      if (loop)
      {
        for (spline in splines)
          spline.solve_looped();
      }
      else
      {
        for (spline in splines)
          spline.solve_straight();
      }
    }
    dirty = false;
  }

  public function evaluatePoint(t:Float, v:Vector3D):Void
  {
    if (splines.length != 3) throw 'Assertion failed';
    v.x = splines[0].evaluate(t, loop);
    v.y = splines[1].evaluate(t, loop);
    v.z = splines[2].evaluate(t, loop);
  }

  public function evaluatePoint_derivative(t:Float, v:Vector3D):Void
  {
    if (splines.length != 3) throw 'Assertion failed';
    v.x = splines[0].evaluate_derivative(t, loop);
    v.y = splines[1].evaluate_derivative(t, loop);
    v.z = splines[2].evaluate_derivative(t, loop);
  }

  public function evaluate(t:Float, v:Array<Float>):Void
  {
    for (spline in splines)
      v.push(spline.evaluate(t, loop));
  }

  public function evaluate_derivative(t:Float, v:Array<Float>):Void
  {
    for (spline in splines)
      v.push(spline.evaluate_derivative(t, loop));
  }

  public function evaluate_second_derivative(t:Float, v:Array<Float>):Void
  {
    for (spline in splines)
      v.push(spline.evaluate_second_derivative(t, loop));
  }

  public function evaluate_third_derivative(t:Float, v:Array<Float>):Void
  {
    for (spline in splines)
      v.push(spline.evaluate_third_derivative(t, loop));
  }

  public function set_point(i:Int, v:Array<Float>):Void
  {
    if (v.length != splines.length) throw "CubicSplineN::set_point requires the passed point to be the same dimension as the spline.";
    for (n in 0...splines.length)
      splines[n].set_point(i, v[n]);
    dirty = true;
  }

  public function set_type(i:Int, v:Array<Float>):Void
  {
    if (v.length != splines.length) throw "CubicSplineN::set_type requires the passed point to be the same dimension as the spline.";
    for (n in 0...splines.length)
      splines[n].splineMode = v[n];
    dirty = true;
  }

  public function set_offset(i:Int, v:Array<Float>):Void
  {
    if (v.length != splines.length) throw "CubicSplineN::set_offset requires the passed point to be the same dimension as the spline.";
    for (n in 0...splines.length)
      splines[n].splineOffset = v[n];
    dirty = true;
  }

  public function set_coefficients(i:Int, b:Array<Float>, c:Array<Float>, d:Array<Float>):Void
  {
    if (!(b.length == c.length && c.length == d.length && d.length == splines.length))
      throw "CubicSplineN: coefficient vectors must be the same dimension as the spline.";
    for (n in 0...splines.length)
      splines[n].set_coefficients(i, b[n], c[n], d[n]);
    dirty = true;
  }

  public function add_point(i:Int, v:Array<Float>):Void
  {
    if (v.length != splines.length) throw "CubicSplineN::add_point requires the passed point to be the same dimension as the spline.";
    for (n in 0...splines.length)
      splines[n].add_point(i, v[n]);
    dirty = true;
  }

  public function add_coefficients(i:Int, b:Array<Float>, c:Array<Float>, d:Array<Float>):Void
  {
    if (!(b.length == c.length && c.length == d.length && d.length == splines.length))
      throw "CubicSplineN: coefficient vectors must be the same dimension as the spline.";
    for (n in 0...splines.length)
      splines[n].add_coefficients(i, b[n], c[n], d[n]);
    dirty = true;
  }

  public function get_coefficients(i, b:Array<Float>, c:Array<Float>, d:Array<Float>):Void
  {
    if (!(b.length == c.length && c.length == d.length && d.length == splines.length))
      throw "CubicSplineN: coefficient vectors must be the same dimension as the spline.";
    for (n in 0...splines.length)
    {
      var coefficients:Array<Float> = splines[n].get_coefficients(i);
      b[n] = coefficients[0];
      c[n] = coefficients[1];
      d[n] = coefficients[2];
    }
  }

  public function set_spatial_extent(i:Int, extent:Float):Void
  {
    if (i >= splines.length) throw "CubicSplineN: index of spline to set extent of is out of range.";
    splines[i].spatial_extent = extent;
    dirty = true;
  }

  public function get_spatial_extent(i:Int):Float
  {
    if (i >= splines.length) throw "CubicSplineN: index of spline to set extent of is out of range.";
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

  public function empty():Bool return splines.length == 0 || splines[0].empty();

  public function redimension(d:Int):Void
  {
    splines.resize(d);
    for (i in 0...splines.length)
    {
      if (splines[i] == null) splines[i] = new CubicSpline();
    }
    dirty = true;
  }

  public function dimension():Int return splines.length;

  public function set_loop(b:Bool):Void
  {
    dirty = true;
    loop = b;
  }

  public function get_loop():Bool return loop;

  public function set_polygonal(b:Bool):Void
  {
    dirty = true;
    polygonal = b;
  }

  public function get_polygonal():Bool return polygonal;

  public function set_dirty(b:Bool):Void dirty = b;

  public function get_dirty():Bool return dirty;
}

class CubicSplineHandler
{
  public var spline:CubicSplineN;
  public var subtract_song_beat_from_curr:Bool = true;

  public function new()
  {
    spline = new CubicSplineN();
    spline.redimension(3);
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
    spline.evaluatePoint(t_value, ret);
  }

  public function EvalDerivForBeat(song_beat:Float, note_beat:Float, ret:Vector3D)
  {
    var t_value:Float = BeatToTValue(song_beat, note_beat);
    spline.evaluatePoint_derivative(t_value, ret);
  }

  public function EvalForReceptor(song_beat:Float, ret:Vector3D)
  {
    var t_value:Float = 0.0;
    if (!subtract_song_beat_from_curr)
    {
      t_value = song_beat;
    }
    spline.evaluatePoint(t_value, ret);
  }

  public function MakeWeightedAverage(out:CubicSplineHandler, from:CubicSplineHandler, to:CubicSplineHandler, between:Float)
  {
    if (between >= 0.5) out.subtract_song_beat_from_curr = to.subtract_song_beat_from_curr;
    else
      out.subtract_song_beat_from_curr = from.subtract_song_beat_from_curr;
    spline.weighted_average(out.spline, from.spline, to.spline, between);
  }
}

class Entry
{
  public var diagonals:Array<Float>;
  public var multiples:Array<Float>;

  public function new()
  {
    diagonals = [];
    multiples = [];
  }
}

class SplineSolutionCache
{
  var straight_diagonals:Array<Entry>;
  var looped_diagonals:Array<Entry>;
  final solution_cache_limit:Int = 16;

  public function find_in_cache(cache:Array<Entry>, outd:Array<Float>, outm:Array<Float>):Bool
  {
    var out_size:Int = outd.length;
    for (entry in cache)
    {
      if (out_size == entry.diagonals.length)
      {
        for (i in 0...out_size)
          outd[i] = entry.diagonals[i];
        outm.resize(entry.multiples.length);
        for (i in 0...entry.multiples.length)
          outm[i] = entry.multiples[i];
        return true;
      }
    }
    return false;
  }

  public function add_to_cache(cache:Array<Entry>, outd:Array<Float>, outm:Array<Float>):Void
  {
    if (cache.length >= solution_cache_limit) cache.pop();
    var entry:Entry = new Entry();
    entry.diagonals = outd.copy();
    entry.multiples = outm.copy();
    cache.unshift(entry);
  }

  public function prep_inner(last:Int, out:Array<Float>):Void
  {
    for (i in 1...last)
      out[i] = 4.0;
  }

  public function solve_diagonals_straight(diagonals:Array<Float>, multiples:Array<Float>):Void
  {
    if (find_in_cache(straight_diagonals, diagonals, multiples)) return;
    var last:Int = diagonals.length;
    diagonals[0] = 2.0;
    prep_inner(last - 1, diagonals);
    diagonals[last - 1] = 2.0;

    diagonals[1] -= 0.5;
    multiples.push(0.5);
    for (i in 1...last - 1)
    {
      final diag_recip:Float = 1.0 / diagonals[i];
      diagonals[i + 1] -= diag_recip;
      multiples.push(diag_recip);
    }

    var i:Int = last - 1;
    while (i > 0)
    {
      multiples.push(1.0 / diagonals[i]);
      i--;
    }

    add_to_cache(straight_diagonals, diagonals, multiples);
  }

  public function solve_diagonals_looped(diagonals:Array<Float>, multiples:Array<Float>):Void
  {
    if (find_in_cache(looped_diagonals, diagonals, multiples)) return;
    var last:Int = diagonals.length;
    diagonals[0] = 4.0;
    prep_inner(last, diagonals);
    var right_column:Array<Float> = [];
    for (i in 0...last - 1)
      right_column.push(0.0);
    right_column[0] = 1.0;
    right_column[last - 2] = 1.0;

    for (i in 0...last - 2)
    {
      final diag_recip:Float = 1.0 / diagonals[i];
      diagonals[i + 1] -= diag_recip;
      right_column[i + 1] -= right_column[i] * diag_recip;
      multiples.push(diag_recip);
    }

    final diag_recip:Float = 1.0 / diagonals[last - 2];
    diagonals[last - 1] -= right_column[last - 2] * diag_recip;
    multiples.push(diag_recip);

    var i:Int = last - 2;
    while (i > 0)
    {
      final diag_recip:Float = 1.0 / diagonals[i];
      right_column[i - 1] -= right_column[i] * diag_recip;
      multiples.push(diag_recip);
      i--;
    }

    final diag_recip:Float = 1.0 / diagonals[0];
    right_column[0] -= right_column[1] * diag_recip;
    multiples.push(diag_recip);

    final end:Int = last - 1;
    for (i in 0...end)
      multiples.push(right_column[i] / diagonals[end]);

    add_to_cache(looped_diagonals, diagonals, multiples);
  }

  public function new()
  {
    straight_diagonals = [];
    looped_diagonals = [];
  }
}
