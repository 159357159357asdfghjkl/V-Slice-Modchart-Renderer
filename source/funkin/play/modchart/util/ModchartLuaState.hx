package funkin.play.modchart.util;

import llua.Lua;
import llua.LuaL;
import llua.State;
import llua.Convert;

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
    Lua_helper.add_callback(lua, "ApplyModifiers", function(str:String, ?pn:Int) {
      if (pn == 1) PlayState.instance.opponentStrumline.mods.fromString(str);
      else if (pn == 2) PlayState.instance.playerStrumline.mods.fromString(str);
      else
      {
        PlayState.instance.opponentStrumline.mods.fromString(str);
        PlayState.instance.playerStrumline.mods.fromString(str);
      }
    });
    Lua_helper.add_callback(lua, 'getTime', function() {
      return Conductor.instance.getTimeWithDelta();
    });
    Lua_helper.add_callback(lua, 'getBeat', function() {
      return Conductor.instance.currentBeatTime;
    });
    Lua_helper.add_callback(lua, 'getTimeFromBeat', function(a:Float) {
      return Conductor.instance.getBeatTimeInMs(a);
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
