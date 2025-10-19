package funkin.play.modchart.util;

import llua.Lua;
import llua.LuaL;
import llua.State;
import llua.Convert;
import flixel.text.FlxText;
import flixel.util.FlxColor;

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
      PlayState.instance.ApplyModifiers(str, pn);
    });
    Lua_helper.add_callback(lua, 'getTime', function() {
      return Conductor.instance.getTimeWithDelta() / 1000;
    });
    Lua_helper.add_callback(lua, 'getBeat', function() {
      return Conductor.instance.currentBeatTime;
    });
    Lua_helper.add_callback(lua, 'getTimeFromBeat', function(a:Float) {
      return Conductor.instance.getBeatTimeInMs(a) / 1000;
    });
    Lua_helper.add_callback(lua, 'setHealth', function(a:Float) {
      PlayState.instance.health = a;
    });
    Lua_helper.add_callback(lua, 'getHealth', function(a:Float) {
      return PlayState.instance.health;
    });
    Lua_helper.add_callback(lua, 'setITGMode', function(a:Bool) {
      PlayState.instance.itgMode = a;
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
        var a:String = 'unknown';
        switch (type)
        {
          case Lua.LUA_TBOOLEAN:
            a = "boolean";
          case Lua.LUA_TNUMBER:
            a = "number";
          case Lua.LUA_TSTRING:
            a = "string";
          case Lua.LUA_TTABLE:
            a = "table";
          case Lua.LUA_TFUNCTION:
            a = "function";
        }
        if (type <= Lua.LUA_TNIL) a = "nil";
        if (type > Lua.LUA_TNIL) luaTrace("ERROR (" + func + "): attempt to call a " + a + " value", FlxColor.RED);
        Lua.pop(lua, 1);
        return null;
      }
      for (arg in args)
        Convert.toLua(lua, arg);
      var status:Int = Lua.pcall(lua, args.length, 1, 0);
      if (status != Lua.LUA_OK)
      {
        var v:String = Lua.tostring(lua, -1);
        Lua.pop(lua, 1);
        if (v != null) v = v.trim();
        if (v == null || v == "")
        {
          switch (status)
          {
            case Lua.LUA_ERRRUN:
              v = "Runtime Error";
            case Lua.LUA_ERRMEM:
              v = "Memory Allocation Error";
            case Lua.LUA_ERRERR:
              v = "Critical Error";
          }
          v = "Unknown Error";
        }

        luaTrace("ERROR (" + func + "): " + v, FlxColor.RED);
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

  public static function luaTrace(text:String, color:FlxColor = FlxColor.WHITE)
  {
    PlayState.instance.addTextToDebug(text, color);
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

class DebugLuaText extends FlxText
{
  public var disableTime:Float = 6;

  public function new()
  {
    super(10, 10, FlxG.width - 20, '', 16);

    setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    scrollFactor.set();
    borderSize = 1;
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);
    disableTime -= elapsed;
    if (disableTime < 0) disableTime = 0;
    if (disableTime < 1) alpha = disableTime;

    if (alpha == 0 || y >= FlxG.height) kill();
  }
}
