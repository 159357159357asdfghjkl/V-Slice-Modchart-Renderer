package funkin.play.notes;

import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.FlxG;
import funkin.play.notes.notestyle.NoteStyle;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxSort;
import funkin.play.notes.NoteHoldCover;
import funkin.play.notes.NoteSplash;
import funkin.play.notes.NoteSprite;
import funkin.play.notes.SustainTrail;
import funkin.data.song.SongData.SongNoteData;
import funkin.ui.options.PreferencesMenu;
import funkin.util.SortUtil;
import funkin.modding.events.ScriptEvent;
import funkin.play.notes.notekind.NoteKindManager;
import funkin.play.modchart.Modchart;
import funkin.play.modchart.util.ModchartMath;
import openfl.geom.Vector3D;
import flixel.FlxG;
import flixel.math.FlxMath;
import openfl.Vector;
import openfl.geom.Vector3D;
import openfl.display.BitmapData;
import openfl.display.GraphicsPathCommand;
import openfl.geom.Matrix;

/**
 * A group of sprites which handles the receptor, the note splashes, and the notes (with sustains) for a given player.
 */
class Strumline extends FlxSpriteGroup
{
  public static final DIRECTIONS:Array<NoteDirection> = [NoteDirection.LEFT, NoteDirection.DOWN, NoteDirection.UP, NoteDirection.RIGHT];
  public static final STRUMLINE_SIZE:Int = 104;
  public static final NOTE_SPACING:Int = STRUMLINE_SIZE + 8;

  // Positional fixes for new strumline graphics.
  static final INITIAL_OFFSET = -0.275 * STRUMLINE_SIZE;
  static final NUDGE:Float = 2.0;

  public static final KEY_COUNT:Int = 4;
  static final NOTE_SPLASH_CAP:Int = 6;

  static var RENDER_DISTANCE_MS(get, never):Float;

  static function get_RENDER_DISTANCE_MS():Float
  {
    return FlxG.height / Constants.PIXELS_PER_MS;
  }

  /**
   * Whether this strumline is controlled by the player's inputs.
   * False means it's controlled by the opponent or Bot Play.
   */
  public var isPlayer:Bool;

  /**
   * Usually you want to keep this as is, but if you are using a Strumline and
   * playing a sound that has it's own conductor, set this (LatencyState for example)
   */
  public var conductorInUse(get, set):Conductor;

  // Used in-game to control the scroll speed within a song
  public var scrollSpeed:Float = 1.0;

  public function resetScrollSpeed():Void
  {
    scrollSpeed = PlayState.instance?.currentChart?.scrollSpeed ?? 1.0;
  }

  var _conductorInUse:Null<Conductor>;

  function get_conductorInUse():Conductor
  {
    if (_conductorInUse == null) return Conductor.instance;
    return _conductorInUse;
  }

  function set_conductorInUse(value:Conductor):Conductor
  {
    return _conductorInUse = value;
  }

  /**
   * The notes currently being rendered on the strumline.
   * This group iterates over this every frame to update note positions.
   * The PlayState also iterates over this to calculate user inputs.
   */
  public var notes:FlxTypedSpriteGroup<NoteSprite>;

  public var holdNotes:FlxTypedSpriteGroup<SustainTrail>;

  public var onNoteIncoming:FlxTypedSignal<NoteSprite->Void>;

  var strumlineNotes:FlxTypedSpriteGroup<StrumlineNote>;
  var strumLineNotes:Array<StrumlineNote> = [];
  var noteSplashes:FlxTypedSpriteGroup<NoteSplash>;
  var noteHoldCovers:FlxTypedSpriteGroup<NoteHoldCover>;

  var notesVwoosh:FlxTypedSpriteGroup<NoteSprite>;
  var holdNotesVwoosh:FlxTypedSpriteGroup<SustainTrail>;

  final noteStyle:NoteStyle;

  #if FEATURE_GHOST_TAPPING
  var ghostTapTimer:Float = 0.0;
  #end

  /**
   * The note data for the song. Should NOT be altered after the song starts,
   * so we can easily rewind.
   */
  var noteData:Array<SongNoteData> = [];

  var nextNoteIndex:Int = -1;

  var heldKeys:Array<Bool> = [];

  public var mods:Modchart;
  public var modNumber:Int;

  public var defaultHeight:Float = 0.0;
  public var xoffArray:Array<Float> = [-NOTE_SPACING * 1.5, -NOTE_SPACING / 2, NOTE_SPACING / 2, NOTE_SPACING * 1.5];

  public function new(noteStyle:NoteStyle, isPlayer:Bool, modNumber:Int)
  {
    super();

    this.isPlayer = isPlayer;
    this.noteStyle = noteStyle;
    this.modNumber = modNumber;

    this.strumlineNotes = new FlxTypedSpriteGroup<StrumlineNote>();
    this.strumlineNotes.zIndex = 10;
    this.add(this.strumlineNotes);

    // Hold notes are added first so they render behind regular notes.
    this.holdNotes = new FlxTypedSpriteGroup<SustainTrail>();
    this.holdNotes.zIndex = 20;
    this.add(this.holdNotes);

    this.holdNotesVwoosh = new FlxTypedSpriteGroup<SustainTrail>();
    this.holdNotesVwoosh.zIndex = 21;
    this.add(this.holdNotesVwoosh);

    this.notes = new FlxTypedSpriteGroup<NoteSprite>();
    this.notes.zIndex = 30;
    this.add(this.notes);

    this.notesVwoosh = new FlxTypedSpriteGroup<NoteSprite>();
    this.notesVwoosh.zIndex = 31;
    this.add(this.notesVwoosh);

    this.noteHoldCovers = new FlxTypedSpriteGroup<NoteHoldCover>(0, 0, 4);
    this.noteHoldCovers.zIndex = 40;
    this.add(this.noteHoldCovers);

    this.noteSplashes = new FlxTypedSpriteGroup<NoteSplash>(0, 0, NOTE_SPLASH_CAP);
    this.noteSplashes.zIndex = 50;
    this.add(this.noteSplashes);

    this.refresh();

    this.onNoteIncoming = new FlxTypedSignal<NoteSprite->Void>();
    resetScrollSpeed();

    for (i in 0...KEY_COUNT)
    {
      var child:StrumlineNote = new StrumlineNote(noteStyle, isPlayer, DIRECTIONS[i]);
      child.parentStrumline = this;
      child.x = getXPos(DIRECTIONS[i]);
      child.x += INITIAL_OFFSET;
      child.y = 0;
      child.column = i;
      noteStyle.applyStrumlineOffsets(child);
      this.strumlineNotes.add(child);
      strumLineNotes.push(child);
    }

    for (i in 0...KEY_COUNT)
    {
      heldKeys.push(false);
    }

    // This MUST be true for children to update!
    this.active = true;
    defaultHeight = height;
    mods = new Modchart();
  }

