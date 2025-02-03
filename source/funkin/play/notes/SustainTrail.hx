package funkin.play.notes;

import funkin.play.notes.notestyle.NoteStyle;
import funkin.play.notes.NoteDirection;
import funkin.data.song.SongData.SongNoteData;
import flixel.util.FlxDirectionFlags;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.tile.FlxDrawTrianglesItem;
import flixel.math.FlxMath;
import funkin.ui.options.PreferencesMenu;
import funkin.play.modchart.shaders.ModchartHSVShader;
import funkin.play.modchart.util.ModchartMath;
import openfl.geom.Vector3D;
import flixel.math.FlxPoint;
import funkin.play.modchart.util.ModchartMath;

/**
 * This is based heavily on the `FlxStrip` class. It uses `drawTriangles()` to clip a sustain note
 * trail at a certain time.
 * The whole `FlxGraphic` is used as a texture map. See the `NOTE_hold_assets.fla` file for specifics
 * on how it should be constructed.
 *
 * @author MtH
 */
class SustainTrail extends FlxSprite
{
  /**
   * The triangles corresponding to the hold, followed by the endcap.
   * `top left, top right, bottom left`
   * `top left, bottom left, bottom right`
   */
  static final TRIANGLE_VERTEX_INDICES:Array<Int> = [0, 1, 2, 1, 2, 3, 4, 5, 6, 5, 6, 7];

  public var strumTime:Float = 0; // millis
  public var noteDirection:NoteDirection = 0;
  public var sustainLength(default, set):Float = 0; // millis
  public var fullSustainLength:Float = 0;
  public var modNumber:Int;
  public var noteData:Null<SongNoteData>;
  public var parentStrumline:Strumline;

  public var cover:NoteHoldCover = null;

  /**
   * Set to `true` if the user hit the note and is currently holding the sustain.
   * Should display associated effects.
   */
  public var hitNote:Bool = false;

  /**
   * Set to `true` if the user missed the note or released the sustain.
   * Should make the trail transparent.
   */
  public var missedNote:Bool = false;

  /**
   * Set to `true` after handling additional logic for missing notes.
   */
  public var handledMiss:Bool = false;

  // maybe BlendMode.MULTIPLY if missed somehow, drawTriangles does not support!

  /**
   * A `Vector` of floats where each pair of numbers is treated as a coordinate location (an x, y pair).
   */
  public var vertices:DrawData<Float> = new DrawData<Float>();

  /**
   * A `Vector` of integers or indexes, where every three indexes define a triangle.
   */
  public var indices:DrawData<Int> = new DrawData<Int>();

  /**
   * A `Vector` of normalized coordinates used to apply texture mapping.
   */
  public var uvtData:DrawData<Float> = new DrawData<Float>();

  private var processedGraphic:FlxGraphic;

  private var zoom:Float = 1;

  /**
   * What part of the trail's end actually represents the end of the note.
   * This can be used to have a little bit sticking out.
   */
  public var endOffset:Float = 0.5; // 0.73 is roughly the bottom of the sprite in the normal graphic!

  /**
   * At what point the bottom for the trail's end should be clipped off.
   * Used in cases where there's an extra bit of the graphic on the bottom to avoid antialiasing issues with overflow.
   */
  public var bottomClip:Float = 0.9;

  public var isPixel:Bool;
  public var noteStyleOffsets:Array<Float>;

  var graphicWidth:Float = 0;
  var graphicHeight:Float = 0;

  public var defaultScale:Array<Float>;
  public var offsetX:Float;
  public var offsetY:Float;
  public var hsvShader:ModchartHSVShader;
  public var vwoosh:Bool;

  public var SCALE:Vector3D = new Vector3D();
  public var skew(default, null):FlxPoint = FlxPoint.get();
  public var rotation:Vector3D = new Vector3D();
  public var z:Float = 0;

  public var isChartingState:Bool = false;

