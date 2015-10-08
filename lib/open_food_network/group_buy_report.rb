module OpenFoodNetwork

  GroupBuyVariantRow = Struct.new(:variant, :sum_quantities, :sum_max_quantities) do
    def to_row
      [variant.product.supplier.name, variant.product.name, "UNITSIZE", variant.options_text, variant.weight, sum_quantities, sum_max_quantities]
    end
  end

  GroupBuyProductRow = Struct.new(:product, :sum_quantities, :sum_max_quantities) do
    def to_row
      [product.supplier.name, product.name, "UNITSIZE", "TOTAL", "", sum_quantities, sum_max_quantities]
    end
  end

  class GroupBuyReport
    def initialize orders
      @orders = orders
    end

    def header
      ["Supplier", "Product", "Unit Size", "Variant", "Weight", "Total Ordered", "Total Max"]
    end

    def variants_and_quantities
      variants_and_quantities = []
      line_items = @orders.map { |o| o.line_items }.flatten
      supplier_groups = line_items.group_by { |li| li.variant.product.supplier }
      supplier_groups.each do |supplier, line_items_by_supplier|
        product_groups = line_items_by_supplier.group_by { |li| li.variant.product }
        product_groups.each do |product, line_items_by_product|

          # Cycle thorugh variant of a product
          variant_groups = line_items_by_product.group_by { |li| li.variant }
          variant_groups.each do |variant, line_items_by_variant|
            sum_quantities = line_items_by_variant.sum { |li| li.quantity }
            sum_max_quantities = line_items_by_variant.sum { |li| li.max_quantity || 0 } 
            variants_and_quantities << GroupBuyVariantRow.new(variant, sum_quantities, sum_max_quantities)
          end

          # Sum quantities for each product (Total line)
          sum_quantities = line_items_by_product.sum { |li| (li.variant.weight || 0) * li.quantity }
          sum_max_quantities = line_items_by_product.sum { |li| (li.variant.weight || 0) * (li.max_quantity || 0) }
          variants_and_quantities << GroupBuyProductRow.new(product, sum_quantities, sum_max_quantities)
        end
      end
      variants_and_quantities
    end

    def table
      table = []
      variants_and_quantities.each do |vr|
        table << vr.to_row
      end
      table
    end
  end
end
