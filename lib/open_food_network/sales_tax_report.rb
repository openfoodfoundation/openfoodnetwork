
module OpenFoodNetwork
  class SalesTaxReport

    def initialize orders
      @orders = orders
    end

    def header
      currency_symbol = Spree::Money.currency_symbol
      ["Order number", "Date", "Items", "Items total (#{currency_symbol})", "Taxable Items Total (#{currency_symbol})",
        "Sales Tax (#{currency_symbol})", "Delivery Charge (#{currency_symbol})", "Tax on Delivery (#{currency_symbol})",
        "Total Tax (#{currency_symbol})", "Customer", "Distributor"]
    end

    def table
      sales_tax_details = []
      @orders.each do |order|
        totals = {items: 0, items_total: 0.0, taxable_total: 0.0, sales_tax: 0.0}
        
        order.line_items.each do |line_item|
          totals[:items] += line_item.quantity
          totals[:items_total] += line_item.amount
          
          tax_rate = Spree::TaxRate.find_by_tax_category_id(line_item.variant.product.tax_category_id).andand.amount
          
          if tax_rate != nil && tax_rate != 0
            totals[:taxable_total] += line_item.amount
            totals[:sales_tax] += line_item.amount * tax_rate
          end
        end
        
        shipping_cost = order.adjustments.find_by_label("Shipping").andand.amount
        shipping_cost = shipping_cost.nil? ? 0.0 : shipping_cost
        if Spree::Config[:shipment_inc_vat] && shipping_cost != nil
          shipping_tax = shipping_cost * Spree::Config[:shipping_tax_rate]
        else
          shipping_tax = 0.0
        end
        
        sales_tax_details << [order.number, order.created_at, totals[:items], totals[:items_total],
          totals[:taxable_total], totals[:sales_tax], shipping_cost, shipping_tax, totals[:sales_tax] + shipping_tax,
          order.bill_address.full_name, order.distributor.andand.name]
        
      end
      sales_tax_details
    end
  end
end
