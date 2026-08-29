package funkin.play.notes;

import funkin.play.notes.notestyle.NoteStyle;
import funkin.data.song.SongData.SongNoteData;
import funkin.mobile.ui.FunkinHitbox.FunkinHitboxControlSchemes;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.tile.FlxDrawTrianglesItem.DrawData;
import flixel.math.FlxMath;
import openfl.geom.Vector3D;
import openfl.geom.ColorTransform;
import funkin.play.modchart.util.ModchartMath;
import funkin.play.modchart.Modchart;

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
  public var parentStrumline:Strumline;

  public var cover:NoteHoldCover = null;

  /**
   * The note data associated with this hold note sprite.
   * This is used to store the strum time, length, and other properties.
   */
  public var noteData:Null<SongNoteData>;

  /**
   * Set this to `false` to disable scoring for this note.
   * The note will no longer count towards ratings, points, or accuracy.
   * @default `true` to enable scoring.
   */
  public var scoreable:Bool = true;

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
    this.useNew = useNew;
    setupHoldNoteGraphic(noteStyle);
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
      this.indices = new DrawData<Int>(indices.length, false, indices);
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
      && !funkin.mobile.input.ControlsHandler.hasExternalInputDevice) #end;

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
  var updatedThisFrame:Bool = false;

  override function update(elapsed)
  {
    super.update(elapsed);
    updatedThisFrame = false;
    if (previousScrollSpeed != (parentStrumline?.scrollSpeed ?? 1.0))
    {
      triggerRedraw();
    }
    if (!updatedThisFrame && useNew) updateClipping();
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

  var spPos:Vector3D = new Vector3D();
  var spZoom:Vector3D = new Vector3D();
  var spSkew:Vector3D = new Vector3D();
  var spStealth:Vector3D = new Vector3D();
  var realSpZoom:Float = 1;
  var realSpStealth:Float = 0;
  var left:Vector3D = new Vector3D(1, 0, 0, 1);
  var right:Vector3D = new Vector3D(1, 0, 0, 1);

  function clearout():Void
  {
    spZoom = spSkew = spPos = spStealth = left = right = null;
  }

  function getPos(width:Float, time:Float):Array<Vector3D>
  {
    var mods:Modchart = parentStrumline.mods;
    var conductorInUse:Conductor = parentStrumline.conductorInUse;
    var speed:Float = parentStrumline.scrollSpeed;
    var down:Bool = parentStrumline.isDownscroll;
    var column:Int = noteData?.getDirection() ?? noteDirection % Strumline.KEY_COUNT;
    var pn:Int = parentStrumline.modNumber;
    var xoffArray:Array<Float> = parentStrumline.xoffArray;
    var ofs:Float = (mods.getValue('centeredpath') + mods.getValue('centeredpath$column')) * Strumline.NOTE_SPACING;
    var timeDiff:Float = mods.baseHoldSize;
    var yOffset:Float = mods.GetYOffset(conductorInUse, time, speed, column, strumTime) + ofs;
    var pos:Vector3D = new Vector3D(mods.GetXPos(column, yOffset, pn, xoffArray, false, true),
      mods.GetYPos(column, yOffset, pn, xoffArray, down, true, true) + this.yOffset, mods.GetZPos(column, yOffset, pn, xoffArray));
    var difference:Vector3D = parentStrumline.getDifference();
    var originVec:Vector3D = new Vector3D(difference.x, FlxG.height / 2);
    var strumPos:Vector3D = new Vector3D(mods.GetXPos(column, ofs, pn, xoffArray, false), mods.GetYPos(column, ofs, pn, xoffArray, down),
      mods.GetZPos(column, ofs, pn, xoffArray));
    var effect:Float = 1 - mods.getValue('straightholds');
    var noteYOffset:Float = mods.GetYOffset(conductorInUse, strumTime, speed, column, strumTime) + ofs;
    var notePos:Vector3D = new Vector3D(mods.GetXPos(column, noteYOffset, pn, xoffArray, true), mods.GetYPos(column, noteYOffset, pn, xoffArray, down),
      mods.GetZPos(column, noteYOffset, pn, xoffArray));
    var yOffset2:Float = mods.GetYOffset(conductorInUse, time + timeDiff, speed, column, conductorInUse.getTimeWithDelta() + timeDiff) + ofs;
    var pos4:Vector3D = new Vector3D(mods.GetXPos(column, yOffset2, pn, xoffArray, false, true),
      mods.GetYPos(column, yOffset2, pn, xoffArray, down, true, true) + this.yOffset, mods.GetZPos(column, yOffset2, pn, xoffArray));
    var angles:Vector3D = ModchartMath.getDirectionsBetweenTwoVectors(pos, pos4);
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
    var rotation:Vector3D = new Vector3D(mods.GetRotationX(column, yOffset, true, angles.x, true), mods.GetRotationY(column, yOffset, true, angles.y, true),
      mods.GetRotationZ(column, yOffset, noteBeat, true, angles.z, true));
    var fullPos:Vector3D = pos.clone();
    var scale:Array<Float> = mods.GetScale(column, yOffset, pn);
    var scalePos:Vector3D = new Vector3D(this.scale.x * scale[0], this.scale.y * scale[1], scale[4]);
    var skewPos:Vector3D = new Vector3D(scale[2], scale[3]);
    mods.modifyPos(fullPos, scalePos, rotation, skewPos, xoffArray, column);
    var zoom2:Vector3D = parentStrumline.zoom2;
    var zoom1:Vector3D = parentStrumline.zoom;
    var newZoom:Vector3D = new Vector3D(zoom1.x * zoom2.x, zoom1.y * zoom2.y, zoom1.z * zoom2.z);
    mods.modifyPosByValue(fullPos, scalePos, rotation, skewPos, column, parentStrumline.rotation.add(parentStrumline.rotation2),
      parentStrumline.skew.add(parentStrumline.skew2), newZoom);
    if (mods.getValue('spiralholds') != 0) rotation.z += angles.z * ModchartMath.deg - 90;
    parentStrumline.getSplineAxisPos('pos', column, yOffset, 1, spPos);
    parentStrumline.getSplineAxisPos('zoom', column, yOffset, 1, spZoom);
    realSpZoom = 1 - 0.5 * spZoom.x;
    parentStrumline.getSplineAxisPos('stealth', column, yOffset, 1, spStealth);
    realSpStealth = ModchartMath.clamp(1 - spStealth.x, 0, 1);
    parentStrumline.getSplineAxisPos('skew', column, yOffset, 1, spSkew);
    fullPos.incrementBy(spPos);
    fullPos.incrementBy(difference);
    scalePos.scaleBy(realSpZoom);
    skewPos.x += spSkew.x;
    left.x = -width / 2;
    right.x = -left.x;
    var zPos:Array<Vector3D> = ModchartMath.processActor(fullPos, [left, right], rotation, scalePos, skewPos, originVec, parentStrumline.fov, rotationOrder,
      offsetX, offsetY);
    zPos[0].decrementBy(offset);
    zPos[1].decrementBy(offset);
    var yposWithoutReverse:Float = mods.GetYPos(column, yOffset, pn, xoffArray, down, false);
    var none:Bool = mods.ArrowGetPercentVisible(yposWithoutReverse, column, yOffset, false, true) >= 1.0;
    var splineStealth:Float = realSpStealth > 0.5 ? 1.0 : 0.0;
    var alpha:Float = mods.GetAlpha(yposWithoutReverse, column, yOffset, false, true);
    if (none) alpha = splineStealth;
    alpha *= this.alpha * parentStrumline.alpha;
    var glow:Float = mods.GetGlow(yposWithoutReverse, column, yOffset, false, true);
    var splineGlow:Float = ModchartMath.scale(Math.abs(realSpStealth - 0.5), 0, 0.5, 1.3, 0);
    var diffuses:Vector3D = new Vector3D(mods.ArrowGetPercentRGB(column, yOffset, yposWithoutReverse, 'red'),
      mods.ArrowGetPercentRGB(column, yOffset, yposWithoutReverse, 'green'), mods.ArrowGetPercentRGB(column, yOffset, yposWithoutReverse, 'blue'), alpha);
    var glowColor:Vector3D = new Vector3D(mods.getValue('stealthglowred') * mods.getValue('stealthglowred$column'),
      mods.getValue('stealthglowgreen') * mods.getValue('stealthglowgreen$column'),
      mods.getValue('stealthglowblue') * mods.getValue('stealthglowblue$column'), none ? splineGlow : glow);
    zPos.push(diffuses);
    zPos.push(glowColor);
    return zPos;
  }

  public function updateClipping(songTime:Float = 0)
  {
    if (useNew) updateClippingNew(songTime);
    else
      updateClippingOld(songTime);
  }

  function longHoldsOffsetedYPos(dry0:Float, dry1:Float, value:Float, noteY:Array<Float>, reverse:Int, trueIndex:Int):Array<Float>
  {
    if (trueIndex == 0 || noteY.length < 0) return [dry0, dry1, 0];

    var p:Array<Float> = [value * dry0, value * dry1, 0];
    if (p[0] * reverse < noteY[0] * reverse)
    {
      p[0] = noteY[0];
      p[2] += 1;
    }
    if (p[1] * reverse < noteY[1] * reverse)
    {
      p[1] = noteY[1];
      p[2] += 1;
    }
    return p;
  }

  public var transforms:Array<ColorTransform> = [];

  // recognize multiple hold parts
  var verticesArray:Array<Float> = [];
  var uvtDataArray:Array<Float> = [];
  var indicesArray:Array<Int> = [];

  public function updateClippingNew(songTime:Float = 0):Void
  {
    if (graphic == null || parentStrumline == null || updatedThisFrame)
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
    var drawsize:Float = 1 + parentStrumline.mods.getValue('drawsize');
    var drawsizeback:Float = 1 + parentStrumline.mods.getValue('drawsizeback');
    var scrollSpeed:Float = parentStrumline.scrollSpeed * Constants.PIXELS_PER_MS;
    if (scrollSpeed < 0.01) scrollSpeed = 0.01;
    var draw_ms_after_targets:Float = -parentStrumline.pathSizeBack * drawsizeback / scrollSpeed;
    var centered_times_boomerang:Float = parentStrumline.mods.getValue('centered') * parentStrumline.mods.getValue('boomerang');
    draw_ms_after_targets -= Std.int(ModchartMath.scale(centered_times_boomerang, 0.0, 1.0, 0.0, -FlxG.height / 2));
    var draw_ms_before_targets:Float = parentStrumline.pathSizeFront * drawsize / scrollSpeed;
    var draw_scale:Float = 1 + 0.5 * Math.abs(parentStrumline.mods.tilt);
    draw_scale *= 1 + Math.abs(parentStrumline.mods.getValue('mini'));
    draw_ms_after_targets *= draw_scale;
    draw_ms_before_targets *= draw_scale;
    var roughness:Float = parentStrumline.mods.baseHoldSize * (1 / scrollSpeed);
    var column:Int = noteData?.getDirection() ?? noteDirection % Strumline.KEY_COUNT;
    var reverse_mult:Int = parentStrumline.mods.GetReversePercentForColumn(column) > 0.5 ? -1 : 1;
    var longHolds:Float = 1 + parentStrumline.mods.getValue('longholds');
    if (longHolds < 0) longHolds = 0;
    var noteY:Array<Float> = [];
    var grain:Float = parentStrumline.mods.getValue('granulate');
    if (Math.abs(grain) <= FlxMath.EPSILON) grain = 4;
    var length:Int = Math.floor((fullSustainLength) / (roughness * grain));
    if (grain < 0) length = Math.floor((fullSustainLength) / (1 / (roughness * Math.abs(grain))));
    if (parentStrumline.mods.getValue('spiralholds') > 0
      && !parentStrumline.mods.NeedZBuffer()) length = Std.int(fullSustainLength / Strumline.NOTE_SPACING);
    if (length < 2) length = 2;
    var drawTail:Bool = true;
    var trueIndex:Int = 0;
    verticesArray.resize(0);
    uvtDataArray.resize(0);
    indicesArray.resize(0);
    for (i in 0...length + 1)
    {
      var time:Float = strumTime + (fullSustainLength / length * i);
      var nextTime:Float = time + fullSustainLength / length;
      var diff:Float = time - Conductor.instance.getTimeWithDelta();
      var isHitting:Bool = hitNote && !missedNote;
      if (isHitting && Conductor.instance.getTimeWithDelta() >= time) time = Conductor.instance.getTimeWithDelta();
      if (isHitting && Conductor.instance.getTimeWithDelta() >= nextTime) nextTime = Conductor.instance.getTimeWithDelta();
      var skip:Bool = FlxMath.equal(time - nextTime, 0);
      if (!(draw_ms_after_targets <= diff && diff <= draw_ms_before_targets) || (skip && hitNote))
      {
        if (i == length) drawTail = false;
        continue;
      }
      var a:Int = trueIndex * 2;
      var pos:Array<Vector3D> = getPos(graphicWidth, time);
      if (a == 0) noteY = [pos[0].y, pos[1].y];
      var ypos:Array<Float> = longHoldsOffsetedYPos(pos[0].y, pos[1].y, longHolds, noteY, reverse_mult, trueIndex);
      if (ypos[2] > 2)
      {
        if (i == length) drawTail = false;
        continue;
      }
      verticesArray[a * 2] = pos[0].x + graphicWidth / 2;
      verticesArray[a * 2 + 1] = ypos[0];
      verticesArray[(a + 1) * 2] = pos[1].x + graphicWidth / 2;
      verticesArray[(a + 1) * 2 + 1] = ypos[1];

      transforms[trueIndex * 2] = getShader(pos[2], pos[3]);
      transforms[trueIndex * 2 + 1] = getShader(pos[2], pos[3]);

      var fullVLength:Float = (-partHeight) / graphic.height / zoom;
      uvtDataArray[a * 2] = 1 / 4 * (noteDirection % 4);
      uvtDataArray[a * 2 + 1] = (fullVLength / length * i);
      uvtDataArray[(a + 1) * 2] = uvtDataArray[a * 2] + 1 / 8;
      uvtDataArray[(a + 1) * 2 + 1] = uvtDataArray[a * 2 + 1];

      indicesArray[trueIndex * 6 + 0] = a + 1;
      indicesArray[trueIndex * 6 + 1] = a + 2;
      indicesArray[trueIndex * 6 + 2] = a + 0;
      indicesArray[trueIndex * 6 + 3] = a + 1;
      indicesArray[trueIndex * 6 + 4] = a + 3;
      indicesArray[trueIndex * 6 + 5] = a + 2;

      trueIndex++;
    }

    var end:Int = (trueIndex - 1) * 2;
    var next:Int = trueIndex * 2;
    if (drawTail)
    {
      verticesArray[next * 2] = verticesArray[end * 2];
      verticesArray[next * 2 + 1] = verticesArray[end * 2 + 1];
      verticesArray[(next + 1) * 2] = verticesArray[(end + 1) * 2];
      verticesArray[(next + 1) * 2 + 1] = verticesArray[(end + 1) * 2 + 1];
      uvtDataArray[next * 2] = 1 / 4 * (noteDirection % 4) + 1 / 8;
      uvtDataArray[next * 2 + 1] = if (partHeight > 0)
      {
        0;
      }
      else
      {
        (bottomHeight - clipHeight) / zoom / graphic.height;
      };
      uvtDataArray[(next + 1) * 2] = uvtDataArray[next * 2] + 1 / 8;
      uvtDataArray[(next + 1) * 2 + 1] = uvtDataArray[next * 2 + 1];
      transforms[next] = transforms[end];
      transforms[next + 1] = transforms[end + 1];
      indicesArray[trueIndex * 6 + 0] = next + 1;
      indicesArray[trueIndex * 6 + 1] = next + 2;
      indicesArray[trueIndex * 6 + 2] = next + 0;
      indicesArray[trueIndex * 6 + 3] = next + 1;
      indicesArray[trueIndex * 6 + 4] = next + 3;
      indicesArray[trueIndex * 6 + 5] = next + 2;
      trueIndex++;

      var bottom:Int = trueIndex * 2;
      var capHeight:Float = graphic.height * (bottomClip - endOffset) * zoom;
      var time:Float = strumTime + fullSustainLength + capHeight;
      if (hitNote && !missedNote && Conductor.instance.getTimeWithDelta() >= time) time = Conductor.instance.getTimeWithDelta();
      var pos:Array<Vector3D> = getPos(graphicWidth, time);
      var ypos:Array<Float> = longHoldsOffsetedYPos(pos[0].y, pos[1].y, longHolds, noteY, reverse_mult, trueIndex);
      if (ypos[2] < 2)
      {
        verticesArray[bottom * 2] = pos[0].x + graphicWidth / 2;
        verticesArray[bottom * 2 + 1] = ypos[0];
        verticesArray[(bottom + 1) * 2] = pos[1].x + graphicWidth / 2;
        verticesArray[(bottom + 1) * 2 + 1] = ypos[1];
        transforms[bottom] = getShader(pos[2], pos[3]);
        transforms[bottom + 1] = getShader(pos[2], pos[3]);
        uvtDataArray[bottom * 2] = uvtDataArray[next * 2];
        uvtDataArray[bottom * 2 + 1] = bottomClip;
        uvtDataArray[(bottom + 1) * 2] = uvtDataArray[(next + 1) * 2];
        uvtDataArray[(bottom + 1) * 2 + 1] = uvtDataArray[bottom * 2 + 1];
      }
      else
        indicesArray.splice(-6, 6);
    }
    else
    {
      indicesArray.splice(-6, 6);
    }
    setVertices(verticesArray);
    setUVTData(uvtDataArray);
    setIndices(indicesArray);
    updatedThisFrame = true;
  }

  function getShader(diffPos:Vector3D, glowPos:Vector3D)
  {
    var c:ColorTransform = new ColorTransform();
    c.redMultiplier = diffPos.x * colorTransform.redMultiplier;
    c.greenMultiplier = diffPos.y * colorTransform.greenMultiplier;
    c.blueMultiplier = diffPos.z * colorTransform.blueMultiplier;
    c.alphaMultiplier = diffPos.w * colorTransform.alphaMultiplier + glowPos.w;
    c.redOffset = glowPos.x * 255 * glowPos.w + colorTransform.redOffset;
    c.greenOffset = glowPos.y * 255 * glowPos.w + colorTransform.greenOffset;
    c.blueOffset = glowPos.z * 255 * glowPos.w + colorTransform.blueOffset;
    return c;
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

    updatedThisFrame = true;
  }

  @:access(flixel.FlxCamera)
  override public function draw():Void
  {
    if (alpha == 0 || graphic == null || vertices == null || !visible || !alive) return;

    for (camera in cameras)
    {
      if (!camera.visible || !camera.exists) continue;
      // if (!isOnScreen(camera)) continue; // TODO: Update this code to make it work properly.
      getScreenPosition(_point, camera).subtractPoint(offset);
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
        camera.drawTriangles(graphic, vertices, indices, uvtData, null, _point, blend, true, antialiasing, colorTransform, shader);
    }

    #if FLX_DEBUG
    if (FlxG.debugger.drawDebug) drawDebug();
    #end
  }

  public override function kill():Void
  {
    super.kill();

    if (!((cover?.animation?.name ?? "").startsWith("holdCoverEnd"))) cover?.playEnd();
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
    transforms.splice(0, transforms.length);
    clearout();
    super.destroy();
  }
}
