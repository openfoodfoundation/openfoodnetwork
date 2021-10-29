# frozen_string_literal: true

require "active_support/concern"

module CalculatedAdjustments
  extend ActiveSupport::Concern

  included do
    has_one :calculator, as: :calculable, class_name: "Spree::Calculator", dependent: :destroy
    accepts_nested_attributes_for :calculator
    validates :calculator, presence: true
  end

  class_methods do
    def calculators
      spree_calculators.__send__(model_name_without_spree_namespace)
    end

    private

    def model_name_without_spree_namespace
      to_s.tableize.gsub('/', '_').sub('spree_', '')
    end

    def spree_calculators
      Rails.application.config.spree.calculators
    end
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
  def create_adjustment(label, adjustable, mandatory = false, state = "closed", tax_category = nil)
    amount = compute_amount(adjustable)
    return if amount.zero? && !mandatory

    adjustment_attributes = {
      amount: amount,
      originator: self,
      order: order_object_for(adjustable),
      label: label,
      mandatory: mandatory,
      state: state,
      tax_category: tax_category
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

  def order_object_for(target)
    # Temporary method for adjustments transition.
    if target.is_a? Spree::Order
      target
    elsif target.respond_to?(:order)
      target.order
    end
  end
end
