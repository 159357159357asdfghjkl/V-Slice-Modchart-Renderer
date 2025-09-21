package funkin.play.modchart;

import flixel.FlxG;
import funkin.play.notes.Strumline;
import funkin.play.modchart.util.ModchartMath;
import openfl.geom.Vector3D;
import funkin.util.GRhythmUtil;

using StringTools;

/**
 * StepMania Port + NotITG Mods
 * orient(7/28/25) / asymptote(8/10/25) / cubic(8/24/25) / straightholds(3/?/25) / sin|cos|tanclip(8/24/25) were made by me
 */
class Modchart
{
  public var defaults:Map<String, Float> = new Map<String, Float>();

  private var modList:Map<String, Float>;
  private var altname:Map<String, String> = new Map<String, String>();
  final ARROW_SIZE:Float = Strumline.NOTE_SPACING;
  final SCREEN_HEIGHT = FlxG.height;

  function selectTanType(angle:Float, is_cosec:Float)
  {
    if (is_cosec != 0) return ModchartMath.fastCsc(angle, getValue('tanclip'));
    else
      return ModchartMath.fastTan(angle, getValue('tanclip'));
  }

  var dim_x:Int = 0;
  var dim_y:Int = 1;
  var dim_z:Int = 2;

  function CalculateDrunkAngle(time:Float, speed:Float, col:Int, offset:Float, col_frequency:Float, y_offset:Float, period:Float, offset_frequency:Float,
      real_offset:Float):Float
  {
    return (time
      + real_offset * 100) * (1 + speed)
      + col * ((offset * col_frequency) + col_frequency)
      + y_offset * ((period * offset_frequency) + offset_frequency) / SCREEN_HEIGHT;
  }

  function CalculateBumpyAngle(y_offset:Float, offset:Float, period:Float):Float
  {
    return (y_offset + (100.0 * offset)) / ((period * 16.0) + 16.0);
  }

  function CalculateDigitalAngle(y_offset:Float, offset:Float, period:Float, period2:Float, isZ:Bool = false):Float
  {
    var nITGPeriod:Float = (Math.PI * (60 + (60 * period2)) - ARROW_SIZE) / ARROW_SIZE; // easy to convert
    if (isZ) nITGPeriod = Math.PI * (1 + period2) - 1;
    if (period2 == 0) nITGPeriod = 0;
    return Math.PI * (y_offset + (1.0 * offset)) / ((ARROW_SIZE + ((period + nITGPeriod) * ARROW_SIZE)));
  }

  function getTime():Float
  {
    return Conductor.instance.getTimeWithDelta() / 1000;
  }

  function getBeat():Float
  {
    return Conductor.instance.getTimeInSteps(getTime() * 1000) / Constants.STEPS_PER_BEAT;
  }

  function initDefaultMods()
  {
    var ZERO:Array<String> = [
      'boost',
      'brake',
      'wave',
      'waveoffset',
      'waveperiod',
      'boomerang',
      'expand',
      'expandperiod',
      'drunk',
      'drunkspeed',
      'drunkoffset',
      'drunkperiod',
      'drunkspacing',
      'tandrunk',
      'tandrunkspeed',
      'tandrunkoffset',
      'tandrunkperiod',
      'tandrunkspacing',
      'drunkz',
      'drunkzspeed',
      'drunkzoffset',
      'drunkzperiod',
      'drunkzspacing',
      'tandrunkz',
      'tandrunkzspeed',
      'tandrunkzoffset',
      'tandrunkzperiod',
      'tandrunkzspacing',
      'tanexpand',
      'tanexpandperiod',
      'tipsy',
      'tipsyspeed',
      'tipsyoffset',
      'tipsyspacing',
      'tantipsy',
      'tantipsyspeed',
      'tantipsyoffset',
      'tantipsyspacing',
      'tornado',
      'tornadooffset',
      'tornadoperiod',
      'tantornado',
      'tantornadooffset',
      'tantornadoperiod',
      'tornadoz',
      'tornadozoffset',
      'tornadozperiod',
      'tantornadoz',
      'tantornadozoffset',
      'tantornadozperiod',
      'tornadoy',
      'tornadoyoffset',
      'tornadoyperiod',
      'tantornadoy',
      'tantornadoyoffset',
      'tantornadoyperiod',
      'movex',
      'movey',
      'movez',
      'movexoffset',
      'moveyoffset',
      'movezoffset',
      'movexoffset1',
      'moveyoffset1',
      'movezoffset1',
      'randomspeed',
      'reverse',
      'split',
      'divide',
      'alternate',
      'cross',
      'centered',
      'swap',
      'attenuatex',
      'attenuatexoffset',
      'attenuatey',
      'attenuateyoffset',
      'attenuatez',
      'attenuatezoffset',
      'beat',
      'beatoffset',
      'beatmult',
      'beatperiod',
      'beaty',
      'beatyoffset',
      'beatymult',
      'beatyperiod',
      'beatz',
      'beatzoffset',
      'beatzmult',
      'beatzperiod',
      'bumpyx',
      'bumpyxoffset',
      'bumpyxperiod',
      'tanbumpyx',
      'tanbumpyxoffset',
      'tanbumpyxperiod',
      'bumpyy',
      'bumpyyoffset',
      'bumpyyperiod',
      'tanbumpyy',
      'tanbumpyyoffset',
      'tanbumpyyperiod',
      'bumpy',
      'bumpyoffset',
      'bumpyperiod',
      'tanbumpy',
      'tanbumpyoffset',
      'tanbumpyperiod',
      'flip',
      'invert',
      'zigzag',
      'zigzagoffset',
      'zigzagperiod',
      'zigzagz',
      'zigzagzoffset',
      'zigzagzperiod',
      'sawtooth',
      'sawtoothoffset',
      'sawtoothperiod',
      'sawtoothz',
      'sawtoothzoffset',
      'sawtoothzperiod',
      'parabolax',
      'parabolaxoffset',
      'parabolay',
      'parabolayoffset',
      'parabolaz',
      'parabolazoffset',
      'digital',
      'digitalsteps',
      'digitaloffset',
      'digitalperiod',
      'tandigital',
      'tandigitalsteps',
      'tandigitaloffset',
      'tandigitalperiod',
      'digitaly',
      'digitalysteps',
      'digitalyoffset',
      'digitalyperiod',
      'tandigitaly',
      'tandigitalysteps',
      'tandigitalyoffset',
      'tandigitalyperiod',
      'digitalz',
      'digitalzsteps',
      'digitalzoffset',
      'digitalzperiod',
      'tandigitalz',
      'tandigitalzsteps',
      'tandigitalzoffset',
      'tandigitalzperiod',
      'square',
      'squareoffset',
      'squareperiod',
      'squarez',
      'squarezoffset',
      'squarezperiod',
      'bounce',
      'bounceoffset',
      'bounceperiod',
      'bouncey',
      'bounceyoffset',
      'bounceyperiod',
      'bouncez',
      'bouncezoffset',
      'bouncezperiod',
      'xmode',
      'tiny',
      'tipsyx',
      'tipsyxspeed',
      'tipsyxoffset',
      'tipsyxspacing',
      'tantipsyx',
      'tantipsyxspeed',
      'tantipsyxoffset',
      'tantipsyxspacing',
      'tipsyz',
      'tipsyzspeed',
      'tipsyzoffset',
      'tipsyzspacing',
      'tantipsyz',
      'tantipsyzspeed',
      'tantipsyzoffset',
      'tantipsyzspacing',
      'drunky',
      'drunkyspeed',
      'drunkyoffset',
      'drunkyperiod',
      'drunkyspacing',
      'tandrunky',
      'tandrunkyspeed',
      'tandrunkyoffset',
      'tandrunkyperiod',
      'tandrunkyspacing',
      'vibratex',
      'vibratey',
      'vibratez',
      'pulse',
      'pulseinner',
      'pulseouter',
      'pulseoffset',
      'pulseperiod',
      'shrinkmult',
      'shrinklinear',
      'noteskewx',
      'noteskewy',
      'tinyx',
      'tinyy',
      'tinyz',
      'confusionx',
      'confusionxoffset',
      'confusiony',
      'confusionyoffset',
      'confusion',
      'confusionoffset',
      'dizzy',
      'twirl',
      'roll',
      'stealth',
      'hidden',
      'hiddenoffset',
      'sudden',
      'suddenoffset',
      'blink',
      'vanish',
      'dark',
      'cosecant',
      'dizzyholds',
      'rotationx',
      'rotationy',
      'vanishoffset',
      'vanishsize',
      'rotationz',
      'skewx',
      'skewy',
      'spiralx',
      'spiralxoffset',
      'spiralxperiod',
      'spiraly',
      'spiralyoffset',
      'spiralyperiod',
      'spiralz',
      'spiralzoffset',
      'spiralzperiod',
      'granulate',
      'gayholds',
      'arrowpath',
      'arrowpathgranulate',
      'arrowpathsize',
      'arrowpathdrawsize',
      'arrowpathdrawsizeback',
      'mini',
      'drawsize',
      'drawsizeback',
      'holdtinyx',
      'tanpulse',
      'tanpulseinner',
      'tanpulseouter',
      'tanpulseoffset',
      'tanpulseperiod',
      'shrinklinearx',
      'shrinklineary',
      'shrinklinearz',
      'shrinkmultx',
      'shrinkmulty',
      'shrinkmultz',
      'tapstealth',
      'holdstealth',
      'centered2',
      'orient',
      'orientoffset',
      'noreorient',
      'orienty',
      'orientyoffset',
      'noreorienty',
      'orientx',
      'orientxoffset',
      'noreorientx',
      'holdgirth',
      'variableboomerang',
      'reversetype',
      'holdheadstealth',
      'asymptote',
      'asymptotescale',
      'asymptoteoffset',
      'cubicx',
      'cubicxoffset',
      'cubicy',
      'cubicyoffset',
      'cubicz',
      'cubiczoffset',
      'x',
      'y',
      'z',
      'noteskewtype',
      'longholds',
      'spiralholds',
      'sinclip',
      'cosclip',
      'tanclip',
      'digitalperiod2',
      'digitalyperiod2',
      'digitalzperiod2',
      'tandigitalperiod2',
      'tandigitalyperiod2',
      'tandigitalzperiod2',
      'squareperiod2',
      'squarezperiod2',
      'overhead',
      'incoming',
      'space',
      'hallway',
      'distant',
      'mmod',
      'stealthred',
      'stealthgreen',
      'stealthblue',
      'suddenred',
      'suddengreen',
      'suddenblue',
      'suddenredoffset',
      'suddengreenoffset',
      'suddenblueoffset',
      'hiddenred',
      'hiddengreen',
      'hiddenblue',
      'hiddenredoffset',
      'hiddengreenoffset',
      'hiddenblueoffset',
      'blinkred',
      'blinkgreen',
      'blinkblue',
    ];
    var ONE:Array<String> = [
      'xmod',
      'zoom',
      'zoomx',
      'zoomy',
      'zoomz',
      'stealthtype',
      'stealthpastreceptors',
      'scale',
      'scalex',
      'scaley',
      'scalez',
      'scrollspeedmult',
      'stealthglowred',
      'stealthglowgreen',
      'stealthglowblue'
    ];

    for (i in 0...Strumline.KEY_COUNT)
    {
      ZERO.push('reverse$i');
      ZERO.push('movex$i');
      ZERO.push('movey$i');
      ZERO.push('movez$i');
      ZERO.push('movexoffset$i');
      ZERO.push('moveyoffset$i');
      ZERO.push('movezoffset$i');
      ZERO.push('movexoffset1$i');
      ZERO.push('moveyoffset1$i');
      ZERO.push('movezoffset1$i');
      ZERO.push('tiny$i');
      ZERO.push('holdtinyx$i');
      ZERO.push('bumpy$i');
      ZERO.push('tanbumpy$i');
      ZERO.push('bumpyoffset$i');
      ZERO.push('bumpyperiod$i');
      ZERO.push('tanbumpyoffset$i');
      ZERO.push('tanbumpyperiod$i');
      ZERO.push('bumpyx$i');
      ZERO.push('tanbumpyx$i');
      ZERO.push('bumpyxoffset$i');
      ZERO.push('bumpyxperiod$i');
      ZERO.push('tanbumpyxoffset$i');
      ZERO.push('tanbumpyxperiod$i');
      ZERO.push('bumpyy$i');
      ZERO.push('tanbumpyy$i');
      ZERO.push('bumpyyoffset$i');
      ZERO.push('bumpyyperiod$i');
      ZERO.push('tanbumpyyoffset$i');
      ZERO.push('tanbumpyyperiod$i');
      ZERO.push('holdgirth$i');
      ONE.push('scalex$i');
      ONE.push('scaley$i');
      ONE.push('scalez$i');
      ONE.push('scale$i');
      ONE.push('scrollspeedmult$i');
      ZERO.push('noteskewx$i');
      ZERO.push('noteskewy$i');
      ZERO.push('tinyx$i');
      ZERO.push('tinyy$i');
      ZERO.push('tinyz$i');
      ZERO.push('confusionx$i');
      ZERO.push('confusiony$i');
      ZERO.push('confusion$i');
      ZERO.push('confusionxoffset$i');
      ZERO.push('confusionyoffset$i');
      ZERO.push('confusionoffset$i');
      ZERO.push('dark$i');
      ZERO.push('stealth$i');
      ZERO.push('tapstealth$i');
      ZERO.push('holdstealth$i');
      ZERO.push('holdheadstealth$i');
      ZERO.push('arrowpath$i');
      ZERO.push('beat$i');
      ZERO.push('beatmult$i');
      ZERO.push('beatoffset$i');
      ZERO.push('beatperiod$i');
      ZERO.push('beaty$i');
      ZERO.push('beatymult$i');
      ZERO.push('beatyoffset$i');
      ZERO.push('beatyperiod$i');
      ZERO.push('beatz$i');
      ZERO.push('beatzmult$i');
      ZERO.push('beatzoffset$i');
      ZERO.push('beatzperiod$i');
      ZERO.push('boost$i');
      ZERO.push('brake$i');
      ZERO.push('wave$i');
      ZERO.push('waveoffset$i');
      ZERO.push('waveperiod$i');
      ZERO.push('dizzy$i');
      ZERO.push('roll$i');
      ZERO.push('drunk$i');
      ZERO.push('drunkoffset$i');
      ZERO.push('drunkperiod$i');
      ZERO.push('drunkspeed$i');
      ZERO.push('drunkspacing$i');
      ZERO.push('drunky$i');
      ZERO.push('drunkyoffset$i');
      ZERO.push('drunkyperiod$i');
      ZERO.push('drunkyspeed$i');
      ZERO.push('drunkyspacing$i');
      ZERO.push('drunkz$i');
      ZERO.push('drunkzoffset$i');
      ZERO.push('drunkzperiod$i');
      ZERO.push('drunkzspeed$i');
      ZERO.push('drunkzspacing$i');
      ZERO.push('tandrunk$i');
      ZERO.push('tandrunkoffset$i');
      ZERO.push('tandrunkperiod$i');
      ZERO.push('tandrunkspeed$i');
      ZERO.push('tandrunkspacing$i');
      ZERO.push('tandrunky$i');
      ZERO.push('tandrunkyoffset$i');
      ZERO.push('tandrunkyperiod$i');
      ZERO.push('tandrunkyspeed$i');
      ZERO.push('tandrunkyspacing$i');
      ZERO.push('tandrunkz$i');
      ZERO.push('tandrunkzoffset$i');
      ZERO.push('tandrunkzperiod$i');
      ZERO.push('tandrunkzspeed$i');
      ZERO.push('tandrunkzspacing$i');
      ZERO.push('twirl$i');
      ZERO.push('zigzag$i');
      ZERO.push('zigzagoffset$i');
      ZERO.push('zigzagperiod$i');
      ZERO.push('zigzagz$i');
      ZERO.push('zigzagzoffset$i');
      ZERO.push('zigzagzperiod$i');
      ZERO.push('sawtooth$i');
      ZERO.push('sawtoothoffset$i');
      ZERO.push('sawtoothperiod$i');
      ZERO.push('sawtoothz$i');
      ZERO.push('sawtoothzoffset$i');
      ZERO.push('sawtoothzperiod$i');
      ZERO.push('centered$i');
      ZERO.push('arrowpathsize$i');
      ZERO.push('centered2$i');
      ONE.push('stealthglowred$i');
      ONE.push('stealthglowgreen$i');
      ONE.push('stealthglowblue$i');
    }

    for (mod in ZERO)
      defaults.set(mod, 0);

    for (mod in ONE)
      defaults.set(mod, 100);

    defaults.set('cmod', 20000);
    altname.set('land', 'brake');
    altname.set('dwiwave', 'expand');
    altname.set('converge', 'centered');

    // in the groove 2 mod name
    altname.set('accel', 'boost');
    altname.set('decel', 'brake');
    altname.set('drift', 'drunk');
    altname.set('float', 'tipsy');

    // notitg names
    // idk why notitg makes tons of aliases fuck
    // i hate you
    altname.set('glitchytan', 'cosecant');
    altname.set('plannedomspeed', 'scrollspeedmult');
    altname.set('randomvanish', 'vanish');
    altname.set('grain', 'granulate');
    altname.set('ultraman', 'alternate');
    altname.set('arrowpathgrain', 'arrowpathgranulate');
    altname.set('arrowpathgirth', 'arrowpathsize');
    altname.set('arrowpathwidth', 'arrowpathsize');
    altname.set('drawsizefront', 'drawsize');
    altname.set('drawdistance', 'drawsize');
    altname.set('drawdistancefront', 'drawsize');
    altname.set('drawdistanceback', 'drawsizeback');
    altname.set('arrowpathdrawsizefront', 'arrowpathdrawsize');
    altname.set('arrowpathdrawdistance', 'arrowpathdrawsize');
    altname.set('arrowpathdrawdistancefront', 'arrowpathdrawsize');
    altname.set('arrowpathdrawdistanceback', 'arrowpathdrawsizeback');
    altname.set('hideholds', 'holdstealth');
    altname.set('hidetaps', 'tapstealth');
    altname.set('hideholdheads', 'holdheadstealth');
    altname.set('holdtiny', 'holdtinyx');
    altname.set('beatsize', 'beatperiod');
    altname.set('beatysize', 'beatyperiod');
    altname.set('beatzsize', 'beatzperiod');
    altname.set('bumpyz', 'bumpy');
    altname.set('bumpyzoffset', 'bumpyoffset');
    altname.set('bumpyzperiod', 'bumpyperiod');
    altname.set('bumpyxsize', 'bumpyxperiod');
    altname.set('bumpyysize', 'bumpyyperiod');
    altname.set('bumpysize', 'bumpyperiod');
    altname.set('bumpyzsize', 'bumpyperiod');
    altname.set('tanbumpyxsize', 'tanbumpyxperiod');
    altname.set('tanbumpyysize', 'tanbumpyyperiod');
    altname.set('tanbumpysize', 'tanbumpyperiod');
    altname.set('tanbumpyzsize', 'tanbumpyperiod');
    altname.set('tanbumpyz', 'tanbumpy');
    altname.set('tanbumpyzoffset', 'tanbumpyoffset');
    altname.set('tanbumpyzperiod', 'tanbumpyperiod');
    altname.set('drunksize', 'drunkperiod');
    altname.set('drunkysize', 'drunkyperiod');
    altname.set('drunkzsize', 'drunkzperiod');
    altname.set('tandrunksize', 'tandrunkperiod');
    altname.set('tandrunkysize', 'tandrunkyperiod');
    altname.set('tandrunkzsize', 'tandrunkzperiod');
    altname.set('wavesize', 'waveperiod');
    altname.set('expandsize', 'expandperiod');
    altname.set('sawtoothsize', 'sawtoothperiod');
    altname.set('sawtoothzsize', 'sawtoothzperiod');
    altname.set('zigzagsize', 'zigzagperiod');
    altname.set('zigzagzsize', 'zigzagzperiod');
    altname.set('sawtoothsize', 'sawtoothperiod');
    altname.set('sawtoothzsize', 'sawtoothzperiod');
    altname.set('unboundedreverse', 'reversetype');
    altname.set('cosec', 'cosecant');
    altname.set('centeredpath', 'centered2');
    altname.set('longboy', 'longholds');
    altname.set('longboys', 'longholds');
    altname.set('holdtype', 'spiralholds');
    altname.set('asymptotesize', 'asymptotescale');
    altname.set('stealthr', 'stealthred');
    altname.set('stealthg', 'stealthgreen');
    altname.set('stealthb', 'stealthblue');
    altname.set('suddenr', 'suddenred');
    altname.set('suddeng', 'suddengreen');
    altname.set('suddenb', 'suddenblue');
    altname.set('suddenro', 'suddenredoffest');
    altname.set('suddengo', 'suddengreenoffset');
    altname.set('suddenbo', 'suddenblueoffset');
    altname.set('hiddenr', 'hiddenred');
    altname.set('hiddeng', 'hiddengreen');
    altname.set('hiddenb', 'hiddenblue');
    altname.set('hiddenro', 'hiddenredoffest');
    altname.set('hiddengo', 'hiddengreenoffset');
    altname.set('hiddenbo', 'hiddenblueoffset');
    altname.set('blinkr', 'blinkred');
    altname.set('blinkg', 'blinkgreen');
    altname.set('blinkb', 'blinkblue');
    altname.set('stealthgr', 'stealthglowred');
    altname.set('stealthgg', 'stealthglowgreen');
    altname.set('stealthgb', 'stealthglowblue');

    for (i in 0...Strumline.KEY_COUNT)
    {
      altname.set('hideholds$i', 'holdstealth$i');
      altname.set('hidetaps$i', 'tapstealth$i');
      altname.set('hideholdheads$i', 'holdheadstealth$i');
      altname.set('holdtiny$i', 'holdtinyx$i');
      altname.set('beatsize$i', 'beatperiod$i');
      altname.set('beatysize$i', 'beatyperiod$i');
      altname.set('beatzsize$i', 'beatzperiod$i');
      altname.set('bumpyz$i', 'bumpy');
      altname.set('bumpyxsize$i', 'bumpyxperiod$i');
      altname.set('bumpyysize$i', 'bumpyyperiod$i');
      altname.set('bumpyzsize$i', 'bumpyperiod$i');
      altname.set('bumpysize$i', 'bumpyperiod$i');
      altname.set('tanbumpyz$i', 'tanbumpy');
      altname.set('tanbumpyxsize$i', 'tanbumpyxperiod$i');
      altname.set('tanbbumpyysize$i', 'tanbumpyyperiod$i');
      altname.set('tanbumpyzsize$i', 'tanbumpyperiod$i');
      altname.set('tanbumpysize$i', 'tanbumpyperiod$i');
      altname.set('land$i', 'brake$i');
      altname.set('drunksize$i', 'drunkperiod$i');
      altname.set('drunkysize$i', 'drunkyperiod$i');
      altname.set('drunkzsize$i', 'drunkzperiod$i');
      altname.set('tandrunksize$i', 'tandrunkperiod$i');
      altname.set('tandrunkysize$i', 'tandrunkyperiod$i');
      altname.set('tandrunkzsize$i', 'tandrunkzperiod$i');
      altname.set('plannedomspeed$i', 'scrollspeedmult$i');
      altname.set('wavesize$i', 'waveperiod$i');
      altname.set('zigzagsize$i', 'zigzagperiod$i');
      altname.set('zigzagzsize$i', 'zigzagzperiod$i');
      altname.set('sawtoothsize$i', 'sawtoothperiod$i');
      altname.set('sawtoothzsize$i', 'sawtoothzperiod$i');
      altname.set('converge$i', 'centered$i');
      altname.set('arrowpathgirth$i', 'arrowpathsize$i');
      altname.set('arrowpathwidth$i', 'arrowpathsize$i');
      altname.set('centeredpath$i', 'centered2$i');
      altname.set('stealthgr$i', 'stealthglowred$i');
      altname.set('stealthgg$i', 'stealthglowgreen$i');
      altname.set('stealthgb$i', 'stealthglowblue$i');
    }
  }

