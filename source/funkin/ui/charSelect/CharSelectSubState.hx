package funkin.ui.charSelect;

import funkin.ui.freeplay.FreeplayState;
import flixel.text.FlxText;
import funkin.ui.PixelatedIcon;
import flixel.system.debug.watch.Tracker.TrackerProfile;
import flixel.math.FlxPoint;
import flixel.tweens.FlxTween;
import openfl.display.BlendMode;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import funkin.play.stage.Stage;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEventDispatcher;
import funkin.graphics.adobeanimate.FlxAtlasSprite;
import flixel.FlxObject;
import openfl.display.BlendMode;
import flixel.group.FlxGroup;
import funkin.util.MathUtil;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.sound.FlxSound;
import funkin.audio.FunkinSound;

class CharSelectSubState extends MusicBeatSubState
{
  var cursor:FlxSprite;
  var cursorBlue:FlxSprite;
  var cursorDarkBlue:FlxSprite;

  var grpCursors:FlxTypedGroup<FlxSprite>;

  var cursorConfirmed:FlxSprite;
  var cursorDenied:FlxSprite;

  var cursorX:Int = 0;
  var cursorY:Int = 0;

  var cursorFactor:Float = 110;
  var cursorOffsetX:Float = -16;
  var cursorOffsetY:Float = -48;

  var cursorLocIntended:FlxPoint = new FlxPoint(0, 0);
  var lerpAmnt:Float = 0.95;

  var tmrFrames:Int = 60;

  var currentStage:Stage;

  var playerChill:CharSelectPlayer;
  var playerChillOut:CharSelectPlayer;
  var gfChill:CharSelectGF;
  var gfChillOut:CharSelectGF;

  var curChar(default, set):String = "pico";
  var nametag:Nametag;
  var camFollow:FlxObject;

  var availableChars:Map<Int, String> = new Map<Int, String>();
  var pressedSelect:Bool = false;

  var selectTimer:FlxTimer = new FlxTimer();
  var selectSound:FunkinSound;

  public function new()
  {
    super();

    availableChars.set(4, "bf");
    availableChars.set(3, "pico");
  }