  public function refresh():Void
  {
    sort(SortUtil.byZIndex, FlxSort.ASCENDING);
  }

  override function get_width():Float
  {
    return KEY_COUNT * Strumline.NOTE_SPACING;
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    mods.update(elapsed);
    updateNotes();
    #if FEATURE_GHOST_TAPPING
    updateGhostTapTimer(elapsed);
    #end
  }

  // only for arrowpath
  function getPosWithOffset(xoff:Float = 0, yoff:Float = 0, time:Float, column:Int)
  {
    var conductorInUse:Conductor = conductorInUse ?? Conductor.instance;
    time += conductorInUse.songPosition;
    var speed:Float = scrollSpeed;
    var pn:Int = modNumber;
    var vwoosh = false;
    var ofs = mods.getValue('centered2') * Strumline.NOTE_SPACING;
    var yOffset:Float = mods.GetYOffset(conductorInUse, time, speed, vwoosh, column, Conductor.instance.songPosition) + ofs;
    var pos:Vector3D = new Vector3D(mods.GetXPos(column, yOffset, pn, xoffArray, false), mods.GetYPos(column, yOffset, pn, xoffArray, defaultHeight),
      mods.GetZPos(column, yOffset, pn, xoffArray));
    var effect:Float = 1 + (mods.getValue('gayholds'));
    var noteYOffset:Float = mods.GetYOffset(conductorInUse, Conductor.instance.songPosition, speed, vwoosh, column, Conductor.instance.songPosition) + ofs;
    var notePos:Vector3D = new Vector3D(mods.GetXPos(column, noteYOffset, pn, xoffArray, true),
      mods.GetYPos(column, noteYOffset, pn, xoffArray, defaultHeight), mods.GetZPos(column, noteYOffset, pn, xoffArray));
    var strumPos:Vector3D = new Vector3D(mods.GetXPos(column, ofs, pn, xoffArray, false), mods.GetYPos(column, ofs, pn, xoffArray, defaultHeight),
      mods.GetZPos(column, ofs, pn, xoffArray));
    var timeDiff:Float = mods.baseHoldSize;
    var yOffset2:Float = mods.GetYOffset(conductorInUse, time + timeDiff, speed, vwoosh, column, Conductor.instance.songPosition + timeDiff) + ofs;
    var pos4:Vector3D = new Vector3D(mods.GetXPos(column, yOffset2, pn, xoffArray, false), mods.GetYPos(column, yOffset2, pn, xoffArray, defaultHeight),
      mods.GetZPos(column, yOffset2, pn, xoffArray));
    mods.modifyPos(pos, xoffArray);
    mods.modifyPos(notePos, xoffArray);
    mods.modifyPos(strumPos, xoffArray);
    mods.modifyPos(pos4, xoffArray);
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
    if (yOffset <= 0)
    {
      offset.x = pos3.x - strumPos.x;
      offset.z = pos3.z - strumPos.z;
    }
    var noteBeat:Float = Conductor.instance.currentBeatTime;
    var rotation:Vector3D = new Vector3D(mods.GetRotationX(column, yOffset, true), mods.GetRotationY(column, yOffset, true),
      (mods.GetRotationZ(column, yOffset, noteBeat, true, ang)) + this.angle);
    var fullPos:Vector3D = pos;
    var realPos:Vector3D = new Vector3D(xoff, yoff);
    var scale:Array<Float> = mods.GetScale(column, yOffset, modNumber, [1, 1]);
    var zoom:Float = mods.GetZoom(column, yOffset, modNumber) ?? 1;
    var scaledPos:Vector3D = ModchartMath.scaleVector3(realPos, scale[0] * zoom, scale[1] * zoom, scale[4]);
    var skewedPos:Vector3D = ModchartMath.skewVector2(scaledPos, scale[2], scale[3]);
    var rotatedPos:Vector3D = ModchartMath.rotateVector3(skewedPos, rotation.x, rotation.y, rotation.z);
    var origin:Vector3D = new Vector3D(0, FlxG.height / 2);
    var zPos:Vector3D = ModchartMath.PerspectiveProjection(rotatedPos.add(new Vector3D(fullPos.x, fullPos.y, fullPos.z - 1000)), origin).subtract(fullPos);
    zPos.incrementBy(new Vector3D(fullPos.x, fullPos.y));
    zPos.decrementBy(offset);
    zPos.incrementBy(getDifference());
    zPos.x += 50; // offset
    zPos.y += 90;
    return zPos;
  }

