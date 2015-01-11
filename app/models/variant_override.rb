class VariantOverride < ActiveRecord::Base
  belongs_to :hub, class_name: 'Enterprise'
  belongs_to :variant, class_name: 'Spree::Variant'

  validates_presence_of :hub_id, :variant_id

  scope :for_hubs, lambda { |hubs|
    where(hub_id: hubs)
  }

  def self.price_for(hub, variant)
    self.for(hub, variant).andand.price
  end

  def self.count_on_hand_for(hub, variant)
    self.for(hub, variant).andand.count_on_hand
  end

  def self.stock_overridden?(hub, variant)
    count_on_hand_for(hub, variant).present?
  end

  def self.decrement_stock!(hub, variant, quantity)
    vo = self.for(hub, variant)

    if vo.nil?
      Bugsnag.notify RuntimeError.new "Attempting to decrement stock level for a variant without a VariantOverride."

    elsif vo.count_on_hand.blank?
      Bugsnag.notify RuntimeError.new "Attempting to decrement stock level on a VariantOverride without a count_on_hand specified."

    else
      vo.decrement! :count_on_hand, quantity
    end
  end


  private

  def self.for(hub, variant)
    VariantOverride.where(variant_id: variant, hub_id: hub).first
  end

end
