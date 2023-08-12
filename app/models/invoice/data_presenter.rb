# frozen_string_literal: true

class Invoice
  class DataPresenter
    attr_reader :invoice

    delegate :data, to: :invoice
    delegate :number, :date, to: :invoice, prefix: true

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

    def checkout_adjustments(exclude: [], reject_zero_amount: true)
      adjustments = all_eligible_adjustments

      adjustments.reject! { |a| a.originator_type == 'Spree::TaxRate' }

      if exclude.include? :line_item
        adjustments.reject! { |a|
          a.adjustable_type == 'Spree::LineItem'
        }
      end

      if reject_zero_amount
        adjustments.reject! { |a| a.amount == 0 }
      end

      adjustments
    end

    def display_checkout_taxes_hash
      totals = OrderTaxAdjustmentsFetcher.new(nil).totals(all_tax_adjustments)

      totals.map do |tax_rate, tax_amount|
        {
          amount: Spree::Money.new(tax_amount, currency: order.currency),
          percentage: number_to_percentage(tax_rate.amount * 100, precision: 1),
          rate_amount: tax_rate.amount,
        }
      end.sort_by { |tax| tax[:rate_amount] }
    end

    def display_date
      I18n.l(invoice_date.to_date, format: :long)
    end

    def all_tax_adjustments
      all_eligible_adjustments.select { |a| a.originator_type == 'Spree::TaxRate' }
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
      Spree::Money.new(new_outstanding_balance, currency: currency)
    end

    def display_checkout_tax_total
      Spree::Money.new(total_tax, currency: currency)
    end

    def display_checkout_total_less_tax
      Spree::Money.new(total - total_tax, currency: currency)
    end

    def display_total
      Spree::Money.new(total, currency: currency)
    end
  end
end
