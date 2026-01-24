package funkin.play.notes;

import funkin.play.notes.notestyle.NoteStyle;
import funkin.data.song.SongData.SongNoteData;
import funkin.mobile.ui.FunkinHitbox.FunkinHitboxControlSchemes;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.tile.FlxDrawTrianglesItem.DrawData;
import flixel.graphics.tile.FlxDrawTrianglesItem;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import funkin.play.modchart.util.ModchartMath;
import openfl.geom.Vector3D;
import flixel.math.FlxPoint;
import funkin.play.modchart.util.ModchartMath;
import flixel.graphics.tile.FlxGraphicsShader;
import openfl.geom.ColorTransform;
import openfl.display.TriangleCulling;
import funkin.util.GRhythmUtil;

using flixel.util.FlxColorTransformUtil;

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
  public var noteData:Null<SongNoteData>;
  public var parentStrumline:Strumline;

  public var cover:NoteHoldCover = null;

  /**
   * The Y Offset of the note.
   */
  public var yOffset:Float = 0.0;

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

  /**
   * Whether the note will recieve custom vertex data
   */
  public var customVertexData:Bool = false;

  public var isPixel:Bool;
  public var noteStyleOffsets:Array<Float>;

  var graphicWidth:Float = 0;
  var graphicHeight:Float = 0;

  public var offsetX:Float;
  public var offsetY:Float;
  public var currentZValue:Float = 0;
  public var rotationOrder:String = 'zyx';
  public var fov:Float = 45;
  public var useNew:Bool = false;

  /**
   * Normally you would take strumTime:Float, noteData:Int, sustainLength:Float, parentNote:Note (?)
   * @param NoteData
   * @param SustainLength Length in milliseconds.
   * @param fileName
   */
  public function new(noteDirection:NoteDirection, sustainLength:Float, noteStyle:NoteStyle, useNew:Bool = false)
  {
    super(0, 0);

    // BASIC SETUP
    this.sustainLength = sustainLength;
    this.fullSustainLength = sustainLength;
    this.noteDirection = noteDirection;

    setupHoldNoteGraphic(noteStyle);
    this.useNew = useNew;
    noteStyleOffsets = noteStyle.getHoldNoteOffsets();

    setIndices(TRIANGLE_VERTEX_INDICES);

    this.active = true; // This NEEDS to be true for the note to be drawn!
  }

  /**
   * Sets the indices for the triangles.
   * @param indices The indices to set.
   */
  public function setIndices(indices:Array<Int>):Void
  {
    if (this.indices.length == indices.length)
    {
      for (i in 0...indices.length)
      {
        this.indices[i] = indices[i];
      }
    }
    else
    {
      this.indices = new DrawData<Int>(indices.length, true, indices);
    }
  }

  /**
   * Sets the vertices for the triangles.
   * @param vertices The vertices to set.
   */
  public function setVertices(vertices:Array<Float>):Void
  {
    if (this.vertices.length == vertices.length)
    {
      for (i in 0...vertices.length)
      {
        this.vertices[i] = vertices[i];
      }
    }
    else
    {
      this.vertices = new DrawData<Float>(vertices.length, false, vertices);
    }
  }

  /**
   * Sets the UV data for the triangles.
   * @param uvtData The UV data to set.
   */
  public function setUVTData(uvtData:Array<Float>):Void
  {
    if (this.uvtData.length == uvtData.length)
    {
      for (i in 0...uvtData.length)
      {
        this.uvtData[i] = uvtData[i];
      }
    }
    else
    {
      this.uvtData = new DrawData<Float>(uvtData.length, false, uvtData);
    }
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

    flipY = Preferences.downscroll #if mobile
    || (Preferences.controlsScheme == FunkinHitboxControlSchemes.Arrows
      && !funkin.mobile.input.ControlsHandler.usingExternalInputDevice) #end;

    // alpha = 0.6;
    alpha = 1.0;
    updateColorTransform();

    updateClipping();
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
    var down:Bool = parentStrumline?.isDownscroll ?? false;
    var column:Int = noteData?.getDirection() ?? noteDirection % Strumline.KEY_COUNT;
    var pn:Int = parentStrumline?.modNumber ?? 0;
    var reversedOff:Float = (FlxG.height - (parentStrumline?.defaultHeight ?? 0.) - Constants.STRUMLINE_Y_OFFSET * 2);
    var xoffArray:Array<Float> = parentStrumline?.xoffArray ?? [0, 0, 0, 0];
    var ofs = ((parentStrumline?.mods?.getValue('centeredpath') ?? 0.0)
      + (parentStrumline?.mods?.getValue('centeredpath$column') ?? 0.0)) * Strumline.NOTE_SPACING;
    var timeDiff:Float = (parentStrumline?.mods?.baseHoldSize ?? 0);
    var yOffset:Float = (parentStrumline?.mods?.GetYOffset(conductorInUse, time, speed, column, strumTime) ?? 0.0) + ofs;
    var pos:Vector3D = new Vector3D(parentStrumline?.mods?.GetXPos(column, yOffset, pn, xoffArray, false, true) ?? 0.0,
      parentStrumline?.mods?.GetYPos(column, yOffset, pn, xoffArray, down, reversedOff, true, true) ?? 0.0,
      parentStrumline?.mods?.GetZPos(column, yOffset, pn, xoffArray) ?? 0.0);
    currentZValue = pos.z;
    var effect:Float = 1 - (parentStrumline?.mods?.getValue('straightholds') ?? 0);
    var noteYOffset:Float = (parentStrumline?.mods?.GetYOffset(conductorInUse, strumTime, speed, column, strumTime) ?? 0.0) + ofs;
    var notePos:Vector3D = new Vector3D(parentStrumline?.mods?.GetXPos(column, noteYOffset, pn, xoffArray, true) ?? 0.0,
      parentStrumline?.mods?.GetYPos(column, noteYOffset, pn, xoffArray, down, reversedOff) ?? 0.0,
      parentStrumline?.mods?.GetZPos(column, noteYOffset, pn, xoffArray) ?? 0.0);
    var strumPos:Vector3D = new Vector3D(parentStrumline?.mods?.GetXPos(column, ofs, pn, xoffArray, false) ?? 0.0,
      parentStrumline?.mods?.GetYPos(column, ofs, pn, xoffArray, down, reversedOff) ?? 0.0, parentStrumline?.mods?.GetZPos(column, ofs, pn, xoffArray) ?? 0.0);
    var yOffset2:Float = (parentStrumline?.mods?.GetYOffset(conductorInUse, time + timeDiff, speed, column, conductorInUse.getTimeWithDelta() + timeDiff) ?? 0)
      + ofs;
    var pos4:Vector3D = new Vector3D(parentStrumline?.mods?.GetXPos(column, yOffset2, pn, xoffArray, false, true) ?? 0,
      parentStrumline?.mods?.GetYPos(column, yOffset2, pn, xoffArray, down, reversedOff, true, true) ?? 0,
      parentStrumline?.mods?.GetZPos(column, yOffset2, pn, xoffArray) ?? 0);
    var diff = pos4.subtract(pos);
    var ang = Math.atan2(diff.y, diff.x);
    var angOrientX = Math.atan2(diff.y, diff.z);
    var angOrientY = Math.atan2(diff.z, diff.x);
    var pos2:Vector3D = notePos.clone();
    var pos3:Vector3D = strumPos.clone();
    pos2.x *= effect;
    pos2.z *= effect;
    pos3.x *= effect;
    pos3.z *= effect;
    pos.x *= effect;
    pos.z *= effect;
    var offset:Vector3D = new Vector3D(pos2.x - notePos.x, 0, pos2.z - notePos.z);
    if (hitNote && !missedNote)
    {
      offset.x = pos3.x - strumPos.x;
      offset.z = pos3.z - strumPos.z;
    }
    var noteBeat:Float = Conductor.instance.getTimeInSteps(strumTime) / Constants.STEPS_PER_BEAT;
    var rotation:Vector3D = new Vector3D(parentStrumline?.mods?.GetRotationX(column, yOffset, true, angOrientX) ?? 0.0,
      parentStrumline?.mods?.GetRotationY(column, yOffset, true, angOrientY) ?? 0.0,
      (parentStrumline?.mods?.GetRotationZ(column, yOffset, noteBeat, true, ang, true) ?? 0.0));
    var fullPos:Vector3D = pos.clone();
    var realPos:Vector3D = new Vector3D(xoff, yoff, 0, 1);
    var difference:Vector3D = (parentStrumline != null ? parentStrumline.getDifference() : new Vector3D());
    var originVec:Vector3D = new Vector3D(difference.x, FlxG.height / 2);
    var scale:Array<Float> = parentStrumline?.mods?.GetScale(column, yOffset, pn) ?? [1, 1, 0, 0, 1];
    var zoom:Float = parentStrumline?.mods?.GetZoom(column, yOffset, pn) ?? 1;
    var scalePos:Vector3D = new Vector3D(this.scale.x * scale[0] * zoom, this.scale.y * scale[1] * zoom, scale[4]);
    var skewPos:Vector3D = new Vector3D(scale[2], scale[3]);
    if (parentStrumline != null)
    {
      parentStrumline.mods.modifyPos(fullPos, scalePos, rotation, skewPos, xoffArray, reversedOff, column);
      var newZoom:Vector3D = parentStrumline.zoom.clone();
      newZoom.x *= parentStrumline.zoom2.x;
      newZoom.y *= parentStrumline.zoom2.y;
      newZoom.z *= parentStrumline.zoom2.z;
      parentStrumline.mods.modifyPosByValue(fullPos, scalePos, rotation, skewPos, column, parentStrumline.rotation.add(parentStrumline.rotation2),
        parentStrumline.skew.add(parentStrumline.skew2), newZoom);
    }
    fullPos = fullPos.add(difference);
    var m:Array<Array<Float>> = ModchartMath.translateMatrix(fullPos.x, fullPos.y, fullPos.z);
    if (parentStrumline != null)
    {
      var spiralHolds:Float = parentStrumline.mods.getValue('spiralholds');
      if (spiralHolds != 0) rotation.z += ang * ModchartMath.deg - 90;
    }
    var rotate:Array<Array<Float>> = ModchartMath.rotateMatrix(m, rotation.x, rotation.y, rotation.z, rotationOrder);
    var scaleMat:Array<Array<Float>> = ModchartMath.scaleMatrix(rotate, scalePos.x, scalePos.y, scalePos.z);
    var skew:Array<Array<Float>> = ModchartMath.skewMatrix(scaleMat, skewPos.x, skewPos.y);
    var zPos:Vector3D = ModchartMath.initPerspective(realPos, skew, fov, FlxG.width, FlxG.height,
      ModchartMath.scale(skewPos.z, 0.1, 1.0, originVec.x, FlxG.width / 2), originVec.y);
    zPos.decrementBy(offset);
    zPos.incrementBy(new Vector3D(offsetX, offsetY));
    var yposWithoutReverse:Float = parentStrumline?.mods?.GetYPos(column, yOffset, pn, xoffArray, down, reversedOff, false) ?? 0.0;
    var alpha:Float = parentStrumline?.mods?.GetAlpha(yposWithoutReverse, column, yOffset, false, true) ?? 1.0;
    var glow:Float = parentStrumline?.mods?.GetGlow(yposWithoutReverse, column, yOffset, false, true) ?? 0.0;
    var diffuses:Vector3D = new Vector3D(parentStrumline?.mods?.ArrowGetPercentRGB(column, yOffset, yposWithoutReverse, 'red') ?? 1,
      parentStrumline?.mods?.ArrowGetPercentRGB(column, yOffset, yposWithoutReverse, 'green') ?? 1,
      parentStrumline?.mods?.ArrowGetPercentRGB(column, yOffset, yposWithoutReverse, 'blue') ?? 1, alpha);
    var glowColor:Vector3D = new Vector3D((parentStrumline?.mods?.getValue('stealthglowred') ?? 1) * (parentStrumline?.mods?.getValue('stealthglowred$column') ?? 1),
      (parentStrumline?.mods?.getValue('stealthglowgreen') ?? 1) * (parentStrumline?.mods?.getValue('stealthglowgreen$column') ?? 1),
      (parentStrumline?.mods?.getValue('stealthglowblue') ?? 1) * (parentStrumline?.mods?.getValue('stealthglowblue$column') ?? 1), glow);
    return [zPos, diffuses, glowColor];
  }

  public function updateClipping(songTime:Float = 0)
  {
    if (useNew) updateClippingNew(songTime);
    else
      updateClippingOld(songTime);
  }

  var transforms:Array<ColorTransform> = [];

  public function updateClippingNew(songTime:Float = 0):Void
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
    var roughness:Float = parentStrumline?.mods?.baseHoldSize ?? 1;
    var longHolds:Float = 1 + (parentStrumline?.mods?.getValue('longholds') ?? 0.0);
    if (longHolds < 0) longHolds = 0;
    var grain:Float = parentStrumline?.mods?.getValue('granulate') ?? 0;
    if (grain == 0) grain = 4;
    var length:Int = Math.floor((fullSustainLength) / (roughness * grain));
    if (grain < 0) length = Math.floor((fullSustainLength) / (roughness / Math.abs(grain)));
    if (parentStrumline != null)
    {
      var spiralHolds:Float = parentStrumline.mods.getValue('spiralholds');
      if (spiralHolds > 0 && !parentStrumline.mods.NeedZBuffer())
      {
        length = Std.int(fullSustainLength / Strumline.NOTE_SPACING);
      }
    }
    if (length < 2) length = 2;
    var halfWidth:Float = graphicWidth / 2;
    var ct:Array<ColorTransform> = [];
    var drawsize:Float = 1 + (parentStrumline?.mods?.getValue('drawsize') ?? 0.0);
    var drawsizeback:Float = 1 + (parentStrumline?.mods?.getValue('drawsizeback') ?? 0.0);
    var renderDist:Float = FlxG.height / Constants.PIXELS_PER_MS / (parentStrumline?.scrollSpeed ?? 1);
    var frontPart:Float = Conductor.instance.getTimeWithDelta() + renderDist * drawsize;
    var backPart:Float = Conductor.instance.getTimeWithDelta() - (Constants.HIT_WINDOW_MS) * drawsizeback;
    for (i in 0...length + 1)
    {
      var a:Int = i * 2;
      var time:Float = strumTime + (fullSustainLength / length * i);
      if (hitNote && !missedNote && Conductor.instance.getTimeWithDelta() >= time) time = Conductor.instance.getTimeWithDelta();
      var pos1:Array<Vector3D> = getPosWithOffset(-halfWidth, 0, time);
      var pos2:Array<Vector3D> = getPosWithOffset(halfWidth, 0, time);
      vertices[a * 2] = pos1[0].x + halfWidth;
      vertices[a * 2 + 1] = pos1[0].y * (i == 0 ? 1 : longHolds);
      vertices[(a + 1) * 2] = pos2[0].x + halfWidth;
      vertices[(a + 1) * 2 + 1] = pos2[0].y * (i == 0 ? 1 : longHolds);
      if (time > frontPart || time < backPart)
      {
        pos1[1] = new Vector3D();
        pos1[2] = new Vector3D();
        pos2[1] = new Vector3D();
        pos2[2] = new Vector3D();
      }
      ct.push(getShader(pos1[1], pos1[2]));
      ct.push(getShader(pos2[1], pos2[2]));
      if (i == length - 1)
      {
        ct.push(getShader(pos1[1], pos1[2]));
        ct.push(getShader(pos2[1], pos2[2]));
      }
    }
    var end:Int = length * 2;
    var next:Int = (length + 1) * 2;
    var bottom:Int = (length + 2) * 2;
    vertices[next * 2] = vertices[end * 2];
    vertices[next * 2 + 1] = vertices[end * 2 + 1];
    vertices[(next + 1) * 2] = vertices[(end + 1) * 2];
    vertices[(next + 1) * 2 + 1] = vertices[(end + 1) * 2 + 1];

    var capHeight:Float = graphic.height * (bottomClip - endOffset) * zoom;
    var time:Float = strumTime + fullSustainLength + capHeight / Constants.PIXELS_PER_MS;
    if (hitNote && !missedNote && Conductor.instance.getTimeWithDelta() >= time) time = Conductor.instance.getTimeWithDelta();
    var pos1:Array<Vector3D> = getPosWithOffset(-halfWidth, 0, time);
    var pos2:Array<Vector3D> = getPosWithOffset(halfWidth, 0, time);
    vertices[bottom * 2] = pos1[0].x + halfWidth;
    vertices[bottom * 2 + 1] = pos1[0].y;
    vertices[(bottom + 1) * 2] = pos2[0].x + halfWidth;
    vertices[(bottom + 1) * 2 + 1] = pos2[0].y;
    if (time > frontPart || Conductor.instance.getTimeWithDelta() > backPart)
    {
      pos1[1] = new Vector3D();
      pos1[2] = new Vector3D();
      pos2[1] = new Vector3D();
      pos2[2] = new Vector3D();
    }
    ct.push(getShader(pos1[1], pos1[2]));
    ct.push(getShader(pos2[1], pos2[2]));

    for (i in 0...length + 1)
    {
      var fullVLength:Float = (-partHeight) / graphic.height / zoom;
      var a:Int = i * 2;
      var array:Array<Int> = [for (i in 0...length) i];
      array.reverse();
      uvtData[a * 2] = 1 / 4 * (noteDirection % 4);
      uvtData[a * 2 + 1] = (fullVLength / length * array[i]);
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
    uvtData[bottom * 2] = uvtData[next * 2];
    uvtData[bottom * 2 + 1] = bottomClip;
    uvtData[(bottom + 1) * 2] = uvtData[(next + 1) * 2];
    uvtData[(bottom + 1) * 2 + 1] = uvtData[bottom * 2 + 1];
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
    transforms = ct;
  }

  function getShader(diffPos:Vector3D, glowPos:Vector3D)
  {
    var c:ColorTransform = new ColorTransform();
    c.redMultiplier = diffPos.x;
    c.greenMultiplier = diffPos.y;
    c.blueMultiplier = diffPos.z;
    c.alphaMultiplier = diffPos.w + glowPos.w;
    c.redOffset = glowPos.x * 255 * glowPos.w;
    c.greenOffset = glowPos.y * 255 * glowPos.w;
    c.blueOffset = glowPos.z * 255 * glowPos.w;
    return c;
  }

  public function updateClippingOld(songTime:Float = 0):Void
  {
    if (graphic == null || customVertexData)
    {
      return;
    }
    var clipHeight:Float = sustainHeight(sustainLength - (songTime - strumTime), parentStrumline?.scrollSpeed ?? 1.0).clamp(0, graphicHeight);
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
    setIndices(TRIANGLE_VERTEX_INDICES);
  }

  @:access(flixel.FlxCamera)
  override public function draw():Void
  {
    if (alpha == 0 || graphic == null || vertices == null || !visible) return;

    for (camera in cameras)
    {
      if (!camera.visible || !camera.exists) continue;
      // if (!isOnScreen(camera)) continue; // TODO: Update this code to make it work properly.

      if (useNew)
      {
        #if !flash
        var drawItem = camera.startTrianglesBatch(graphic, antialiasing, true, blend, true, shader);
        drawItem.addTriangles2(vertices, indices, uvtData, new DrawData<Int>(4, true, [0, 0, 0, 0]), _point, camera._bounds, transforms);
        #else
        useNew = false;
        #end
      }
      else
      {
        getScreenPosition(_point, camera).subtractPoint(offset);
        camera.drawTriangles(graphic, vertices, indices, uvtData, null, _point, blend, true, antialiasing, colorTransform, shader);
      }
    }

    #if FLX_DEBUG
    if (FlxG.debugger.drawDebug) drawDebug();
    #end
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
  }

  override public function destroy():Void
  {
    vertices = null;
    indices = null;
    uvtData = null;

    super.destroy();
  }
}
