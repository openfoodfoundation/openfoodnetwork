class VariantOverride < ActiveRecord::Base
  acts_as_taggable

  belongs_to :hub, class_name: 'Enterprise'
  belongs_to :variant, class_name: 'Spree::Variant'

  validates_presence_of :hub_id, :variant_id
  # Default stock can be nil, indicating stock should not be reset or zero, meaning reset to zero. Need to ensure this can be set by the user.
  validates :default_stock, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  after_save :refresh_products_cache_from_save
  after_destroy :refresh_products_cache_from_destroy

  default_scope where(permission_revoked_at: nil)

  scope :for_hubs, lambda { |hubs|
    where(hub_id: hubs)
  }

  def self.indexed(hub)
    Hash[
      for_hubs(hub).preload(:variant).map { |vo| [vo.variant, vo] }
    ]
  end

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
    else
      vo.decrement_stock! quantity
    end
  end

  def stock_overridden?
    count_on_hand.present?
  end

  def decrement_stock!(quantity)
    if stock_overridden?
      decrement! :count_on_hand, quantity
    else
      Bugsnag.notify RuntimeError.new "Attempting to decrement stock level on a VariantOverride without a count_on_hand specified."
    end
  end

  def increment_stock!(quantity)
    if stock_overridden?
      increment! :count_on_hand, quantity
    else
      Bugsnag.notify RuntimeError.new "Attempting to decrement stock level on a VariantOverride without a count_on_hand specified."
    end
  end

  def default_stock?
    default_stock.present?
  end

  def reset_stock!
    if resettable
      if default_stock?
        self.attributes = { count_on_hand: default_stock }
        self.save
      else
        Bugsnag.notify RuntimeError.new "Attempting to reset stock level for a variant with no default stock level."
      end
    end
    self
  end

  private

  def self.for(hub, variant)
    VariantOverride.where(variant_id: variant, hub_id: hub).first
  end

  def refresh_products_cache_from_save
    OpenFoodNetwork::ProductsCache.variant_override_changed self
  end

  def refresh_products_cache_from_destroy
    OpenFoodNetwork::ProductsCache.variant_override_destroyed self
  end
end
