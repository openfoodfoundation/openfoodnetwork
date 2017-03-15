module OpenFoodNetwork
  class SalesTaxReport
    include Spree::ReportsHelper
    attr_accessor :user, :params

    def initialize(user, params)
      @user = user
      @params = params
    end

    def header
      case params[:report_type]
      when "tax_rates"
        [I18n.t(:report_header_order_number),
         I18n.t(:report_header_total_excl_vat, currency_symbol: currency_symbol)] +
        relevant_rates.map { |rate| "%.1f%% (%s)" % [rate.to_f * 100, currency_symbol] } +
        [I18n.t(:report_header_total_tax, currency_symbol: currency_symbol),
         I18n.t(:report_header_total_incl_vat, currency_symbol: currency_symbol)]
       else
        [I18n.t(:report_header_order_number),
         I18n.t(:report_header_date),
         I18n.t(:report_header_items),
         I18n.t(:report_header_items_total, currency_symbol: currency_symbol),
         I18n.t(:report_header_taxable_items_total, currency_symbol: currency_symbol),
         I18n.t(:report_header_sales_tax, currency_symbol: currency_symbol),
         I18n.t(:report_header_delivery_charge, currency_symbol: currency_symbol),
         I18n.t(:report_header_tax_on_delivery, currency_symbol: currency_symbol),
         I18n.t(:report_header_tax_on_fees, currency_symbol: currency_symbol),
         I18n.t(:report_header_total_tax, currency_symbol: currency_symbol),
         I18n.t(:report_header_customer),
         I18n.t(:report_header_distributor)]
      end
    end

    def search
      permissions = OpenFoodNetwork::Permissions.new(user)
      permissions.editable_orders.complete.not_state(:canceled).search(params[:q])
    end

    def orders
      search.result
    end

    def table
      case params[:report_type]
      when "tax_rates"
        orders.map do |order|
          [order.number, order.total - order.total_tax] +
            relevant_rates.map { |rate| order.tax_adjustment_totals.fetch(rate, 0) } +
            [order.total_tax, order.total]
        end
      else
        orders.map do |order|
          totals = totals_of order.line_items
          shipping_cost = shipping_cost_for order

          [order.number, order.created_at, totals[:items], totals[:items_total],
           totals[:taxable_total], totals[:sales_tax], shipping_cost, order.shipping_tax, order.enterprise_fee_tax, order.total_tax,
           order.bill_address.full_name, order.distributor.andand.name]
        end
      end
    end


    private

    def relevant_rates
      return @relevant_rates unless @relevant_rates.nil?
      @relevant_rates = Spree::TaxRate.pluck(:amount).uniq
    end

    def totals_of(line_items)
      totals = {items: 0, items_total: 0.0, taxable_total: 0.0, sales_tax: 0.0}

      line_items.each do |line_item|
        totals[:items] += line_item.quantity
        totals[:items_total] += line_item.amount

        sales_tax = tax_included_in line_item

        if sales_tax > 0
          totals[:taxable_total] += line_item.amount
          totals[:sales_tax] += sales_tax
        end
      end

      totals.each_pair do |k, v|
        totals[k] = totals[k].round(2)
      end

      totals
    end

    def shipping_cost_for(order)
      shipping_cost = order.adjustments.find_by_label("Shipping").andand.amount
      shipping_cost = shipping_cost.nil? ? 0.0 : shipping_cost
    end

    def tax_included_in(line_item)
      line_item.adjustments.sum &:included_tax
    end

    def shipment_inc_vat
      Spree::Config.shipment_inc_vat
    end

    def shipping_tax_rate
      Spree::Config.shipping_tax_rate
    end
  end
end
