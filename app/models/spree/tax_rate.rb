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
  class TaxRate < ActiveRecord::Base
    acts_as_paranoid

    before_destroy :deals_with_adjustments_for_deleted_source

    include Spree::Core::CalculatedAdjustments
    include Spree::Core::AdjustmentSource

    has_many :adjustments, as: :source
    belongs_to :zone, class_name: "Spree::Zone", inverse_of: :tax_rates
    belongs_to :tax_category, class_name: "Spree::TaxCategory", inverse_of: :tax_rates

    validates :amount, presence: true, numericality: true
    validates :tax_category_id, presence: true
    validates_with DefaultTaxZoneValidator

    scope :by_zone, ->(zone) { where(zone_id: zone) }

    # Gets the array of TaxRates appropriate for the specified order
    def self.match(order)
      return [] if order.distributor && !order.distributor.charges_sales_tax
      return [] unless order.tax_zone

      includes(zone: { zone_members: :zoneable }).load.select do |rate|
        rate.potentially_applicable?(order)
      end
    end

    # Pre-tax amounts must be stored so that we can calculate
    # correct rate amounts in the future. For example:
    # https://github.com/spree/spree/issues/4318#issuecomment-34723428
    def self.store_pre_tax_amount(item, rates)
      if rates.any? { |r| r.included_in_price }
        case item
        when Spree::LineItem
          item_amount = item.amount
        when Spree::Shipment
          item_amount = item.cost
        when Spree::Adjustment
          return
        end
        pre_tax_amount = item_amount / (1 + rates.map(&:amount).sum)
        item.update_column(:pre_tax_amount, pre_tax_amount)
      end
    end

    def self.adjust(order, items)
      applicable_rates = self.match(order)
      applicable_tax_categories = applicable_rates.map(&:tax_category)

      relevant_items, non_relevant_items = items.partition do |item|
        applicable_tax_categories.include?(item.tax_category)
      end

      relevant_items.each do |item|
        pp "REL"
        item.adjustments.tax.delete_all
        relevant_rates = applicable_rates.select { |rate| rate.tax_category == item.tax_category }
        store_pre_tax_amount(item, relevant_rates)
        # we could pass relevant_rates down here so we don't need to persist pre_tax_amount
        relevant_rates.each do |rate|
          rate.adjust(order, item)
        end
      end

      non_relevant_items.each do |item|
        pp "non-REL"
        if item.adjustments.tax.present?
          item.adjustments.tax.delete_all
          item.update_column(:pre_tax_amount, nil) # will currently break with fees...
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

      address ||= Address.new(country_id: Spree::Config[:default_country_id])
      rate = category.tax_rates.detect { |tax_rate| tax_rate.zone.include? address }.try(:amount)

      rate || 0
    end

    # Tax rates can *potentially* be applicable to an order.
    # We do not know if they are/aren't until we attempt to apply these rates to
    # the items contained within the Order itself.
    # For instance, if a rate passes the criteria outlined in this method,
    # but then has a tax category that doesn't match against any of the line items
    # inside of the order, then that tax rate will not be applicable to anything.
    # For instance:
    #
    # Zones:
    #   - Spain (default tax zone)
    #   - France
    #
    # Tax rates: (note: amounts below do not actually reflect real VAT rates)
    #   21% inclusive - "Clothing" - Spain
    #   18% inclusive - "Clothing" - France
    #   10% inclusive - "Food" - Spain
    #   8% inclusive - "Food" - France
    #   5% inclusive - "Hotels" - Spain
    #   2% inclusive - "Hotels" - France
    #
    # Order has:
    #   Line Item #1 - Tax Category: Clothing
    #   Line Item #2 - Tax Category: Food
    #
    # Tax rates that should be selected:
    #
    #  21% inclusive - "Clothing" - Spain
    #  10% inclusive - "Food" - Spain
    #
    # If the order's address changes to one in France, then the tax will be recalculated:
    #
    #  18% inclusive - "Clothing" - France
    #  8% inclusive - "Food" - France
    #
    # Note here that the "Hotels" tax rates will not be used at all.
    # This is because there are no items which have the tax category of "Hotels".
    #
    # Under no circumstances should negative adjustments be applied for the Spanish tax rates.
    #
    # Those rates should never come into play at all and only the French rates should apply.
    def potentially_applicable?(order)
      # If the rate's zone matches the order's tax zone, then it's applicable.
      self.zone == order.tax_zone ||
      # If the rate's zone *contains* the order's tax zone, then it's applicable.
      self.zone.contains?(order.tax_zone) ||
      # 1) The rate's zone is the default zone, then it's always applicable.
      (self.included_in_price? && self.zone.default_tax)
    end

    # Creates necessary tax adjustments for the item.
    def adjust(order, item)
      amount = compute_amount(item)
      return if amount == 0

      included = included_in_price && default_zone_or_zone_match?(item)

      if amount < 0
        label = Spree.t(:refund) + ' ' + create_label
      end

      self.adjustments.create!(
        {
          adjustable: item,
          amount: amount,
          order: order,
          label: label || create_label,
          included: included
        }
      )
    end

    # This method is used by Adjustment#update to recalculate the cost.
    def compute_amount(item)
      if included_in_price
        if default_zone_or_zone_match?(item)
          calculator.compute(item)
        else
          # In this case, it's a refund.
          calculator.compute(item) * - 1
        end
      else
        calculator.compute(item)
      end
    end

    def default_zone_or_zone_match?(item)
      Zone.default_tax.contains?(item.order.tax_zone) ||
        item.order.tax_zone == self.zone
    end

    # This #compute_tax method below looks really suspect. It's not part of Spree's original code here,
    # and the way we are using this method probably needs to be removed or adjusted during cleanup.

    # Manually apply a TaxRate to a particular amount. TaxRates normally compute against
    # LineItems or Orders, so we mock out a line item here to fit the interface
    # that our calculator (usually DefaultTax) expects.
    def compute_tax(amount)
      line_item = LineItem.new quantity: 1
      line_item.tax_category = tax_category
      line_item.define_singleton_method(:price) { amount }

      # Tax on adjustments (represented by the included_tax field) is always inclusive of
      # tax. However, there's nothing to stop an admin from setting one up with a tax rate
      # that's marked as not inclusive of tax, and that would result in the DefaultTax
      # calculator generating a slightly incorrect value. Therefore, we treat the tax
      # rate as inclusive of tax for the calculations below, regardless of its original
      # setting.
      with_tax_included_in_price do
        calculator.compute line_item
      end
    end

    private

    def create_label
      label = ""
      label << (name.presence || tax_category.name) + " "
      label << (show_rate_in_label? ? "#{amount * 100}%" : "")
      label << " (#{I18n.t('models.tax_rate.included_in_price')})" if included_in_price?
      label
    end

    def with_tax_included_in_price
      old_included_in_price = included_in_price

      self.included_in_price = true
      calculator.calculable.included_in_price = true

      result = yield
    ensure
      self.included_in_price = old_included_in_price
      calculator.calculable.included_in_price = old_included_in_price

      result
    end
  end
end
