package funkin.play.modchart.util;

class Sort
{
  static final max_chunk_size:Int = 32;

  public static function _insertion_sort_impl(array:Array<Dynamic>, first:Int, last:Int, less:(Dynamic, Dynamic) -> Bool)
  {
    for (i in first + 1...last + 1)
    {
      var v = array[i];
      var j = i;
      while (j > first && less(v, array[j - 1]))
      {
        array[j] = array[j - 1];
        j--;
      }
      array[j] = v;
    }
    return array;
  }

  private static function _merge(array:Array<Dynamic>, workspace:Array<Dynamic>, low:Int, middle:Int, high:Int, less:(Dynamic, Dynamic) -> Bool)
  {
    var i:Int = 0;
    var j:Int = low;
    var k:Int = middle + 1;
    while (j <= middle && k <= high)
    {
      if (less(array[k], array[j]))
      {
        workspace[i] = array[k];
        k++;
      }
      else
      {
        workspace[i] = array[j];
        j++;
      }
      i++;
    }
    while (j <= middle)
    {
      workspace[i] = array[j];
      j++;
      i++;
    }
    while (k <= high)
    {
      workspace[i] = array[k];
      k++;
      i++;
    }
    for (i in 0...workspace.length)
    {
      array[low + i] = workspace[i];
    }
    return array;
  }

  private static function _merge_sort_impl(array:Array<Dynamic>, workspace:Array<Dynamic>, low:Int, high:Int, less:(Dynamic, Dynamic) -> Bool)
  {
    if (high - low <= max_chunk_size)
    {
      _insertion_sort_impl(array, low, high, less);
    }
    else
    {
      var middle = Math.floor((low + high) / 2);
      _merge_sort_impl(array, workspace, low, middle, less);
      _merge_sort_impl(array, workspace, middle + 1, high, less);
      _merge(array, workspace, low, middle, high, less);
    }
    return array;
  }

  private static function _sort_setup(array:Array<Dynamic>, ?less:(Dynamic, Dynamic) -> Bool):{trivial:Bool, n:Int, less:(Dynamic, Dynamic) -> Bool}
  {
    var n:Int = array.length;
    var trivial:Bool = (n <= 1);
    if (!trivial)
    {
      if (less(array[0], array[0])) trace('invalid order function for sorting; less(v, v) should not be true for any v.');
    }
    return {trivial: trivial, n: n, less: less};
  }

  public static function stable_sort(array:Array<Dynamic>, less:(Dynamic, Dynamic) -> Bool):Array<Dynamic>
  {
    var setup = _sort_setup(array, less);
    var trivial = setup.trivial;
    var n = setup.n;
    var lessFn = setup.less;
    if (!trivial)
    {
      var workspace = new Array<Dynamic>();
      _merge_sort_impl(array, workspace, 0, n - 1, lessFn);
    }
    return array;
  }

  public static function insertion_sort(array:Array<Dynamic>, less:(Dynamic, Dynamic) -> Bool):Array<Dynamic>
  {
    var setup = _sort_setup(array, less);
    var trivial = setup.trivial;
    var n = setup.n;
    var lessFn = setup.less;
    if (!trivial)
    {
      _insertion_sort_impl(array, 0, n - 1, lessFn);
    }
    return array;
  }
}