  override public function draw():Void
  {
    super.draw();
    // stolen from schmovin but modified a little
    var currentBeat:Float = conductorInUse.currentBeatTime;
    var bitmap = new openfl.display.Shape();
    var grain = mods.getValue('arrowpathgranulate');
    var roughness:Int = mods.baseHoldSize;
    var backLength:Float = 200;
    backLength *= (1 + mods.getValue('arrowpathdrawsizeback'));
    var frontLength:Float = Math.round(FlxG.height / Constants.PIXELS_PER_MS);
    frontLength *= (1 + mods.getValue('arrowpathdrawsize'));
    var subdivisions:Int = Math.round(Math.abs(backLength + frontLength) / (roughness * (1 + grain)));
    if (grain < 0) subdivisions = Math.round(Math.abs(backLength + frontLength) / (roughness / (1 + Math.abs(grain))));
    if (subdivisions <= 1) subdivisions = 1;
    for (column in 0...KEY_COUNT)
    {
      var commands = new Vector<Int>();
      var data = new Vector<Float>();
      var player = modNumber;
      var alpha = mods.getValue('arrowpath${column}') + mods.getValue('arrowpath');
      if (alpha <= 0) continue;
      var size:Float = 1 + mods.getValue('arrowpathsize');
      var path1 = getPosWithOffset(-size / 2, size / 2, 0, column);
      bitmap.graphics.lineStyle(size, 0xFFFFFF, alpha);
      commands.push(GraphicsPathCommand.MOVE_TO);
      data.push(path1.x);
      data.push(path1.y);
      for (i in 0...subdivisions)
      {
        var path2 = getPosWithOffset(-size / 2, size / 2, (backLength + frontLength) / subdivisions * i - backLength, column);
        commands.push(GraphicsPathCommand.LINE_TO);
        data.push(path2.x);
        data.push(path2.y);
      }
      bitmap.graphics.drawPath(commands, data);
      var bitmapData = new BitmapData(FlxG.width, FlxG.height, true, 0);
      bitmapData.draw(bitmap);
      for (camera in cameras)
      {
        camera.canvas.graphics.beginBitmapFill(bitmapData, new Matrix());
        camera.canvas.graphics.drawRect(0, 0, FlxG.width, FlxG.height);
        camera.canvas.graphics.endFill();
      }
    }
  }

  #if FEATURE_GHOST_TAPPING
  /**
   * Returns `true` if no notes are in range of the strumline and the player can spam without penalty.
   */
  public function mayGhostTap():Bool
  {
    // Any notes in range of the strumline.
    if (getNotesMayHit().length > 0)
    {
      return false;
    }
    // Any hold notes in range of the strumline.
    if (getHoldNotesHitOrMissed().length > 0)
    {
      return false;
    }

    // Note has been hit recently.
    if (ghostTapTimer > 0.0) return false;

    // **yippee**
    return true;
  }
  #end

  /**
   * Return notes that are within `Constants.HIT_WINDOW` ms of the strumline.
   * @return An array of `NoteSprite` objects.
   */
  public function getNotesMayHit():Array<NoteSprite>
  {
    return notes.members.filter(function(note:NoteSprite) {
      return note != null && note.alive && !note.hasBeenHit && note.mayHit;
    });
  }

  /**
   * Return hold notes that are within `Constants.HIT_WINDOW` ms of the strumline.
   * @return An array of `SustainTrail` objects.
   */
  public function getHoldNotesHitOrMissed():Array<SustainTrail>
  {
    return holdNotes.members.filter(function(holdNote:SustainTrail) {
      return holdNote != null && holdNote.alive && (holdNote.hitNote || holdNote.missedNote);
    });
  }

  public function getNoteSprite(noteData:SongNoteData):NoteSprite
  {
    if (noteData == null) return null;

    for (note in notes.members)
    {
      if (note == null) continue;
      if (note.alive) continue;

      if (note.noteData == noteData) return note;
    }

    return null;
  }

  public function getHoldNoteSprite(noteData:SongNoteData):SustainTrail
  {
    if (noteData == null || ((noteData.length ?? 0.0) <= 0.0)) return null;

    for (holdNote in holdNotes.members)
    {
      if (holdNote == null) continue;
      if (holdNote.alive) continue;

      if (holdNote.noteData == noteData) return holdNote;
    }

    return null;
  }

  /**
   * Call this when resetting the playstate.
   */
  public function vwooshNotes():Void
  {
    for (note in notes.members)
    {
      if (note == null) continue;
      if (!note.alive) continue;

      notes.remove(note);
      notesVwoosh.add(note);

      var targetY:Float = FlxG.height + note.y;
      if (Preferences.downscroll) targetY = 0 - note.height;
      FlxTween.tween(note, {y: targetY}, 0.5,
        {
          ease: FlxEase.expoIn,
          onComplete: function(twn) {
            note.kill();
            notesVwoosh.remove(note, true);
            note.destroy();
          }
        });
    }

    for (holdNote in holdNotes.members)
    {
      if (holdNote == null) continue;
      if (!holdNote.alive) continue;

      holdNotes.remove(holdNote);
      holdNotesVwoosh.add(holdNote);

      var targetY:Float = FlxG.height + holdNote.y;
      if (Preferences.downscroll) targetY = 0 - holdNote.height;
      FlxTween.tween(holdNote, {y: targetY}, 0.5,
        {
          ease: FlxEase.expoIn,
          onComplete: function(twn) {
            holdNote.kill();
            holdNotesVwoosh.remove(holdNote, true);
            holdNote.destroy();
          }
        });
    }
  }

  /**
   * For a note's strumTime, calculate its Y position relative to the strumline.
   * NOTE: Assumes Conductor and PlayState are both initialized.
   * @param strumTime
   * @return Float
   */
  public function calculateNoteYPos(strumTime:Float, vwoosh:Bool = true):Float
  {
    // Make the note move faster visually as it moves offscreen.
    // var vwoosh:Float = (strumTime < Conductor.songPosition) && vwoosh ? 2.0 : 1.0;
    // ^^^ commented this out... do NOT make it move faster as it moves offscreen!
    var vwoosh:Float = 1.0;

    return
      Constants.PIXELS_PER_MS * (conductorInUse.songPosition - strumTime - Conductor.instance.inputOffset) * scrollSpeed * vwoosh * (Preferences.downscroll ? 1 : -1);
  }

  public function getDifference():Vector3D
  {
    return new Vector3D(x + NOTE_SPACING * 1.5, y);
  }

