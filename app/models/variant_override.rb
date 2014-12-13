class VariantOverride < ActiveRecord::Base
  belongs_to :hub, class_name: 'Enterprise'
  belongs_to :variant, class_name: 'Spree::Variant'

  validates_presence_of :hub_id, :variant_id

  scope :for_hubs, lambda { |hubs|
    where(hub_id: hubs)
  }

  def self.price_for(variant, hub)
    VariantOverride.where(variant_id: variant, hub_id: hub).first.andand.price
  end
end
