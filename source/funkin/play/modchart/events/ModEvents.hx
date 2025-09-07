package funkin.play.modchart.events;

import funkin.play.modchart.events.ModEases.Ease;
import funkin.play.modchart.Modchart;
import funkin.play.modchart.util.*;
import funkin.play.modchart.events.templates.*;

// mirin template haxe port

typedef ExtraVars =
{
  @:optional var plr:Array<Int>;
  @:optional var m:Dynamic;
  @:optional var mode:Dynamic;
  @:optional var time:Bool;
  @:optional var step:Bool;
  @:optional var relative:Bool;
  @:optional var flip:Bool;
  @:optional var startVal:Float;
}

typedef FuncExtraVars =
{
  @:optional var persist:Float; // false: 0.5
  @:optional var defer:Bool;
  @:optional var mode:Dynamic;
  @:optional var m:Dynamic;
  @:optional var time:Bool;
  @:optional var step:Bool;
  @:optional var flip:Bool;
}

typedef NodeExtraVars =
{
  @:optional var defer:Bool;
}

class ModEvents
{
  public var mods:Array<Map<String, Float>> = [];
  public var default_mods:Array<Map<String, Float>> = [];
  public var modState:Array<Modchart> = [];

  public var stepMode:Bool = false; // troll

  final MAX_PN:Int = 8;
  var poptions:Array<{get:(String) -> Float, set:(String, Float) -> Void}> = [];

  function initPlrOptions()
  {
    for (pn in 0...MAX_PN)
    {
      var pn:Int = pn;
      var mt =
        {
          get: function(k:String):Float {
            return mods[pn][modState[pn].getName(k)];
          },
          set: function(k:String, v:Float):Void {
            k = modState[pn].getName(k);
            mods[pn][k] = v;
          }
        }
      poptions[pn] = mt;
    }
  }

  public var trollModMgr:TrollEngineModchartScripts;

  public function new(state:Array<Modchart>)
  {
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
    initPlrOptions();
    var reversedState:Array<Modchart> = state.copy();
    reversedState.reverse();
    trollModMgr = new TrollEngineModchartScripts(this, reversedState);
  }

  public function setdefault(modArray:Array<Dynamic>)
  {
    for (pn in 0...MAX_PN)
    {
      var i:Int = 0;
      while (i < modArray.length)
      {
        modState[pn].defaults[modArray[i + 1]] = modArray[i];
        i += 2;
      }
    }
    return this;
  }

  var eases:Array<Map<String, Dynamic>> = [];

  public function ease(beat:Float, len:Float, easing:Ease, modArray:Array<Dynamic>, ?extra:ExtraVars)
  {
    var newLen:Float = len;
    var table:Map<String, Dynamic> = new Map<String, Dynamic>();
    if (extra == null) extra = {plr: [0, 1]};
    if (extra.plr == null) extra.plr = [0, 1];
    if (easing(1) < 0.5) table.set('transient', 1);
    if (extra.mode != null || extra.m != null) newLen = len - beat;
    if (extra.flip == null) extra.flip = false;
    if (extra.time == null) extra.time = false;
    if (extra.step == null) extra.step == false;
    if (extra.relative == null) extra.relative = false;
    if (extra.time == true) extra.step = false;
    if (extra.step == true) extra.time = false;
    if (stepMode)
    {
      extra.step = true;
      extra.time = false;
    }
    table.set('time', extra.time);
    table.set('len', newLen);
    table.set('start_time', table['time'] ? beat : Conductor.instance.getBeatTimeInMs(beat));
    table.set('beat', beat);
    table.set('ease', easing);
    table.set('flip', extra.flip);
    table.set('mod', modArray);
    table.set('startVal', extra.startVal);
    table.set('relative', extra.relative);

    table.set('step', extra.step);
    var plr:Array<Int> = extra.plr;
    for (i in plr)
    {
      var copy = table.copy();
      copy.set('plr', i);
      eases.push(copy);
    }
    return this;
  }

  public function add(beat:Float, len:Float, easing:Ease, modArr:Array<Dynamic>, ?extra:ExtraVars)
  {
    if (extra == null) extra = {relative: true};
    extra.relative = true;
    ease(beat, len, easing, modArr, extra);
    return this;
  }

  public function set(beat:Float, modArr:Array<Dynamic>, ?extra:ExtraVars)
  {
    ease(beat, 0, ModEases.instant, modArr, extra);
    return this;
  }