  /**
   * Normally you would take strumTime:Float, noteData:Int, sustainLength:Float, parentNote:Note (?)
   * @param NoteData
   * @param SustainLength Length in milliseconds.
   * @param fileName
   */
  public function new(noteDirection:NoteDirection, sustainLength:Float, noteStyle:NoteStyle, modNumber:Int)
  {
    super(0, 0);

    // BASIC SETUP
    this.sustainLength = sustainLength;
    this.fullSustainLength = sustainLength;
    this.noteDirection = noteDirection;
    this.modNumber = modNumber;

    hsvShader = new ModchartHSVShader();
    setupHoldNoteGraphic(noteStyle);
    noteStyleOffsets = noteStyle.getHoldNoteOffsets();

    indices = new DrawData<Int>(12, true, TRIANGLE_VERTEX_INDICES);
    defaultScale = [scale.x, scale.y];
    this.active = true; // This NEEDS to be true for the note to be drawn!
  }

  /**
   * Creates hold note graphic and applies correct zooming
   * @param noteStyle The note style
   */
  public function setupHoldNoteGraphic(noteStyle:NoteStyle):Void
  {
    loadGraphic(noteStyle.getHoldNoteAssetPath());

    antialiasing = true;

    this.isPixel = noteStyle.isHoldNotePixel();
    if (isPixel)
    {
      endOffset = bottomClip = 1;
      antialiasing = false;
    }
    else
    {
      endOffset = 0.5;
      bottomClip = 0.9;
    }

    zoom = 1.0;
    zoom *= noteStyle.fetchHoldNoteScale();

    // CALCULATE SIZE
    graphicWidth = graphic.width / 8 * zoom; // amount of notes * 2
    graphicHeight = sustainHeight(sustainLength, parentStrumline?.scrollSpeed ?? 1.0);
    // instead of scrollSpeed, PlayState.SONG.speed

    flipY = Preferences.downscroll;

    // alpha = 0.6;
    alpha = 1.0;
    // calls updateColorTransform(), which initializes processedGraphic!
    updateColorTransform();

    updateClipping();

    this.shader = hsvShader.shader;
  }

  function getBaseScrollSpeed()
  {
    return (PlayState.instance?.currentChart?.scrollSpeed ?? 1.0);
  }

  var previousScrollSpeed:Float = 1;

  override function update(elapsed)
  {
    super.update(elapsed);
    updateClipping();
    if (previousScrollSpeed != (parentStrumline?.scrollSpeed ?? 1.0))
    {
      triggerRedraw();
    }
    previousScrollSpeed = parentStrumline?.scrollSpeed ?? 1.0;
  }

  /**
   * Calculates height of a sustain note for a given length (milliseconds) and scroll speed.
   * @param	susLength	The length of the sustain note in milliseconds.
   * @param	scroll		The current scroll speed.
   */
  public static inline function sustainHeight(susLength:Float, scroll:Float)
  {
    return (susLength * Constants.PIXELS_PER_MS * scroll);
  }

  function set_sustainLength(s:Float):Float
  {
    if (s < 0.0) s = 0.0;

    if (sustainLength == s) return s;
    this.sustainLength = s;
    triggerRedraw();
    return this.sustainLength;
  }

  function triggerRedraw()
  {
    graphicHeight = sustainHeight(sustainLength, parentStrumline?.scrollSpeed ?? 1.0);
    updateClipping();
    updateHitbox();
  }

  public override function updateHitbox():Void
  {
    width = graphicWidth;
    height = graphicHeight;
    offset.set(noteStyleOffsets[0], noteStyleOffsets[1]);
    origin.set(width * 0.5, height * 0.5);
  }