  public function initMods()
  {
    modList = defaults.copy();
  }

  public function getModTable()
    return modList;

  public function createAliasForMod(alias:String, mod:String)
  {
    var name:String = getName(mod);
    altname.set(alias, name);
  }

  var approaches:Array<Map<String, Array<Null<Float>>>> = [];

  public function fromString(mod:String)
  {
    var a:Array<String> = mod.split(',');
    for (sOneMod in a)
    {
      var sBit:String = sOneMod;
      sBit = sBit.toLowerCase();
      sBit = sBit.trim();

      var level:Float = 1.0;
      var speed:Float = 1.0;
      var asParts:Array<String> = sBit.split(" ");

      for (s in asParts)
      {
        s = s.trim();
        if (s == "no")
        {
          level = 0.0;
        }
        else if ((Std.parseInt(s.charAt(0)) != null) || s.charAt(0) == '-')
        {
          level = Std.parseFloat(s) / 100.0;
        }
        else if (s.charAt(0) == '*')
        {
          speed = Std.parseFloat(s.split('*')[1]);
        }
      }
      sBit = asParts[asParts.length - 1].trim();

      var on:Bool = (level > 0.5);
      var mult:EReg = ~/^([0-9]+(\.[0-9]+)?)x$/;
      var cReg:EReg = ~/^c([+-]?[0-9]*\.?[0-9]+([eE][+-]?[0-9]+)?)$/;
      var mReg:EReg = ~/^m([+-]?[0-9]*\.?[0-9]+([eE][+-]?[0-9]+)?)$/;
      var name:String = sBit;
      if (mult.match(name))
      {
        var a:String = mult.matched(1);
        level = Std.parseFloat(a);
        name = 'xmod';
      }
      else if (cReg.match(name))
      {
        var numStr:String = cReg.matched(1);
        level = Std.parseFloat(numStr) / 100.0;
        name = 'cmod';
        if (!Math.isFinite(level) || level <= 0.0)
        {
          level = 200;
        }
      }
      else if (mReg.match(name))
      {
        var numStr:String = mReg.matched(1);
        level = Std.parseFloat(numStr) / 100.0;
        name = 'mmod';
      }
      approaches.push([name => [level, speed]]);
    }
  }

  public function setValue(s:String, val:Float):Void
  {
    var name:String = getName(s);
    modList.set(name, val);
  }

  public function getValue(s:String):Float
  {
    var name:String = getName(s);
    var val:Null<Float> = modList.get(name);
    if (val == null) return 0;
    val /= 100;
    return val;
  }

  var checkedName:Array<String> = [];

  public function getName(s:String):String
  {
    var default_name:String = 'overhead';
    var s1:String = s.toLowerCase();
    var name:String = altname.exists(s1) ? altname.get(s1) : s1;
    if (!modList.exists(name))
    {
      if (!checkedName.contains(name))
      {
        checkedName.push(s1);
        lime.app.Application.current.window.alert('Modifier name "$s1" does not exist. Check your script!', 'Modchart Script');
      }
      return default_name;
    }
    return name;
  }