  override public function create():Void
  {
    super.create();

    selectSound = new FunkinSound();
    selectSound.loadEmbedded(Paths.sound('CS_select'));
    selectSound.pitch = 1;
    selectSound.volume = 0.7;
    FlxG.sound.defaultSoundGroup.add(selectSound);

    // playing it here to preload it. not doing this makes a super awkward pause at the end of the intro
    // TODO: probably make an intro thing for funkinSound itself that preloads the next audio?
    FunkinSound.playMusic('stayFunky',
      {
        startingVolume: 0,
        overrideExisting: true,
        restartTrack: true
      });
    var introMusic:String = Paths.music('stayFunky/stayFunky-intro');
    FunkinSound.load(introMusic, 1.0, false, true, true, () -> {
      FunkinSound.playMusic('stayFunky',
        {
          startingVolume: 1,
          overrideExisting: true,
          restartTrack: true
        });
    });

    var bg:FlxSprite = new FlxSprite(-153, -140);
    bg.loadGraphic(Paths.image('charSelect/charSelectBG'));
    bg.scrollFactor.set(0.1, 0.1);
    add(bg);

    var crowd:FlxAtlasSprite = new FlxAtlasSprite(0, 0, Paths.animateAtlas("charSelect/crowd"));
    crowd.anim.play("");
    crowd.scrollFactor.set(0.3, 0.3);
    add(crowd);

    var stageSpr:FlxSprite = new FlxSprite(-40, 391);
    stageSpr.frames = Paths.getSparrowAtlas("charSelect/charSelectStage");
    stageSpr.animation.addByPrefix("idle", "stage", 24, true);
    stageSpr.animation.play("idle");
    add(stageSpr);

    var curtains:FlxSprite = new FlxSprite(-47, -49);
    curtains.loadGraphic(Paths.image('charSelect/curtains'));
    curtains.scrollFactor.set(1.4, 1.4);
    add(curtains);

    var barthing:FlxAtlasSprite = new FlxAtlasSprite(0, 0, Paths.animateAtlas("charSelect/barThing"));
    barthing.anim.play("");
    barthing.blend = BlendMode.MULTIPLY;
    barthing.scrollFactor.set(0, 0);
    add(barthing);

    var charLight:FlxSprite = new FlxSprite(800, 250);
    charLight.loadGraphic(Paths.image('charSelect/charLight'));
    add(charLight);

    var charLightGF:FlxSprite = new FlxSprite(180, 240);
    charLightGF.loadGraphic(Paths.image('charSelect/charLight'));
    add(charLightGF);

    gfChill = new CharSelectGF();
    gfChill.switchGF("bf");
    add(gfChill);

    playerChill = new CharSelectPlayer(0, 0);
    playerChill.switchChar("bf");
    add(playerChill);

    playerChillOut = new CharSelectPlayer(0, 0);
    playerChillOut.switchChar("bf");
    add(playerChillOut);

    var speakers:FlxAtlasSprite = new FlxAtlasSprite(0, 0, Paths.animateAtlas("charSelect/charSelectSpeakers"));
    speakers.anim.play("");
    speakers.scrollFactor.set(1.8, 1.8);
    add(speakers);

    var fgBlur:FlxSprite = new FlxSprite(-125, 170);
    fgBlur.loadGraphic(Paths.image('charSelect/foregroundBlur'));
    fgBlur.blend = openfl.display.BlendMode.MULTIPLY;
    add(fgBlur);

    var dipshitBlur:FlxSprite = new FlxSprite(419, -65);
    dipshitBlur.frames = Paths.getSparrowAtlas("charSelect/dipshitBlur");
    dipshitBlur.animation.addByPrefix('idle', "CHOOSE vertical", 24, true);
    dipshitBlur.blend = BlendMode.ADD;
    dipshitBlur.animation.play("idle");
    add(dipshitBlur);

    var dipshitBacking:FlxSprite = new FlxSprite(423, -17);
    dipshitBacking.frames = Paths.getSparrowAtlas("charSelect/dipshitBacking");
    dipshitBacking.animation.addByPrefix('idle', "CHOOSE horizontal", 24, true);
    dipshitBacking.blend = BlendMode.ADD;
    dipshitBacking.animation.play("idle");
    add(dipshitBacking);

    var chooseDipshit:FlxSprite = new FlxSprite(426, -13);
    chooseDipshit.loadGraphic(Paths.image('charSelect/chooseDipshit'));
    add(chooseDipshit);

    chooseDipshit.scrollFactor.set();
    dipshitBacking.scrollFactor.set();
    dipshitBlur.scrollFactor.set();

    nametag = new Nametag();
    add(nametag);

    nametag.scrollFactor.set();

    FlxG.debugger.addTrackerProfile(new TrackerProfile(FlxSprite, ["x", "y", "alpha", "scale", "blend"]));
    FlxG.debugger.addTrackerProfile(new TrackerProfile(FlxAtlasSprite, ["x", "y"]));
    FlxG.debugger.addTrackerProfile(new TrackerProfile(FlxSound, ["pitch", "volume"]));

    // FlxG.debugger.track(crowd);
    // FlxG.debugger.track(stageSpr, "stageSpr");
    // FlxG.debugger.track(bfChill, "bf chill");
    // FlxG.debugger.track(playerChill, "player");
    // FlxG.debugger.track(nametag, "nametag");
    FlxG.debugger.track(selectSound, "selectSound");
    // FlxG.debugger.track(chooseDipshit, "choose dipshit");
    // FlxG.debugger.track(barthing, "barthing");
    // FlxG.debugger.track(fgBlur, "fgBlur");
    // FlxG.debugger.track(dipshitBlur, "dipshitBlur");
    // FlxG.debugger.track(dipshitBacking, "dipshitBacking");
    // FlxG.debugger.track(charLightGF, "charLight");
    // FlxG.debugger.track(gfChill, "gfChill");

    grpCursors = new FlxTypedGroup<FlxSprite>();
    add(grpCursors);

    cursor = new FlxSprite(0, 0);
    cursor.loadGraphic(Paths.image('charSelect/charSelector'));
    cursor.color = 0xFFFFFF00;

    // FFCC00

    cursorBlue = new FlxSprite(0, 0);
    cursorBlue.loadGraphic(Paths.image('charSelect/charSelector'));
    cursorBlue.color = 0xFF3EBBFF;

    cursorDarkBlue = new FlxSprite(0, 0);
    cursorDarkBlue.loadGraphic(Paths.image('charSelect/charSelector'));
    cursorDarkBlue.color = 0xFF3C74F7;

    cursorBlue.blend = BlendMode.SCREEN;
    cursorDarkBlue.blend = BlendMode.SCREEN;

    cursorConfirmed = new FlxSprite(0, 0);
    cursorConfirmed.scrollFactor.set();
    cursorConfirmed.frames = Paths.getSparrowAtlas("charSelect/charSelectorConfirm");
    cursorConfirmed.animation.addByPrefix("idle", "cursor ACCEPTED", 24, true);
    cursorConfirmed.visible = false;
    add(cursorConfirmed);

    cursorDenied = new FlxSprite(0, 0);
    cursorDenied.scrollFactor.set();
    cursorDenied.frames = Paths.getSparrowAtlas("charSelect/charSelectorDenied");
    cursorDenied.animation.addByPrefix("idle", "cursor DENIED", 24, false);
    cursorDenied.visible = false;
    add(cursorDenied);

    grpCursors.add(cursorDarkBlue);
    grpCursors.add(cursorBlue);
    grpCursors.add(cursor);

    initLocks();

    cursor.scrollFactor.set();
    cursorBlue.scrollFactor.set();
    cursorDarkBlue.scrollFactor.set();

    FlxTween.color(cursor, 0.2, 0xFFFFFF00, 0xFFFFCC00, {type: FlxTween.PINGPONG});

    // FlxG.debugger.track(cursor);

    FlxG.debugger.addTrackerProfile(new TrackerProfile(CharSelectSubState, ["curChar", "grpXSpread", "grpYSpread"]));
    FlxG.debugger.track(this);

    FlxG.sound.playMusic(Paths.music('charSelect/charSelectMusic'));

    camFollow = new FlxObject(0, 0, 1, 1);
    add(camFollow);
    camFollow.screenCenter();

    FlxG.camera.follow(camFollow, LOCKON, 0.01);

    var temp:FlxSprite = new FlxSprite();
    temp.loadGraphic(Paths.image('charSelect/placement'));
    add(temp);
    temp.alpha = 0.0;
    Conductor.stepHit.add(spamOnStep);
    // FlxG.debugger.track(temp, "tempBG");
  }