  function getPosWithOffset(xoff:Float = 0, yoff:Float = 0, time:Float)
  {
    var conductorInUse:Conductor = parentStrumline?.conductorInUse ?? Conductor.instance;
    var speed:Float = parentStrumline?.scrollSpeed ?? 1.0;
    var column:Int = noteData?.getDirection() ?? noteDirection % Strumline.KEY_COUNT;
    var pn:Int = modNumber;
    var xoffArray:Array<Float> = [];
    for (i in 0...4)
      xoffArray.push((parentStrumline?.x ?? 0.0) + i * Strumline.NOTE_SPACING);
    var yOffset:Float = parentStrumline?.mods?.GetYOffset(conductorInUse, time, speed, vwoosh, column) ?? 0.0;
    var pos:Vector3D = new Vector3D(xoff + parentStrumline?.mods?.GetXPos(column, yOffset, pn, xoffArray) ?? 0.0,
      yoff + parentStrumline?.mods?.GetYPos(column, yOffset, pn, xoffArray) ?? 0.0, parentStrumline?.mods?.GetZPos(column, yOffset, pn, xoffArray) ?? 0.0);
    if (parentStrumline != null) parentStrumline.mods.modifyPos(pos, xoffArray);
    var scaledPos:Vector3D = ModchartMath.scaleVector3(pos, SCALE.x, SCALE.y, SCALE.z);
    var skewedPos:Vector3D = ModchartMath.skewVector2(scaledPos, skew.x, skew.y);
    var rotatedPos:Vector3D = ModchartMath.rotateVector3(skewedPos, rotation.x, rotation.y, rotation.z);
    var finalPos:Vector3D = ModchartMath.PerspectiveProjection(rotatedPos.add(new Vector3D(x, y, z - 1000))).subtract(new Vector3D(x, y, z));
    finalPos.incrementBy(new Vector3D(offsetX, offsetY));
    return finalPos;
  }

  public function updateClipping():Void
  {
    if (isChartingState) updateClippingOld();
    else
      updateClippingNew();
  }

  public function updateClippingNew():Void
  {
    if (graphic == null)
    {
      return;
    }

    var clipHeight:Float = FlxMath.bound(sustainHeight(sustainLength + strumTime, parentStrumline?.scrollSpeed ?? 1.0), 0, graphicHeight);
    if (clipHeight <= 0.1)
    {
      visible = false;
      return;
    }
    else
    {
      visible = true;
    }

    var bottomHeight:Float = graphic.height * zoom * endOffset;
    var partHeight:Float = clipHeight - bottomHeight;

    var roughness:Float = 0.6;
    var length:Int = Std.int(fullSustainLength / (roughness * 100));

    for (i in 0...length)
    {
      var a:Int = i * 2;
      var time:Float = strumTime + (fullSustainLength / length * i);
      if (hitNote && !missedNote && Conductor.instance.songPosition >= strumTime)
      {
        var diff:Float = Conductor.instance.songPosition - strumTime;
        time = strumTime + (sustainLength / length * i) + diff;
      }
      var pos1:Vector3D = getPosWithOffset(0, 0, time);
      var pos2:Vector3D = getPosWithOffset(graphicWidth, 0, time);
      vertices[a * 2] = pos1.x;
      vertices[a * 2 + 1] = pos1.y;
      vertices[(a + 1) * 2] = pos2.x;
      vertices[(a + 1) * 2 + 1] = pos2.y;
    }

    var end:Int = (length - 1) * 2;
    var next:Int = length * 2;
    vertices[next * 2] = vertices[end * 2];
    vertices[next * 2 + 1] = vertices[end * 2 + 1];
    vertices[(next + 1) * 2] = vertices[(end + 1) * 2];
    vertices[(next + 1) * 2 + 1] = vertices[(end + 1) * 2 + 1];
    var time:Float = strumTime + fullSustainLength;
    var diff:Float = Conductor.instance.songPosition - strumTime;
    if (hitNote && !missedNote && Conductor.instance.songPosition >= strumTime)
    {
      time = strumTime + sustainLength + diff;
    }
    var bottomnext:Int = (length + 1) * 2;
    var pos1:Vector3D = getPosWithOffset(0, 0, time);
    var pos2:Vector3D = getPosWithOffset(graphicWidth, 0, time);
    vertices[bottomnext * 2] = pos1.x;
    vertices[bottomnext * 2 + 1] = pos1.y;
    vertices[(bottomnext + 1) * 2] = pos2.x;
    vertices[(bottomnext + 1) * 2 + 1] = pos2.y;

    for (i in 0...length)
    {
      var a:Int = i * 2;
      uvtData[a * 2] = 1 / 4 * (noteDirection % 4);
      uvtData[a * 2 + 1] = ModchartMath.lerp(1 / (i + 1), (-partHeight) / graphic.height / zoom, 0);
      uvtData[(a + 1) * 2] = uvtData[a * 2] + 1 / 8;
      uvtData[(a + 1) * 2 + 1] = uvtData[a * 2 + 1];
    }

    uvtData[next * 2] = 1 / 4 * (noteDirection % 4) + 1 / 8;
    uvtData[next * 2 + 1] = if (partHeight > 0)
    {
      0;
    }
    else
    {
      (bottomHeight - clipHeight) / zoom / graphic.height;
    };
    uvtData[(next + 1) * 2] = uvtData[next * 2] + 1 / 8;
    uvtData[(next + 1) * 2 + 1] = uvtData[next * 2 + 1];
    uvtData[bottomnext * 2] = uvtData[next * 2];
    uvtData[bottomnext * 2 + 1] = bottomClip;
    uvtData[(bottomnext + 1) * 2] = uvtData[(next + 1) * 2];
    uvtData[(bottomnext + 1) * 2 + 1] = uvtData[bottomnext * 2 + 1];

    var indices:Array<Int> = [];
    for (i in 0...end)
    {
      indices.push(i);
      indices.push(i + 1);
      indices.push(i + 2);
    }
    indices.push(next);
    indices.push(next + 1);
    indices.push(next + 2);
    indices.push(next + 1);
    indices.push(next + 2);
    indices.push(next + 3);
    this.indices = new DrawData<Int>(indices.length, true, indices);
  }