  function CalculateTipsyOffset(time:Float, offset:Float, speed:Float, col:Int, real_offset:Float, ?tan:Float = 0)
  {
    var time_times_timer:Float = (time + real_offset * 100) * ((speed * 1.2) + 1.2);
    var arrow_times_mag:Float = ARROW_SIZE * 0.4;
    return (tan == 0 ? ModchartMath.fastCos(time_times_timer + (col * ((offset * 1.8) + 1.8)),
      getValue('cosclip')) * arrow_times_mag : selectTanType(time_times_timer + (col * ((offset * 1.8) + 1.8)), getValue('cosecant')) * arrow_times_mag);
  }

  var approachIndex:Int = 0;

  public function update():Void
  {
    var a = approaches[approachIndex];
    if (a != null)
    {
      for (name => value in a)
      {
        if (value[0] == null || value[1] == null) continue;
        if (!(getValue(name) == value[0]))
        {
          var to_move:Float = getTime() * value[1];
          var last_value:Float = getValue(name);
          var fDelta:Float = value[0] - last_value;
          var fSign:Float = fDelta / Math.abs(fDelta);
          var fToMove:Float = fSign * to_move;
          if (Math.abs(fToMove) > Math.abs(fDelta)) fToMove = fDelta;
          setValue(name, last_value * 100 + fToMove);
        }
        else
        {
          approachIndex++;
        }
      }
    }
  }

  public var baseHoldSize(get, never):Float; // ms

  function get_baseHoldSize():Float
  {
    return 30;
  }

  public function GetYOffset(conductor:Conductor, time:Float, speed:Float, iCol:Int, parentTime:Float):Float
  {
    var scrollSpeed:Float = speed;
    var curTime:Float = getTime();
    scrollSpeed *= getValue('xmod');
    if (getValue('mmod') != 0) scrollSpeed = getValue('mmod') / Conductor.instance.bpm;
    scrollSpeed *= getValue('scrollspeedmult') * getValue('scrollspeedmult$iCol');
    var fYOffset:Float = GRhythmUtil.getNoteY(time, 1, true, conductor) * -1;
    if (getValue('cmod') > 0)
    {
      fYOffset *= getValue('cmod') / 200;
    }
    var fYAdjust:Float = 0;
    if (fYOffset < 0)
    {
      return fYOffset * scrollSpeed;
    }
    if (getValue('boost') != 0)
    {
      var fEffectHeight:Float = SCREEN_HEIGHT;
      var fNewYOffset:Float = fYOffset * 1.5 / ((fYOffset + fEffectHeight / 1.2) / fEffectHeight);
      var fAccelYAdjust:Float = getValue('boost') * (fNewYOffset - fYOffset);

      fAccelYAdjust = ModchartMath.clamp(fAccelYAdjust, -400, 400);
      fYAdjust += fAccelYAdjust;
    }
    if (getValue('brake') != 0)
    {
      var fEffectHeight:Float = SCREEN_HEIGHT;
      var fScale:Float = ModchartMath.scale(fYOffset, 0., fEffectHeight, 0, 1.);
      var fNewYOffset:Float = fYOffset * fScale;
      var fBrakeYAdjust:Float = getValue('brake') * (fNewYOffset - fYOffset);
      fBrakeYAdjust = ModchartMath.clamp(fBrakeYAdjust, -400, 400);
      fYAdjust += fBrakeYAdjust;
    }
    if (getValue('boost$iCol') != 0)
    {
      var fEffectHeight:Float = SCREEN_HEIGHT;
      var fNewYOffset:Float = fYOffset * 1.5 / ((fYOffset + fEffectHeight / 1.2) / fEffectHeight);
      var fAccelYAdjust:Float = getValue('boost$iCol') * (fNewYOffset - fYOffset);

      fAccelYAdjust = ModchartMath.clamp(fAccelYAdjust, -400, 400);
      fYAdjust += fAccelYAdjust;
    }
    if (getValue('brake$iCol') != 0)
    {
      var fEffectHeight:Float = SCREEN_HEIGHT;
      var fScale:Float = ModchartMath.scale(fYOffset, 0., fEffectHeight, 0, 1.);
      var fNewYOffset:Float = fYOffset * fScale;
      var fBrakeYAdjust:Float = getValue('brake$iCol') * (fNewYOffset - fYOffset);
      fBrakeYAdjust = ModchartMath.clamp(fBrakeYAdjust, -400, 400);
      fYAdjust += fBrakeYAdjust;
    }
    if (getValue('wave') != 0)
    {
      fYAdjust += getValue('wave') * 20 * ModchartMath.fastSin((fYOffset + getValue('waveoffset') * 100) / ((getValue('waveperiod') * 38) + 38),
        getValue('sinclip'));
    }
    if (getValue('wave$iCol') != 0)
    {
      fYAdjust += getValue('wave$iCol') * 20 * ModchartMath.fastSin((fYOffset + getValue('waveoffset$iCol') * 100) / ((getValue('waveperiod$iCol') * 38) + 38),
        getValue('sinclip'));
    }
    if (getValue('parabolay') != 0) fYAdjust += getValue('parabolay') * ((fYOffset + 2 * getValue('parabolayoffset')) / ARROW_SIZE) * ((fYOffset
      + 2 * getValue('parabolayoffset')) / ARROW_SIZE);

    fYOffset += fYAdjust;

    if (getValue('boomerang') != 0)
    {
      fYOffset = ((-1 * fYOffset * fYOffset / SCREEN_HEIGHT) + 1.5 * fYOffset) * (getValue('variableboomerang') != 0 ? getValue('boomerang') : 1);
    }

    if (getValue('expand') != 0)
    {
      var expandSeconds:Float = curTime;
      expandSeconds = ModchartMath.mod(expandSeconds, (Math.PI * 2) / (getValue('expandperiod') + 1));
      var fExpandMultiplier:Float = ModchartMath.scale(ModchartMath.fastCos(expandSeconds * 3 * (getValue('expandperiod') + 1), getValue('cosclip')), -1, 1,
        0.75, 1.75);
      scrollSpeed *= ModchartMath.scale(getValue('expand'), 0, 1, 1, fExpandMultiplier);
    }
    if (getValue('tanexpand') != 0)
    {
      var tanExpandSeconds:Float = curTime;
      tanExpandSeconds = ModchartMath.mod(tanExpandSeconds, (Math.PI * 2) / (getValue('tanexpandperiod') + 1));
      var fExpandMultiplier:Float = ModchartMath.scale(selectTanType(tanExpandSeconds * 3 * (getValue('tanexpandperiod') + 1), getValue('cosecant')), -1, 1,
        0.75, 1.75);
      scrollSpeed *= ModchartMath.scale(getValue('tanexpand'), 0, 1, 1, fExpandMultiplier);
    }
    if (getValue('randomspeed') > 0)
    {
      var noteBeat:Float = Conductor.instance.getTimeInSteps(parentTime) / Constants.STEPS_PER_BEAT;
      var seed:Int = (ModchartMath.BeatToNoteRow(noteBeat) << 8) + (iCol * 100);

      for (i in 0...3)
        seed = ((seed * 1664525) + 1013904223) & 0xFFFFFFFF;
      var fRandom:Float = seed / 4294967296.0;

      scrollSpeed *= ModchartMath.scale(fRandom, 0.0, 1.0, 1.0, getValue('randomspeed') + 1.0);
    }
    fYOffset *= scrollSpeed;
    return fYOffset;
  }

  public function GetReversePercentForColumn(iCol:Int):Float
  {
    var f:Float = 0;
    var iNumCols:Int = 4;
    f += getValue('reverse');
    f += getValue('reverse${iCol}');
    if (iCol >= iNumCols / 2) f += getValue('split');
    if ((iCol % 2) == 1) f += getValue('alternate');
    var iFirstCrossCol = iNumCols / 4;
    var iLastCrossCol = iNumCols - 1 - iFirstCrossCol;
    if (iCol >= iFirstCrossCol && iCol <= iLastCrossCol) f += getValue('cross');
    if (getValue('reversetype') == 0)
    {
      if (f > 2) f = ModchartMath.mod(f, 2);
      if (f > 1) f = ModchartMath.scale(f, 1., 2., 1., 0.);
    }
    return f;
  }

  public var notefieldZoom:Float = 1.0;

