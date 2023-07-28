# frozen_string_literal: true

module Spree
  class ShippingMethod < ApplicationRecord
    include CalculatedAdjustments
    DISPLAY_ON_OPTIONS = {
      both: "",
      back_end: "back_end"
    }.freeze

    acts_as_paranoid
    acts_as_taggable

    default_scope -> { where(deleted_at: nil) }

    has_many :shipping_rates, inverse_of: :shipping_method
    has_many :shipments, through: :shipping_rates
    has_many :shipping_method_categories
    has_many :shipping_categories, through: :shipping_method_categories
    has_many :distributor_shipping_methods
    has_many :distributors, through: :distributor_shipping_methods,
                            class_name: 'Enterprise',
                            foreign_key: 'distributor_id'

    has_and_belongs_to_many :zones, join_table: 'spree_shipping_methods_zones',
                                    class_name: 'Spree::Zone'

    belongs_to :tax_category, class_name: 'Spree::TaxCategory', optional: true

    validates :name, presence: true
    validate :distributor_validation
    validate :at_least_one_shipping_category
    validates :display_on, inclusion: { in: DISPLAY_ON_OPTIONS.values }, allow_nil: true

    after_initialize :init

    after_save :touch_distributors

    scope :managed_by, lambda { |user|
      if user.has_spree_role?('admin')
        where(nil)
      else
        joins(:distributors).
          where('distributors_shipping_methods.distributor_id IN (?)',
                user.enterprises.select(&:id)).
          select('DISTINCT spree_shipping_methods.*')
      end
    }

    scope :for_distributors, ->(distributors) {
      non_unique_matches = unscoped.joins(:distributors).where(enterprises: { id: distributors })
      where(id: non_unique_matches.map(&:id))
    }
    scope :for_distributor, lambda { |distributor|
      joins(:distributors).
        where('enterprises.id = ?', distributor)
    }

    scope :by_name, -> { order('spree_shipping_methods.name ASC') }

    # Here we allow checkout with shipping methods without zones (see issue #3928 for details)
    #   and also checkout with addresses outside of the zones of the selected shipping method
    # This method could be used, like in Spree, to validate shipping method zones on checkout.
    def delivers_to?(address)
      address.present?
    end

    def build_tracking_url(tracking)
      tracking_url.gsub(/:tracking/, tracking) unless tracking.blank? || tracking_url.blank?
    end

    # Some shipping methods are only meant to be set via backend
    def frontend?
      display_on != "back_end"
    end

    def has_distributor?(distributor)
      distributors.include?(distributor)
    end

    # Checks whether the shipping method is of delivery type, meaning that it
    # requires the user to specify a ship address at checkout.
    #
    # @return [Boolean]
    def delivery?
      require_ship_address
    end

    # Return the services (pickup, delivery) that different distributors provide, in the format:
    # {distributor_id => {pickup: true, delivery: false}, ...}
    def self.services
      Hash[
        Spree::ShippingMethod.
          joins(:distributor_shipping_methods).
          group('distributor_id').
          select("distributor_id").
          select("BOOL_OR(spree_shipping_methods.require_ship_address = 'f') AS pickup").
          select("BOOL_OR(spree_shipping_methods.require_ship_address = 't') AS delivery").
          map { |sm| [sm.distributor_id.to_i, { pickup: sm.pickup, delivery: sm.delivery }] }
      ]
    end

    def self.backend
      where(display_on: DISPLAY_ON_OPTIONS[:back_end])
    end

    def self.frontend
      where(display_on: [nil, ""])
    end

    def init
      self.calculator ||= ::Calculator::None.new if new_record?
    end

    private

    def no_active_or_upcoming_order_cycle_distributors_with_only_one_shipping_method?
      return true if new_record?

      distributors.
        with_order_cycles_as_distributor_outer.
        merge(OrderCycle.active.or(OrderCycle.upcoming)).none? do |distributor|
        distributor.shipping_method_ids.one?
      end
    end

    def at_least_one_shipping_category
      return unless shipping_categories.empty?

      errors.add(:base, "You need to select at least one shipping category")
    end

    def touch_distributors
      distributors.each do |distributor|
        distributor.touch if distributor.persisted?
      end
    end

    def distributor_validation
      validates_with DistributorsValidator
    end
  end
end
