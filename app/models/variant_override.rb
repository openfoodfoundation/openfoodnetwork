class VariantOverride < ActiveRecord::Base
  belongs_to :variant, class_name: 'Spree::Variant'
  belongs_to :hub, class_name: 'Enterprise'

  def self.price_for(variant, hub)
    VariantOverride.where(variant_id: variant, hub_id: hub).first.andand.price
  end
end
