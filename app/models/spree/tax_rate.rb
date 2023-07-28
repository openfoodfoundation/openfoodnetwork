# frozen_string_literal: false

module Spree
  class DefaultTaxZoneValidator < ActiveModel::Validator
    def validate(record)
      return unless record.included_in_price

      return if Zone.default_tax

      record.errors.add(:included_in_price, Spree.t("errors.messages.included_price_validation"))
    end
  end
end

module Spree
  class TaxRate < ApplicationRecord
    self.belongs_to_required_by_default = false

    acts_as_paranoid
    include CalculatedAdjustments

    belongs_to :zone, class_name: "Spree::Zone", inverse_of: :tax_rates
    belongs_to :tax_category, class_name: "Spree::TaxCategory", inverse_of: :tax_rates
    has_many :adjustments, as: :originator

    validates :amount, presence: true, numericality: true
    validates :tax_category, presence: true
    validates_with DefaultTaxZoneValidator

    scope :by_zone, ->(zone) { where(zone_id: zone) }

    # Gets the array of TaxRates appropriate for the specified order
    def self.match(order)
      return [] if order.distributor && !order.distributor.charges_sales_tax
      return [] unless order.tax_zone

      all.includes(zone: { zone_members: :zoneable }).load.select do |rate|
        rate.potentially_applicable?(order.tax_zone)
      end
    end

    def self.adjust(order, items)
      applicable_rates = match(order)
      applicable_tax_categories = applicable_rates.map(&:tax_category)

      relevant_items, non_relevant_items = items.partition do |item|
        applicable_tax_categories.include?(item.tax_category)
      end

      relevant_items.each do |item|
        item.adjustments.tax.delete_all
        relevant_rates = applicable_rates.select { |rate| rate.tax_category == item.tax_category }
        relevant_rates.each do |rate|
          rate.adjust(order, item)
        end
      end

      non_relevant_items.each do |item|
        if item.adjustments.tax.present?
          item.adjustments.tax.delete_all
          Spree::ItemAdjustments.new(item).update
        end
      end
    end

    # For VAT, the default rate is the rate that is configured for the default category
    # It is needed for every price calculation (as all customer facing prices include VAT)
    # Here we return the actual amount, which may be 0 in case of wrong setup, but is never nil
    def self.default
      category = TaxCategory.includes(:tax_rates).find_by(is_default: true)
      return 0 unless category

      address ||= Address.new(country_id: DefaultCountry.id)
      rate = category.tax_rates
        .detect { |tax_rate| tax_rate.zone.contains_address? address }.try(:amount)

      rate || 0
    end

    def potentially_applicable?(order_tax_zone)
      # If the rate's zone matches the order's tax zone, then it's applicable.
      zone == order_tax_zone ||
        # If the rate's zone *contains* the order's tax zone, then it's applicable.
        zone.contains?(order_tax_zone) ||
        # The rate's zone is the default zone, then it's always applicable.
        (included_in_price? && zone.default_tax)
    end

    # Creates necessary tax adjustments for the item.
    def adjust(order, item)
      amount = compute_amount(item)
      return if amount.zero?

      included = included_in_price && default_zone_or_zone_match?(order)

      adjustments.create!(
        adjustable: item,
        amount: amount,
        order: order,
        label: create_label(amount),
        included: included
      )
    end

    # This method is used by Adjustment#update to recalculate the cost.
    def compute_amount(item)
      if included_in_price
        if default_zone_or_zone_match?(item.order)
          calculator.compute(item)
        else
          # In this case, it's a refund.
          calculator.compute(item) * - 1
        end
      else
        calculator.compute(item)
      end
    end

    def default_zone_or_zone_match?(order)
      Zone.default_tax&.contains?(order.tax_zone) || order.tax_zone == zone
    end

    private

    def create_label(adjustment_amount)
      label = ""
      label << "#{Spree.t(:refund)} " if adjustment_amount.negative?
      label << "#{name.presence || tax_category.name} "
      label << (show_rate_in_label? ? "#{amount * 100}%" : "")
      label << " (#{I18n.t('models.tax_rate.included_in_price')})" if included_in_price?
      label
    end
  end
end
