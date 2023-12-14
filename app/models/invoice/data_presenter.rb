# frozen_string_literal: true

class Invoice
  class DataPresenter
    include ::ActionView::Helpers::NumberHelper
    attr_reader :invoice

    delegate :display_number, :data, :previous_invoice, to: :invoice
    delegate :date, to: :invoice, prefix: true

    FINALIZED_NON_SUCCESSFUL_STATES = %w(canceled returned).freeze

    extend Invoice::DataPresenterAttributes

    attributes :additional_tax_total, :currency, :included_tax_total, :payment_total,
               :shipping_method_id, :state, :total, :number, :note, :special_instructions,
               :completed_at

    attributes_with_presenter :bill_address, :customer, :distributor, :ship_address,
                              :shipping_method, :order_cycle

    array_attribute :sorted_line_items, class_name: 'LineItem'
    array_attribute :all_eligible_adjustments, class_name: 'Adjustment'
    array_attribute :payments, class_name: 'Payment'

    # if any of the following attributes is updated, a new invoice should be generated
    invoice_generation_attributes :additional_tax_total, :all_eligible_adjustments, :bill_address,
                                  :included_tax_total, :payments, :payment_total, :ship_address,
                                  :shipping_method_id, :sorted_line_items, :total

    # if any of the following attributes is updated, the latest invoice should be updated
    invoice_update_attributes :note, :special_instructions, :state,
                              :all_eligible_adjustments, :payments

    def initialize(invoice)
      @invoice = invoice
    end

    def has_taxes_included
      included_tax_total > 0
    end

    def total_tax
      additional_tax_total + included_tax_total
    end

    def order_completed_at
      return nil if data[:completed_at].blank?

      Time.zone.parse(data[:completed_at])
    end

    def checkout_adjustments(exclude: [])
      adjustments = all_eligible_adjustments
        .reject { |a| a.originator.type == 'Spree::TaxRate' }
        .map(&:clone)

      adjustments.reject! { |a| a.amount == 0 }
      [:line_item, :shipment].each do |type|
        next unless exclude.include? type

        adjustments.reject! { |a|
          a.adjustable_type == "Spree::#{type.to_s.classify}"
        }
      end
      adjustments
    end

    def shipment_adjustment
      all_eligible_adjustments.find { |a| a.originator.type == 'Spree::ShippingMethod' }
    end

    # contains limited information about the shipment
    def shipment
      shipment_adjustment&.adjustable || null_shipment
    end

    def null_shipment
      Struct.new(
        :amount,
        :included_tax_total,
        :additional_tax_total,
      ).new(0, 0, 0)
    end

    def display_shipment_amount_without_taxes
      Spree::Money.new(shipment.amount - shipment.included_tax_total, currency:)
    end

    def display_shipment_amount_with_taxes
      Spree::Money.new(shipment.amount + shipment.additional_tax_total, currency:)
    end

    def display_shipment_tax_rates
      all_eligible_adjustments.select { |a|
        a.originator.type == 'Spree::TaxRate' && a.adjustable_type == 'Spree::Shipment'
      }.map(&:originator)
        .map { |tr| number_to_percentage(tr.amount * 100, precision: 1) }.join(", ")
    end

    def display_checkout_taxes_hash
      tax_adjustment_totals.map do |tax_rate_id, tax_amount|
        tax_rate = tax_rate_by_id[tax_rate_id]
        {
          amount: Spree::Money.new(tax_amount, currency:),
          percentage: number_to_percentage(tax_rate.amount * 100, precision: 1),
          rate_amount: tax_rate.amount,
        }
      end.sort_by { |tax| tax[:rate_amount] }
    end

    def display_date
      I18n.l(invoice_date.to_date, format: :long)
    end

    def display_tax_adjustment_total
      Spree::Money.new(all_tax_adjustments.map(&:amount).sum, currency:)
    end

    def tax_adjustment_totals
      all_tax_adjustments.each_with_object(Hash.new(0)) do |adjustment, totals|
        totals[adjustment.originator.id] += adjustment.amount
      end
    end

    def tax_rate_by_id
      all_tax_adjustments.each_with_object({}) do |adjustment, tax_rates|
        tax_rates[adjustment.originator.id] = adjustment.originator
      end
    end

    def all_tax_adjustments
      all_eligible_adjustments.select { |a| a.originator.type == 'Spree::TaxRate' }
    end

    def paid?
      data[:payment_state] == 'paid' || data[:payment_state] == 'credit_owed'
    end

    def outstanding_balance?
      !new_outstanding_balance.zero?
    end

    def new_outstanding_balance
      if state.in?(FINALIZED_NON_SUCCESSFUL_STATES)
        -payment_total
      else
        total - payment_total
      end
    end

    def outstanding_balance_label
      new_outstanding_balance.negative? ? I18n.t(:credit_owed) : I18n.t(:balance_due)
    end

    def last_payment
      payments.max_by(&:created_at)
    end

    def last_payment_method
      last_payment&.payment_method
    end

    def display_outstanding_balance
      Spree::Money.new(new_outstanding_balance, currency:)
    end

    def display_checkout_tax_total
      Spree::Money.new(total_tax, currency:)
    end

    def display_checkout_total_less_tax
      Spree::Money.new(total - total_tax, currency:)
    end

    def display_total
      Spree::Money.new(total, currency:)
    end
  end
end
