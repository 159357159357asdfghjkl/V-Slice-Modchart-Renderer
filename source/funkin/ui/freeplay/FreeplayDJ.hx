package funkin.ui.freeplay;

import flixel.FlxSprite;
import flixel.util.FlxSignal;
import funkin.util.assets.FlxAnimationUtil;
import funkin.graphics.adobeanimate.FlxAtlasSprite;
import funkin.audio.FunkinSound;
import flixel.util.FlxTimer;
import funkin.data.freeplay.player.PlayerRegistry;
import funkin.data.freeplay.player.PlayerData.PlayerFreeplayDJData;
import funkin.audio.FunkinSound;
import funkin.audio.FlxStreamSound;

class FreeplayDJ extends FlxAtlasSprite
{
  // Represents the sprite's current status.
  // Without state machines I would have driven myself crazy years ago.
  public var currentState:DJBoyfriendState = Intro;

  // A callback activated when the intro animation finishes.
  public var onIntroDone:FlxSignal = new FlxSignal();

  // A callback activated when the idle easter egg plays.
  public var onIdleEasterEgg:FlxSignal = new FlxSignal();

  var seenIdleEasterEgg:Bool = false;

  static final IDLE_EGG_PERIOD:Float = 60.0;
  static final IDLE_CARTOON_PERIOD:Float = 120.0;

  // Time since last special idle animation you.
  var timeIdling:Float = 0;

  final characterId:String = Constants.DEFAULT_CHARACTER;
  final playableCharData:PlayerFreeplayDJData;

  public function new(x:Float, y:Float, characterId:String)
  {
    this.characterId = characterId;

    var playableChar = PlayerRegistry.instance.fetchEntry(characterId);
    playableCharData = playableChar.getFreeplayDJData();

    super(x, y, playableCharData.getAtlasPath());

    onAnimationFrame.add(function(name, number) {
      if (name == playableCharData.getAnimationPrefix('cartoon'))
      {
        if (number == playableCharData.getCartoonSoundClickFrame())
        {
          FunkinSound.playOnce(Paths.sound('remote_click'));
        }
        if (number == playableCharData.getCartoonSoundCartoonFrame())
        {
          runTvLogic();
        }
      }
    });

    FlxG.debugger.track(this);
    FlxG.console.registerObject("dj", this);

    onAnimationComplete.add(onFinishAnim);

    FlxG.console.registerFunction("freeplayCartoon", function() {
      currentState = Cartoon;
    });
  }

  override public function listAnimations():Array<String>
  {
    var anims:Array<String> = [];
    @:privateAccess
    for (animKey in anim.symbolDictionary)
    {
      anims.push(animKey.name);
    }
    return anims;
  }

  var lowPumpLoopPoint:Int = 4;

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    switch (currentState)
    {
      case Intro:
        // Play the intro animation then leave this state immediately.
        var animPrefix = playableCharData.getAnimationPrefix('intro');
        if (getCurrentAnimation() != animPrefix) playFlashAnimation(animPrefix, true);
        timeIdling = 0;
      case Idle:
        // We are in this state the majority of the time.
        var animPrefix = playableCharData.getAnimationPrefix('idle');
        if (getCurrentAnimation() != animPrefix)
        {
          playFlashAnimation(animPrefix, true, false, true);
        }

        if (getCurrentAnimation() == animPrefix && this.isLoopFinished())
        {
          if (timeIdling >= IDLE_EGG_PERIOD && !seenIdleEasterEgg)
          {
            currentState = IdleEasterEgg;
          }
          else if (timeIdling >= IDLE_CARTOON_PERIOD)
          {
            currentState = Cartoon;
          }
        }
        timeIdling += elapsed;
      case Confirm:
        var animPrefix = playableCharData.getAnimationPrefix('confirm');
        if (getCurrentAnimation() != animPrefix) playFlashAnimation(animPrefix, false);
        timeIdling = 0;
      case FistPumpIntro:
        var animPrefix = playableCharData.getAnimationPrefix('fistPump');
        if (getCurrentAnimation() != animPrefix) playFlashAnimation('Boyfriend DJ fist pump', false);
        if (getCurrentAnimation() == animPrefix && anim.curFrame >= 4)
        {
          playAnimation("Boyfriend DJ fist pump", true, false, false, 0);
        }
      case FistPump:

      case IdleEasterEgg:
        var animPrefix = playableCharData.getAnimationPrefix('idleEasterEgg');
        if (getCurrentAnimation() != animPrefix)
        {
          onIdleEasterEgg.dispatch();
          playFlashAnimation(animPrefix, false);
          seenIdleEasterEgg = true;
        }
        timeIdling = 0;
      case Cartoon:
        var animPrefix = playableCharData.getAnimationPrefix('cartoon');
        if (animPrefix == null)
        {
          currentState = IdleEasterEgg;
        }
        else
        {
          if (getCurrentAnimation() != animPrefix) playFlashAnimation(animPrefix, true);
          timeIdling = 0;
        }
      default:
        // I shit myself.
    }