  public function acc(beat:Float, modArr:Array<Dynamic>, ?extra:ExtraVars)
  {
    if (extra == null) extra = {relative: true};
    extra.relative = true;
    ease(beat, 0, ModEases.instant, modArr, extra);
    return this;
  }

  var funcs:Array<Map<String, Dynamic>> = [];

  public function func_function(self:Array<Dynamic>, ?extra:FuncExtraVars)
  {
    self[2] = self[1];
    self[1] = null;
    if (extra == null) extra = {defer: false};
    if (extra.defer == null) extra.defer = false;
    if (extra.mode != null && extra.persist != null) extra.persist -= self[0];
    if (extra.persist != null)
    {
      var fn = self[2];
      var final_time = self[0] + extra.persist;
      self[2] = function(beat:Float) {
        if (beat < final_time) fn(beat);
      }
    }
    if (extra.time == null) extra.time = false;
    if (extra.step == null) extra.step == false;
    if (stepMode)
    {
      extra.step = true;
      extra.time = false;
    }
    var table:Map<String, Dynamic> = new Map<String, Dynamic>();
    table.set('beat', self[0]);
    table.set('len', self[1]);
    table.set('func', self[2]);
    table.set('priority', (extra.defer == true ? -1 : 1) * funcs.length);
    table.set('time', extra.time);
    table.set('step', extra.step);
    table.set('start_time', (extra.time == true ? self[0] : Conductor.instance.getBeatTimeInMs(self[0])));
    funcs.push(table);
  }

  public function func_perframe(self:Array<Dynamic>, ?can_use_poptions:Bool, ?extra:FuncExtraVars)
  {
    var table:Map<String, Dynamic> = new Map<String, Dynamic>();
    if (extra == null) extra = {defer: false};
    if (extra.time == null) extra.time = false;
    if (extra.step == null) extra.step == false;
    if (extra.defer == null) extra.defer = false;
    if (can_use_poptions == null) can_use_poptions = false;
    if (can_use_poptions == true)
    {
      table.set('mods', []);
      for (pn in 0...MAX_PN)
        table['mods'][pn] = [];
    }
    if (stepMode)
    {
      extra.step = true;
      extra.time = false;
    }
    table.set('beat', self[0]);
    table.set('len', self[1]);
    table.set('func', self[2]);
    table.set('time', extra.time);
    table.set('step', extra.step);
    table.set('priority', (extra.defer == true ? -1 : 1) * funcs.length);
    table.set('start_time', (extra.time == true ? self[0] : Conductor.instance.getBeatTimeInMs(self[0])));
    funcs.push(table);
  }

  public function func_ease(self:Array<Dynamic>, ?extra:FuncExtraVars)
  {
    if (extra == null) extra = {defer: false};
    if (extra.mode != null || extra.m != null) self[1] = self[1] - self[0];
    if (extra.time == null) extra.time = false;
    if (extra.step == null) extra.step == false;
    if (extra.defer == null) extra.defer = false;
    if (extra.persist == null) extra.persist = 0;
    if (stepMode)
    {
      extra.step = true;
      extra.time = false;
    }
    var fn = self.pop();
    var eas = self[2];
    var start_percent:Float = 0;
    var end_percent:Float = 1;
    if (self.length >= 5)
    {
      start_percent = self[3];
      self.splice(3, 1);
    }
    if (self.length >= 4)
    {
      end_percent = self[3];
      self.splice(3, 1);
    }
    var end_beat = self[0] + self[1];

    self[2] = function(beat:Float) {
      var progress:Float = (beat - self[0]) / self[1];
      if (extra.flip == true) progress = 1 - (beat - self[0]) / self[1];
      fn(start_percent + (end_percent - start_percent) * eas(progress));
    }

    func_perframe(self, false, extra);
    if (extra.persist != 0.5)
    {
      func_function([
        end_beat,
        function() {
          fn(end_percent);
        }
      ],
        {
          persist: extra.persist,
          defer: extra.defer,
          mode: extra.mode
        });
    }
  }

  public function func(self:Array<Dynamic>, ?extra:FuncExtraVars)
  {
    if (self.length == 2) func_function(self, extra);
    else if (self.length == 3) func_perframe(self, true, extra);
    else
      func_ease(self, extra);
    return this;
  }

  public function alias(table:Array<String>)
  {
    if (table.length == 2)
    {
      for (i in modState)
        i.createAliasForMod(table[0], table[1]);
    }
  }

  var auxes:Map<String, Bool> = [];

  public function aux(self:Array<String>)
  {
    for (i in 0...self.length)
    {
      auxes.set(self[i], true);
    }
    return this;
  }

