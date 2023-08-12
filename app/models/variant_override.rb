# frozen_string_literal: true

require 'spree/localized_number'

class VariantOverride < ApplicationRecord
  extend Spree::LocalizedNumber
  include StockSettingsOverrideValidation

  self.belongs_to_required_by_default = false

  acts_as_taggable

  belongs_to :hub, class_name: 'Enterprise'
  belongs_to :variant, class_name: 'Spree::Variant'

  validates :hub, presence: true
  validates :variant, presence: true
  # Default stock can be nil, indicating stock should not be reset or zero, meaning reset to zero.
  # Need to ensure this can be set by the user.
  validates :default_stock, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :count_on_hand, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  default_scope { where(permission_revoked_at: nil) }

  scope :for_hubs, lambda { |hubs|
    where(hub_id: hubs)
  }

  scope :distinct_import_dates, lambda {
    select('DISTINCT variant_overrides.import_date').
      where('variant_overrides.import_date IS NOT NULL').
      order('import_date DESC')
  }

  localize_number :price

  def self.indexed(hub)
    for_hubs(hub).preload(:variant).index_by(&:variant)
  end

  def stock_overridden?
    # If count_on_hand is present, it means on_demand is false
    #   See StockSettingsOverrideValidation for details
    count_on_hand.present?
  end

  def use_producer_stock_settings?
    on_demand.nil?
  end

  def move_stock!(quantity)
    unless stock_overridden?
      Bugsnag.notify RuntimeError.new "Attempting to move stock of a VariantOverride " \
                                      "without a count_on_hand specified."
      return
    end

    if quantity > 0
      increment! :count_on_hand, quantity
    elsif quantity < 0
      decrement! :count_on_hand, -quantity
    end
  end

  def default_stock?
    default_stock.present?
  end

  def reset_stock!
    if resettable
      if default_stock?
        self.attributes = { on_demand: false, count_on_hand: default_stock }
        save
      else
        Bugsnag.notify RuntimeError.new "Attempting to reset stock level for a variant " \
                                        "with no default stock level."
      end
    end
    self
  end

  def deletable?
    price.blank? &&
      count_on_hand.blank? &&
      default_stock.blank? &&
      resettable.blank? &&
      sku.nil? &&
      on_demand.nil?
  end
end
