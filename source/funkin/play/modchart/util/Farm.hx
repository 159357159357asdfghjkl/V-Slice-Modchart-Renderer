package funkin.play.modchart.util;

import hscript.Parser;
import hscript.Interp;

class Farm
{
  var farm:Array<String>;
  var farmBuilding:String;

  public function new()
  {
    farm = [];
  }

  public function addpart(a:Dynamic)
  {
    farm.push(Std.string(a));
    return this;
  }

  public function buildFarm(?s:String, ?i:Int, ?j:Int)
  {
    var building:String = __concat(s, i, j);
    this.farmBuilding = building;
    return building;
  }

  public function setupFarm()
  {
    var parser:Parser = new Parser();
    parser.allowTypes = true;
    var result:Dynamic = new Interp().execute(parser.parseString(farmBuilding));
    return result;
  }

  public static function setupBuild(build:String)
  {
    var parser:Parser = new Parser();
    parser.allowTypes = true;
    var result:Dynamic = new Interp().execute(parser.parseString(build));
    return result;
  }

  public function destroyFarm()
  {
    farm = [];
    return farm;
  }

  function __concat(?s:String, ?i:Int, ?j:Int)
  {
    if (s == null) s == '';
    if (i == null) i = 0;
    if (j == null) j = farm.length - 1;
    var brandNewFarm:Array<String> = [];
    for (i in i...j + 1)
    {
      brandNewFarm.push(farm[i]);
    }
    return brandNewFarm.join(s);
  }
}
