package funkin.play.notes;

import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import funkin.play.notes.NoteDirection;
import flixel.graphics.frames.FlxFramesCollection;
import funkin.util.assets.FlxAnimationUtil;
import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.FlxSprite;
import funkin.play.modchart.shaders.ModchartHSVShader;
import flixel.math.FlxPoint;
import openfl.geom.Vector3D;
import funkin.play.modchart.objects.FunkinActor;
import flixel.math.FlxPoint;
import flixel.graphics.FlxGraphic;

class NoteHoldCover extends FlxTypedSpriteGroup<FunkinActor>
{
  static final FRAMERATE_DEFAULT:Int = 24;

  static var glowFrames:FlxFramesCollection;

  public var holdNote:SustainTrail;

  var glow:FunkinActor;

  public var column:Int = 0;
  public var offsetX:Float = 0;
  public var offsetY:Float = 0;
  public var defaultScale:Array<Float>;
  public var skew:Vector3D = new Vector3D();
  public var rotation:Vector3D = new Vector3D();
  public var SCALE:Vector3D = new Vector3D(1, 1);
  public var z:Float = 0;
  public var hsvShader:ModchartHSVShader;

  public function new()
  {
    super(0, 0);

    setup();

    defaultScale = [scale.x, scale.y];
  }

  override public function draw():Void
  {
    super.draw();
  }

  function createGraphic()
  {
    for (i in frames.frames)
    {
      // var graphic:FlxGraphic = FlxGraphic.fromFrame(i, true, )
    }
  }

  public static function preloadFrames():Void
  {
    glowFrames = null;
    for (direction in Strumline.DIRECTIONS)
    {
      var directionName = direction.colorName.toTitleCase();

      var atlas:FlxFramesCollection = Paths.getSparrowAtlas('holdCover${directionName}');
      atlas.parent.persist = true;

      if (glowFrames != null)
      {
        glowFrames = FlxAnimationUtil.combineFramesCollections(glowFrames, atlas);
      }
      else
      {
        glowFrames = atlas;
      }
    }
  }

  /**
   * Add ALL the animations to this sprite. We will recycle and reuse the FlxSprite multiple times.
   */
  function setup():Void
  {
    glow = new FunkinActor(0, 0, true);
    add(glow);
    glow.z = this.z;
    glow.SCALE.x = this.SCALE.x;
    glow.SCALE.y = this.SCALE.y;
    glow.rotation.x = this.rotation.x;
    glow.rotation.y = this.rotation.y;
    glow.rotation.z = this.rotation.z;
    // glow.offsetX = this.offsetX;
    // glow.offsetY = this.offsetY;
    glow.skew.x = this.skew.x;
    glow.skew.y = this.skew.y;
    if (glowFrames == null) preloadFrames();
    glow.frames = glowFrames;

    for (direction in Strumline.DIRECTIONS)
    {
      var directionName = direction.colorName.toTitleCase();

      glow.animation.addByPrefix('holdCoverStart$directionName', 'holdCoverStart${directionName}0', FRAMERATE_DEFAULT, false, false, false);
      glow.animation.addByPrefix('holdCover$directionName', 'holdCover${directionName}0', FRAMERATE_DEFAULT, true, false, false);
      glow.animation.addByPrefix('holdCoverEnd$directionName', 'holdCoverEnd${directionName}0', FRAMERATE_DEFAULT, false, false, false);
    }

    glow.animation.finishCallback = this.onAnimationFinished;
    this.hsvShader = new ModchartHSVShader();
    glow.shader = hsvShader.shader;
    if (glow.animation.getAnimationList().length < 3 * 4)
    {
      trace('WARNING: NoteHoldCover failed to initialize all animations.');
    }
  }

  public override function update(elapsed):Void
  {
    super.update(elapsed);
    if (glow != null)
    {
      glow.z = this.z;
      glow.SCALE.x = this.SCALE.x;
      glow.SCALE.y = this.SCALE.y;
      glow.rotation.x = this.rotation.x;
      glow.rotation.y = this.rotation.y;
      glow.rotation.z = this.rotation.z;
      glow.offsetX = this.offsetX;
      glow.offsetY = this.offsetY;
      glow.skew.x = this.skew.x;
      glow.skew.y = this.skew.y;
    }
  }

  public function playStart():Void
  {
    var direction:NoteDirection = holdNote.noteDirection;
    glow.animation.play('holdCoverStart${direction.colorName.toTitleCase()}');
  }

  public function playContinue():Void
  {
    var direction:NoteDirection = holdNote.noteDirection;
    glow.animation.play('holdCover${direction.colorName.toTitleCase()}');
  }

  public function playEnd():Void
  {
    var direction:NoteDirection = holdNote.noteDirection;
    glow.animation.play('holdCoverEnd${direction.colorName.toTitleCase()}');
  }

  public override function kill():Void
  {
    super.kill();

    this.visible = false;

    if (glow != null) glow.visible = false;
  }

  public override function revive():Void
  {
    super.revive();

    this.visible = true;
    this.alpha = 1.0;
    this.hsvShader.hue = 1.0;
    this.hsvShader.saturation = 1.0;
    this.hsvShader.value = 1.0;
    if (glow != null) glow.visible = true;
  }

  public function onAnimationFinished(animationName:String):Void
  {
    if (animationName.startsWith('holdCoverStart'))
    {
      playContinue();
    }
    if (animationName.startsWith('holdCoverEnd'))
    {
      // *lightning* *zap* *crackle*
      this.visible = false;
      this.kill();
    }
  }
}