  var nodes:Array<Map<String, Dynamic>> = [];

  public function node(self:Array<Dynamic>, extra:NodeExtraVars)
  {
    if (Std.isOfType(self[2], Float) || Std.isOfType(self[2], Int))
    {
      var multipliers = [];
      var i:Int = 2;
      while (self[i] != null)
      {
        var removed:Float = self.splice(i, 1)[0];
        var amt = 'p * ' + removed * 0.01;
        multipliers.push(amt);
        i++;
      }
      var ret:String = multipliers.join(', ');
      var code:String = 'return function(p:Float) return [' + ret + '];';
      var fn = Farm.setupBuild(code)();
      self[2] = fn;
    }

    var i:Int = 1;
    var inputs:Array<String> = [];
    while (Std.isOfType(self[i], String))
    {
      inputs.push(self[i]);
      i++;
    }
    var fn = self[i];
    i++;
    var out:Array<Dynamic> = [];
    while (self[i] != null)
    {
      out.push(self[i]);
      i++;
    }
    var result:Map<String, Dynamic> = ['inputs' => inputs, 'out' => out, 'fn' => fn];
    result.set('priority', (extra.defer ? -1 : 1) * (nodes.length + 1));
    nodes.push(result);
    return this;
  }

  function sort()
  {
    Sort.stable_sort(eases, (a:Map<String, Dynamic>, b:Map<String, Dynamic>) -> {
      return a['start_time'] < b['start_time'];
    });
    Sort.stable_sort(funcs, (a:Map<String, Dynamic>, b:Map<String, Dynamic>) -> {
      if (a['start_time'] == b['start_time'])
      {
        var x = a['priority'];
        var y = b['priority'];
        return x * x * y < x * y * y;
      }
      else
      {
        return a['start_time'] < b['start_time'];
      }
    });
  }

  public function onStart():Void
  {
    sort();
  }

  public function clear():Void
  {
    active_eases = [];
    active_funcs.remove();
    funcs = [];
    eases = [];
    eases_index = 0;
    funcs_index = 0;
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
  var active_funcs:Methods<Map<String, Dynamic>> = new Methods<Map<String, Dynamic>>((a, b) -> {
    var x:Int = a['priority'];
    var y:Int = b['priority'];
    return x * x * y < x * y * y;
  });

  public function update(beat:Float, step:Float, time:Float)
  {
    var i:Int = 0;
    while (i < MAX_PN)
    {
      for (a => b in auxes)
      {
        if (b == true)
        {
          a = modState[i].getName(a);
          modState[i].getModTable().remove(a);
          modState[i + 1].getModTable().remove(a);
        }
      }
      mods[i] = modState[i].getModTable();
      mods[i + 1] = modState[i + 1].getModTable();
      i += 2;
    }
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
        e.set('_$mod', (e['startVal'] != null ? e['startVal'] : mods.copy()[plr].copy()[mod]));
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
        // lime.app.Application.current.window.alert("test"); // idk why trace don't work
        var e3:Float = e['flip'] == true ? 1 - e['ease']((measure - e['beat']) / e['len']) : e['ease']((measure - e['beat']) / e['len']);
        var i:Int = 0;
        while (i < e['mod'].length)
        {
          var mod = e['mod'][i + 1];
          var a:Int = 1;
          if (mod == 'straightholds') a = -1;
          mods[plr][mod] = e['_$mod'] + e3 * e['__$mod'] * a;
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
          mods[plr][mod] = e['_$mod'] + e['__$mod'];
          touch_mod(mod, plr);
          i += 2;
        }
        active_eases.splice(active_eases_index, 1);
      }
    }
    while (funcs_index <= funcs.length - 1)
    {
      var e = funcs[funcs_index];
      var measure:Float = e['time'] ? time : (e['step'] ? step : beat);
      if (measure < e['beat']) break;
      if (e['len'] == null)
      {
        e['func'](measure);
      }
      else if (measure < e['beat'] + e['len'])
      {
        active_funcs.add(e);
      }
      funcs_index++;
    }
    while (true)
    {
      var e:Map<String, Dynamic> = active_funcs.next();
      if (e == null) break;
      var measure:Float = e['time'] ? time : (e['step'] ? step : beat);
      if (measure < e['beat'] + e['len'])
      {
        if (e['mods'] != null)
        {
          e['func'](measure, poptions);
        }
        else
        {
          e['func'](measure);
        }
      }
      else
      {
        active_funcs.remove();
      }
    }
  }
}