  function updateNotes():Void
  {
    if (noteData.length == 0) return;

    // Ensure note data gets reset if the song happens to loop.
    // NOTE: I had to remove this line because it was causing notes visible during the countdown to be placed multiple times.
    // I don't remember what bug I was trying to fix by adding this.
    // if (conductorInUse.currentStep == 0) nextNoteIndex = 0;

    var songStart:Float = PlayState.instance?.startTimestamp ?? 0.0;
    var hitWindowStart:Float = conductorInUse.songPosition - Constants.HIT_WINDOW_MS;
    var renderWindowStart:Float = conductorInUse.songPosition + RENDER_DISTANCE_MS;

    for (noteIndex in nextNoteIndex...noteData.length)
    {
      var note:Null<SongNoteData> = noteData[noteIndex];

      if (note == null) continue; // Note is blank
      if (note.time < songStart || note.time < hitWindowStart)
      {
        // Note is in the past, skip it.
        nextNoteIndex = noteIndex + 1;
        continue;
      }
      if (note.time > renderWindowStart) break; // Note is too far ahead to render

      var noteSprite = buildNoteSprite(note);

      if (note.length > 0)
      {
        noteSprite.holdNoteSprite = buildHoldNoteSprite(note);
      }

      nextNoteIndex = noteIndex + 1; // Increment the nextNoteIndex rather than splicing the array, because splicing is slow.

      onNoteIncoming.dispatch(noteSprite);
    }

    var height:Float = defaultHeight;
    var difference:Vector3D = getDifference(); // i'm fucked with this shit
    var c2 = mods.getValue('centered2') * Strumline.NOTE_SPACING;
    var timeDiff:Float = mods.baseHoldSize;
    // Update rendering of notes.
    for (note in notes.members)
    {
      if (note == null || !note.alive) continue;
      var vwoosh:Bool = note.holdNoteSprite == null;
      var col:Int = note.noteData.getDirection();
      note.offsetX = -NUDGE;
      note.offsetY = -INITIAL_OFFSET;
      note.offsetX += difference.x;
      note.offsetY += difference.y;
      var realofs = mods.GetYOffset(conductorInUse, note.strumTime, scrollSpeed, vwoosh, col, note.strumTime) + c2;
      var zpos = mods.GetZPos(col, realofs, modNumber, xoffArray);
      var xpos = mods.GetXPos(col, realofs, modNumber, xoffArray, true);
      var ypos = mods.GetYPos(col, realofs, modNumber, xoffArray, height);
      var scale:Array<Float> = mods.GetScale(col, realofs, modNumber, note.defaultScale);
      var zoom:Float = mods.GetZoom(col, realofs, modNumber);
      var pos:Vector3D = new Vector3D(xpos, ypos, zpos);
      mods.modifyPos(pos, xoffArray);
      var realofs2 = mods.GetYOffset(conductorInUse, note.strumTime + timeDiff, scrollSpeed, vwoosh, col, note.strumTime + timeDiff) + c2;
      var pos2:Vector3D = new Vector3D(mods.GetXPos(col, realofs2, modNumber, xoffArray, true), mods.GetYPos(col, realofs2, modNumber, xoffArray, height),
        mods.GetZPos(col, realofs2, modNumber, xoffArray));
      mods.modifyPos(pos2, xoffArray);
      var diff = pos2.subtract(pos);
      var ang = Math.atan2(diff.y, diff.x);
      note.SCALE.x = scale[0] * zoom;
      note.SCALE.y = scale[1] * zoom;
      note.SCALE.z = scale[4];
      note.skew.x = scale[2];
      note.skew.y = scale[3];
      note.x = pos.x;
      note.y = pos.y;
      note.z = pos.z;
      note.originVec = new Vector3D(0, FlxG.height / 2);
      var yposWithoutReverse:Float = mods.GetYPos(col, realofs, modNumber, xoffArray, height, false);
      note.alphaValue = mods.GetAlpha(yposWithoutReverse, col, realofs, note.holdNoteSprite != null, false);
      note.glow = mods.GetGlow(yposWithoutReverse, col, realofs, note.holdNoteSprite != null, false);
      // note.hsvShader.ALPHA = mods.GetAlpha(yposWithoutReverse, col, realofs);
      // note.hsvShader.GLOW = mods.GetGlow(yposWithoutReverse, col, realofs);
      var noteBeat:Float = (note.strumTime / 1000) * (Conductor.instance.bpm / 60);
      note.rotation.copyFrom(new Vector3D(mods.GetRotationX(col, realofs, note.holdNoteSprite != null),
        mods.GetRotationY(col, realofs, note.holdNoteSprite != null),
        mods.GetRotationZ(col, realofs, noteBeat, note.holdNoteSprite != null, ang) + note.angle));
      // If the note is miss
      var isOffscreen = Preferences.downscroll ? note.y > FlxG.height : note.y < -note.height;
      if (note.handledMiss && isOffscreen)
      {
        killNote(note);
      }
    }

    // Update rendering of hold notes.
    for (holdNote in holdNotes.members)
    {
      if (holdNote == null || !holdNote.alive) continue;

      if (conductorInUse.songPosition > holdNote.strumTime && holdNote.hitNote && !holdNote.missedNote)
      {
        if (isPlayer && !isKeyHeld(holdNote.noteDirection))
        {
          // Stopped pressing the hold note.
          playStatic(holdNote.noteDirection);
          holdNote.missedNote = true;
          holdNote.visible = true;
          holdNote.alpha = 0.0; // Completely hide the dropped hold note.
        }
      }

      var renderWindowEnd = holdNote.strumTime + holdNote.fullSustainLength + Constants.HIT_WINDOW_MS + RENDER_DISTANCE_MS / 8;

      if (holdNote.missedNote && conductorInUse.songPosition >= renderWindowEnd)
      {
        // Hold note is offscreen, kill it.
        holdNote.visible = false;
        holdNote.kill(); // Do not destroy! Recycling is faster.
      }
      else if (holdNote.hitNote && holdNote.sustainLength <= 0)
      {
        // Hold note is completed, kill it.
        if (isKeyHeld(holdNote.noteDirection))
        {
          playPress(holdNote.noteDirection);
        }
        else
        {
          playStatic(holdNote.noteDirection);
        }

        if (holdNote.cover != null && isPlayer)
        {
          holdNote.cover.playEnd();
        }
        else if (holdNote.cover != null)
        {
          // *lightning* *zap* *crackle*
          holdNote.cover.visible = false;
          holdNote.cover.kill();
        }

        holdNote.visible = false;
        holdNote.kill();
      }
      else if (holdNote.missedNote && (holdNote.fullSustainLength > holdNote.sustainLength))
      {
        // Hold note was dropped before completing, keep it in its clipped state.
        holdNote.visible = true;
        holdNote.x = holdNote.y = 0;
        var yOffset:Float = (holdNote.fullSustainLength - holdNote.sustainLength) * Constants.PIXELS_PER_MS;
        var vwoosh:Bool = false;
        holdNote.offsetX = STRUMLINE_SIZE / 2 - holdNote.width / 2;
        holdNote.offsetY = -INITIAL_OFFSET + yOffset + STRUMLINE_SIZE / 2;
        holdNote.offsetX += difference.x;
        holdNote.offsetY += difference.y;
        // Clean up the cover.
        if (holdNote.cover != null)
        {
          holdNote.cover.visible = false;
          holdNote.cover.kill();
        }
        holdNote.vwoosh = vwoosh;
      }
      else if (conductorInUse.songPosition > holdNote.strumTime && holdNote.hitNote)
      {
        // Hold note is currently being hit, clip it off.
        holdConfirm(holdNote.noteDirection);
        holdNote.visible = true;

        holdNote.sustainLength = (holdNote.strumTime + holdNote.fullSustainLength) - conductorInUse.songPosition;

        if (holdNote.sustainLength <= 10)
        {
          holdNote.visible = false;
        }
        var vwoosh:Bool = false;
        var col:Int = holdNote.noteData.getDirection();
        holdNote.x = holdNote.y = 0;
        holdNote.offsetX = STRUMLINE_SIZE / 2 - holdNote.width / 2;
        holdNote.offsetY = -INITIAL_OFFSET + STRUMLINE_SIZE / 2;
        holdNote.offsetX += difference.x;
        holdNote.offsetY += difference.y;
        holdNote.vwoosh = vwoosh;
      }
      else
      {
        // Hold note is new, render it normally.
        holdNote.visible = true;
        var vwoosh:Bool = false;
        holdNote.x = holdNote.y = 0;
        var col:Int = holdNote.noteData.getDirection();
        holdNote.offsetX = STRUMLINE_SIZE / 2 - holdNote.width / 2;
        holdNote.offsetY = -INITIAL_OFFSET + STRUMLINE_SIZE / 2;
        holdNote.offsetX += difference.x;
        holdNote.offsetY += difference.y;
        holdNote.vwoosh = vwoosh;
      }
    }

    for (strumNote in strumlineNotes.members)
    {
      if (strumNote == null || !strumNote.alive) continue;
      var col:Int = strumNote.column;
      strumNote.offsetX = INITIAL_OFFSET + noteStyle._data.assets.noteStrumline.offsets[0];
      strumNote.offsetY = noteStyle._data.assets.noteStrumline.offsets[1];
      strumNote.offsetX += difference.x;
      strumNote.offsetY += difference.y;
      var zpos = mods.GetZPos(col, c2, modNumber, xoffArray);
      var xpos:Float = mods.GetXPos(col, c2, modNumber, xoffArray, false);
      var ypos:Float = mods.GetYPos(col, c2, modNumber, xoffArray, height);
      var scale:Array<Float> = mods.GetScale(col, c2, modNumber, strumNote.defaultScale);
      var zoom:Float = mods.GetZoom(col, c2, modNumber);
      var pos:Vector3D = new Vector3D(xpos, ypos, zpos);
      mods.modifyPos(pos, xoffArray);
      var realofs2 = calculateNoteYPos(Conductor.instance.songPosition + timeDiff, false) + c2;
      var pos2:Vector3D = new Vector3D(mods.GetXPos(col, realofs2, modNumber, xoffArray, true), mods.GetYPos(col, realofs2, modNumber, xoffArray, height),
        mods.GetZPos(col, realofs2, modNumber, xoffArray));
      var realofs3 = calculateNoteYPos(Conductor.instance.songPosition, false) + c2;
      var pos3:Vector3D = new Vector3D(mods.GetXPos(col, realofs3, modNumber, xoffArray, true), mods.GetYPos(col, realofs3, modNumber, xoffArray, height),
        mods.GetZPos(col, realofs3, modNumber, xoffArray));
      mods.modifyPos(pos3, xoffArray);
      var diff = pos2.subtract(pos3);
      var ang = Math.atan2(diff.y, diff.x);
      strumNote.rotation.copyFrom(new Vector3D(mods.ReceptorGetRotationX(col), mods.ReceptorGetRotationY(col),
        mods.ReceptorGetRotationZ(col, ang) + strumNote.angle));
      strumNote.SCALE.x = scale[0] * zoom;
      strumNote.SCALE.y = scale[1] * zoom;
      strumNote.SCALE.z = scale[4];
      strumNote.skew.x = scale[2];
      strumNote.skew.y = scale[3];
      strumNote.x = pos.x;
      strumNote.y = pos.y;
      strumNote.z = pos.z;
      strumNote.originVec = new Vector3D(0, FlxG.height / 2);
      var fBaseAlpha:Float = 1 - mods.getValue('dark') - mods.getValue('dark$col');
      fBaseAlpha = ModchartMath.clamp(fBaseAlpha, 0, 1);
      strumNote.alphaValue = fBaseAlpha;
    }
    for (splash in noteSplashes)
    {
      if (splash == null || !splash.alive) continue;
      var col:Int = splash.column;
      splash.offsetX = INITIAL_OFFSET;
      splash.offsetY = -INITIAL_OFFSET;
      splash.offsetX += difference.x;
      splash.offsetY += difference.y;
      var zpos = mods.GetZPos(col, c2, modNumber, xoffArray);
      splash.currentZValue = zpos;
      var xpos = mods.GetXPos(col, c2, modNumber, xoffArray, false);
      var ypos = mods.GetYPos(col, c2, modNumber, xoffArray, height);
      var scale:Array<Float> = mods.GetScale(col, c2, modNumber, splash.defaultScale);
      var zoom:Float = mods.GetZoom(col, c2, modNumber);
      var pos:Vector3D = new Vector3D(xpos, ypos, zpos);
      mods.modifyPos(pos, xoffArray);
      var perspective = ModchartMath.PerspectiveProjection(new Vector3D(pos.x, pos.y, pos.z - 1000), new Vector3D(0, FlxG.height / 2));
      splash.scale.x = scale[0] * zoom / perspective.z;
      splash.scale.y = scale[1] * zoom / perspective.z;
      splash.x = perspective.x + splash.offsetX;
      splash.y = perspective.y + splash.offsetY;
      var fBaseAlpha:Float = 1 - mods.getValue('dark') - mods.getValue('dark$col');
      fBaseAlpha = ModchartMath.clamp(fBaseAlpha, 0, 1);
      splash.hsvShader.ALPHA = fBaseAlpha;
    }
    for (cover in noteHoldCovers)
    {
      if (cover == null || !cover.alive) continue;
      var col:Int = cover.column;
      cover.offsetX = STRUMLINE_SIZE / 2 - cover.width / 2 - 12;
      cover.offsetY = INITIAL_OFFSET + STRUMLINE_SIZE / 2 - 96;
      cover.offsetX += difference.x;
      cover.offsetY += difference.y;
      var zpos = mods.GetZPos(col, c2, modNumber, xoffArray);
      cover.currentZValue = zpos;
      var xpos:Float = mods.GetXPos(col, c2, modNumber, xoffArray, false);
      var ypos:Float = mods.GetYPos(col, c2, modNumber, xoffArray, height);
      var scale:Array<Float> = mods.GetScale(col, c2, modNumber, cover.defaultScale);
      var zoom:Float = mods.GetZoom(col, c2, modNumber);
      var pos:Vector3D = new Vector3D(xpos, ypos, zpos);
      mods.modifyPos(pos, xoffArray);
      cover.x = pos.x;
      cover.y = pos.y;
      var perspective = ModchartMath.PerspectiveProjection(new Vector3D(pos.x, pos.y, pos.z - 1000), new Vector3D(0, FlxG.height / 2));
      cover.scale.x = scale[0] * zoom / perspective.z;
      cover.scale.y = scale[1] * zoom / perspective.z;
      cover.x = perspective.x + cover.offsetX;
      cover.y = perspective.y + cover.offsetY;
      var fBaseAlpha:Float = 1 - mods.getValue('dark') - mods.getValue('dark$col');
      fBaseAlpha = ModchartMath.clamp(fBaseAlpha, 0, 1);
      cover.hsvShader.ALPHA = fBaseAlpha;
    }
    // Update rendering of pressed keys.
    for (dir in DIRECTIONS)
    {
      if (isKeyHeld(dir) && getByDirection(dir).getCurrentAnimation() == "static")
      {
        playPress(dir);
      }
    }

    if (notes.members.length > 1) notes.members.insertionSort(compareNoteSprites.bind(FlxSort.ASCENDING));

    if (holdNotes.members.length > 1) holdNotes.members.insertionSort(compareHoldNoteSprites.bind(FlxSort.ASCENDING));

    if (strumlineNotes.members.length > 1) strumlineNotes.members.insertionSort(compareStrumlineNotes.bind(FlxSort.ASCENDING));

    if (noteSplashes.members.length > 1) noteSplashes.members.insertionSort(compareNoteSplashes.bind(FlxSort.ASCENDING));

    if (noteHoldCovers.members.length > 1) noteHoldCovers.members.insertionSort(compareNoteHoldCovers.bind(FlxSort.ASCENDING));
  }

