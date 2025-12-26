package funkin.play.modchart.util;

import llua.Lua;
import llua.LuaL;
import llua.State;
import llua.Convert;
import flixel.text.FlxText;
import flixel.util.FlxColor;

using StringTools;

typedef Property =
{
  var get:State->Int;
  var set:State->Int;
}

// from psych engine
class ModchartLuaState
{
  public var L:State = null;

  static var _L:State;

  public function new(script:String)
  {
    L = LuaL.newstate();
    _L = L;
    LuaL.openlibs(L);
    Lua.init_callbacks(L);
    var result:Dynamic = LuaL.dofile(L, script);
    var resultStr:String = Lua.tostring(L, result);
    if (resultStr != null && result != 0)
    {
      #if windows
      lime.app.Application.current.window.alert(resultStr, 'Error on lua script!');
      #end
      L = null;
      return;
    }
    Lua_helper.add_callback(L, "ApplyModifiers", function(str:String, ?pn:Int) {
      PlayState.instance.ApplyModifiers(str, pn);
    });
    Lua_helper.add_callback(L, "GetNoteData", function(b:Float, eb:Float, ?pn:Int) {
      return PlayState.instance.GetNoteData(b, eb, pn);
    });
    Lua_helper.add_callback(L, 'getTime', function() {
      return Conductor.instance.getTimeWithDelta() / 1000;
    });
    Lua_helper.add_callback(L, 'getBeat', function() {
      return Conductor.instance.currentBeatTime;
    });
    Lua_helper.add_callback(L, 'getTimeFromBeat', function(a:Float) {
      return Conductor.instance.getBeatTimeInMs(a) / 1000;
    });
    Lua_helper.add_callback(L, 'setHealth', function(a:Float) {
      PlayState.instance.health = a;
    });
    Lua_helper.add_callback(L, 'getHealth', function(a:Float) {
      return PlayState.instance.health;
    });
    Lua_helper.add_callback(L, 'setITGMode', function(a:Bool) {
      PlayState.instance.itgMode = a;
    });
    Lua_helper.add_callback(L, 'printToGame', function(a:String, ?color:Int) {
      luaTrace(a, color);
    });
  }

  public static function createClass(name:String, methods:Map<String, cpp.Callable<StatePointer->Int>>)
  {
    var L:State = get();
    Lua.newtable(L);
    Lua.pushstring(L, name);
    Lua.settable(L, Lua.LUA_GLOBALSINDEX);
    for (funcname => func in methods)
    {
      Lua.pushcfunction(L, func);
      Lua.setfield(L, Lua.gettop(L), funcname);
    }
  }

  public var closed:Bool = false;

  public function call(func:String, args:Array<Dynamic>):Dynamic
  {
    if (closed) return null;
    try
    {
      if (L == null) return null;
      Lua.getglobal(L, func);
      var type:Int = Lua.type(L, -1);
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
        Lua.pop(L, 1);
        return null;
      }
      for (arg in args)
        Convert.toLua(L, arg);
      var status:Int = Lua.pcall(L, args.length, 1, 0);
      if (status != Lua.LUA_OK)
      {
        var v:String = Lua.tostring(L, -1);
        Lua.pop(L, 1);
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
      var result:Dynamic = cast Convert.fromLua(L, -1);
      if (result == null) result = null;
      Lua.pop(L, 1);
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

  public static function get()
  {
    var pRet:State = null;
    if (_L != null)
    {
      pRet = Lua.newthread(_L);
      var iLast:Int = Lua.objlen(_L, 1);
      Lua.rawseti(_L, 1, iLast + 1);
    }
    return pRet;
  }

  public function stop(?classesToRemove:Array<String>)
  {
    closed = true;
    if (L == null)
    {
      return;
    }
    if (classesToRemove != null && classesToRemove.length > 0)
    {
      for (sName in classesToRemove)
      {
        Lua.pushnil(L);
        Lua.setglobal(L, sName);
      }
    }
    Lua.close(L);
    L = null;
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