  public function updateClippingOld(songTime:Float = 0):Void
  {
    if (graphic == null)
    {
      return;
    }

    var clipHeight:Float = FlxMath.bound(sustainHeight(sustainLength - (songTime - strumTime), parentStrumline?.scrollSpeed ?? 1.0), 0, graphicHeight);
    if (clipHeight <= 0.1)
    {
      visible = false;
      return;
    }
    else
    {
      visible = true;
    }

    var bottomHeight:Float = graphic.height * zoom * endOffset;
    var partHeight:Float = clipHeight - bottomHeight;

    // ===HOLD VERTICES==
    // Top left
    vertices[0 * 2] = 0.0; // Inline with left side
    vertices[0 * 2 + 1] = flipY ? clipHeight : graphicHeight - clipHeight;

    // Top right
    vertices[1 * 2] = graphicWidth;
    vertices[1 * 2 + 1] = vertices[0 * 2 + 1]; // Inline with top left vertex

    // Bottom left
    vertices[2 * 2] = 0.0; // Inline with left side
    vertices[2 * 2 + 1] = if (partHeight > 0)
    {
      // flipY makes the sustain render upside down.
      flipY ? 0.0 + bottomHeight : vertices[1] + partHeight;
    }
    else
    {
      vertices[0 * 2 + 1]; // Inline with top left vertex (no partHeight available)
    }

    // Bottom right
    vertices[3 * 2] = graphicWidth;
    vertices[3 * 2 + 1] = vertices[2 * 2 + 1]; // Inline with bottom left vertex

    // ===HOLD UVs===

    // The UVs are a bit more complicated.
    // UV coordinates are normalized, so they range from 0 to 1.
    // We are expecting an image containing 8 horizontal segments, each representing a different colored hold note followed by its end cap.

    uvtData[0 * 2] = 1 / 4 * (noteDirection % 4); // 0%/25%/50%/75% of the way through the image
    uvtData[0 * 2 + 1] = (-partHeight) / graphic.height / zoom; // top bound
    // Top left

    // Top right
    uvtData[1 * 2] = uvtData[0 * 2] + 1 / 8; // 12.5%/37.5%/62.5%/87.5% of the way through the image (1/8th past the top left)
    uvtData[1 * 2 + 1] = uvtData[0 * 2 + 1]; // top bound

    // Bottom left
    uvtData[2 * 2] = uvtData[0 * 2]; // 0%/25%/50%/75% of the way through the image
    uvtData[2 * 2 + 1] = 0.0; // bottom bound

    // Bottom right
    uvtData[3 * 2] = uvtData[1 * 2]; // 12.5%/37.5%/62.5%/87.5% of the way through the image (1/8th past the top left)
    uvtData[3 * 2 + 1] = uvtData[2 * 2 + 1]; // bottom bound

    // === END CAP VERTICES ===
    // Top left
    vertices[4 * 2] = vertices[2 * 2]; // Inline with bottom left vertex of hold
    vertices[4 * 2 + 1] = vertices[2 * 2 + 1]; // Inline with bottom left vertex of hold

    // Top right
    vertices[5 * 2] = vertices[3 * 2]; // Inline with bottom right vertex of hold
    vertices[5 * 2 + 1] = vertices[3 * 2 + 1]; // Inline with bottom right vertex of hold

    // Bottom left
    vertices[6 * 2] = vertices[2 * 2]; // Inline with left side
    vertices[6 * 2 + 1] = flipY ? (graphic.height * (-bottomClip + endOffset) * zoom) : (graphicHeight + graphic.height * (bottomClip - endOffset) * zoom);

    // Bottom right
    vertices[7 * 2] = vertices[3 * 2]; // Inline with right side
    vertices[7 * 2 + 1] = vertices[6 * 2 + 1]; // Inline with bottom of end cap

    // === END CAP UVs ===
    // Top left
    uvtData[4 * 2] = uvtData[2 * 2] + 1 / 8; // 12.5%/37.5%/62.5%/87.5% of the way through the image (1/8th past the top left of hold)
    uvtData[4 * 2 + 1] = if (partHeight > 0)
    {
      0;
    }
    else
    {
      (bottomHeight - clipHeight) / zoom / graphic.height;
    };

    // Top right
    uvtData[5 * 2] = uvtData[4 * 2] + 1 / 8; // 25%/50%/75%/100% of the way through the image (1/8th past the top left of cap)
    uvtData[5 * 2 + 1] = uvtData[4 * 2 + 1]; // top bound

    // Bottom left
    uvtData[6 * 2] = uvtData[4 * 2]; // 12.5%/37.5%/62.5%/87.5% of the way through the image (1/8th past the top left of hold)
    uvtData[6 * 2 + 1] = bottomClip; // bottom bound

    // Bottom right
    uvtData[7 * 2] = uvtData[5 * 2]; // 25%/50%/75%/100% of the way through the image (1/8th past the top left of cap)
    uvtData[7 * 2 + 1] = uvtData[6 * 2 + 1]; // bottom bound
  }