  var grpIcons:FlxSpriteGroup;

  var grpXSpread(default, set):Float = 107;
  var grpYSpread(default, set):Float = 127;

  function initLocks()
  {
    grpIcons = new FlxSpriteGroup();
    add(grpIcons);

    FlxG.debugger.addTrackerProfile(new TrackerProfile(FlxSpriteGroup, ["x", "y"]));
    // FlxG.debugger.track(grpIcons, "iconGrp");

    for (i in 0...9)
    {
      if (availableChars.exists(i))
      {
        var path:String = availableChars.get(i);
        var temp:PixelatedIcon = new PixelatedIcon(0, 0);
        temp.setCharacter(path);
        temp.setGraphicSize(128, 128);
        temp.updateHitbox();
        temp.ID = 0;
        grpIcons.add(temp);
      }
      else
      {
        var temp:FlxSprite = new FlxSprite();
        temp.ID = 1;
        temp.frames = Paths.getSparrowAtlas("charSelect/locks");

        var lockIndex:Int = i + 1;

        if (i == 3) lockIndex = 3;

        if (i >= 4) lockIndex = i - 2;

        temp.animation.addByIndices("idle", "LOCK FULL " + lockIndex + " instance 1", [0], "", 24);
        temp.animation.addByIndices("selected", "LOCK FULL " + lockIndex + " instance 1", [3, 4, 5], "", 24, false);
        temp.animation.addByIndices("clicked", "LOCK FULL " + lockIndex + " instance 1", [9, 10, 11, 12, 13, 14, 15], "", 24, false);

        temp.animation.play("idle");

        grpIcons.add(temp);
      }
    }

    updateIconPositions();

    grpIcons.scrollFactor.set();
  }