  /**
   * Return notes that are within, or way after, `Constants.HIT_WINDOW` ms of the strumline.
   * @return An array of `NoteSprite` objects.
   */
  public function getNotesOnScreen():Array<NoteSprite>
  {
    return notes.members.filter(function(note:NoteSprite) {
      return note != null && note.alive && !note.hasBeenHit;
    });
  }

  #if FEATURE_GHOST_TAPPING
  function updateGhostTapTimer(elapsed:Float):Void
  {
    // If it's still our turn, don't update the ghost tap timer.
    if (getNotesOnScreen().length > 0) return;

    ghostTapTimer -= elapsed;

    if (ghostTapTimer <= 0)
    {
      ghostTapTimer = 0;
    }
  }
  #end

  /**
   * Called when the PlayState skips a large amount of time forward or backward.
   */
  public function handleSkippedNotes():Void
  {
    // By calling clean(), we remove all existing notes so they can be re-added.
    clean();
    // By setting noteIndex to 0, the next update will skip past all the notes that are in the past.
    nextNoteIndex = 0;
  }

  public function onBeatHit():Void
  {
    if (notes.members.length > 1) notes.members.insertionSort(compareNoteSprites.bind(FlxSort.ASCENDING));

    if (holdNotes.members.length > 1) holdNotes.members.insertionSort(compareHoldNoteSprites.bind(FlxSort.ASCENDING));
  }