  public function GetXPos(iCol:Int, fYOffset:Float, pn:Int, xOffset:Array<Float>, isNote:Bool = false, isHoldBody:Bool = false):Float
  {
    var time:Float = getTime();
    var f:Float = 0;
    f += ARROW_SIZE * getValue('movex${iCol}') + getValue('movexoffset$iCol') + getValue('movexoffset1$iCol');

    f += ARROW_SIZE * getValue('movex') + getValue('movexoffset') + getValue('movexoffset1');

    if (getValue('drunk') != 0) f += getValue('drunk') * ModchartMath.fastCos(CalculateDrunkAngle(time, getValue('drunkspeed'), iCol,
      getValue('drunkspacing'), 0.2, fYOffset, getValue('drunkperiod'), 10, getValue('drunkoffset')),
      getValue('cosclip')) * ARROW_SIZE * 0.5;

    if (getValue('tandrunk') != 0) f += getValue('tandrunk') * selectTanType(CalculateDrunkAngle(time, getValue('tandrunkspeed'), iCol,
      getValue('tandrunkspacing'), 0.2, fYOffset, getValue('tandrunkperiod'), 10, getValue('tandrunkoffset')),
      getValue('cosecant')) * ARROW_SIZE * 0.5;

    if (getValue('drunk$iCol') != 0) f += getValue('drunk$iCol') * ModchartMath.fastCos(CalculateDrunkAngle(time, getValue('drunkspeed$iCol'), iCol,
      getValue('drunkspacing$iCol'), 0.2, fYOffset, getValue('drunkperiod$iCol'), 10, getValue('drunkoffset$iCol')),
      getValue('cosclip')) * ARROW_SIZE * 0.5;

    if (getValue('tandrunk$iCol') != 0) f += getValue('tandrunk$iCol') * selectTanType(CalculateDrunkAngle(time, getValue('tandrunkspeed$iCol'), iCol,
      getValue('tandrunkspacing$iCol'), 0.2, fYOffset, getValue('tandrunkperiod$iCol'), 10, getValue('tandrunkoffset$iCol')),
      getValue('cosecant')) * ARROW_SIZE * 0.5;

    if (getValue('attenuatex') != 0) f += getValue('attenuatex') * ((fYOffset + 100 * getValue('attenuatexoffset')) / ARROW_SIZE) * ((fYOffset
      + 100 * getValue('attenuatexoffset')) / ARROW_SIZE) * (xOffset[iCol] / ARROW_SIZE);

    if (getValue('beat') != 0)
    {
      do
      {
        var fAccelTime:Float = 0.2;
        var fTotalTime:Float = 0.5;
        var beatFactor:Float = 0;
        var fBeat:Float = ((getBeat() + fAccelTime + getValue('beatoffset')) * (getValue('beatmult') + 1));
        var bEvenBeat:Bool = (Std.int(fBeat) % 2) != 0;
        if (fBeat < 0) break;
        fBeat -= ModchartMath.trunc(fBeat);
        fBeat += 1;
        fBeat -= ModchartMath.trunc(fBeat);
        if (fBeat >= fTotalTime) break;
        if (fBeat < fAccelTime)
        {
          beatFactor = ModchartMath.scale(fBeat, 0.0, fAccelTime, 0.0, 1.0);
          beatFactor *= beatFactor;
        }
        else
        {
          beatFactor = ModchartMath.scale(fBeat, fAccelTime, fTotalTime, 1.0, 0.0);
          beatFactor = 1 - (1 - beatFactor) * (1 - beatFactor);
        }
        if (bEvenBeat) beatFactor *= -1;
        beatFactor *= 20.0;
        var fShift:Float = beatFactor * ModchartMath.fastSin(((fYOffset / (getValue('beatperiod') * 30.0 + 30.0))) + (Math.PI / 2), getValue('sinclip'));
        f += getValue('beat') * fShift;
      }
      while (false);
    }

    if (getValue('beat$iCol') != 0)
    {
      do
      {
        var fAccelTime:Float = 0.2;
        var fTotalTime:Float = 0.5;
        var fBeat:Float = ((getBeat() + fAccelTime + getValue('beatoffset$iCol')) * (getValue('beatmult$iCol') + 1));
        var bEvenBeat:Bool = (Std.int(fBeat) % 2) != 0;
        var beatFactor:Float = 0;
        if (fBeat < 0) break;
        fBeat -= ModchartMath.trunc(fBeat);
        fBeat += 1;
        fBeat -= ModchartMath.trunc(fBeat);
        if (fBeat >= fTotalTime) break;
        if (fBeat < fAccelTime)
        {
          beatFactor = ModchartMath.scale(fBeat, 0.0, fAccelTime, 0.0, 1.0);
          beatFactor *= beatFactor;
        }
        else
        {
          beatFactor = ModchartMath.scale(fBeat, fAccelTime, fTotalTime, 1.0, 0.0);
          beatFactor = 1 - (1 - beatFactor) * (1 - beatFactor);
        }
        if (bEvenBeat) beatFactor *= -1;
        beatFactor *= 20.0;
        var fShift:Float = beatFactor * ModchartMath.fastSin(((fYOffset / (getValue('beatperiod$iCol') * 30.0 + 30.0))) + (Math.PI / 2), getValue('sinclip'));
        f += getValue('beat$iCol') * fShift;
      }
      while (false);
    }

    if (getValue('bumpyx') != 0) f += getValue('bumpyx') * 40 * ModchartMath.fastSin(CalculateBumpyAngle(fYOffset, getValue('bumpyxoffset'),
      getValue('bumpyxperiod')), getValue('sinclip'));

    if (getValue('tanbumpyx') != 0) f += getValue('tanbumpyx') * 40 * selectTanType(CalculateBumpyAngle(fYOffset, getValue('tanbumpyxoffset'),
      getValue('tanbumpyxperiod')), getValue('cosecant'));

    if (getValue('bumpyx$iCol') != 0) f += getValue('bumpyx$iCol') * 40 * ModchartMath.fastSin(CalculateBumpyAngle(fYOffset, getValue('bumpyxoffset$iCol'),
      getValue('bumpyxperiod$iCol')), getValue('sinclip'));

    if (getValue('tanbumpyx$iCol') != 0) f += getValue('tanbumpyx$iCol') * 40 * selectTanType(CalculateBumpyAngle(fYOffset, getValue('tanbumpyxoffset$iCol'),
      getValue('tanbumpyxperiod$iCol')), getValue('cosecant'));

    if (getValue('flip') != 0)
    {
      var iFirstCol:Int = 0;
      var iLastCol:Int = 3;
      var iNewCol:Int = Std.int(ModchartMath.scale(iCol, iFirstCol, iLastCol, iLastCol, iFirstCol));
      var fOldPixelOffset:Float = xOffset[iCol] * notefieldZoom;
      var fNewPixelOffset:Float = xOffset[iNewCol] * notefieldZoom;
      var fDistance:Float = fNewPixelOffset - fOldPixelOffset;
      f += fDistance * getValue('flip');
    }

    if (getValue('divide') != 0) f += getValue('divide') * (ARROW_SIZE * (iCol >= 2 ? 1 : -1));

    if (getValue('invert') != 0)
    {
      final iNumCols:Int = 4;
      final iNumSides:Int = 1;
      final iNumColsPerSide:Int = Std.int(iNumCols / iNumSides);
      final iSideIndex:Int = Std.int(iCol / iNumColsPerSide);
      final iColOnSide:Int = Std.int(iCol % iNumColsPerSide);

      final iColLeftOfMiddle:Int = Std.int((iNumColsPerSide - 1) / 2);
      final iColRightOfMiddle:Int = Std.int((iNumColsPerSide + 1) / 2);

      var iFirstColOnSide:Int = -1;
      var iLastColOnSide:Int = -1;
      if (iColOnSide <= iColLeftOfMiddle)
      {
        iFirstColOnSide = 0;
        iLastColOnSide = iColLeftOfMiddle;
      }
      else if (iColOnSide >= iColRightOfMiddle)
      {
        iFirstColOnSide = iColRightOfMiddle;
        iLastColOnSide = iNumColsPerSide - 1;
      }
      else
      {
        iFirstColOnSide = Std.int(iColOnSide / 2);
        iLastColOnSide = Std.int(iColOnSide / 2);
      }

      // mirror
      var iNewColOnSide:Int;
      if (iFirstColOnSide == iLastColOnSide) iNewColOnSide = 0;
      else
        iNewColOnSide = Std.int(ModchartMath.scale(iColOnSide, iFirstColOnSide, iLastColOnSide, iLastColOnSide, iFirstColOnSide));
      final iNewCol:Int = iSideIndex * iNumColsPerSide + iNewColOnSide;

      var fOldPixelOffset:Float = xOffset[iCol];
      var fNewPixelOffset:Float = xOffset[iNewCol];
      var invertDistance:Float = fNewPixelOffset - fOldPixelOffset;
      f += getValue('invert') * invertDistance;
    }

    if (getValue('zigzag') != 0)
    {
      var fResult:Float = ModchartMath.triangle((Math.PI * (1 / (getValue('zigzagperiod') + 1)) * ((fYOffset +
        (100.0 * (getValue('zigzagoffset')))) / ARROW_SIZE)));

      f += (getValue('zigzag') * ARROW_SIZE / 2) * fResult;
    }

    if (getValue('zigzag$iCol') != 0)
    {
      var fResult:Float = ModchartMath.triangle((Math.PI * (1 / (getValue('zigzagperiod$iCol') + 1)) * ((fYOffset +
        (100.0 * (getValue('zigzagoffset$iCol')))) / ARROW_SIZE)));

      f += (getValue('zigzag$iCol') * ARROW_SIZE / 2) * fResult;
    }

    if (getValue('sawtooth') != 0) f += (getValue('sawtooth') * ARROW_SIZE) * ((0.5 / (getValue('sawtoothperiod') + 1) * (fYOffset
      + 100.0 * getValue('sawtoothoffset'))) / ARROW_SIZE
      - Math.floor((0.5 / (getValue('sawtoothperiod') + 1) * (fYOffset + 100.0 * getValue('sawtoothoffset'))) / ARROW_SIZE));

    if (getValue('sawtooth$iCol') != 0) f += (getValue('sawtooth$iCol') * ARROW_SIZE) * ((0.5 / (getValue('sawtoothperiod$iCol') + 1) * (fYOffset
      + 100.0 * getValue('sawtoothoffset$iCol'))) / ARROW_SIZE
      - Math.floor((0.5 / (getValue('sawtoothperiod$iCol') + 1) * (fYOffset + 100.0 * getValue('sawtoothoffset$iCol'))) / ARROW_SIZE));

    if (getValue('parabolax') != 0) f += getValue('parabolax') * ((fYOffset + 2 * getValue('parabolaxoffset')) / ARROW_SIZE) * ((fYOffset
      + 2 * getValue('parabolaxoffset')) / ARROW_SIZE);

    if (getValue('digital') != 0) f += (getValue('digital') * ARROW_SIZE * 0.5) * Math.round((getValue('digitalsteps') +
      1) * ModchartMath.fastSin(CalculateDigitalAngle(fYOffset, getValue('digitaloffset'), getValue('digitalperiod'), getValue('digitalperiod2')),
      getValue('sinclip'))) / (getValue('digitalsteps') + 1);

    if (getValue('tandigital') != 0) f += (getValue('tandigital') * ARROW_SIZE * 0.5) * Math.round((getValue('tandigitalsteps') +
      1) * selectTanType(CalculateDigitalAngle(fYOffset, getValue('tandigitaloffset'), getValue('tandigitalperiod'), getValue('tandigitalperiod2')),
      getValue('cosecant'))) / (getValue('tandigitalsteps') + 1);

    if (getValue('square') != 0)
    {
      var nITGPeriod:Float = (Math.PI * (60 + (60 * getValue('squareperiod2'))) - ARROW_SIZE) / ARROW_SIZE;
      if (getValue('squareperiod2') == 0) nITGPeriod = 0;
      var fResult:Float = ModchartMath.square((Math.PI * (fYOffset + (100.0 * (getValue('squareoffset')))) / (ARROW_SIZE
        + ((getValue('squareperiod') + nITGPeriod) * ARROW_SIZE))));

      f += (getValue('square') * ARROW_SIZE * 0.5) * fResult;
    }

    if (getValue('bounce') != 0)
    {
      var fBounceAmt:Float = Math.abs(ModchartMath.fastSin(((fYOffset + (100.0 * (getValue('bounceoffset')))) / (60 + (getValue('bounceperiod') * 60))),
        getValue('sinclip')));

      f += getValue('bounce') * ARROW_SIZE * 0.5 * fBounceAmt;
    }

    if (getValue('xmode') != 0) f += getValue('xmode') * (pn == 0 ? fYOffset : -fYOffset);

    if (getValue('tiny') != 0)
    {
      var fTinyPercent:Float = getValue('tiny');
      fTinyPercent = Math.min(Math.pow(0.5, fTinyPercent), 1.);
      f *= fTinyPercent;
    }

    if (getValue('tipsyx') != 0) f += getValue('tipsyx') * CalculateTipsyOffset(time, getValue('tipsyxspacing'), getValue('tipsyxspeed'), iCol,
      getValue('tipsyxoffset'));

    if (getValue('tantipsyx') != 0) f += getValue('tantipsyx') * CalculateTipsyOffset(time, getValue('tantipsyxspacing'), getValue('tantipsyxspeed'), iCol,
      getValue('tantipsyxoffset'), 1);

    if (getValue('swap') != 0) f += FlxG.width / 2 * getValue('swap') * (pn == 1 ? -1 : 1);

    if (getValue('tornado') != 0)
    {
      var iTornadoWidth:Int = 2;
      var iStartCol:Int = iCol - iTornadoWidth;
      var iEndCol:Int = iCol + iTornadoWidth;
      iStartCol = ModchartMath.iClamp(iStartCol, 0, 3);
      iEndCol = ModchartMath.iClamp(iEndCol, 0, 3);
      var fMinX:Float = ModchartMath.FLT_MAX_x32;
      var fMaxX:Float = ModchartMath.FLT_MIN_x32;

      for (i in iStartCol...iEndCol + 1)
      {
        fMinX = Math.min(fMinX, xOffset[i]);
        fMaxX = Math.max(fMaxX, xOffset[i]);
      }
      var fRealPixelOffset:Float = xOffset[iCol] * notefieldZoom;
      var fPositionBetween:Float = ModchartMath.scale(fRealPixelOffset, fMinX * notefieldZoom, fMaxX * notefieldZoom, -1, 1);
      var fRads:Float = Math.acos(fPositionBetween);
      fRads += (fYOffset + getValue('tornadooffset') * 100) * ((6 * getValue('tornadoperiod')) + 6) / SCREEN_HEIGHT;
      var fAdjustedPixelOffset:Float = ModchartMath.scale(ModchartMath.fastCos(fRads, getValue('cosclip')), -1, 1, fMinX * notefieldZoom,
        fMaxX * notefieldZoom);

      f += (fAdjustedPixelOffset - fRealPixelOffset) * getValue('tornado');
    }

    if (getValue('tantornado') != 0)
    {
      var iTornadoWidth:Int = 2;
      var iStartCol:Int = iCol - iTornadoWidth;
      var iEndCol:Int = iCol + iTornadoWidth;

      iStartCol = ModchartMath.iClamp(iStartCol, 0, 3);
      iEndCol = ModchartMath.iClamp(iEndCol, 0, 3);
      var fMinX:Float = ModchartMath.FLT_MAX_x32;
      var fMaxX:Float = ModchartMath.FLT_MIN_x32;

      for (i in iStartCol...iEndCol + 1)
      {
        fMinX = Math.min(fMinX, xOffset[i]);
        fMaxX = Math.max(fMaxX, xOffset[i]);
      }
      var fRealPixelOffset:Float = xOffset[iCol] * notefieldZoom;
      var fPositionBetween:Float = ModchartMath.scale(fRealPixelOffset, fMinX * notefieldZoom, fMaxX * notefieldZoom, -1, 1);
      var fRads:Float = Math.acos(fPositionBetween);

      fRads += (fYOffset + getValue('tantornadooffset') * 100) * ((6 * getValue('tantornadoperiod')) + 6) / SCREEN_HEIGHT;
      var fAdjustedPixelOffset:Float = ModchartMath.scale(selectTanType(fRads, getValue('cosecant')), -1, 1, fMinX * notefieldZoom, fMaxX * notefieldZoom);
      f += (fAdjustedPixelOffset - fRealPixelOffset) * getValue('tantornado');
    }

    if (getValue('spiralx') != 0) f += fYOffset * getValue('spiralx') * ModchartMath.fastCos((fYOffset + getValue('spiralxoffset')) * (1
      + getValue('spiralxperiod')), getValue('cosclip'));

    if (getValue('cubicx') != 0)
    {
      f += Math.pow((fYOffset + 2 * getValue('cubicxoffset')) / ARROW_SIZE, 3) * 2 * getValue('cubicx');
    }

    if (getValue('asymptote') != 0)
    {
      var fAsymptoteEffect:Float = (xOffset[iCol] * (1 + getValue('asymptote') * 1000) - xOffset[iCol]) * Math.exp(-Math.abs(fYOffset
        + getValue('asymptoteoffset') * 100) * (1 + getValue('asymptotescale')));
      f += fAsymptoteEffect;
    }

    f += xOffset[iCol] * notefieldZoom;
    if (isNote || isHoldBody) f += getValue('skewx') * fYOffset;
    return f;
  }

