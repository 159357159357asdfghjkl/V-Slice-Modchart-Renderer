package funkin.play.modchart.events;

import funkin.play.modchart.events.ModEases.Ease;
import funkin.play.modchart.Modchart;
import funkin.play.modchart.util.*;

typedef ExtraVars =
{
  @:optional var plr:Array<Int>;
  @:optional var m:Dynamic;
  @:optional var mode:Dynamic;
  @:optional var time:Bool;
  @:optional var step:Bool;
  @:optional var relative:Bool;
  @:optional var flip:Bool;
}

/**
 * A port of xero's Mirin Template
 * but only a part of mirin
 */
class ModEvents
{
  public var mods:Array<Map<String, Float>> = [];
  public var default_mods:Array<Map<String, Float>> = [];
  public var modState:Array<Modchart> = [];

  final MAX_PN:Int = 8;

  public function new(state:Array<Modchart>)
  {
    var i:Int = 0;
    while (i < MAX_PN)
    {
      mods[i] = state[0].getModTable();
      mods[i + 1] = state[1].getModTable();
      i += 2;
    }
    var i:Int = 0;
    while (i < MAX_PN)
    {
      default_mods[i] = state[0].defaults.copy();
      default_mods[i + 1] = state[1].defaults.copy();
      i += 2;
    }
    var i:Int = 0;
    while (i < MAX_PN)
    {
      modState[i] = state[0];
      modState[i + 1] = state[1];
      i += 2;
    }
  }

  var eases:Array<Map<String, Dynamic>> = [];

  public function ease(beat:Float, len:Float, easing:Ease, modArray:Array<Dynamic>, ?extra:ExtraVars)
  {
    var newLen:Float = len;
    var table:Map<String, Dynamic> = new Map<String, Dynamic>();
    if (extra == null) extra = {plr: [1, 2]};
    if (extra.plr == null) extra.plr = [1, 2];
    if (easing(1) < 0.5) table.set('transient', 1);
    if (extra.mode != null || extra.m != null) newLen = len - beat;
    if (extra.flip == null) extra.flip = false;
    table.set('time', extra.time);
    table.set('len', newLen);
    table.set('start_time', table['time'] ? beat : Conductor.instance.getBeatTimeInMs(beat));
    table.set('beat', beat);
    table.set('ease', easing);
    table.set('flip', extra.flip);
    table.set('mod', modArray);

    if (extra.time == null) extra.time = false;
    if (extra.step == null) extra.step == false;
    if (extra.relative == null) extra.relative = false;
    if (extra.time == true) extra.step = false;
    if (extra.step == true) extra.time = false;
    table.set('relative', extra.relative);
    table.set('step', extra.step);
    var plr:Array<Int> = extra.plr;
    for (i in plr)
    {
      var copy = table.copy();
      copy.set('plr', i - 1);
      eases.push(copy);
    }
  }

  public function add(beat:Float, len:Float, easing:Ease, modArr:Array<Dynamic>, ?extra:ExtraVars)
  {
    if (extra == null) extra = {relative: true};
    extra.relative = true;
    ease(beat, len, easing, modArr, extra);
  }

  public function set(beat:Float, modArr:Array<Dynamic>, ?extra:ExtraVars)
  {
    ease(beat, 0, ModEases.instant, modArr, extra);
  }

  public function acc(beat:Float, modArr:Array<Dynamic>, ?extra:ExtraVars)
  {
    if (extra == null) extra = {relative: true};
    extra.relative = true;
    ease(beat, 0, ModEases.instant, modArr, extra);
  }

  public function setValue(modName:String, val:Float, ?pn:Int)
  {
    modState[pn - 1].setValue(modName, val);
  }

  var funcs:Array<Map<Dynamic, Dynamic>> = [];

  public function alias(table:Array<String>)
  {
    if (table.length == 2)
    {
      for (i in modState)
        i.createAliasForMod(table[0], table[1]);
    }
  }

  public function sort()
  {
    eases.sort((a, b) -> {
      return a['start_time'] - b['start_time'];
    });
    funcs.sort((a, b) -> {
      if (a[0] == b[0])
      {
        var x = a['priority'];
        var y = b['priority'];
        return Std.int(x * x * y - x * y * y);
      }
      else
      {
        return a[0] - b[0];
      }
    });
  }

  function touch_mod(mod:String, ?pn:Int)
  {
    if (pn != null) mods[pn][mod] = mods[pn][mod];
    else
    {
      for (pn in 0...MAX_PN)
        touch_mod(mod, pn);
    }
  }

  var eases_index:Int = 0;
  var active_eases:Array<Map<String, Dynamic>> = [];
  var funcs_index:Int = 0;
  var active_funcs:Array<Map<String, Dynamic>> = [];

  public function update(beat:Float, step:Float, time:Float)
  {
    while (eases_index <= eases.length - 1)
    {
      var e:Map<String, Dynamic> = eases[eases_index];
      var measure:Float = e['time'] ? time : (e['step'] ? step : beat);
      if (measure < e['beat']) break;
      var plr:Int = e['plr'];

      var idx:Int = 0;
      while (idx < e['mod'].length)
      {
        var mod = e['mod'][idx + 1];
        e['mod'][idx + 1] = modState[plr].getName(mod);
        e.set('_$mod', mods.copy()[plr].copy()[mod]);
        e.set('__$mod', e['mod'][idx] - (e['relative'] == true ? 0 : e['_$mod']));
        idx += 2;
      }

      active_eases.push(e);
      eases_index++;
    }

    var active_eases_index:Int = 0;
    while (active_eases_index <= active_eases.length - 1)
    {
      var e:Map<String, Dynamic> = active_eases[active_eases_index];
      var plr:Int = e['plr'];
      var measure:Float = e['time'] ? time : (e['step'] ? step : beat);
      if (measure < e['beat'] + e['len'])
      {
        var e3:Float = e['flip'] == true ? 1 - e['ease']((measure - e['beat']) / e['len']) : e['ease']((measure - e['beat']) / e['len']);
        var i:Int = 0;
        while (i < e['mod'].length)
        {
          var mod = e['mod'][i + 1];
          mods[plr][mod] = e['_$mod'] + e3 * e['__$mod'];
          i += 2;
        }
        active_eases_index++;
      }
      else
      {
        var i:Int = 0;
        while (i < e['mod'].length)
        {
          var mod = e['mod'][i + 1];
          touch_mod(mod, plr);
          i += 2;
        }
        active_eases.splice(active_eases_index, 1);
      }
    }
  }
}
