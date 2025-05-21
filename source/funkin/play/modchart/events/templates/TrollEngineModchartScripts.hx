package funkin.play.modchart.events.templates;

import funkin.play.modchart.events.ModEvents;
import funkin.play.modchart.events.ModEases;
import funkin.play.modchart.events.ModEases.Ease;
import funkin.play.modchart.Modchart;
import funkin.play.modchart.util.ModchartMath;

/**
 * Just do it for fun
 */
class TrollEngineModchartScripts
{
  var modEvents:ModEvents;
  var modState:Array<Modchart>;
  var eases:Map<String, Ease> = [
    'instant' => ModEases.instant,
    'linear' => ModEases.linear,
    'quadin' => ModEases.inQuad,
    'quadout' => ModEases.outQuad,
    'quadinout' => ModEases.inOutQuad,
    'cubein' => ModEases.inCubic,
    'cubeout' => ModEases.outCubic,
    'cubeinout' => ModEases.inOutCubic,
    'quartin' => ModEases.inQuart,
    'quartout' => ModEases.outQuart,
    'quartinout' => ModEases.inOutQuart,
    'quintin' => ModEases.inQuint,
    'quintout' => ModEases.outQuint,
    'quintinout' => ModEases.inOutQuint,
    'expoin' => ModEases.inExpo,
    'expoout' => ModEases.outExpo,
    'expoinout' => ModEases.inOutExpo,
    'circin' => ModEases.inCirc,
    'circout' => ModEases.outCirc,
    'circinout' => ModEases.inOutCirc,
    'bouncein' => ModEases.inBounce,
    'bounceout' => ModEases.outBounce,
    'bounceinout' => ModEases.inOutBounce,
    'sinein' => ModEases.inSine,
    'sineout' => ModEases.outSine,
    'sineinout' => ModEases.inOutSine,
    'elasticin' => ModEases.inElastic,
    'elasticout' => ModEases.outElastic,
    'elasticinout' => ModEases.inOutElastic,
    'backin' => ModEases.inBack,
    'backout' => ModEases.outBack,
    'backinout' => ModEases.inOutBack,
    'smoothstepin' => ModEases.inSmoothStep,
    'smoothstepout' => ModEases.outSmoothStep,
    'smoothstepinout' => ModEases.inOutSmoothStep,
    'smootherstepin' => ModEases.inSmootherStep,
    'smootherstepout' => ModEases.outSmootherStep,
    'smootherstepinout' => ModEases.inOutSmootherStep
  ];

  function getEaseByString(ease:String)
    return eases.get(ease.toLowerCase());

  public function new(mEvents:ModEvents, state:Array<Modchart>)
  {
    this.modEvents = mEvents;
    this.modState = state;
  }

  public function getValue(mod:String, plr:Int):Float
    return modState[plr].getValue(mod);

  public function getPercent(mod:String, plr:Int):Float
    return getValue(mod, plr) * 100;

  public function setValue(mod:String, val:Float, plr:Int = -1)
  {
    if (plr == -1)
    {
      for (i in 0...2)
        modState[i].setValue(mod, val);
    }
    else
    {
      plr = ModchartMath.iClamp(plr, 0, 1);
      modState[plr].setValue(mod, val);
    }
  }

  public function setPercent(mod:String, val:Float, plr:Int = -1)
    setValue(mod, val / 100, plr);

  public function queueEase(step:Float, endStep:Float, modName:String, target:Float, style:Any, player:Int = -1, ?startVal:Float)
  {
    var easeFunc = ModEases.linear;

    if (style == null) {}
    else if (style is String)
    {
      easeFunc = getEaseByString(style);
    }
    else if (Reflect.isFunction(style))
    {
      easeFunc = style;
    }
    if (player == -1)
    {
      modEvents.ease(step / 4, endStep / 4, easeFunc, [target, modName], {mode: 'end', startVal: (startVal != null ? startVal : null)});
    }
    else
    {
      player = ModchartMath.iClamp(player, 0, 1);
      modEvents.ease(step / 4, endStep / 4, easeFunc, [target, modName], {mode: 'end', plr: [player], startVal: (startVal != null ? startVal : null)});
    }
  }

  public function queueSet(step:Float, modName:String, target:Float, player:Int = -1)
  {
    if (player == -1) modEvents.set(step / 4, [target, modName]);
    else
    {
      player = ModchartMath.iClamp(player, 0, 1);
      modEvents.set(step / 4, [target, modName], {plr: [player]});
    }
  }

  inline public function queueEaseL(step:Float, length:Float, modName:String, value:Float, style:Dynamic = 'linear', player = -1, ?startVal:Float)
    queueEase(step, step + length, modName, value, style, player, startVal);

  inline public function queueEaseLB(beat:Float, length:Float, modName:String, value:Float, style:Dynamic = 'linear', player = -1, ?startVal:Float)
    queueEase(beat * 4, (beat + length) * 4, modName, value, style, player, startVal);

  inline public function queueEaseB(beat:Float, endBeat:Float, modName:String, value:Float, style:Dynamic = 'linear', player = -1, ?startVal:Float)
    queueEase(beat * 4, endBeat * 4, modName, value, style, player, startVal);

  inline public function queueSetB(beat:Float, modName:String, value:Float, player = -1)
    queueSet(beat * 4, modName, value, player);

  public function queueEaseP(step:Float, endStep:Float, modName:String, percent:Float, style:Dynamic = 'linear', player:Int = -1, ?startVal:Float)
    queueEase(step, endStep, modName, percent * 0.01, style, player, startVal * 0.01);

  public function queueSetP(step:Float, modName:String, percent:Float, player:Int = -1)
    queueSet(step, modName, percent * 0.01, player);

  public function queueFunc(step:Float, endStep:Float, callback:(Float) -> Void)
    modEvents.func([step / 4, endStep / 4, callback], {mode: 'end'});

  public function queueFuncL(step:Float, length:Float, callback:(Float) -> Void)
    modEvents.func([step / 4, length / 4, callback]);

  public function queueFuncB(beat:Float, endBeat:Float, callback:(Float) -> Void)
    modEvents.func([beat, endBeat, callback], {mode: 'end'});

  public function queueFuncLB(beat:Float, length:Float, callback:(Float) -> Void)
    modEvents.func([beat, length, callback]);

  public function queueFuncOnce(step:Float, callback:(Float) -> Void)
    modEvents.func([step / 4, callback]);

  public function queueEaseFunc(step:Float, endStep:Float, func:Float->Float, callback:(Float, Float) -> Void)
    modEvents.func([step / 4, endStep / 4, ModEases.linear, callback], {mode: 'end'});

  public function queueEaseFuncL(step:Float, length:Float, func:Float->Float, callback:(Float, Float) -> Void)
    modEvents.func([step / 4, length / 4, ModEases.linear, callback]);

  public function queueEaseFuncB(beat:Float, endBeat:Float, func:Float->Float, callback:(Float, Float) -> Void)
    modEvents.func([beat, endBeat, ModEases.linear, callback], {mode: 'end'});

  public function queueEaseFuncLB(beat:Float, length:Float, func:Float->Float, callback:(Float, Float) -> Void)
    modEvents.func([beat, length, ModEases.linear, callback]);
}
