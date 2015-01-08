module OpenFoodNetwork
  class SalesTaxReport
    include Spree::ReportsHelper

    def initialize orders
      @orders = orders
    end

    def header
      ["Order number", "Date", "Items", "Items total (#{currency_symbol})", "Taxable Items Total (#{currency_symbol})",
        "Sales Tax (#{currency_symbol})", "Delivery Charge (#{currency_symbol})", "Tax on Delivery (#{currency_symbol})",
        "Total Tax (#{currency_symbol})", "Customer", "Distributor"]
    end

    def table
      @orders.map do |order|
        totals = totals_of order.line_items
        shipping_cost = shipping_cost_for order
        shipping_tax = shipping_tax_on shipping_cost
        
        [order.number, order.created_at, totals[:items], totals[:items_total],
         totals[:taxable_total], totals[:sales_tax], shipping_cost, shipping_tax, totals[:sales_tax] + shipping_tax,
         order.bill_address.full_name, order.distributor.andand.name]
      end
    end


    private

    def totals_of(line_items)
      totals = {items: 0, items_total: 0.0, taxable_total: 0.0, sales_tax: 0.0}

      line_items.each do |line_item|
        totals[:items] += line_item.quantity
        totals[:items_total] += line_item.amount

        tax_rate = tax_rate_on line_item

        if tax_rate != nil && tax_rate != 0
          totals[:taxable_total] += line_item.amount
          totals[:sales_tax] += line_item.amount * tax_rate
        end
      end

      totals
    end

    def shipping_cost_for(order)
      shipping_cost = order.adjustments.find_by_label("Shipping").andand.amount
      shipping_cost = shipping_cost.nil? ? 0.0 : shipping_cost
    end

    def shipping_tax_on(shipping_cost)
      if Spree::Config[:shipment_inc_vat] && shipping_cost != nil
        shipping_cost * Spree::Config[:shipping_tax_rate]
      else
        0.0
      end
    end

    def tax_rate_on(line_item)
      Spree::TaxRate.find_by_tax_category_id(line_item.variant.product.tax_category_id).andand.amount
    end
  end
end
