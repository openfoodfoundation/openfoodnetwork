require 'active_support/concern'

module ProductOnDemand
  extend ActiveSupport::Concern

  def on_demand=(value)
    raise 'cannot set on_demand of product with variants' if variants.any?
    master.on_demand = value
  end
end
