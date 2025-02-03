package funkin.play.modchart.util;

import hscript.Parser;
import hscript.Interp;

class Tools
{
  public static function loadstring(str:String)
  {
    var parser:Parser = new Parser();
    parser.allowTypes = true;
    var result:Dynamic = new Interp().execute(parser.parseString(str));
    return result;
  }
}
