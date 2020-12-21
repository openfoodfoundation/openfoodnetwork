require 'active_support/concern'

module ProductStock
  extend ActiveSupport::Concern

  def on_demand
    if variants?
      raise 'Cannot determine product on_demand value of product with multiple variants' if variants.size > 1

      variants.first.on_demand
    else
      master.on_demand
    end
  end

  def on_hand
    if variants?
      variants.map(&:on_hand).reduce(:+)
    else
      master.on_hand
    end
  end
end