  public function pressKey(dir:NoteDirection):Void
  {
    heldKeys[dir] = true;
  }

  public function releaseKey(dir:NoteDirection):Void
  {
    heldKeys[dir] = false;
  }

  public function isKeyHeld(dir:NoteDirection):Bool
  {
    return heldKeys[dir];
  }

  /**
   * Called when the song is reset.
   * Removes any special animations and the like.
   * Doesn't reset the notes from the chart, that's handled by the PlayState.
   */
  public function clean():Void
  {
    for (note in notes.members)
    {
      if (note == null) continue;
      killNote(note);
    }

    for (holdNote in holdNotes.members)
    {
      if (holdNote == null) continue;
      holdNote.kill();
    }

    for (splash in noteSplashes)
    {
      if (splash == null) continue;
      splash.kill();
    }

    for (cover in noteHoldCovers)
    {
      if (cover == null) continue;
      cover.kill();
    }

    heldKeys = [false, false, false, false];

    for (dir in DIRECTIONS)
    {
      playStatic(dir);
    }
    resetScrollSpeed();
    // mods = new Modchart();
    #if FEATURE_GHOST_TAPPING
    ghostTapTimer = 0;
    #end
  }

  public function applyNoteData(data:Array<SongNoteData>):Void
  {
    this.notes.clear();

    this.noteData = data.copy();
    this.nextNoteIndex = 0;

    // Sort the notes by strumtime.
    this.noteData.insertionSort(compareNoteData.bind(FlxSort.ASCENDING));
  }

