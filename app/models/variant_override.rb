# frozen_string_literal: true

require 'spree/localized_number'

class VariantOverride < ApplicationRecord
  extend Spree::LocalizedNumber
  include StockSettingsOverrideValidation

  acts_as_taggable

  belongs_to :hub, class_name: 'Enterprise'
  belongs_to :variant, class_name: 'Spree::Variant'

  # Default stock can be nil, indicating stock should not be reset or zero, meaning reset to zero.
  # Need to ensure this can be set by the user.
  validates :default_stock, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :count_on_hand, numericality: {
    greater_than_or_equal_to: 0, unless: :on_demand?
  }, allow_nil: true

  default_scope { where(permission_revoked_at: nil) }

  scope :for_hubs, lambda { |hubs|
    where(hub_id: hubs)
  }

  scope :distinct_import_dates, lambda {
    select('DISTINCT variant_overrides.import_date').
      where.not(variant_overrides: { import_date: nil }).
      order('import_date DESC')
  }

  localize_number :price

  def self.indexed(hub)
    for_hubs(hub).preload(:variant).index_by(&:variant)
  end

  def stock_overridden?
    # Testing for not nil because for a boolean `false.present?` is false.
    !on_demand.nil? || !count_on_hand.nil?
  end

  def use_producer_stock_settings?
    on_demand.nil?
  end

  def move_stock!(quantity)
    unless stock_overridden?
      Alert.raise "Attempting to move stock of a VariantOverride " \
                  "without a count_on_hand specified."
      return
    end

    # rubocop:disable Rails/SkipsModelValidations
    # Cf. conversation https://github.com/openfoodfoundation/openfoodnetwork/pull/12647
    if quantity > 0
      increment! :count_on_hand, quantity
    elsif quantity < 0
      decrement! :count_on_hand, -quantity
    end
    # rubocop:enable Rails/SkipsModelValidations
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
        Alert.raise "Attempting to reset stock level for a variant " \
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
