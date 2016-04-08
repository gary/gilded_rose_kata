# :nodoc:
module Adjustable
  def update_item
    adjust_quality
    adjust_sell_in
  end

  def adjust_quality
    raise NotImplementedError
  end

  def adjust_sell_in
    @item.sell_in -= 1
  end
end

# Item whose sell by date has not yet passed
class ItemUpdatePolicy
  include Adjustable

  def self.no_longer_sellable?(item)
    item.sell_in <= 0
  end

  def self.policy_for(item)
    if no_longer_sellable?(item)
      ExpiredItemUpdatePolicy.new(item)
    else
      new(item)
    end
  end

  def initialize(item)
    @item = item
  end

  def adjust_quality
    if valuable?
      @item.quality -= 1 unless @item.quality >= 50
    end
  end

  protected def valuable?
    !@item.quality.zero?
  end
end

# Item whose sell by date has passed
class ExpiredItemUpdatePolicy < ItemUpdatePolicy
  def adjust_quality
    if valuable?
      @item.quality -= 2 unless @item.quality >= 50
    end
  end
end

# :nodoc:
class ItemUpdater
  def initialize(item)
    @policy = ItemUpdatePolicy.policy_for(item)
  end

  def call
    @policy.update_item
  end
end

def update_quality(items)
  items.each do |item|
    ItemUpdater.new(item).call
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

