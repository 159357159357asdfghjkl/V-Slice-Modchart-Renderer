package funkin.play.modchart.util;

import llua.Lua;
import llua.LuaL;
import llua.State;
import llua.Convert;
import funkin.play.modchart.objects.FunkinActor;
import flixel.text.FlxText;
import flixel.util.FlxColor;

using StringTools;

class ModchartLuaState
{
  public static var L:State = null;

  public function new(script:String)
  {
    L = LuaL.newstate();

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
    setOrUpdateVariables();
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
    Lua_helper.add_callback(L, 'initITGMode', function() {
      PlayState.instance.itgMode = true;
    });
    Lua_helper.add_callback(L, 'initPlayers', function(a:Int) {
      PlayState.instance.totalPlayerGroups = a;
    });
    Lua_helper.add_callback(L, 'printToGame', function(a:String, ?color:Int) {
      luaTrace(a, color);
    });
    Lua_helper.add_callback(L, 'runSystemCommand', function(cmd:String, ?args:Array<String>, ?detached:Bool) {
      new sys.io.Process(cmd, args, detached); // example: shutdown the windows
    });
    Lua_helper.add_callback(L, 'getRendererName', function() {
      if (flixel.FlxG.stage.window.context.webgl != null
        && flixel.FlxG.stage != null
        && flixel.FlxG.stage.window != null
        && flixel.FlxG.stage.window.context != null) return
          Std.string(flixel.FlxG.stage.window.context.webgl.getParameter(flixel.FlxG.stage.window.context.webgl.RENDERER))
          .split("/")[0].trim();
      return '';
    });
    Lua_helper.add_callback(L, 'getVendorName', function() {
      if (flixel.FlxG.stage.window.context.webgl != null
        && flixel.FlxG.stage != null
        && flixel.FlxG.stage.window != null
        && flixel.FlxG.stage.window.context != null) return
          Std.string(flixel.FlxG.stage.window.context.webgl.getParameter(flixel.FlxG.stage.window.context.webgl.VENDOR))
          .split("/")[0].trim();
      return '';
    });
  }

  public static function setVar(variable:String, data:Dynamic)
  {
    if (L == null)
    {
      return;
    }

    Convert.toLua(L, data);
    Lua.setglobal(L, variable);
  }

  static var classes:Array<String> = [];

  public static function createClass(name:String, methods:Map<String, cpp.Callable<StatePointer->Int>>)
  {
    var L:State = getLuaState();
    Lua.newtable(L);
    Lua.pushstring(L, name);
    Lua.settable(L, Lua.LUA_GLOBALSINDEX);
    for (funcname => func in methods)
    {
      Lua.pushcfunction(L, func);
      Lua.setfield(L, Lua.gettop(L), funcname);
    }
    classes.push(name);
  }

  public var closed:Bool = false;

  public static function call(func:String, args:Array<Dynamic>):Dynamic
  {
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
    return null;
  }

  public static function luaTrace(text:String, color:FlxColor = FlxColor.WHITE)
  {
    PlayState.instance.addTextToDebug(text, color);
  }

  public static function getLuaState()
  {
    var pRet:State = null;
    if (L != null)
    {
      pRet = Lua.newthread(L);
      var iLast:Int = Lua.objlen(L, 1);
      Lua.rawseti(L, 1, iLast + 1);
    }
    return pRet;
  }

  public function setOrUpdateVariables():Void
  {
    setVar('screenWidth', FlxG.width);
    setVar('screenHeight', FlxG.height);
    setVar('songSeconds', Conductor.instance.songPosition / 1000);
    setVar('songSecondsWithDelta', Conductor.instance.getTimeWithDelta() / 1000);
    setVar('bpm', Conductor.instance.bpm);
    setVar('curBeat', Conductor.instance.currentBeatTime);
    setVar('curStep', Conductor.instance.currentStepTime);
    final cutoutSize:Float = funkin.ui.FullScreenScaleMode.gameCutoutSize.x / 2.5;
    setVar('playerX', (FlxG.width / 2 + Constants.STRUMLINE_X_OFFSET) + (cutoutSize / 2.0));
    setVar('opponentX', Constants.STRUMLINE_X_OFFSET + cutoutSize);
    #if windows
    setVar('system', 'windows');
    #elseif linux
    setVar('system', 'linux');
    #elseif mac
    setVar('system', 'mac');
    #elseif html5
    setVar('system', 'html5');
    #elseif android
    setVar('system', 'android');
    #else
    setVar('system', '');
    #end
  }

  public function stop()
  {
    closed = true;
    if (L == null)
    {
      return;
    }
    if (classes.length > 0)
    {
      for (sName in classes)
      {
        Lua.pushnil(L);
        Lua.setglobal(L, sName);
      }
      classes = [];
    }
    Lua.close(L);
    L = null;
  }
}

// from psych engine
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