  /**
   * @param note The note to hit.
   * @param removeNote True to remove the note immediately, false to make it transparent and let it move offscreen.
   */
  public function hitNote(note:NoteSprite, removeNote:Bool = true):Void
  {
    playConfirm(note.direction);
    note.hasBeenHit = true;

    if (removeNote)
    {
      killNote(note);
    }
    else
    {
      note.alpha = 0.5;
      note.desaturate();
    }

    if (note.holdNoteSprite != null)
    {
      note.holdNoteSprite.hitNote = true;
      note.holdNoteSprite.missedNote = false;

      note.holdNoteSprite.sustainLength = (note.holdNoteSprite.strumTime + note.holdNoteSprite.fullSustainLength) - conductorInUse.songPosition;
    }

    #if FEATURE_GHOST_TAPPING
    ghostTapTimer = Constants.GHOST_TAP_DELAY;
    #end
  }

  public function killNote(note:NoteSprite):Void
  {
    if (note == null) return;
    note.visible = false;
    notes.remove(note, false);
    note.kill();

    if (note.holdNoteSprite != null)
    {
      note.holdNoteSprite.missedNote = true;
      note.holdNoteSprite.visible = false;
    }
  }

  public function getByIndex(index:Int):StrumlineNote
  {
    return this.strumLineNotes[index];
  }

  public function getByDirection(direction:NoteDirection):StrumlineNote
  {
    return getByIndex(DIRECTIONS.indexOf(direction));
  }

  public function playStatic(direction:NoteDirection):Void
  {
    getByDirection(direction).playStatic();
  }

  public function playPress(direction:NoteDirection):Void
  {
    getByDirection(direction).playPress();
  }

  public function playConfirm(direction:NoteDirection):Void
  {
    getByDirection(direction).playConfirm();
  }

  public function holdConfirm(direction:NoteDirection):Void
  {
    getByDirection(direction).holdConfirm();
  }

  public function isConfirm(direction:NoteDirection):Bool
  {
    return getByDirection(direction).isConfirm();
  }

  public function playNoteSplash(direction:NoteDirection):Void
  {
    // TODO: Add a setting to disable note splashes.
    // if (Settings.noSplash) return;
    if (!noteStyle.isNoteSplashEnabled()) return;

    var splash:NoteSplash = this.constructNoteSplash();

    if (splash != null)
    {
      splash.play(direction);

      splash.x = this.x;
      splash.x += getXPos(direction);
      splash.x += INITIAL_OFFSET;
      splash.y = this.y;
      splash.y -= INITIAL_OFFSET;
      splash.y += 0;
      splash.column = Std.int(direction);
    }
  }

  public function playNoteHoldCover(holdNote:SustainTrail):Void
  {
    // TODO: Add a setting to disable note splashes.
    // if (Settings.noSplash) return;
    if (!noteStyle.isHoldNoteCoverEnabled()) return;

    var cover:NoteHoldCover = this.constructNoteHoldCover();

    if (cover != null)
    {
      cover.holdNote = holdNote;
      holdNote.cover = cover;
      cover.visible = true;

      cover.playStart();

      cover.x = this.x;
      cover.x += getXPos(holdNote.noteDirection);
      cover.x += STRUMLINE_SIZE / 2;
      cover.x -= cover.width / 2;
      cover.x += -12; // Manual tweaking because fuck.

      cover.y = this.y;
      cover.y += INITIAL_OFFSET;
      cover.y += STRUMLINE_SIZE / 2;
      cover.y += -96; // Manual tweaking because fuck.
      cover.column = holdNote.noteData.getDirection();
    }
  }

  public function buildNoteSprite(note:SongNoteData):NoteSprite
  {
    var noteSprite:NoteSprite = constructNoteSprite();

    if (noteSprite != null)
    {
      var noteKindStyle:NoteStyle = NoteKindManager.getNoteStyle(note.kind, this.noteStyle.id) ?? this.noteStyle;
      noteSprite.setupNoteGraphic(noteKindStyle);
      noteSprite.parentStrumline = this;
      noteSprite.direction = note.getDirection();
      noteSprite.noteData = note;

      noteSprite.x = this.x;
      noteSprite.x += getXPos(DIRECTIONS[note.getDirection() % KEY_COUNT]);
      noteSprite.x -= (noteSprite.width - Strumline.STRUMLINE_SIZE) / 2; // Center it
      noteSprite.x -= NUDGE;
      // noteSprite.x += INITIAL_OFFSET;
      noteSprite.y = -9999;
    }

    return noteSprite;
  }

