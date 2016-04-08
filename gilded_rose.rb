# :nodoc:
class ItemManager
  attr_reader :item

  def initialize(item)
    @item = item
  end

  def update_quality
    item.sell_in -= 1

    if valuable?
      amount = if aged_brie?
                 -1
               elsif no_longer_sellable?
                 2
               else
                 1
               end

      item.quality -= amount unless item.quality == 50
    end
  end

  private def after_sell_in?
    item.sell_in < -1
  end

  private def aged_brie?
    item.name == 'Aged Brie'
  end

  private def no_longer_sellable?
    on_sell_in? || after_sell_in?
  end

  private def valuable?
    !item.quality.zero?
  end

  private def on_sell_in?
    item.sell_in == -1
  end
end

def update_quality(items)
  items.each do |item|
    ItemManager.new(item).update_quality
  end
end

# DO NOT CHANGE THINGS BELOW -----------------------------------------

Item = Struct.new(:name, :sell_in, :quality)

# We use the setup in the spec rather than the following for testing.
#
# Items = [
#   Item.new("+5 Dexterity Vest", 10, 20),
#   Item.new("Aged Brie", 2, 0),
#   Item.new("Elixir of the Mongoose", 5, 7),
#   Item.new("Sulfuras, Hand of Ragnaros", 0, 80),
#   Item.new("Backstage passes to a TAFKAL80ETC concert", 15, 20),
#   Item.new("Conjured Mana Cake", 3, 6),
# ]