  function updateIconPositions()
  {
    grpIcons.x = 450;
    grpIcons.y = 120;
    for (index => member in grpIcons.members)
    {
      var posX:Float = (index % 3);
      var posY:Float = Math.floor(index / 3);

      member.x = posX * grpXSpread;
      member.y = posY * grpYSpread;

      member.x += grpIcons.x;
      member.y += grpIcons.y;
    }
  }

  var holdTmrUp:Float = 0;
  var holdTmrDown:Float = 0;
  var holdTmrLeft:Float = 0;
  var holdTmrRight:Float = 0;
  var spamUp:Bool = false;
  var spamDown:Bool = false;
  var spamLeft:Bool = false;
  var spamRight:Bool = false;

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    Conductor.instance.update();

    if (controls.UI_UP_R || controls.UI_DOWN_R || controls.UI_LEFT_R || controls.UI_RIGHT_R) selectSound.pitch = 1;

    if (controls.UI_UP) holdTmrUp += elapsed;
    if (controls.UI_UP_R)
    {
      holdTmrUp = 0;
      spamUp = false;
    }

    if (controls.UI_DOWN) holdTmrDown += elapsed;
    if (controls.UI_DOWN_R)
    {
      holdTmrDown = 0;
      spamDown = false;
    }

    if (controls.UI_LEFT) holdTmrLeft += elapsed;
    if (controls.UI_LEFT_R)
    {
      holdTmrLeft = 0;
      spamLeft = false;
    }

    if (controls.UI_RIGHT) holdTmrRight += elapsed;
    if (controls.UI_RIGHT_R)
    {
      holdTmrRight = 0;
      spamRight = false;
    }

    var initSpam = 0.5;

    if (holdTmrUp >= initSpam) spamUp = true;
    if (holdTmrDown >= initSpam) spamDown = true;
    if (holdTmrLeft >= initSpam) spamLeft = true;
    if (holdTmrRight >= initSpam) spamRight = true;

    if (controls.UI_UP_P)
    {
      cursorY -= 1;
      holdTmrUp = 0;

      selectSound.play(true);
    }
    if (controls.UI_DOWN_P)
    {
      cursorY += 1;
      holdTmrDown = 0;
      selectSound.play(true);
    }
    if (controls.UI_LEFT_P)
    {
      cursorX -= 1;
      holdTmrLeft = 0;
      selectSound.play(true);
    }
    if (controls.UI_RIGHT_P)
    {
      cursorX += 1;
      holdTmrRight = 0;
      selectSound.play(true);
    }

    if (cursorX < -1)
    {
      cursorX = 1;
    }
    if (cursorX > 1)
    {
      cursorX = -1;
    }
    if (cursorY < -1)
    {
      cursorY = 1;
    }
    if (cursorY > 1)
    {
      cursorY = -1;
    }

    if (availableChars.exists(getCurrentSelected()))
    {
      curChar = availableChars.get(getCurrentSelected());

      if (controls.ACCEPT)
      {
        cursorConfirmed.visible = true;
        cursorConfirmed.x = cursor.x - 2;
        cursorConfirmed.y = cursor.y - 4;
        cursorConfirmed.animation.play("idle", true);

        grpCursors.visible = false;

        FlxG.sound.play(Paths.sound('CS_confirm'));

        FlxTween.tween(FlxG.sound.music, {pitch: 0.1}, 1.5, {ease: FlxEase.quadInOut});
        playerChill.playAnimation("select");
        pressedSelect = true;
        selectTimer.start(1.5, (_) -> {
          pressedSelect = false;
          FlxG.switchState(FreeplayState.build(
            {
              {
                character: curChar
              }
            }));
        });
      }

      if (pressedSelect && controls.BACK)
      {
        cursorConfirmed.visible = false;
        grpCursors.visible = true;

        FlxTween.globalManager.cancelTweensOf(FlxG.sound.music);
        FlxTween.tween(FlxG.sound.music, {pitch: 1.0}, 1, {ease: FlxEase.quartInOut});
        playerChill.playAnimation("deselect");
        pressedSelect = false;
        selectTimer.cancel();
      }
    }
    else
    {
      curChar = "locked";

      if (controls.ACCEPT)
      {
        cursorDenied.visible = true;
        cursorDenied.x = cursor.x - 2;
        cursorDenied.y = cursor.y - 4;
        cursorDenied.animation.play("idle", true);
        cursorDenied.animation.finishCallback = (_) -> {
          cursorDenied.visible = false;
        };
      }
    }