  public function GetYPos(iCol:Int, fYOffset:Float, pn:Int, xOffset:Array<Float>, down:Bool, fYReversedOffset:Float, WithReverse:Bool = true,
      isHoldBody:Bool = false):Float
  {
    var f:Float = fYOffset;
    var time:Float = getTime();
    if (WithReverse)
    {
      f -= (getValue('centered2') + getValue('centered2$iCol')) * ARROW_SIZE;
      var zoom:Float = 1 - 0.5 * getValue('mini');
      if (Math.abs(zoom) < 0.01) zoom = 0.01;
      var yReversedOffset:Float = fYReversedOffset / zoom;
      var fPercentReverse:Float = GetReversePercentForColumn(iCol);
      var fShift:Float = fPercentReverse * yReversedOffset;
      fShift = ModchartMath.scale(getValue('centered'), 0., 1., fShift, yReversedOffset / 2);
      fShift = ModchartMath.scale(getValue('centered$iCol'), 0., 1., fShift, yReversedOffset / 2);
      fShift = ModchartMath.scale(getValue('centered2'), 0., 1., fShift, ARROW_SIZE);
      fShift = ModchartMath.scale(getValue('centered2$iCol'), 0., 1., fShift, ARROW_SIZE);
      var fScale:Float = ModchartMath.scale(fPercentReverse, 0.0, 1.0, 1.0, -1.0);
      f *= fScale;
      f += fShift;
    }
    f += ARROW_SIZE * getValue('movey$iCol') + getValue('moveyoffset$iCol') + getValue('moveyoffset1$iCol');

    f += ARROW_SIZE * getValue('movey') + getValue('moveyoffset') + getValue('moveyoffset1');

    if (getValue('attenuatey') != 0) f += getValue('attenuatey') * ((fYOffset + 100 * getValue('attenuateyoffset')) / ARROW_SIZE) * ((fYOffset
      + 100 * getValue('attenuateyoffset')) / ARROW_SIZE) * (xOffset[iCol] / ARROW_SIZE);

    if (getValue('tipsy') != 0) f += getValue('tipsy') * CalculateTipsyOffset(time, getValue('tipsyspacing'), getValue('tipsyspeed'), iCol,
      getValue('tipsyoffset'));

    if (getValue('tantipsy') != 0) f += getValue('tantipsy') * CalculateTipsyOffset(time, getValue('tantipsyspacing'), getValue('tantipsyspeed'), iCol,
      getValue('tantipsyoffset'), 1);

    if (getValue('beaty') != 0)
    {
      do
      {
        var fAccelTime:Float = 0.2;
        var fTotalTime:Float = 0.5;
        var fBeat:Float = ((getBeat() + fAccelTime + getValue('beatyoffset')) * (getValue('beatymult') + 1));
        var bEvenBeat:Bool = (Std.int(fBeat) % 2) != 0;
        var beatFactor:Float = 0;
        if (fBeat < 0) break;
        fBeat -= ModchartMath.trunc(fBeat);
        fBeat += 1;
        fBeat -= ModchartMath.trunc(fBeat);
        if (fBeat >= fTotalTime) break;
        if (fBeat < fAccelTime)
        {
          beatFactor = ModchartMath.scale(fBeat, 0.0, fAccelTime, 0.0, 1.0);
          beatFactor *= beatFactor;
        }
        else
        {
          beatFactor = ModchartMath.scale(fBeat, fAccelTime, fTotalTime, 1.0, 0.0);
          beatFactor = 1 - (1 - beatFactor) * (1 - beatFactor);
        }
        if (bEvenBeat) beatFactor *= -1;
        beatFactor *= 20.0;
        var fShift:Float = beatFactor * ModchartMath.fastSin(((fYOffset / (getValue('beatyperiod') * 30.0 + 30.0))) + (Math.PI / 2), getValue('sinclip'));
        f += getValue('beaty') * fShift;
      }
      while (false);
    }

    if (getValue('beaty$iCol') != 0)
    {
      do
      {
        var fAccelTime:Float = 0.2;
        var fTotalTime:Float = 0.5;
        var fBeat:Float = ((getBeat() + fAccelTime + getValue('beatyoffset$iCol')) * (getValue('beatymult$iCol') + 1));
        var bEvenBeat:Bool = (Std.int(fBeat) % 2) != 0;
        var beatFactor:Float = 0;
        if (fBeat < 0) break;
        fBeat -= ModchartMath.trunc(fBeat);
        fBeat += 1;
        fBeat -= ModchartMath.trunc(fBeat);
        if (fBeat >= fTotalTime) break;
        if (fBeat < fAccelTime)
        {
          beatFactor = ModchartMath.scale(fBeat, 0.0, fAccelTime, 0.0, 1.0);
          beatFactor *= beatFactor;
        }
        else
        {
          beatFactor = ModchartMath.scale(fBeat, fAccelTime, fTotalTime, 1.0, 0.0);
          beatFactor = 1 - (1 - beatFactor) * (1 - beatFactor);
        }
        if (bEvenBeat) beatFactor *= -1;
        beatFactor *= 20.0;
        var fShift:Float = beatFactor * ModchartMath.fastSin(((fYOffset / (getValue('beatyperiod$iCol') * 30.0 + 30.0))) + (Math.PI / 2), getValue('sinclip'));
        f += getValue('beaty$iCol') * fShift;
      }
      while (false);
    }

    if (getValue('drunky') != 0) f += getValue('drunky') * ModchartMath.fastCos(CalculateDrunkAngle(time, getValue('drunkyspeed'), iCol,
      getValue('drunkyspacing'), 0.2, fYOffset, getValue('drunkyperiod'), 10, getValue('drunkyoffset')),
      getValue('cosclip')) * ARROW_SIZE * 0.5;

    if (getValue('tandrunky') != 0) f += getValue('tandrunky') * selectTanType(CalculateDrunkAngle(time, getValue('tandrunkyspeed'), iCol,
      getValue('tandrunkyspacing'), 0.2, fYOffset, getValue('tandrunkyperiod'), 10, getValue('tandrunkyoffset')),
      getValue('cosecant')) * ARROW_SIZE * 0.5;

    if (getValue('drunky$iCol') != 0) f += getValue('drunky$iCol') * ModchartMath.fastCos(CalculateDrunkAngle(time, getValue('drunkyspeed$iCol'), iCol,
      getValue('drunkyspacing$iCol'), 0.2, fYOffset, getValue('drunkyperiod$iCol'), 10, getValue('drunkyoffset$iCol')),
      getValue('cosclip')) * ARROW_SIZE * 0.5;

    if (getValue('tandrunky$iCol') != 0) f += getValue('tandrunky$iCol') * selectTanType(CalculateDrunkAngle(time, getValue('tandrunkyspeed$iCol'), iCol,
      getValue('tandrunkyspacing$iCol'), 0.2, fYOffset, getValue('tandrunkyperiod$iCol'), 10, getValue('tandrunkyoffset$iCol')),
      getValue('cosecant')) * ARROW_SIZE * 0.5;

    if (getValue('bouncey') != 0)
    {
      var fBounceAmt:Float = Math.abs(ModchartMath.fastSin(((fYOffset + (100.0 * (getValue('bounceyoffset')))) / (60 + (getValue('bounceyperiod') * 60))),
        getValue('sinclip')));

      f += getValue('bouncey') * ARROW_SIZE * 0.5 * fBounceAmt;
    }

    if (getValue('bumpyy') != 0) f += getValue('bumpyy') * 40 * ModchartMath.fastSin(CalculateBumpyAngle(fYOffset, getValue('bumpyyoffset'),
      getValue('bumpyyperiod')), getValue('sinclip'));

    if (getValue('bumpyy$iCol') != 0) f += getValue('bumpyy$iCol') * 40 * ModchartMath.fastSin(CalculateBumpyAngle(fYOffset, getValue('bumpyyoffset$iCol'),
      getValue('bumpyyperiod$iCol')), getValue('sinclip'));

    if (getValue('tanbumpyy') != 0) f += getValue('tanbumpyy') * 40 * selectTanType(CalculateBumpyAngle(fYOffset, getValue('tanbumpyyoffset'),
      getValue('tanbumpyyperiod')), getValue('cosecant'));

    if (getValue('tanbumpyy$iCol') != 0) f += getValue('tanbumpyy$iCol') * 40 * selectTanType(CalculateBumpyAngle(fYOffset, getValue('tanbumpyyoffset$iCol'),
      getValue('tanbumpyyperiod$iCol')), getValue('cosecant'));

    if (getValue('tornadoy') != 0)
    {
      var iTornadoWidth:Int = 2;
      var iStartCol:Int = iCol - iTornadoWidth;
      var iEndCol:Int = iCol + iTornadoWidth;
      iStartCol = ModchartMath.iClamp(iStartCol, 0, 3);
      iEndCol = ModchartMath.iClamp(iEndCol, 0, 3);

      var fMinX:Float = ModchartMath.FLT_MAX_x32;
      var fMaxX:Float = ModchartMath.FLT_MIN_x32;

      for (i in iStartCol...iEndCol + 1)
      {
        fMinX = Math.min(fMinX, xOffset[i]);
        fMaxX = Math.max(fMaxX, xOffset[i]);
      }

      var fRealPixelOffset:Float = xOffset[iCol] * notefieldZoom;
      var fPositionBetween:Float = ModchartMath.scale(fRealPixelOffset, fMinX * notefieldZoom, fMaxX * notefieldZoom, -1, 1);
      var fRads:Float = Math.acos(fPositionBetween);
      fRads += (fYOffset + getValue('tornadoyoffset') * 100) * ((6 * getValue('tornadoyperiod')) + 6) / SCREEN_HEIGHT;

      var fAdjustedPixelOffset:Float = ModchartMath.scale(ModchartMath.fastCos(fRads, getValue('cosclip')), -1, 1, fMinX * notefieldZoom,
        fMaxX * notefieldZoom);

      f += (fAdjustedPixelOffset - fRealPixelOffset) * getValue('tornadoy');
    }

    if (getValue('tantornadoy') != 0)
    {
      var iTornadoWidth:Int = 2;
      var iStartCol:Int = iCol - iTornadoWidth;
      var iEndCol:Int = iCol + iTornadoWidth;
      iStartCol = ModchartMath.iClamp(iStartCol, 0, 3);
      iEndCol = ModchartMath.iClamp(iEndCol, 0, 3);

      var fMinX:Float = ModchartMath.FLT_MAX_x32;
      var fMaxX:Float = ModchartMath.FLT_MIN_x32;

      for (i in iStartCol...iEndCol + 1)
      {
        fMinX = Math.min(fMinX, xOffset[i]);
        fMaxX = Math.max(fMaxX, xOffset[i]);
      }

      var fRealPixelOffset:Float = xOffset[iCol] * notefieldZoom;
      var fPositionBetween:Float = ModchartMath.scale(fRealPixelOffset, fMinX * notefieldZoom, fMaxX * notefieldZoom, -1, 1);
      var fRads:Float = Math.acos(fPositionBetween);
      fRads += (fYOffset + getValue('tantornadoyoffset') * 100) * ((6 * getValue('tantornadoyperiod')) + 6) / SCREEN_HEIGHT;

      var fAdjustedPixelOffset:Float = ModchartMath.scale(selectTanType(fRads, getValue('cosecant')), -1, 1, fMinX * notefieldZoom, fMaxX * notefieldZoom);

      f += (fAdjustedPixelOffset - fRealPixelOffset) * getValue('tantornadoy');
    }
    if (getValue('digitaly') != 0) f += (getValue('digitaly') * ARROW_SIZE * 0.5) * Math.round((getValue('digitalysteps') +
      1) * ModchartMath.fastSin(CalculateDigitalAngle(fYOffset, getValue('digitalyoffset'), getValue('digitalyperiod'), getValue('digitalyperiod2')),
      getValue('sinclip'))) / (getValue('digitalysteps') + 1);

    if (getValue('tandigitaly') != 0) f += (getValue('tandigitaly') * ARROW_SIZE * 0.5) * Math.round((getValue('tandigitalysteps') +
      1) * selectTanType(CalculateDigitalAngle(fYOffset, getValue('tandigitalyoffset'), getValue('tandigitalyperiod'), getValue('tandigitalyperiod2')),
      getValue('cosecant'))) / (getValue('tandigitalysteps') + 1);

    if (getValue('spiraly') != 0) f += fYOffset * getValue('spiraly') * ModchartMath.fastSin((fYOffset + getValue('spiralyoffset')) * (1
      + getValue('spiralyperiod')), getValue('sinclip'));

    if (getValue('cubicy') != 0)
    {
      f += Math.pow((fYOffset + 2 * getValue('cubicyoffset')) / ARROW_SIZE, 3) * 2 * getValue('cubicy');
    }
    f *= (down ? -1 : 1);
    return f;
  }