  @:access(flixel.FlxCamera)
  override public function draw():Void
  {
    if (alpha == 0 || graphic == null || vertices == null) return;

    for (camera in cameras)
    {
      if (!camera.visible || !camera.exists) continue;
      // if (!isOnScreen(camera)) continue; // TODO: Update this code to make it work properly.

      getScreenPosition(_point, camera).subtractPoint(offset);
      camera.drawTriangles(processedGraphic, vertices, indices, uvtData, null, _point, blend, true, antialiasing);
    }

    #if FLX_DEBUG
    if (FlxG.debugger.drawDebug) drawDebug();
    #end
  }

  public function desaturate():Void
  {
    this.hsvShader.saturation = 0.2;
  }

  public function setHue(hue:Float):Void
  {
    this.hsvShader.hue = hue;
  }

  public override function kill():Void
  {
    super.kill();

    strumTime = 0;
    noteDirection = 0;
    sustainLength = 0;
    fullSustainLength = 0;
    noteData = null;

    hitNote = false;
    missedNote = false;
  }

  public override function revive():Void
  {
    super.revive();

    strumTime = 0;
    noteDirection = 0;
    sustainLength = 0;
    fullSustainLength = 0;
    noteData = null;

    hitNote = false;
    missedNote = false;
    handledMiss = false;
    this.hsvShader.hue = 1.0;
    this.hsvShader.saturation = 1.0;
    this.hsvShader.value = 1.0;
  }

  override public function destroy():Void
  {
    vertices = null;
    indices = null;
    uvtData = null;
    SCALE = null;
    skew = null;
    rotation = null;
    processedGraphic.destroy();

    super.destroy();
  }

  override function updateColorTransform():Void
  {
    super.updateColorTransform();
    if (processedGraphic != null) processedGraphic.destroy();
    processedGraphic = FlxGraphic.fromGraphic(graphic, true);
    processedGraphic.bitmap.colorTransform(processedGraphic.bitmap.rect, colorTransform);
  }
}