    updateLockAnims();

    camFollow.screenCenter();
    camFollow.x += cursorX * 10;
    camFollow.y += cursorY * 10;

    cursorLocIntended.x = (cursorFactor * cursorX) + (FlxG.width / 2) - cursor.width / 2;
    cursorLocIntended.y = (cursorFactor * cursorY) + (FlxG.height / 2) - cursor.height / 2;

    cursorLocIntended.x += cursorOffsetX;
    cursorLocIntended.y += cursorOffsetY;

    cursor.x = MathUtil.coolLerp(cursor.x, cursorLocIntended.x, lerpAmnt);
    cursor.y = MathUtil.coolLerp(cursor.y, cursorLocIntended.y, lerpAmnt);

    cursorBlue.x = MathUtil.coolLerp(cursorBlue.x, cursor.x, lerpAmnt * 0.4);
    cursorBlue.y = MathUtil.coolLerp(cursorBlue.y, cursor.y, lerpAmnt * 0.4);

    cursorDarkBlue.x = MathUtil.coolLerp(cursorDarkBlue.x, cursorLocIntended.x, lerpAmnt * 0.2);
    cursorDarkBlue.y = MathUtil.coolLerp(cursorDarkBlue.y, cursorLocIntended.y, lerpAmnt * 0.2);
  }

  function spamOnStep():Void
  {
    if (spamUp || spamDown || spamLeft || spamRight)
    {
      // selectSound.changePitchBySemitone(1);
      if (selectSound.pitch > 5) selectSound.pitch = 5;
      selectSound.play(true);

      if (spamUp)
      {
        cursorY -= 1;
        holdTmrUp = 0;
      }
      if (spamDown)
      {
        cursorY += 1;
        holdTmrDown = 0;
      }
      if (spamLeft)
      {
        cursorX -= 1;
        holdTmrLeft = 0;
      }
      if (spamRight)
      {
        cursorX += 1;
        holdTmrRight = 0;
      }
    }
  }

  private function updateLockAnims():Void
  {
    for (index => member in grpIcons.group.members)
    {
      switch (member.ID)
      {
        case 1:
          if (index == getCurrentSelected())
          {
            switch (member.animation.curAnim.name)
            {
              case "idle":
                member.animation.play("selected");
              case "selected" | "clicked":
                if (controls.ACCEPT) member.animation.play("clicked", true);
            }
          }
          else
          {
            member.animation.play("idle");
          }
        case 0:
          var memb:PixelatedIcon = cast member;

          if (index == getCurrentSelected())
          {
            // memb.pixels = memb.withDropShadow.clone();
            memb.scale.set(2.6, 2.6);

            if (controls.ACCEPT) memb.animation.play("confirm");
          }
          else
          {
            // memb.pixels = memb.noDropShadow.clone();
            memb.scale.set(2, 2);
          }
      }
    }
  }

  function getCurrentSelected():Int
  {
    var tempX:Int = cursorX + 1;
    var tempY:Int = cursorY + 1;
    var gridPosition:Int = tempX + tempY * 3;
    return gridPosition;
  }

  function set_curChar(value:String):String
  {
    if (curChar == value) return value;

    curChar = value;

    nametag.switchChar(value);
    playerChill.visible = false;
    playerChillOut.visible = true;
    playerChillOut.anim.goToFrameLabel("slideout");
    playerChillOut.onAnimationFrame.add((_, frame:Int) -> {
      if (frame == playerChillOut.anim.getFrameLabel("slideout").index + 1)
      {
        playerChill.visible = true;
        playerChill.switchChar(value);
        gfChill.switchGF(value);
      }
      if (frame == playerChillOut.anim.getFrameLabel("slideout").index + 2)
      {
        playerChillOut.switchChar(value);
        playerChillOut.visible = false;
      }
    });
    return value;
  }

  function set_grpXSpread(value:Float):Float
  {
    grpXSpread = value;
    updateIconPositions();
    return value;
  }

  function set_grpYSpread(value:Float):Float
  {
    grpYSpread = value;
    updateIconPositions();
    return value;
  }
}