  public function buildHoldNoteSprite(note:SongNoteData):SustainTrail
  {
    var holdNoteSprite:SustainTrail = constructHoldNoteSprite();

    if (holdNoteSprite != null)
    {
      var noteKindStyle:NoteStyle = NoteKindManager.getNoteStyle(note.kind, this.noteStyle.id) ?? this.noteStyle;
      holdNoteSprite.setupHoldNoteGraphic(noteKindStyle);

      holdNoteSprite.parentStrumline = this;
      holdNoteSprite.noteData = note;
      holdNoteSprite.strumTime = note.time;
      holdNoteSprite.noteDirection = note.getDirection();
      holdNoteSprite.fullSustainLength = note.length;
      holdNoteSprite.sustainLength = note.length;
      holdNoteSprite.missedNote = false;
      holdNoteSprite.hitNote = false;
      holdNoteSprite.visible = true;
      holdNoteSprite.alpha = 1.0;

      holdNoteSprite.x = this.x;
      holdNoteSprite.x += getXPos(DIRECTIONS[note.getDirection() % KEY_COUNT]);
      // holdNoteSprite.x += STRUMLINE_SIZE / 2;
      // holdNoteSprite.x -= holdNoteSprite.width / 2;
      holdNoteSprite.y = -9999;
    }

    return holdNoteSprite;
  }

  /**
   * Custom recycling behavior.
   */
  function constructNoteSplash():NoteSplash
  {
    var result:NoteSplash = null;

    // If we haven't filled the pool yet...
    if (noteSplashes.length < noteSplashes.maxSize)
    {
      // Create a new note splash.
      result = new NoteSplash();
      this.noteSplashes.add(result);
    }
    else
    {
      // Else, find a note splash which is inactive so we can revive it.
      result = this.noteSplashes.getFirstAvailable();

      if (result != null)
      {
        result.revive();
      }
      else
      {
        // The note splash pool is full and all note splashes are active,
        // so we just pick one at random to destroy and restart.
        result = FlxG.random.getObject(this.noteSplashes.members);
      }
    }

    return result;
  }

  /**
   * Custom recycling behavior.
   */
  function constructNoteHoldCover():NoteHoldCover
  {
    var result:NoteHoldCover = null;

    // If we haven't filled the pool yet...
    if (noteHoldCovers.length < noteHoldCovers.maxSize)
    {
      // Create a new note hold cover.
      result = new NoteHoldCover();
      this.noteHoldCovers.add(result);
    }
    else
    {
      // Else, find a note splash which is inactive so we can revive it.
      result = this.noteHoldCovers.getFirstAvailable();

      if (result != null)
      {
        result.revive();
      }
      else
      {
        // The note hold cover pool is full and all note hold covers are active,
        // so we just pick one at random to destroy and restart.
        result = FlxG.random.getObject(this.noteHoldCovers.members);
      }
    }

    return result;
  }

  /**
   * Custom recycling behavior.
   */
  function constructNoteSprite():NoteSprite
  {
    var result:NoteSprite = null;

    // Else, find a note which is inactive so we can revive it.
    result = this.notes.getFirstAvailable();

    if (result != null)
    {
      // Revive and reuse the note.
      result.revive();
    }
    else
    {
      // The note sprite pool is full and all note splashes are active.
      // We have to create a new note.
      result = new NoteSprite(noteStyle);
      this.notes.add(result);
    }

    return result;
  }

  /**
   * Custom recycling behavior.
   */
  function constructHoldNoteSprite():SustainTrail
  {
    var result:SustainTrail = null;

    // Else, find a note which is inactive so we can revive it.
    result = this.holdNotes.getFirstAvailable();

    if (result != null)
    {
      // Revive and reuse the note.
      result.revive();
    }
    else
    {
      // The note sprite pool is full and all note splashes are active.
      // We have to create a new note.
      result = new SustainTrail(0, 0, noteStyle, modNumber);
      result.parentStrumline = this;
      this.holdNotes.add(result);
    }

    return result;
  }

  function getXPos(direction:NoteDirection):Float
  {
    return switch (direction)
    {
      case NoteDirection.LEFT: 0;
      case NoteDirection.DOWN: 0 + (1 * Strumline.NOTE_SPACING);
      case NoteDirection.UP: 0 + (2 * Strumline.NOTE_SPACING);
      case NoteDirection.RIGHT: 0 + (3 * Strumline.NOTE_SPACING);
      default: 0;
    }
  }

  /**
   * Apply a small animation which moves the arrow down and fades it in.
   * Only plays at the start of Free Play songs.
   *
   * Note that modifying the offset of the whole strumline won't have the
   * @param arrow The arrow to animate.
   * @param index The index of the arrow in the strumline.
   */
  function fadeInArrow(index:Int, arrow:StrumlineNote):Void
  {
    arrow.y -= 10;
    arrow.alpha = 0.0;
    FlxTween.tween(arrow, {y: arrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * index)});
  }

  public function fadeInArrows():Void
  {
    for (index => arrow in this.strumlineNotes.members.keyValueIterator())
    {
      fadeInArrow(index, arrow);
    }
  }

  function compareNoteData(order:Int, a:SongNoteData, b:SongNoteData):Int
  {
    return FlxSort.byValues(order, a.time, b.time);
  }

  function compareNoteSprites(order:Int, a:NoteSprite, b:NoteSprite):Int
  {
    return FlxSort.byValues(order, a?.z, b?.z);
  }

  function compareHoldNoteSprites(order:Int, a:SustainTrail, b:SustainTrail):Int
  {
    return FlxSort.byValues(order, a?.currentZValue, b?.currentZValue);
  }

  function compareStrumlineNotes(order:Int, a:StrumlineNote, b:StrumlineNote):Int
  {
    return FlxSort.byValues(order, a?.z, b?.z);
  }

  function compareNoteSplashes(order:Int, a:NoteSplash, b:NoteSplash):Int
  {
    return FlxSort.byValues(order, a?.currentZValue, b?.currentZValue);
  }

  function compareNoteHoldCovers(order:Int, a:NoteHoldCover, b:NoteHoldCover):Int
  {
    return FlxSort.byValues(order, a?.currentZValue, b?.currentZValue);
  }
}