  public function GetZPos(iCol:Int, fYOffset:Float, pn:Int, xOffset:Array<Float>):Float
  {
    var f:Float = 0;
    var time:Float = getTime();
    f += ARROW_SIZE * getValue('movez$iCol') + getValue('movezoffset$iCol') + getValue('movezoffset1$iCol');

    f += ARROW_SIZE * getValue('movez') + getValue('movezoffset') + getValue('movezoffset1');

    if (getValue('tornadoz') != 0)
    {
      var iTornadoWidth:Int = 2;
      var iStartCol:Int = iCol - iTornadoWidth;
      var iEndCol:Int = iCol + iTornadoWidth;
      iStartCol = ModchartMath.iClamp(iStartCol, 0, 3);
      iEndCol = ModchartMath.iClamp(iEndCol, 0, 3);

      var fMinX:Float = ModchartMath.FLT_MAX_x32;
      var fMaxX:Float = ModchartMath.FLT_MIN_x32;

      for (i in iStartCol...iEndCol + 1)
      {
        fMinX = Math.min(fMinX, xOffset[i]);
        fMaxX = Math.max(fMaxX, xOffset[i]);
      }

      var fRealPixelOffset:Float = xOffset[iCol] * notefieldZoom;
      var fPositionBetween:Float = ModchartMath.scale(fRealPixelOffset, fMinX * notefieldZoom, fMaxX * notefieldZoom, -1, 1);
      var fRads:Float = Math.acos(fPositionBetween);
      fRads += (fYOffset + getValue('tornadozoffset') * 100) * ((6 * getValue('tornadozperiod')) + 6) / SCREEN_HEIGHT;

      var fAdjustedPixelOffset:Float = ModchartMath.scale(ModchartMath.fastCos(fRads, getValue('cosclip')), -1, 1, fMinX * notefieldZoom,
        fMaxX * notefieldZoom);

      f += (fAdjustedPixelOffset - fRealPixelOffset) * getValue('tornadoz');
    }

    if (getValue('tantornadoz') != 0)
    {
      var iTornadoWidth:Int = 2;
      var iStartCol:Int = iCol - iTornadoWidth;
      var iEndCol:Int = iCol + iTornadoWidth;
      iStartCol = ModchartMath.iClamp(iStartCol, 0, 3);
      iEndCol = ModchartMath.iClamp(iEndCol, 0, 3);

      var fMinX:Float = ModchartMath.FLT_MAX_x32;
      var fMaxX:Float = ModchartMath.FLT_MIN_x32;

      for (i in iStartCol...iEndCol + 1)
      {
        fMinX = Math.min(fMinX, xOffset[i]);
        fMaxX = Math.max(fMaxX, xOffset[i]);
      }

      var fRealPixelOffset:Float = xOffset[iCol] * notefieldZoom;
      var fPositionBetween:Float = ModchartMath.scale(fRealPixelOffset, fMinX * notefieldZoom, fMaxX * notefieldZoom, -1, 1);
      var fRads:Float = Math.acos(fPositionBetween);
      fRads += (fYOffset + getValue('tantornadozoffset') * 100) * ((6 * getValue('tantornadozperiod')) + 6) / SCREEN_HEIGHT;

      var fAdjustedPixelOffset:Float = ModchartMath.scale(selectTanType(fRads, getValue('cosecant')), -1, 1, fMinX * notefieldZoom, fMaxX * notefieldZoom);

      f += (fAdjustedPixelOffset - fRealPixelOffset) * getValue('tantornadoz');
    }

    if (getValue('drunkz') != 0) f += getValue('drunkz') * ModchartMath.fastCos(CalculateDrunkAngle(time, getValue('drunkzspeed'), iCol,
      getValue('drunkzspacing'), 0.2, fYOffset, getValue('drunkzperiod'), 10, getValue('drunkzoffset')),
      getValue('cosclip')) * ARROW_SIZE * 0.5;

    if (getValue('tandrunkz') != 0) f += getValue('tandrunkz') * selectTanType(CalculateDrunkAngle(time, getValue('tandrunkzspeed'), iCol,
      getValue('tandrunkzspacing'), 0.2, fYOffset, getValue('tandrunkzperiod'), 10, getValue('tandrunkzoffset')),
      getValue('cosecant')) * ARROW_SIZE * 0.5;

    if (getValue('drunkz$iCol') != 0) f += getValue('drunkz$iCol') * ModchartMath.fastCos(CalculateDrunkAngle(time, getValue('drunkzspeed$iCol'), iCol,
      getValue('drunkzspacing$iCol'), 0.2, fYOffset, getValue('drunkzperiod$iCol'), 10, getValue('drunkzoffset$iCol')),
      getValue('cosclip')) * ARROW_SIZE * 0.5;

    if (getValue('tandrunkz$iCol') != 0) f += getValue('tandrunkz$iCol') * selectTanType(CalculateDrunkAngle(time, getValue('tandrunkzspeed$iCol'), iCol,
      getValue('tandrunkzspacing$iCol'), 0.2, fYOffset, getValue('tandrunkzperiod$iCol'), 10, getValue('tandrunkzoffset$iCol')),
      getValue('cosecant')) * ARROW_SIZE * 0.5;

    if (getValue('bouncez') != 0)
    {
      var fBounceAmt:Float = Math.abs(ModchartMath.fastSin(((fYOffset + (100.0 * (getValue('bouncezoffset')))) / (60 + (getValue('bouncezperiod') * 60))),
        getValue('sinclip')));

      f += getValue('bouncez') * ARROW_SIZE * 0.5 * fBounceAmt;
    }

    if (getValue('bumpy') != 0) f += getValue('bumpy') * 40 * ModchartMath.fastSin(CalculateBumpyAngle(fYOffset, getValue('bumpyoffset'),
      getValue('bumpyperiod')), getValue('sinclip'));

    if (getValue('tanbumpy') != 0) f += getValue('tanbumpy') * 40 * selectTanType(CalculateBumpyAngle(fYOffset, getValue('tanbumpyoffset'),
      getValue('tanbumpyperiod')), getValue('cosecant'));

    if (getValue('bumpy$iCol') != 0) f += getValue('bumpy$iCol') * 40 * ModchartMath.fastSin(CalculateBumpyAngle(fYOffset, getValue('bumpyoffset$iCol'),
      getValue('bumpyperiod$iCol')), getValue('sinclip'));

    if (getValue('tanbumpy$iCol') != 0) f += getValue('tanbumpy$iCol') * 40 * selectTanType(CalculateBumpyAngle(fYOffset, getValue('tanbumpyoffset$iCol'),
      getValue('tanbumpyperiod$iCol')), getValue('cosecant'));

    if (getValue('beatz') != 0)
    {
      do
      {
        var fAccelTime:Float = 0.2;
        var fTotalTime:Float = 0.5;
        var fBeat:Float = ((getBeat() + fAccelTime + getValue('beatzoffset')) * (getValue('beatzmult') + 1));
        var bEvenBeat:Bool = (Std.int(fBeat) % 2) != 0;
        var beatFactor:Float = 0;
        if (fBeat < 0) break;
        fBeat -= ModchartMath.trunc(fBeat);
        fBeat += 1;
        fBeat -= ModchartMath.trunc(fBeat);
        if (fBeat >= fTotalTime) break;
        if (fBeat < fAccelTime)
        {
          beatFactor = ModchartMath.scale(fBeat, 0.0, fAccelTime, 0.0, 1.0);
          beatFactor *= beatFactor;
        }
        else
        {
          beatFactor = ModchartMath.scale(fBeat, fAccelTime, fTotalTime, 1.0, 0.0);
          beatFactor = 1 - (1 - beatFactor) * (1 - beatFactor);
        }
        if (bEvenBeat) beatFactor *= -1;
        beatFactor *= 20.0;
        var fShift:Float = beatFactor * ModchartMath.fastSin(((fYOffset / (getValue('beatzperiod') * 30.0 + 30.0))) + (Math.PI / 2), getValue('sinclip'));
        f += getValue('beatz') * fShift;
      }
      while (false);
    }

    if (getValue('beatz$iCol') != 0)
    {
      do
      {
        var fAccelTime:Float = 0.2;
        var fTotalTime:Float = 0.5;
        var fBeat:Float = ((getBeat() + fAccelTime + getValue('beatzoffset$iCol')) * (getValue('beatzmult$iCol') + 1));
        var bEvenBeat:Bool = (Std.int(fBeat) % 2) != 0;
        var beatFactor:Float = 0;
        if (fBeat < 0) break;
        fBeat -= ModchartMath.trunc(fBeat);
        fBeat += 1;
        fBeat -= ModchartMath.trunc(fBeat);
        if (fBeat >= fTotalTime) break;
        if (fBeat < fAccelTime)
        {
          beatFactor = ModchartMath.scale(fBeat, 0.0, fAccelTime, 0.0, 1.0);
          beatFactor *= beatFactor;
        }
        else
        {
          beatFactor = ModchartMath.scale(fBeat, fAccelTime, fTotalTime, 1.0, 0.0);
          beatFactor = 1 - (1 - beatFactor) * (1 - beatFactor);
        }
        if (bEvenBeat) beatFactor *= -1;
        beatFactor *= 20.0;
        var fShift:Float = beatFactor * ModchartMath.fastSin(((fYOffset / (getValue('beatzperiod$iCol') * 30.0 + 30.0))) + (Math.PI / 2), getValue('sinclip'));
        f += getValue('beatz$iCol') * fShift;
      }
      while (false);
    }

    if (getValue('digitalz') != 0) f += (getValue('digitalz') * ARROW_SIZE * 0.5) * Math.round((getValue('digitalzsteps') +
      1) * ModchartMath.fastSin(CalculateDigitalAngle(fYOffset, getValue('digitalzoffset'), getValue('digitalzperiod'), getValue('digitalzperiod2'), true),
      getValue('sinclip'))) / (getValue('digitalzsteps') + 1);

    if (getValue('tandigitalz') != 0) f += (getValue('tandigitalz') * ARROW_SIZE * 0.5) * Math.round((getValue('tandigitalzsteps') +
      1) * selectTanType(CalculateDigitalAngle(fYOffset, getValue('tandigitalzoffset'), getValue('tandigitalzperiod'), getValue('tandigitalzperiod2'), true),
      getValue('cosecant'))) / (getValue('tandigitalzsteps') + 1);

    if (getValue('zigzagz') != 0)
    {
      var fResult:Float = ModchartMath.triangle((Math.PI * (1 / (getValue('zigzagzperiod') + 1)) * ((fYOffset +
        (100.0 * (getValue('zigzagzoffset')))) / ARROW_SIZE)));

      f += (getValue('zigzagz') * ARROW_SIZE / 2) * fResult;
    }

    if (getValue('zigzagz$iCol') != 0)
    {
      var fResult:Float = ModchartMath.triangle((Math.PI * (1 / (getValue('zigzagzperiod$iCol') + 1)) * ((fYOffset +
        (100.0 * (getValue('zigzagzoffset$iCol')))) / ARROW_SIZE)));

      f += (getValue('zigzagz$iCol') * ARROW_SIZE / 2) * fResult;
    }

    if (getValue('sawtoothz') != 0) f += (getValue('sawtoothz') * ARROW_SIZE) * ((0.5 / (getValue('sawtoothzperiod') + 1) * (fYOffset
      + 100.0 * getValue('sawtoothzoffset'))) / ARROW_SIZE
      - Math.floor((0.5 / (getValue('sawtoothperiod') + 1) * (fYOffset + 100.0 * getValue('sawtoothzoffset'))) / ARROW_SIZE));

    if (getValue('sawtoothz$iCol') != 0) f += (getValue('sawtoothz$iCol') * ARROW_SIZE) * ((0.5 / (getValue('sawtoothzperiod$iCol') + 1) * (fYOffset
      + 100.0 * getValue('sawtoothzoffset$iCol'))) / ARROW_SIZE
      - Math.floor((0.5 / (getValue('sawtoothperiod$iCol') + 1) * (fYOffset + 100.0 * getValue('sawtoothzoffset$iCol'))) / ARROW_SIZE));

    if (getValue('squarez') != 0)
    {
      var nITGPeriod:Float = Math.PI * (1 + getValue('period2')) - 1;
      if (getValue('squarezperiod2') == 0) nITGPeriod == 0;
      var fResult:Float = ModchartMath.square((Math.PI * (fYOffset + (100.0 * (getValue('squarezoffset')))) / (ARROW_SIZE
        + ((getValue('squarezperiod') + nITGPeriod) * ARROW_SIZE))));

      f += (getValue('squarez') * ARROW_SIZE * 0.5) * fResult;
    }

    if (getValue('parabolaz') != 0) f += getValue('parabolaz') * ((fYOffset + 2 * getValue('parabolazoffset')) / ARROW_SIZE) * ((fYOffset
      + 2 * getValue('parabolazoffset')) / ARROW_SIZE);

    if (getValue('attenuatez') != 0) f += getValue('attenuatez') * ((fYOffset + 100 * getValue('attenuatezoffset')) / ARROW_SIZE) * ((fYOffset
      + 100 * getValue('attenuatezoffset')) / ARROW_SIZE) * (xOffset[iCol] / ARROW_SIZE);

    if (getValue('tipsyz') != 0) f += getValue('tipsyz') * CalculateTipsyOffset(time, getValue('tipsyzspacing'), getValue('tipsyzspeed'), iCol,
      getValue('tipsyzoffset'));

    if (getValue('tantipsyz') != 0) f += getValue('tantipsyz') * CalculateTipsyOffset(time, getValue('tantipsyzspacing'), getValue('tantipsyzspeed'), iCol,
      getValue('tantipsyzoffset'), 1);

    if (getValue('spiralz') != 0) f += fYOffset * getValue('spiralz') * ModchartMath.fastCos((fYOffset + getValue('spiralzoffset')) * (1
      + getValue('spiralzperiod')));

    if (getValue('cubicz') != 0)
    {
      f += Math.pow((fYOffset + 2 * getValue('cubiczoffset')) / ARROW_SIZE, 3) * 2 * getValue('cubicz');
    }
    return f;
  }

  public function GetRotationZ(iCol:Int, fYOffset:Float, noteBeat:Float, isHoldHead:Bool = false, travelDir:Float, isHoldBody:Bool = false):Float
  {
    var fRotation:Float = 0;
    var beat:Float = getBeat();
    if (!isHoldHead)
    {
      if (getValue('confusion$iCol') != 0) fRotation += getValue('confusion$iCol') * 180.0 / Math.PI;

      if (getValue('confusionoffset') != 0) fRotation += getValue('confusionoffset') * 180.0 / Math.PI;

      if (getValue('confusionoffset$iCol') != 0) fRotation += getValue('confusionoffset$iCol') * 180.0 / Math.PI;

      if (getValue('confusion') != 0)
      {
        var fConfRotation:Float = beat;
        fConfRotation *= getValue('confusion');
        fConfRotation = ModchartMath.mod(fConfRotation, 2 * Math.PI);
        fConfRotation *= -180 / Math.PI;
        fRotation += fConfRotation;
      }
    }
    if (getValue('dizzy') != 0 && (getValue('dizzyholds') != 0 || !isHoldHead))
    {
      var fDizzyRotation = noteBeat - beat;
      fDizzyRotation *= getValue('dizzy');
      fDizzyRotation = ModchartMath.mod(fDizzyRotation, 2 * Math.PI);
      fDizzyRotation *= 180 / Math.PI;
      fRotation += fDizzyRotation;
    }
    if (getValue('dizzy$iCol') != 0 && (getValue('dizzyholds') != 0 || !isHoldHead))
    {
      var fDizzyRotation = noteBeat - beat;
      fDizzyRotation *= getValue('dizzy$iCol');
      fDizzyRotation = ModchartMath.mod(fDizzyRotation, 2 * Math.PI);
      fDizzyRotation *= 180 / Math.PI;
      fRotation += fDizzyRotation;
    }
    if (getValue('orient') != 0 && !isHoldBody)
    {
      var reorient:Float = (GetReversePercentForColumn(iCol) > 0.5 ? -1 : 1);
      var value:Float = (ModchartMath.deg * travelDir - 90 * (getValue('noreorient') == 0 ? reorient : 1) - 55 * getValue('orientoffset'));
      fRotation += value * getValue('orient');
    }
    return fRotation;
  }

