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

  def self.policy_for(item)
    if item.aged_brie?
      AgedBrieUpdatePolicy.new(item)
    elsif item.backstage_pass?
      BackstagePassUpdatePolicy.new(item)
    elsif item.sulfuras?
      SulfurasUpdatePolicy.new(item)
    elsif !item.sellable?
      ExpiredItemUpdatePolicy.new(item)
    else
      new(item)
    end
  end

  def initialize(item)
    @item = item
  end

  def adjust_quality
    adjust if @item.valuable?

    ensure_quality_limit
  end

  # @note quality degrades normally
  protected def adjust
    @item.quality -= 1
  end

  private def ensure_quality_limit
    if (over = @item.quality % 50) != @item.quality
      @item.quality -= over
    end
  end
end

# Item whose sell by date has passed
class ExpiredItemUpdatePolicy < ItemUpdatePolicy
  # @note once the sell by date has passed, quality degrades twice as fast
  protected def adjust
    @item.quality -= 2
  end
end

# @see https://en.wikipedia.org/wiki/Brie
class AgedBrieUpdatePolicy < ItemUpdatePolicy
  # @note quality increases as it ages
  protected def adjust
    amount = @item.sellable? ? 1 : 2

    @item.quality += amount
  end
end

class SulfurasUpdatePolicy < ItemUpdatePolicy
  # @note never has to be sold
  def adjust_sell_in
  end

  # @note never decreases in quality
  def adjust_quality
  end
end

class BackstagePassUpdatePolicy < ItemUpdatePolicy
  # @note increases in value as sell_in approaches, then quality drops
  #       to 0 after the concert
  protected def adjust
    if @item.sellable?
      adjustment = if sell_in_within_5_days?
                     3
                   elsif sell_in_approaching?
                     2
                   else
                     1
                   end
      @item.quality += adjustment
    else
      @item.quality = 0
    end
  end

  private def sell_in_within_5_days?
    @item.sell_in <= 5
  end

  private def sell_in_approaching?
    @item.sell_in <= 10
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

def add_predicates(klass:)
  predicates = <<~CODE
    def aged_brie?
      name == 'Aged Brie'
    end

    def backstage_pass?
      name == 'Backstage passes to a TAFKAL80ETC concert'
    end

    def sellable?
      sell_in > 0
    end

    def sulfuras?
      name == 'Sulfuras, Hand of Ragnaros'
    end

    def valuable?
      !quality.zero?
    end
  CODE

  klass.class_eval(predicates)
end

def update_quality(items)
  add_predicates(klass: items.first.class)

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

