# frozen_string_literal: true

require 'active_support/concern'

module ProductStock
  extend ActiveSupport::Concern

  def on_demand
    raise 'Cannot determine product on_demand value of product with multiple variants' if
      variants.size > 1

    variants.first.on_demand
  end

  def on_hand
    variants.map(&:on_hand).reduce(:+)
  end
end
