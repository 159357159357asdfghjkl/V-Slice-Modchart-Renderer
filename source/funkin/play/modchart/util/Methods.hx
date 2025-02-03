package funkin.play.modchart.util;

class Methods<T>
{
  private var stage:Array<T>;
  private var list:Array<T>;
  private var swap:Array<T>;
  private var n:Int = 0;
  private var stagen:Int = 0;
  private var listn:Int = 0;
  private var swapn:Int = 0;
  private var reverse_comparator:(T, T) -> Bool;
  private var comparator:(T, T) -> Bool;

  public function add(obj:T):Void
  {
    this.n++;
    stagen++;
    stage[stagen - 1] = obj;
  }

  public function remove():Void
  {
    swap[swapn - 1] = null;
    swapn--;
    n--;
  }

  public function next():T
  {
    if (this.n == 0) return null;

    if (swapn == 0) Sort.stable_sort(stage, this.reverse_comparator);

    if (stagen == 0)
    {
      if (listn == 0)
      {
        while (swapn != 0)
        {
          listn++;
          list[listn - 1] = swap[swapn - 1];
          swap[swapn - 1] = null;
          swapn--;
        }
      }
      else
      {
        swapn++;
        swap[swapn - 1] = list[listn - 1];
        list[listn - 1] = null;
        listn--;
      }
    }
    else
    {
      if (listn == 0)
      {
        swapn++;
        swap[swapn - 1] = stage[stagen - 1];
        stage[stagen - 1] = null;
        stagen--;
      }
      else
      {
        if (this.comparator(list[listn - 1], stage[stagen - 1]) == true)
        {
          swapn++;
          swap[swapn - 1] = list[listn - 1];
          list[listn - 1] = null;
          listn--;
        }
        else
        {
          swapn++;
          swap[swapn - 1] = stage[stagen - 1];
          stage[stagen - 1] = null;
          stagen--;
        }
      }
    }
    return swap[swapn - 1];
  }

  public function new(comparator:(T, T) -> Bool)
  {
    stage = new Array<T>();
    list = new Array<T>();
    swap = new Array<T>();
    this.comparator = comparator;
    this.reverse_comparator = function(a:T, b:T) {
      return comparator(b, a);
    };
  }
}
