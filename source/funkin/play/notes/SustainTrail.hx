package funkin.play.notes;

import funkin.play.notes.notestyle.NoteStyle;
import funkin.data.song.SongData.SongNoteData;
import funkin.mobile.ui.FunkinHitbox.FunkinHitboxControlSchemes;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.tile.FlxDrawTrianglesItem.DrawData;
import flixel.math.FlxMath;
import funkin.play.modchart.util.ModchartMath;
import openfl.geom.Vector3D;
import flixel.math.FlxPoint;
import funkin.play.modchart.util.ModchartMath;
import flixel.util.FlxColor;

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

  public var defaultScale:Array<Float> = [1, 1];
  public var offsetX:Float;
  public var offsetY:Float;
  public var currentZValue:Float = 0;

  /**
   * Normally you would take strumTime:Float, noteData:Int, sustainLength:Float, parentNote:Note (?)
   * @param NoteData
   * @param SustainLength Length in milliseconds.
   * @param fileName
   */
  public function new(noteDirection:NoteDirection, sustainLength:Float, noteStyle:NoteStyle)
  {
    super(0, 0);

    // BASIC SETUP
    this.sustainLength = sustainLength;
    this.fullSustainLength = sustainLength;
    this.noteDirection = noteDirection;

    setupHoldNoteGraphic(noteStyle);
    defaultScale = [scale.x, scale.y];
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
    if (previousScrollSpeed != (parentStrumline?.scrollSpeed ?? 1.0))
    {
      triggerRedraw();
    }
    updateClipping();
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
    var ofs = (parentStrumline?.mods?.getValue('centered2') ?? 0.0) * Strumline.NOTE_SPACING;
    var timeDiff:Float = (parentStrumline?.mods?.baseHoldSize ?? 0);
    var yOffset:Float = (parentStrumline?.mods?.GetYOffset(conductorInUse, time, speed, column, strumTime) ?? 0.0) + ofs;
    var pos:Vector3D = new Vector3D(parentStrumline?.mods?.GetXPos(column, yOffset, pn, xoffArray, false) ?? 0.0,
      parentStrumline?.mods?.GetYPos(column, yOffset, pn, xoffArray, down, reversedOff) ?? 0.0,
      parentStrumline?.mods?.GetZPos(column, yOffset, pn, xoffArray) ?? 0.0);
    currentZValue = pos.z;
    var effect:Float = 1 + (parentStrumline?.mods?.getValue('gayholds') ?? 0);
    var noteYOffset:Float = (parentStrumline?.mods?.GetYOffset(conductorInUse, strumTime, speed, column, strumTime) ?? 0.0) + ofs;
    var notePos:Vector3D = new Vector3D(parentStrumline?.mods?.GetXPos(column, noteYOffset, pn, xoffArray, true) ?? 0.0,
      parentStrumline?.mods?.GetYPos(column, noteYOffset, pn, xoffArray, down, reversedOff) ?? 0.0,
      parentStrumline?.mods?.GetZPos(column, noteYOffset, pn, xoffArray) ?? 0.0);
    var strumPos:Vector3D = new Vector3D(parentStrumline?.mods?.GetXPos(column, ofs, pn, xoffArray, false) ?? 0.0,
      parentStrumline?.mods?.GetYPos(column, ofs, pn, xoffArray, down, reversedOff) ?? 0.0, parentStrumline?.mods?.GetZPos(column, ofs, pn, xoffArray) ?? 0.0);
    var yOffset2:Float = (parentStrumline?.mods?.GetYOffset(conductorInUse, time + timeDiff, speed, column, conductorInUse.getTimeWithDelta() + timeDiff) ?? 0)
      + ofs;
    var pos4:Vector3D = new Vector3D(parentStrumline?.mods?.GetXPos(column, yOffset2, pn, xoffArray, false) ?? 0,
      parentStrumline?.mods?.GetYPos(column, yOffset2, pn, xoffArray, down, reversedOff) ?? 0,
      parentStrumline?.mods?.GetZPos(column, yOffset2, pn, xoffArray) ?? 0);
    if (parentStrumline != null)
    {
      parentStrumline.mods.modifyPos(pos, xoffArray, reversedOff);
      parentStrumline.mods.modifyPos(notePos, xoffArray, reversedOff);
      parentStrumline.mods.modifyPos(strumPos, xoffArray, reversedOff);
      parentStrumline.mods.modifyPos(pos4, xoffArray, reversedOff);
    }
    var diff = pos4.subtract(pos);
    var ang = Math.atan2(diff.y, diff.x);
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
    var noteBeat:Float = (strumTime / 1000) * (Conductor.instance.bpm / 60);
    var rotation:Vector3D = new Vector3D(parentStrumline?.mods?.GetRotationX(column, yOffset, true) ?? 0.0,
      parentStrumline?.mods?.GetRotationY(column, yOffset, true) ?? 0.0,
      (parentStrumline?.mods?.GetRotationZ(column, yOffset, noteBeat, true, ang) ?? 0.0) + this.angle);
    var fullPos:Vector3D = pos;
    var realPos:Vector3D = new Vector3D(xoff, yoff);
    var scale:Array<Float> = parentStrumline?.mods?.GetScale(column, yOffset, pn, defaultScale) ?? [1, 1, 0, 0, 1];
    var zoom:Float = parentStrumline?.mods?.GetZoom(column, yOffset, pn) ?? 1;
    var yposWithoutReverse:Float = parentStrumline?.mods?.GetYPos(column, yOffset, pn, xoffArray, down, parentStrumline?.defaultHeight ?? 0.0, false) ?? 0.0;
    var scaledPos:Vector3D = ModchartMath.scaleVector3(realPos, scale[0] * zoom, scale[1] * zoom, scale[4]);
    var skewedPos:Vector3D = ModchartMath.skewVector2(scaledPos, scale[2], scale[3]);
    var rotatedPos:Vector3D = ModchartMath.rotateVector3(skewedPos, rotation.x, rotation.y, rotation.z);
    var origin:Vector3D = new Vector3D(0, reversedOff / 2);
    var zPos:Vector3D = ModchartMath.PerspectiveProjection(rotatedPos.add(new Vector3D(fullPos.x, fullPos.y, fullPos.z - 1000)), origin).subtract(fullPos);
    zPos.incrementBy(new Vector3D(fullPos.x, fullPos.y));
    zPos.decrementBy(offset);
    zPos.incrementBy(new Vector3D(offsetX, offsetY));
    var alpha:Float = parentStrumline?.mods?.GetAlpha(yposWithoutReverse, column, yOffset, false, true) ?? 1.0;
    var glow:Float = parentStrumline?.mods?.GetGlow(yposWithoutReverse, column, yOffset, false, true) ?? 0.0;
    var defaultColor:Vector3D = new Vector3D((color >> 16) & 0xFF, (color >> 8) & 0xFF, color & 0xFF);
    var color:Vector3D = new Vector3D(glow * 255
      + defaultColor.x * (1 - glow), glow * 255
      + defaultColor.y * (1 - glow),
      glow * 255
      + defaultColor.z * (1 - glow));
    color.scaleBy(alpha);
    return [zPos, color];
  }

  public function updateClipping(songTime:Float = 0, useNew:Bool = true)
  {
    if (useNew) updateClippingNew(songTime);
    else
      updateClippingOld(songTime);
  }

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

    var roughness:Float = parentStrumline?.mods?.baseHoldSize ?? 64;
    var grain:Float = parentStrumline?.mods?.getValue('granulate') ?? 0;
    var length:Int = Math.round((fullSustainLength) / (roughness * (1 + grain)));
    if (grain < 0) length = Math.round((fullSustainLength) / (roughness / (1 + Math.abs(grain))));
    if (length <= 1) length = 1;
    var halfWidth:Float = graphicWidth / 2;
    for (i in 0...length)
    {
      var a:Int = i * 2;
      var time:Float = strumTime + (fullSustainLength / length * i);
      if (hitNote && !missedNote && Conductor.instance.songPosition >= strumTime)
      {
        time = Conductor.instance.songPosition + (sustainLength / length * i);
      }
      var pos1:Array<Vector3D> = getPosWithOffset(-halfWidth, 0, time);
      var pos2:Array<Vector3D> = getPosWithOffset(halfWidth, 0, time);
      vertices[a * 2] = pos1[0].x + halfWidth;
      vertices[a * 2 + 1] = pos1[0].y;
      vertices[(a + 1) * 2] = pos2[0].x + halfWidth;
      vertices[(a + 1) * 2 + 1] = pos2[0].y;
      // colors[a * 2] = colors[a * 2 + 1] = FlxColor.fromRGBFloat(pos1[1].x, pos1[1].y, pos1[1].z).to24Bit();
      // colors[(a + 1) * 2] = colors[(a + 1) * 2 + 1] = FlxColor.fromRGBFloat(pos2[1].x, pos2[1].y, pos2[1].z).to24Bit();
    }

    var end:Int = (length - 1) * 2;
    var next:Int = length * 2;
    vertices[next * 2] = vertices[end * 2];
    vertices[next * 2 + 1] = vertices[end * 2 + 1];
    vertices[(next + 1) * 2] = vertices[(end + 1) * 2];
    vertices[(next + 1) * 2 + 1] = vertices[(end + 1) * 2 + 1];
    var bottom:Int = (length + 1) * 2;
    var time:Float = strumTime + fullSustainLength;
    if (hitNote && !missedNote && Conductor.instance.songPosition >= strumTime)
    {
      time = Conductor.instance.songPosition + sustainLength;
    }
    var pos1:Array<Vector3D> = getPosWithOffset(-halfWidth, 0, time);
    var pos2:Array<Vector3D> = getPosWithOffset(halfWidth, 0, time);
    vertices[bottom * 2] = pos1[0].x + halfWidth;
    vertices[bottom * 2 + 1] = pos1[0].y;
    vertices[(bottom + 1) * 2] = pos2[0].x + halfWidth;
    vertices[(bottom + 1) * 2 + 1] = pos2[0].y;
    // colors[bottomnext * 2] = colors[bottomnext * 2 + 1] = FlxColor.fromRGBFloat(pos1[1].x, pos1[1].y, pos1[1].z).to24Bit();
    // colors[(bottomnext + 1) * 2] = colors[(bottomnext + 1) * 2 + 1] = FlxColor.fromRGBFloat(pos2[1].x, pos2[1].y, pos2[1].z).to24Bit();

    for (i in 0...length)
    {
      var a:Int = i * 2;
      uvtData[a * 2] = 1 / 4 * (noteDirection % 4);
      uvtData[a * 2 + 1] = ModchartMath.lerp(1 / (i + 1), (-partHeight) / graphic.height / zoom, 0) * (flipY ? -1 : 1);
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
  }

  /**
   * Sets up new vertex and UV data to clip the trail.
   * If flipY is true, top and bottom bounds swap places.
   * @param songTime	The time to clip the note at, in milliseconds.
   */
  public function updateClippingOld(songTime:Float = 0):Void
  {
    if (graphic == null || customVertexData)
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

    var idx:Int = 0;
    while (idx < vertices.length)
    {
      var column:Int = noteData?.getDirection() ?? noteDirection % Strumline.KEY_COUNT;
      var defX:Float = parentStrumline?.xoffArray[column] ?? 0.0;
      var diff:Null<Vector3D> = parentStrumline?.getDifference();
      vertices[idx] += defX + offsetX;
      var speed:Float = parentStrumline?.scrollSpeed ?? 1.0;
      vertices[idx + 1] += funkin.util.GRhythmUtil.getNoteY(strumTime, speed, parentStrumline?.isDownscroll ?? false) + offsetY;
      if (diff != null)
      {
        vertices[idx] -= diff.x;
        vertices[idx + 1] -= diff.y;
      }
      idx += 2;
    }
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
      camera.drawTriangles(graphic, vertices, indices, uvtData, null, _point, blend, true, antialiasing, colorTransform, shader);
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
