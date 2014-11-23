
module OpenFoodNetwork
  class SalesTaxReport

    def initialize orders
      @orders = orders
    end

    def header
      ["Order number", "Date", "Items", "Items total", "Taxable Items Total", "Sales Tax", 
        "Delivery Charge", "Tax on Delivery", "Total Tax", "Customer", "Distributor"]
    end

    def table
      sales_tax_details = []
      @orders.each do |order|
        totals = {"items" => 0, "items_total" => 0.0, "taxable_total" => 0.0, "sales_tax" => 0.0}
        
        order.line_items.each do |line_item|
          totals["items"] += line_item.quantity
          totals["items_total"] += line_item.price * line_item.quantity
          
          tax_rate = Spree::TaxRate.find_by_tax_category_id(line_item.variant.product.tax_category_id).andand.amount
          
          if tax_rate != nil && tax_rate != 0
            totals["taxable_total"] += (line_item.price * line_item.quantity)
            totals["sales_tax"] += (line_item.price * line_item.quantity) * tax_rate
          end
        end
        
        shipping_cost = order.adjustments.find_by_label("Shipping").andand.amount
        shipping_cost = (shipping_cost == nil) ? 0.0 : shipping_cost
        shipping_tax = (Spree::Config[:shipment_inc_vat] && shipping_cost != nil) ? shipping_cost * 0.2 : 0.0
        
        #config option for charging tax on shipping fee or not? exists, need to set rate...
        #calculate additional tax for shipping...
        #ignore non-shipping adjustments? any potential issues?
        #show payment status? other necessary/useful info?
        #check which orders are pulled, and which are filtered out... maybe have a dropdown to make it explicit...?
        
        sales_tax_details << [order.number, order.created_at, totals["items"], totals["items_total"],
          totals["taxable_total"], totals["sales_tax"], shipping_cost, shipping_tax, totals["sales_tax"] + shipping_tax,
          order.bill_address.full_name, order.distributor.andand.name]
        
      end
      sales_tax_details
    end
  end
end