    #if debug
    if (FlxG.keys.pressed.CONTROL)
    {
      if (FlxG.keys.justPressed.LEFT)
      {
        this.offsetX -= FlxG.keys.pressed.ALT ? 0.1 : (FlxG.keys.pressed.SHIFT ? 10.0 : 1.0);
      }

      if (FlxG.keys.justPressed.RIGHT)
      {
        this.offsetX += FlxG.keys.pressed.ALT ? 0.1 : (FlxG.keys.pressed.SHIFT ? 10.0 : 1.0);
      }

      if (FlxG.keys.justPressed.UP)
      {
        this.offsetY -= FlxG.keys.pressed.ALT ? 0.1 : (FlxG.keys.pressed.SHIFT ? 10.0 : 1.0);
      }

      if (FlxG.keys.justPressed.DOWN)
      {
        this.offsetY += FlxG.keys.pressed.ALT ? 0.1 : (FlxG.keys.pressed.SHIFT ? 10.0 : 1.0);
      }

      if (FlxG.keys.justPressed.C)
      {
        currentState = (currentState == Idle ? Cartoon : Idle);
      }
    }
    #end
  }

  function onFinishAnim(name:String):Void
  {
    // var name = anim.curSymbol.name;

    if (name == playableCharData.getAnimationPrefix('intro'))
    {
      currentState = Idle;
      onIntroDone.dispatch();
    }
    else if (name == playableCharData.getAnimationPrefix('idle'))
    {
      // trace('Finished idle');
    }
    else if (name == playableCharData.getAnimationPrefix('confirm'))
    {
      // trace('Finished confirm');
    }
    else if (name == playableCharData.getAnimationPrefix('fistPump'))
    {
      // trace('Finished fist pump');
      currentState = Idle;
    }
    else if (name == playableCharData.getAnimationPrefix('idleEasterEgg'))
    {
      // trace('Finished spook');
      currentState = Idle;
    }
    else if (name == playableCharData.getAnimationPrefix('loss'))
    {
      // trace('Finished loss reaction');
      currentState = Idle;
    }
    else if (name == playableCharData.getAnimationPrefix('cartoon'))
    {
      // trace('Finished cartoon');

      var frame:Int = FlxG.random.bool(33) ? playableCharData.getCartoonLoopBlinkFrame() : playableCharData.getCartoonLoopFrame();

      // Character switches channels when the video ends, or at a 10% chance each time his idle loops.
      if (FlxG.random.bool(5))
      {
        frame = playableCharData.getCartoonChannelChangeFrame();
        // boyfriend switches channel code?
        // runTvLogic();
      }
      trace('Replay idle: ${frame}');
      playAnimation(playableCharData.getAnimationPrefix('cartoon'), true, false, false, frame);
      // trace('Finished confirm');
    }
    else
    {
      trace('Finished ${name}');
    }
  }

  public function resetAFKTimer():Void
  {
    timeIdling = 0;
    seenIdleEasterEgg = false;
  }

  var offsetX:Float = 0.0;
  var offsetY:Float = 0.0;

  var cartoonSnd:Null<FunkinSound> = null;

  public var playingCartoon:Bool = false;

  public function runTvLogic()
  {
    if (cartoonSnd == null)
    {
      // tv is OFF, but getting turned on
      FunkinSound.playOnce(Paths.sound('tv_on'), 1.0, function() {
        loadCartoon();
      });
    }
    else
    {
      // plays it smidge after the click
      FunkinSound.playOnce(Paths.sound('channel_switch'), 1.0, function() {
        cartoonSnd.destroy();
        loadCartoon();
      });
    }

    // loadCartoon();
  }

  function loadCartoon()
  {
    cartoonSnd = FunkinSound.load(Paths.sound(getRandomFlashToon()), 1.0, false, true, true, function() {
      playAnimation("Boyfriend DJ watchin tv OG", true, false, false, 60);
    });

    // Fade out music to 40% volume over 1 second.
    // This helps make the TV a bit more audible.
    FlxG.sound.music.fadeOut(1.0, 0.1);

    // Play the cartoon at a random time between the start and 5 seconds from the end.
    cartoonSnd.time = FlxG.random.float(0, Math.max(cartoonSnd.length - (5 * Constants.MS_PER_SEC), 0.0));
  }

  final cartoonList:Array<String> = openfl.utils.Assets.list().filter(function(path) return path.startsWith("assets/sounds/cartoons/"));

  function getRandomFlashToon():String
  {
    var randomFile = FlxG.random.getObject(cartoonList);

    // Strip folder prefix
    randomFile = randomFile.replace("assets/sounds/", "");
    // Strip file extension
    randomFile = randomFile.substring(0, randomFile.length - 4);

    return randomFile;
  }

  public function confirm():Void
  {
    currentState = Confirm;
  }

  public function fistPump():Void
  {
    currentState = FistPumpIntro;
  }

  public function pumpFist():Void
  {
    currentState = FistPump;
    playAnimation("Boyfriend DJ fist pump", true, false, false, 4);
  }

  public function pumpFistBad():Void
  {
    currentState = FistPump;
    playAnimation("Boyfriend DJ loss reaction 1", true, false, false, 4);
  }

  override public function getCurrentAnimation():String
  {
    if (this.anim == null || this.anim.curSymbol == null) return "";
    return this.anim.curSymbol.name;
  }

  public function playFlashAnimation(id:String, Force:Bool = false, Reverse:Bool = false, Loop:Bool = false, Frame:Int = 0):Void
  {
    playAnimation(id, Force, Reverse, Loop, Frame);
    applyAnimOffset();
  }

  function applyAnimOffset()
  {
    var AnimName = getCurrentAnimation();
    var daOffset = playableCharData.getAnimationOffsetsByPrefix(AnimName);
    if (daOffset != null)
    {
      var xValue = daOffset[0];
      var yValue = daOffset[1];
      if (AnimName == "Boyfriend DJ watchin tv OG")
      {
        xValue += offsetX;
        yValue += offsetY;
      }

      trace('Successfully applied offset ($AnimName): ' + xValue + ', ' + yValue);
      offset.set(xValue, yValue);
    }
    else
    {
      trace('No offset found ($AnimName), defaulting to: 0, 0');
      offset.set(0, 0);
    }
  }

  public override function destroy():Void
  {
    super.destroy();

    if (cartoonSnd != null)
    {
      cartoonSnd.destroy();
      cartoonSnd = null;
    }
  }
}

enum DJBoyfriendState
{
  Intro;
  Idle;
  Confirm;
  FistPumpIntro;
  FistPump;
  IdleEasterEgg;
  Cartoon;
}
