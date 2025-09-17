package funkin.play.modchart.util;

import llua.Lua;
import llua.LuaL;
import llua.State;
import llua.Convert;
import funkin.play.modchart.events.ModEvents;
import funkin.play.modchart.events.ModEases;
import funkin.play.modchart.events.ModEases.Ease;

using StringTools;

// from psych engine
class ModchartLuaState
{
  public var lua:State = null;

  public function new(script:String)
  {
    lua = LuaL.newstate();
    LuaL.openlibs(lua);
    Lua.init_callbacks(lua);
    var result:Dynamic = LuaL.dofile(lua, script);
    var resultStr:String = Lua.tostring(lua, result);
    if (resultStr != null && result != 0)
    {
      #if windows
      lime.app.Application.current.window.alert(resultStr, 'Error on lua script!');
      #end
      lua = null;
      return;
    }
    var eases:Map<String, Ease> = [
      'instant' => ModEases.instant,
      'linear' => ModEases.linear,
      'inquad' => ModEases.inQuad,
      'outquad' => ModEases.outQuad,
      'inoutquad' => ModEases.inOutQuad,
      'incubic' => ModEases.inCubic,
      'outcubic' => ModEases.outCubic,
      'inoutcubic' => ModEases.inOutCubic,
      'inquart' => ModEases.inQuart,
      'outquart' => ModEases.outQuart,
      'inoutquart' => ModEases.inOutQuart,
      'inquint' => ModEases.inQuint,
      'outquint' => ModEases.outQuint,
      'inoutquint' => ModEases.inOutQuint,
      'inexpo' => ModEases.inExpo,
      'outexpo' => ModEases.outExpo,
      'inoutexpo' => ModEases.inOutExpo,
      'incirc' => ModEases.inCirc,
      'outcirc' => ModEases.outCirc,
      'inoutcirc' => ModEases.inOutCirc,
      'inbounce' => ModEases.inBounce,
      'outbounce' => ModEases.outBounce,
      'inoutbounce' => ModEases.inOutBounce,
      'insine' => ModEases.inSine,
      'outsine' => ModEases.outSine,
      'inoutsine' => ModEases.inOutSine,
      'inelastic' => ModEases.inElastic,
      'outelastic' => ModEases.outElastic,
      'inoutelastic' => ModEases.inOutElastic,
      'inback' => ModEases.inBack,
      'outback' => ModEases.outBack,
      'inoutback' => ModEases.inOutBack,
      'bounce' => ModEases.bounce,
      'tri' => ModEases.tri,
      'bell' => ModEases.bell,
      'pop' => ModEases.pop,
      'tap' => ModEases.tap,
      'pulse' => ModEases.pulse,
      'spike' => ModEases.spike,
      'inverse' => ModEases.inverse,
      'popelasticinternal' => ModEases.popElasticInternal,
      'tapelasticinternal' => ModEases.tapElasticInternal,
      'pulseelasticinternal' => ModEases.pulseElasticInternal,
      'insmoothstep' => ModEases.inSmoothStep,
      'outsmoothstep' => ModEases.outSmoothStep,
      'inoutsmoothstep' => ModEases.inOutSmoothStep,
      'insmootherstep' => ModEases.inSmootherStep,
      'outsmootherstep' => ModEases.outSmootherStep,
      'inoutsmootherstep' => ModEases.inOutSmootherStep
    ];
    // scripts
    Lua_helper.add_callback(lua, "set", function(modArray:Array<Dynamic>, extra:Any = null) {
      var beat:Float = modArray[0];
      var mods:Array<Dynamic> = [];
      for (i in 1...modArray.length)
        mods.push(modArray[i]);
      PlayState.instance.modEvents.set(beat, mods, extra);
    });
    Lua_helper.add_callback(lua, "ease", function(modArray:Array<Dynamic>, extra:Any = null) {
      var beat:Float = modArray[0];
      var len:Float = modArray[1];
      var ease:String = modArray[2];
      var mods:Array<Dynamic> = [];
      for (i in 3...modArray.length)
        mods.push(modArray[i]);
      PlayState.instance.modEvents.ease(beat, len, eases.get(ease.toLowerCase()), mods, extra);
    });
    Lua_helper.add_callback(lua, "add", function(modArray:Array<Dynamic>, extra:Any = null) {
      var beat:Float = modArray[0];
      var len:Float = modArray[1];
      var ease:String = modArray[2];
      var mods:Array<Dynamic> = [];
      for (i in 3...modArray.length)
        mods.push(modArray[i]);
      PlayState.instance.modEvents.add(beat, len, eases.get(ease.toLowerCase()), mods, extra);
    });
    Lua_helper.add_callback(lua, "acc", function(modArray:Array<Dynamic>, extra:Any = null) {
      var beat:Float = modArray[0];
      var mods:Array<Dynamic> = [];
      for (i in 1...modArray.length)
        mods.push(modArray[i]);
      PlayState.instance.modEvents.acc(beat, mods, extra);
    });
    Lua_helper.add_callback(lua, "setdefault", function(modArray:Array<Dynamic>) {
      PlayState.instance.modEvents.setdefault(modArray);
    });
    Lua_helper.add_callback(lua, "apply_modifiers", function(str:String, ?pn:Int) {
      if (pn == 0) PlayState.instance.opponentStrumline.mods.fromString(str);
      else if (pn == 1) PlayState.instance.playerStrumline.mods.fromString(str);
      else if (pn == null)
      {
        PlayState.instance.opponentStrumline.mods.fromString(str);
        PlayState.instance.playerStrumline.mods.fromString(str);
      }
    });
    Lua_helper.add_callback(lua, 'getTime', function() {
      return Conductor.instance.getTimeWithDelta();
    });
    Lua_helper.add_callback(lua, 'getBeat', function() {
      return Conductor.instance.getTimeInSteps(Conductor.instance.getTimeWithDelta()) / Constants.STEPS_PER_BEAT;
    });
  }

  public var closed:Bool = false;

  public function call(func:String, args:Array<Dynamic>):Dynamic
  {
    if (closed) return null;
    try
    {
      if (lua == null) return null;
      Lua.getglobal(lua, func);
      var type:Int = Lua.type(lua, -1);
      if (type != Lua.LUA_TFUNCTION)
      {
        Lua.pop(lua, 1);
        return null;
      }
      for (arg in args)
        Convert.toLua(lua, arg);
      var status:Int = Lua.pcall(lua, args.length, 1, 0);
      if (status != Lua.LUA_OK)
      {
        return null;
      }
      var result:Dynamic = cast Convert.fromLua(lua, -1);
      if (result == null) result = null;
      Lua.pop(lua, 1);
      return result;
    }
    catch (e:Dynamic)
    {
      trace(e);
    }
    if (closed) return null;
    return null;
  }

  public function stop()
  {
    closed = true;
    if (lua == null)
    {
      return;
    }
    Lua.close(lua);
    lua = null;
  }
}