  public function GetRotationX(iCol:Int, fYOffset:Float, isHoldHead:Bool = false, travelDir:Float):Float
  {
    var fRotation:Float = 0;
    var beat:Float = getBeat();
    if (!isHoldHead)
    {
      if (getValue('confusionx$iCol') != 0) fRotation += getValue('confusionx$iCol') * 180.0 / Math.PI;

      if (getValue('confusionxoffset') != 0) fRotation += getValue('confusionxoffset') * 180.0 / Math.PI;

      if (getValue('confusionxoffset$iCol') != 0) fRotation += getValue('confusionxoffset$iCol') * 180.0 / Math.PI;

      if (getValue('confusionx') != 0)
      {
        var fConfRotation:Float = beat;
        fConfRotation *= getValue('confusionx');
        fConfRotation = ModchartMath.mod(fConfRotation, 2 * Math.PI);
        fConfRotation *= -180 / Math.PI;
        fRotation += fConfRotation;
      }
    }
    if (getValue('roll') != 0)
    {
      fRotation += getValue('roll') * fYOffset / 2;
    }
    if (getValue('roll$iCol') != 0)
    {
      fRotation += getValue('roll$iCol') * fYOffset / 2;
    }
    if (getValue('orientx') != 0 && !isHoldHead)
    {
      var reorient:Float = (GetReversePercentForColumn(iCol) > 0.5 ? -1 : 1);
      var value:Float = (ModchartMath.deg * travelDir - 90 * (getValue('noreorientx') == 0 ? reorient : 1) - 55 * getValue('orientxoffset'));
      fRotation += value * getValue('orientx');
    }
    return fRotation;
  }

  public function GetRotationY(iCol:Int, fYOffset:Float, isHoldHead:Bool = false, travelDir:Float):Float
  {
    var fRotation:Float = 0;
    var beat:Float = getBeat();
    if (!isHoldHead)
    {
      if (getValue('confusiony$iCol') != 0) fRotation += getValue('confusiony$iCol') * 180.0 / Math.PI;

      if (getValue('confusionyoffset') != 0) fRotation += getValue('confusionyoffset') * 180.0 / Math.PI;

      if (getValue('confusionyoffset$iCol') != 0) fRotation += getValue('confusionyoffset$iCol') * 180.0 / Math.PI;

      if (getValue('confusiony') != 0)
      {
        var fConfRotation:Float = beat;
        fConfRotation *= getValue('confusiony');
        fConfRotation = ModchartMath.mod(fConfRotation, 2 * Math.PI);
        fConfRotation *= -180 / Math.PI;
        fRotation += fConfRotation;
      }
    }
    if (getValue('twirl') != 0)
    {
      fRotation += getValue('twirl') * fYOffset / 2;
    }
    if (getValue('twirl$iCol') != 0)
    {
      fRotation += getValue('twirl$iCol') * fYOffset / 2;
    }
    if (getValue('orienty') != 0 && !isHoldHead)
    {
      var reorient:Float = (GetReversePercentForColumn(iCol) > 0.5 ? -1 : 1);
      var value:Float = (ModchartMath.deg * travelDir - 90 * (getValue('noreorienty') == 0 ? reorient : 1) - 55 * getValue('orientyoffset'));
      fRotation += value * getValue('orienty');
    }
    return fRotation;
  }

  public function ReceptorGetRotationZ(iCol:Int, travelDir:Float):Float
  {
    var fRotation:Float = 0;
    var beat:Float = getBeat();
    if (getValue('confusion$iCol') != 0) fRotation += getValue('confusion$iCol') * 180.0 / Math.PI;

    if (getValue('confusionoffset') != 0) fRotation += getValue('confusionoffset') * 180.0 / Math.PI;

    if (getValue('confusionoffset$iCol') != 0) fRotation += getValue('confusionoffset$iCol') * 180.0 / Math.PI;

    if (getValue('confusion') != 0)
    {
      var fConfRotation:Float = beat;
      fConfRotation *= getValue('confusion');
      fConfRotation = ModchartMath.mod(fConfRotation, 2 * Math.PI);
      fConfRotation *= -180 / Math.PI;
      fRotation += fConfRotation;
    }
    if (getValue('orient') != 0)
    {
      var reorient:Float = (GetReversePercentForColumn(iCol) > 0.5 ? -1 : 1);
      var value:Float = (ModchartMath.deg * travelDir - 90 * (getValue('noreorient') == 0 ? reorient : 1) - 55 * getValue('orientoffset'));
      fRotation += value * getValue('orient');
    }
    return fRotation;
  }

  public function ReceptorGetRotationX(iCol:Int, travelDir:Float):Float
  {
    var fRotation:Float = 0;
    var beat:Float = getBeat();
    if (getValue('confusionx$iCol') != 0) fRotation += getValue('confusionx$iCol') * 180.0 / Math.PI;

    if (getValue('confusionxoffset') != 0) fRotation += getValue('confusionxoffset') * 180.0 / Math.PI;

    if (getValue('confusionxoffset$iCol') != 0) fRotation += getValue('confusionxoffset$iCol') * 180.0 / Math.PI;

    if (getValue('confusionx') != 0)
    {
      var fConfRotation:Float = beat;
      fConfRotation *= getValue('confusionx');
      fConfRotation = ModchartMath.mod(fConfRotation, 2 * Math.PI);
      fConfRotation *= -180 / Math.PI;
      fRotation += fConfRotation;
    }
    if (getValue('orientx') != 0)
    {
      var reorient:Float = (GetReversePercentForColumn(iCol) > 0.5 ? -1 : 1);
      var value:Float = (ModchartMath.deg * travelDir - 90 * (getValue('noreorientx') == 0 ? reorient : 1) - 55 * getValue('orientxoffset'));
      fRotation += value * getValue('orientx');
    }
    return fRotation;
  }

  public function ReceptorGetRotationY(iCol:Int, travelDir:Float):Float
  {
    var fRotation:Float = 0;
    var beat:Float = getBeat();
    if (getValue('confusiony$iCol') != 0) fRotation += getValue('confusiony$iCol') * 180.0 / Math.PI;

    if (getValue('confusionyoffset') != 0) fRotation += getValue('confusionyoffset') * 180.0 / Math.PI;

    if (getValue('confusionyoffset$iCol') != 0) fRotation += getValue('confusionyoffset$iCol') * 180.0 / Math.PI;

    if (getValue('confusiony') != 0)
    {
      var fConfRotation:Float = beat;
      fConfRotation *= getValue('confusiony');
      fConfRotation = ModchartMath.mod(fConfRotation, 2 * Math.PI);
      fConfRotation *= -180 / Math.PI;
      fRotation += fConfRotation;
    }
    if (getValue('orienty') != 0)
    {
      var reorient:Float = (GetReversePercentForColumn(iCol) > 0.5 ? -1 : 1);
      var value:Float = (ModchartMath.deg * travelDir - 90 * (getValue('noreorienty') == 0 ? reorient : 1) - 55 * getValue('orientyoffset'));
      fRotation += value * getValue('orienty');
    }
    return fRotation;
  }

  var FADE_DIST_Y:Float = 40;

  function GetHiddenSudden():Float
    return getValue('hidden') * getValue('sudden');

  function GetHiddenEndLine():Float
    return SCREEN_HEIGHT / 2
      + FADE_DIST_Y * ModchartMath.scale(GetHiddenSudden(), 0., 1., -1.0, -1.25)
      + SCREEN_HEIGHT / 2 / (1 - getValue('mini') * 0.5) * getValue('hiddenoffset');

  function GetHiddenStartLine():Float
    return SCREEN_HEIGHT / 2
      + FADE_DIST_Y * ModchartMath.scale(GetHiddenSudden(), 0., 1., 0.0, -0.25)
      + SCREEN_HEIGHT / 2 / (1 - getValue('mini') * 0.5) * getValue('hiddenoffset');

  function GetSuddenEndLine():Float
    return SCREEN_HEIGHT / 2
      + FADE_DIST_Y * ModchartMath.scale(GetHiddenSudden(), 0., 1., -0.0, 0.25)
      + SCREEN_HEIGHT / 2 / (1 - getValue('mini') * 0.5) * getValue('suddenoffset');

  function GetSuddenStartLine():Float
    return SCREEN_HEIGHT / 2
      + FADE_DIST_Y * ModchartMath.scale(GetHiddenSudden(), 0., 1., 1.0, 1.25)
      + SCREEN_HEIGHT / 2 / (1 - getValue('mini') * 0.5) * getValue('suddenoffset');

  public function ArrowGetPercentVisible(fYPosWithoutReverse:Float, iCol:Int, fYOffset:Float, isHoldHead:Bool, isHoldBody:Bool):Float
  {
    var fDistFromCenterLine:Float = fYPosWithoutReverse - SCREEN_HEIGHT * 0.5 / (1 - getValue('mini') * 0.5);

    var fYPos:Float;
    if (getValue('stealthtype') != 0) fYPos = fYOffset;
    else
      fYPos = fYPosWithoutReverse;

    if (fYPos < 0 && getValue('stealthpastreceptors') == 0) return 1;

    var fVisibleAdjust:Float = 0;
    if (getValue('hidden') != 0)
    {
      var fHiddenVisibleAdjust:Float = ModchartMath.scale(fYPos, GetHiddenStartLine(), GetHiddenEndLine(), 0, -1);
      fHiddenVisibleAdjust = ModchartMath.clamp(fHiddenVisibleAdjust, -1, 0);
      fVisibleAdjust += getValue('hidden') * fHiddenVisibleAdjust;
    }
    if (getValue('sudden') != 0)
    {
      var fSuddenVisibleAdjust:Float = ModchartMath.scale(fYPos, GetSuddenStartLine(), GetSuddenEndLine(), -1, 0);
      fSuddenVisibleAdjust = ModchartMath.clamp(fSuddenVisibleAdjust, -1, 0);
      fVisibleAdjust += getValue('sudden') * fSuddenVisibleAdjust;
    }

    if (getValue('stealth') != 0) fVisibleAdjust -= getValue('stealth');
    if (getValue('stealth$iCol') != 0)
    {
      fVisibleAdjust -= getValue('stealth$iCol');
    }
    if (getValue('holdstealth') != 0 && isHoldBody) fVisibleAdjust -= getValue('holdstealth');
    if (getValue('holdstealth$iCol') != 0 && isHoldBody)
    {
      fVisibleAdjust -= getValue('holdstealth$iCol');
    }
    if (getValue('tapstealth') != 0 && !isHoldBody && !isHoldHead) fVisibleAdjust -= getValue('tapstealth');
    if (getValue('tapstealth$iCol') != 0 && !isHoldBody && !isHoldHead)
    {
      fVisibleAdjust -= getValue('tapstealth$iCol');
    }
    if (getValue('holdheadstealth') != 0 && !isHoldBody && isHoldHead) fVisibleAdjust -= getValue('holdheadstealth');
    if (getValue('holdheadstealth$iCol') != 0 && !isHoldBody && isHoldHead) fVisibleAdjust -= getValue('holdheadstealth$iCol');
    if (getValue('blink') != 0)
    {
      var f:Float = ModchartMath.fastSin(getTime() * 10, getValue('sinclip'));
      f = ModchartMath.Quantize(f, 0.3333);
      fVisibleAdjust += ModchartMath.scale(f, 0, 1, -1, 0);
    }
    if (getValue('vanish') != 0)
    {
      var fRealFadeDist:Float = 80 + 80 * getValue('vanishsize');
      fVisibleAdjust += ModchartMath.scale(Math.abs(fDistFromCenterLine + 100 * getValue('vanishoffset')), fRealFadeDist, 2 * fRealFadeDist, -1,
        0) * getValue('vanish');
    }
    return ModchartMath.clamp(1 + fVisibleAdjust, 0, 1);
  }

  function GetHiddenSudden2(s:String):Float
    return getValue('hidden$s') * getValue('sudden$s');

  function GetHiddenEndLine2(s:String):Float
    return SCREEN_HEIGHT / 2
      + FADE_DIST_Y * ModchartMath.scale(GetHiddenSudden2(s), 0., 1., -1.0, -1.25)
      + SCREEN_HEIGHT / 2 / (1 - getValue('mini') * 0.5) * getValue('hidden${s}offset');

  function GetHiddenStartLine2(s:String):Float
    return SCREEN_HEIGHT / 2
      + FADE_DIST_Y * ModchartMath.scale(GetHiddenSudden2(s), 0., 1., 0.0, -0.25)
      + SCREEN_HEIGHT / 2 / (1 - getValue('mini') * 0.5) * getValue('hidden${s}offset');

  function GetSuddenEndLine2(s:String):Float
    return SCREEN_HEIGHT / 2
      + FADE_DIST_Y * ModchartMath.scale(GetHiddenSudden2(s), 0., 1., -0.0, 0.25)
      + SCREEN_HEIGHT / 2 / (1 - getValue('mini') * 0.5) * getValue('sudden${s}offset');

  function GetSuddenStartLine2(s:String):Float
    return SCREEN_HEIGHT / 2
      + FADE_DIST_Y * ModchartMath.scale(GetHiddenSudden2(s), 0., 1., 1.0, 1.25)
      + SCREEN_HEIGHT / 2 / (1 - getValue('mini') * 0.5) * getValue('sudden${s}offset');

