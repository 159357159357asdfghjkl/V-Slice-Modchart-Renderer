package funkin.ui.freeplay.charselect;

import funkin.data.IRegistryEntry;
import funkin.data.freeplay.player.PlayerData;
import funkin.data.freeplay.player.PlayerRegistry;
import funkin.play.scoring.Scoring.ScoringRank;

/**
 * An object used to retrieve data about a playable character (also known as "weeks").
 * Can be scripted to override each function, for custom behavior.
 */
class PlayableCharacter implements IRegistryEntry<PlayerData>
{
  /**
   * The ID of the playable character.
   */
  public final id:String;

  /**
   * Playable character data as parsed from the JSON file.
   */
  public final _data:PlayerData;

  /**
   * @param id The ID of the JSON file to parse.
   */
  public function new(id:String)
  {
    this.id = id;
    _data = _fetchData(id);

    if (_data == null)
    {
      throw 'Could not parse playable character data for id: $id';
    }
  }

  /**
   * Retrieve the readable name of the playable character.
   */
  public function getName():String
  {
    // TODO: Maybe add localization support?
    return _data.name;
  }

  /**
   * Retrieve the list of stage character IDs associated with this playable character.
   * @return The list of associated character IDs
   */
  public function getOwnedCharacterIds():Array<String>
  {
    return _data.ownedChars;
  }

  /**
   * Return `true` if, when this character is selected in Freeplay,
   * songs unassociated with a specific character should appear.
   */
  public function shouldShowUnownedChars():Bool
  {
    return _data.showUnownedChars;
  }

  public function shouldShowCharacter(id:String):Bool
  {
    if (_data.ownedChars.contains(id))
    {
      return true;
    }

    if (_data.showUnownedChars)
    {
      var result = !PlayerRegistry.instance.isCharacterOwned(id);
      return result;
    }

    return false;
  }

  public function getFreeplayDJData():PlayerFreeplayDJData
  {
    return _data.freeplayDJ;
  }

  public function getCharSelectData():PlayerCharSelectData
  {
    return _data.charSelect;
  }

  public function getFreeplayDJText(index:Int):String
  {
    return _data.freeplayDJ.getFreeplayDJText(index);
  }

  /**
   * @param rank Which rank to get info for
   * @return An array of animations. For example, BF Great has two animations, one for BF and one for GF
   */
  public function getResultsAnimationDatas(rank:ScoringRank):Array<PlayerResultsAnimationData>
  {
    if (_data.results == null)
    {
      return [];
    }

    switch (rank)
    {
      case PERFECT | PERFECT_GOLD:
        return _data.results.perfect;
      case EXCELLENT:
        return _data.results.excellent;
      case GREAT:
        return _data.results.great;
      case GOOD:
        return _data.results.good;
      case SHIT:
        return _data.results.loss;
    }
  }

  /**
   * Returns whether this character is unlocked.
   */
  public function isUnlocked():Bool
  {
    return _data.unlocked;
  }

  /**
   * Called when the character is destroyed.
   * TODO: Document when this gets called
   */
  public function destroy():Void {}

  public function toString():String
  {
    return 'PlayableCharacter($id)';
  }

  /**
   * Retrieve and parse the JSON data for a playable character by ID.
   * @param id The ID of the character
   * @return The parsed player data, or null if not found or invalid
   */
  static function _fetchData(id:String):Null<PlayerData>
  {
    return PlayerRegistry.instance.parseEntryDataWithMigration(id, PlayerRegistry.instance.fetchEntryVersion(id));
  }
}
