# frozen_string_literal: true

module Spree
  module Core
    module CalculatedAdjustments
      def self.included(klass)
        klass.class_eval do
          has_one :calculator, class_name: "Spree::Calculator", as: :calculable, dependent: :destroy
          accepts_nested_attributes_for :calculator
          validates :calculator, presence: true

          def self.calculators
            spree_calculators.__send__(model_name_without_spree_namespace)
          end

          def calculator_type
            calculator.class.to_s if calculator
          end

          def calculator_type=(calculator_type)
            klass = calculator_type.constantize if calculator_type
            self.calculator = klass.new if klass && !calculator.is_a?(klass)
          end

          # Creates a new adjustment for the target object
          #   (which is any class that has_many :adjustments) and sets amount based on the
          #   calculator as applied to the given calculable (Order, LineItems[], Shipment, etc.)
          # By default the adjustment will not be considered mandatory
          def create_adjustment(label, adjustable, mandatory = false, state = "closed")
            amount = compute_amount(adjustable)
            return if amount.zero? && !mandatory

            adjustment_attributes = {
              amount: amount,
              originator: self,
              order: order_object_for(adjustable),
              label: label,
              mandatory: mandatory,
              state: state,
              included: tax_included?(self, adjustable)
            }

            if adjustable.respond_to?(:adjustments)
              adjustable.adjustments.create(adjustment_attributes)
            else
              adjustable.create_adjustment(adjustment_attributes)
            end
          end

          # Calculate the amount to be used when creating an adjustment
          # NOTE: May be overriden by classes where this module is included into.
          def compute_amount(calculable)
            calculator.compute(calculable)
          end

          def self.model_name_without_spree_namespace
            to_s.tableize.gsub('/', '_').sub('spree_', '')
          end
          private_class_method :model_name_without_spree_namespace

          def self.spree_calculators
            Rails.application.config.spree.calculators
          end
          private_class_method :spree_calculators

          private

          # Used for setting the #included boolean on tax adjustments. This will be removed in a
          # later step, as the responsibility for creating all adjustments related to tax will be
          # moved into the Spree::TaxRate class.
          def tax_included?(originator, target)
            originator.is_a?(Spree::TaxRate) &&
              originator.included_in_price &&
              originator.default_zone_or_zone_match?(order_object_for(target))
          end

          def order_object_for(target)
            # Temporary method for adjustments transition.
            if target.is_a? Spree::Order
              target
            elsif target.respond_to?(:order)
              target.order
            end
          end
        end
      end
    end
  end
end