  public function ArrowGetPercentRGB(iCol:Int, fYOffset:Float, fYPosWithoutReverse:Float, color:String):Float
  {
    var fYPos:Float;
    if (getValue('stealthtype') != 0) fYPos = fYOffset;
    else
      fYPos = fYPosWithoutReverse;

    if (fYPos < 0 && getValue('stealthpastreceptors') == 0) return 1;
    var fVisibleAdjust:Float = 0;
    if (getValue('hidden$color') != 0)
    {
      var fHiddenVisibleAdjust:Float = ModchartMath.scale(fYPos, GetHiddenStartLine2(color), GetHiddenEndLine2(color), 0, -1);
      fHiddenVisibleAdjust = ModchartMath.clamp(fHiddenVisibleAdjust, -1, 0);
      fVisibleAdjust += getValue('hidden$color') * fHiddenVisibleAdjust;
    }
    if (getValue('sudden$color') != 0)
    {
      var fSuddenVisibleAdjust:Float = ModchartMath.scale(fYPos, GetSuddenStartLine2(color), GetSuddenEndLine2(color), -1, 0);
      fSuddenVisibleAdjust = ModchartMath.clamp(fSuddenVisibleAdjust, -1, 0);
      fVisibleAdjust += getValue('sudden$color') * fSuddenVisibleAdjust;
    }

    if (getValue('stealth$color') != 0) fVisibleAdjust -= getValue('stealth$color');

    if (getValue('blink$color') != 0)
    {
      var f:Float = ModchartMath.fastSin(getTime() * 10, getValue('sinclip'));
      f = ModchartMath.Quantize(f, 0.3333);
      fVisibleAdjust += ModchartMath.scale(f, 0, 1, -1, 0);
    }
    var alpha:Float = ModchartMath.clamp(1 + fVisibleAdjust, 0, 1);
    return ModchartMath.clamp(ModchartMath.scale(alpha, 0.5, 0, 1, 0), 0, 1);
  }

  public function GetAlpha(fYPosWithoutReverse:Float, iCol:Int, fYOffset:Float, isHoldHead:Bool, isHoldBody:Bool):Float
  {
    var fPercentVisible:Float = ArrowGetPercentVisible(fYPosWithoutReverse, iCol, fYOffset, isHoldHead, isHoldBody);
    var fDrawDistanceBeforeTargetsPixels:Float = SCREEN_HEIGHT;
    var fFullAlphaY:Float = fDrawDistanceBeforeTargetsPixels;
    if (fYPosWithoutReverse > fFullAlphaY)
    {
      var f = ModchartMath.scale(fYPosWithoutReverse, fFullAlphaY, fDrawDistanceBeforeTargetsPixels, 1.0, 0.0);
      return f;
    }
    return ModchartMath.clamp(ModchartMath.scale(fPercentVisible, 0.5, 0, 1, 0), 0, 1);
  }

  public function GetGlow(fYPosWithoutReverse:Float, iCol:Int, fYOffset:Float, isHoldHead:Bool, isHoldBody:Bool):Float
  {
    var fPercentVisible:Float = ArrowGetPercentVisible(fYPosWithoutReverse, iCol, fYOffset, isHoldHead, isHoldBody);
    var fPercentFadeToFail:Float = -1;
    if (fPercentFadeToFail != -1) fPercentVisible = 1 - fPercentFadeToFail;
    var fDistFromHalf:Float = Math.abs(fPercentVisible - 0.5);
    return ModchartMath.scale(fDistFromHalf, 0, 0.5, 1.3, 0);
  }

  public function GetScale(iCol:Int, fYOffset:Float, pn:Int, defaultScale:Array<Float>, isHoldBody:Bool = false, isNote:Bool = false):Array<Float>
  {
    var x:Float = defaultScale[0];
    var y:Float = defaultScale[1];
    var z:Float = 1;

    x *= getValue('scale') * getValue('scale$iCol') * getValue('scalex$iCol') * getValue('scalex');

    if (!isHoldBody) y *= getValue('scale') * getValue('scale$iCol') * getValue('scaley$iCol') * getValue('scaley');

    z *= getValue('scale') * getValue('scale$iCol') * getValue('scalez$iCol') * getValue('scalez');

    // notitg's tinyx tinyy mod
    x *= Math.pow(0.5, getValue('tinyx'));
    x *= Math.pow(0.5, getValue('tinyx$iCol'));
    if (!isHoldBody)
    {
      y *= Math.pow(0.5, getValue('tinyy'));
      y *= Math.pow(0.5, getValue('tinyy$iCol'));
    }
    z *= Math.pow(0.5, getValue('tinyz'));
    z *= Math.pow(0.5, getValue('tinyz$iCol'));
    if (isHoldBody)
    {
      x *= Math.pow(0.5, getValue('holdtinyx'));
      x *= Math.pow(0.5, getValue('holdtinyx$iCol'));
      x *= Math.pow(0.5, -getValue('holdgirth'));
      x *= Math.pow(0.5, -getValue('holdgirth$iCol'));
    }
    if (getValue('shrinkmultx') != 0 && fYOffset >= 0) x *= 1 / (1 + (fYOffset * (getValue('shrinkmultx') / 100.0)));
    if (getValue('shrinklinearx') != 0 && fYOffset >= 0) x += fYOffset * (0.5 * getValue('shrinklinearx') / ARROW_SIZE);
    if (getValue('shrinkmulty') != 0 && fYOffset >= 0) y *= 1 / (1 + (fYOffset * (getValue('shrinkmulty') / 100.0)));
    if (getValue('shrinklineary') != 0 && fYOffset >= 0) y += fYOffset * (0.5 * getValue('shrinklineary') / ARROW_SIZE);
    if (getValue('shrinkmultz') != 0 && fYOffset >= 0) z *= 1 / (1 + (fYOffset * (getValue('shrinkmultz') / 100.0)));
    if (getValue('shrinklinearz') != 0 && fYOffset >= 0) z += fYOffset * (0.5 * getValue('shrinklinearz') / ARROW_SIZE);
    // skewx skewy
    var skewx:Float = 0;
    var skewy:Float = 0;
    if (!isHoldBody && isNote)
    {
      skewx += getValue('noteskewx') + getValue('noteskewx$iCol');
      skewy += getValue('noteskewy') + getValue('noteskewy$iCol');
      if (getValue('noteskewtype') != 0)
      {
        if (iCol == 0 || iCol == 3)
        {
          skewx *= -1;
          skewy *= -1;
        }
      }
    }
    return [x, y, skewx, skewy, z];
  }

  public function GetZoom(iCol:Int, fYOffset:Float, pn:Int):Float
  {
    var fZoom:Float = 1;
    var fPulseInner:Float = 1.0;

    if (getValue('pulseinner') != 0 || getValue('pulseouter') != 0 || getValue('pulse') != 0)
    {
      var inner:Float = getValue('pulseinner') == 0 ? getValue('pulse') : getValue('pulseinner');
      fPulseInner = ((inner * 0.5) + 1);
      if (fPulseInner == 0) fPulseInner = 0.01;
    }

    if (getValue('pulseinner') != 0 || getValue('pulseouter') != 0 || getValue('pulse') != 0)
    {
      var outer:Float = getValue('pulseouter') == 0 ? getValue('pulse') : getValue('pulseouter');
      var sine:Float = ModchartMath.fastSin(((fYOffset + (100.0 * (getValue('pulseoffset')))) / (0.4 * (ARROW_SIZE + (getValue('pulseperiod') * ARROW_SIZE)))),
        getValue('sinclip'));

      fZoom *= (sine * (outer * 0.5)) + fPulseInner;
    }

    if (getValue('tanpulseinner') != 0 || getValue('tanpulseouter') != 0 || getValue('tanpulse') != 0)
    {
      var inner:Float = getValue('tanpulseinner') == 0 ? getValue('tanpulse') : getValue('tanpulseinner');
      fPulseInner = ((inner * 0.5) + 1);
      if (fPulseInner == 0) fPulseInner = 0.01;
    }

    if (getValue('tanpulseinner') != 0 || getValue('tanpulseouter') != 0 || getValue('tanpulse') != 0)
    {
      var outer:Float = getValue('tanpulseouter') == 0 ? getValue('tanpulse') : getValue('tanpulseouter');
      var sine:Float = selectTanType(((fYOffset + (100.0 * (getValue('tanpulseoffset')))) / (0.4 * (ARROW_SIZE + (getValue('tanpulseperiod') * ARROW_SIZE)))),
        getValue('cosecant'));

      fZoom *= (sine * (outer * 0.5)) + fPulseInner;
    }

    if (getValue('shrinkmult') != 0 && fYOffset >= 0) fZoom *= 1 / (1 + (fYOffset * (getValue('shrinkmult') / 100.0)));

    if (getValue('shrinklinear') != 0 && fYOffset >= 0) fZoom += fYOffset * (0.5 * getValue('shrinklinear') / ARROW_SIZE);

    if (getValue('tiny') != 0)
    {
      var fTinyPercent = getValue('tiny');
      fTinyPercent = Math.pow(0.5, fTinyPercent);
      fZoom *= fTinyPercent;
    }
    if (getValue('tiny$iCol') != 0)
    {
      var fTinyPercent = Math.pow(0.5, getValue('tiny$iCol'));
      fZoom *= fTinyPercent;
    }
    return fZoom;
  }

  // control full playfield
  // it's like Player.cpp

  @:nullSafety
  public function modifyPos(pos:Vector3D, scale:Vector3D, rotation:Vector3D, skew:Vector3D, xoff:Array<Float>, yReversedOffset:Float, iCol:Int):Void
  {
    if (getValue('rotationx') != 0 || getValue('rotationy') != 0 || getValue('rotationz') != 0)
    {
      var originPos:Vector3D = new Vector3D(0, yReversedOffset / 2);
      var s:Vector3D = pos.subtract(originPos);
      var out:Vector3D = ModchartMath.rotateVec3(s, getValue('rotationx') * 100, getValue('rotationy') * 100, getValue('rotationz') * 100);
      var newpos:Vector3D = out.add(originPos);
      pos.x = newpos.x;
      pos.y = newpos.y;
      pos.z = newpos.z;
      rotation.x += getValue('rotationx') * 100;
      rotation.y += getValue('rotationy') * 100;
      rotation.z += getValue('rotationz') * 100;
    }
    if (getValue('x') != 0) pos.x += getValue('x') * ARROW_SIZE * 1.5625; // cuz 320% x = 500% movex
    if (getValue('y') != 0) pos.y += getValue('y') * ARROW_SIZE * 1.5625;
    if (getValue('z') != 0) pos.z += getValue('z') * ARROW_SIZE * 1.5625;
    if (getValue('skewx') != 0)
    {
      skew.x += getValue('skewx');
      pos.x -= 2 * ARROW_SIZE * getValue('skewx');
    }
    if (getValue('skewy') != 0)
    {
      skew.y += getValue('skewy');
      pos.y -= 2 * ARROW_SIZE * getValue('skewy');
    }
    if (getValue('zoomx') != 0)
    {
      scale.x *= getValue('zoomx');
      pos.x *= getValue('zoomx');
    }
    if (getValue('zoomy') != 0)
    {
      scale.y *= getValue('zoomy');
      pos.y -= ARROW_SIZE * (getValue('zoomy') - 1);
    }
    if (getValue('zoomz') != 0)
    {
      scale.z *= getValue('zoomz');
      // pos.z *= getValue('zoomz');
    }
    if (getValue('zoom') != 0)
    {
      scale.x *= getValue('zoom');
      pos.x *= getValue('zoom');
      scale.y *= getValue('zoom');
      pos.y -= ARROW_SIZE * (getValue('zoom') - 1);
      scale.z *= getValue('zoom');
      // pos.z *= getValue('zoom');
    }
    var fTilt:Float = 0;
    var fSkew:Float = 0;
    if (getValue('incoming') != 0)
    {
      fTilt = -getValue('incoming');
      fSkew = getValue('incoming');
    }
    if (getValue('space') != 0)
    {
      fTilt = getValue('space');
      fSkew = getValue('space');
    }
    if (getValue('hallway') != 0)
    {
      fTilt = -getValue('hallway');
    }
    if (getValue('distant') != 0)
    {
      fTilt = getValue('distant');
    }
    if (getValue('overhead') != 0)
    {
      fTilt = 0;
      fSkew = 0;
    }
    var reverse_mult:Float = (GetReversePercentForColumn(iCol) > 0.5 ? -1 : 1);
    var tilt_degrees:Float = ModchartMath.scale(fTilt, -1., 1., 30, -30) * reverse_mult;
    var zoom:Float = ModchartMath.scale(getValue('mini'), 0., 1., 1., .5);
    var y_offset:Float = 0;
    if (fTilt > 0)
    {
      zoom *= ModchartMath.scale(fTilt, 0., 1., 1., 0.9);
      y_offset = ModchartMath.scale(fTilt, 0., 1., 0., -45.) * reverse_mult;
    }
    else
    {
      zoom *= ModchartMath.scale(fTilt, 0., -1., 1., 0.9);
      y_offset = ModchartMath.scale(fTilt, 0., -1., 0., -20.) * reverse_mult;
    }
    pos.y += y_offset;
    pos.x *= zoom;
    pos.y *= zoom;
    scale.x *= zoom;
    scale.y *= zoom;
    skew.z = fSkew;
    rotation.x += tilt_degrees;
  }

  public var opened:Bool = false;

  public function new()
  {
    initDefaultMods();
    opened = true;
  }
}
