package funkin.ui.charSelect;

import funkin.graphics.adobeanimate.FlxAtlasSprite;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;
import funkin.util.FramesJSFLParser;
import funkin.util.FramesJSFLParser.FramesJSFLInfo;
import funkin.util.FramesJSFLParser.FramesJSFLFrame;
import flixel.math.FlxMath;
import funkin.vis.dsp.SpectralAnalyzer;

class CharSelectGF extends FlxAtlasSprite
{
  var fadeTimer:Float = 0;
  var fadingStatus:FadeStatus = OFF;
  var fadeAnimIndex:Int = 0;

  var animInInfo:FramesJSFLInfo;
  var animOutInfo:FramesJSFLInfo;

  var intendedYPos:Float = 0;
  var intendedAlpha:Float = 0;
  var list:Array<String> = [];
  var char:String = "gf";

  var analyzer:SpectralAnalyzer;

  public function new()
  {
    super(0, 0, Paths.animateAtlas("charSelect/gfChill"));
    anim.play("");
    list = anim.curSymbol.getFrameLabelNames();

    switchGF("bf");
  }

  var _addedCallback:String = "";

  override public function playAnimation(id:String, restart:Bool = false, ignoreOther:Bool = false, loop:Bool = false, startFrame:Int = 0):Void
  {
    if (id == null) id = "idle";
    // var fr = anim.getFrameLabel("confirm");
    // fr.removeCallbacks();
    // fr.add(() -> trace("HEY"));

    if (id != _addedCallback)
    {
      var next = list[list.indexOf(_addedCallback) + 1];
      if (next != null) anim.getFrameLabel(next).removeCallbacks();

      var index:Int = list.indexOf(id);

      _addedCallback = list[index];
      if (index != -1 && index + 1 < list.length)
      {
        var lb = anim.getFrameLabel(list[index + 1]);
        @:privateAccess
        lb.add(() -> playAnimation(list[index], true, false, false));
      }
    }
    super.playAnimation(id, restart, ignoreOther, loop, startFrame);
  }

  override public function update(elapsed:Float)
  {
    super.update(elapsed);

    switch (fadingStatus)
    {
      case OFF:
        // do nothing if it's off!
        // or maybe force position to be 0,0?
        // maybe reset timers?
        resetFadeAnimParams();
      case FADE_OUT:
        doFade(animOutInfo);
      case FADE_IN:
        doFade(animInInfo);
      default:
    }

    if (FlxG.keys.justPressed.J)
    {
      alpha = 1;
      x = y = 0;
      fadingStatus = FADE_OUT;
    }
    if (FlxG.keys.justPressed.K)
    {
      alpha = 0;
      fadingStatus = FADE_IN;
    }
  }

  override public function draw()
  {
    if (analyzer != null) drawFFT();
    super.draw();
  }

  function drawFFT()
  {
    if (char == "nene")
    {
      var levels = analyzer.getLevels();
      var frame = anim.curSymbol.timeline.get("VIZ_bars").get(anim.curFrame);
      var elements = frame.getList();
      var len:Int = cast Math.min(elements.length, 7);

      for (i in 0...len)
      {
        var animFrame:Int = Math.round(levels[i].value * 12);

        #if desktop
        animFrame = Math.round(animFrame * FlxG.sound.volume);
        #end

        animFrame = Math.floor(Math.min(12, animFrame));
        animFrame = Math.floor(Math.max(0, animFrame));

        animFrame = Std.int(Math.abs(animFrame - 12)); // shitty dumbass flip, cuz dave got da shit backwards lol!

        elements[i].symbol.firstFrame = animFrame;
      }
    }
  }

  /**
   * @param animInfo Should not be confused with animInInfo!
   *                 This is merely a local var for the function!
   */
  function doFade(animInfo:FramesJSFLInfo)
  {
    fadeTimer += FlxG.elapsed;
    if (fadeTimer >= 1 / 24)
    {
      fadeTimer = 0;
      // only inc the index for the first frame, used for reference of where to "start"
      if (fadeAnimIndex == 0)
      {
        fadeAnimIndex++;
        return;
      }

      var curFrame:FramesJSFLFrame = animInfo.frames[fadeAnimIndex];
      var prevFrame:FramesJSFLFrame = animInfo.frames[fadeAnimIndex - 1];

      var xDiff:Float = curFrame.x - prevFrame.x;
      var yDiff:Float = curFrame.y - prevFrame.y;
      var alphaDiff:Float = curFrame.alpha - prevFrame.alpha;
      alphaDiff /= 100; // flash exports alpha as a whole number

      alpha += alphaDiff;
      alpha = FlxMath.bound(alpha, 0, 1);
      x += xDiff;
      y += yDiff;

      fadeAnimIndex++;
    }

    if (fadeAnimIndex >= animInfo.frames.length) fadingStatus = OFF;
  }

  function resetFadeAnimParams()
  {
    fadeTimer = 0;
    fadeAnimIndex = 0;
  }

  public function switchGF(str:String)
  {
    str = switch (str)
    {
      case "pico":
        "nene";
      case "bf":
        "gf";
      default:
        "gf";
    }

    char = str;
    switch str
    {
      default:
        loadAtlas(Paths.animateAtlas("charSelect/" + str + "Chill"));
    }

    animInInfo = FramesJSFLParser.parse(Paths.file("images/charSelect/" + str + "AnimInfo/" + str + "In.txt"));
    animOutInfo = FramesJSFLParser.parse(Paths.file("images/charSelect/" + str + "AnimInfo/" + str + "Out.txt"));

    anim.play("");
    playAnimation("idle", true, false, false);
    addFrameCallback(getNextFrameLabel("idle"), () -> playAnimation("idle", true, false, false));

    updateHitbox();
  }
}

enum FadeStatus
{
  OFF;
  FADE_OUT;
  FADE_IN;
}
