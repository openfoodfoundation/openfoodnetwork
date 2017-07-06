module OpenFoodNetwork

  GroupBuyVariantRow = Struct.new(:variant, :sum_quantities, :sum_max_quantities) do
    def to_row
      [variant.product.supplier.name, variant.product.name, I18n.t('admin.reports.unitsize'), variant.options_text, variant.weight, sum_quantities, sum_max_quantities]
    end
  end

  GroupBuyProductRow = Struct.new(:product, :sum_quantities, :sum_max_quantities) do
    def to_row
      [product.supplier.name, product.name, I18n.t('admin.reports.unitsize'), I18n.t('admin.reports.total'), "", sum_quantities, sum_max_quantities]
    end
  end

  class GroupBuyReport
    def initialize orders
      @orders = orders
    end

    def header
      [
        I18n.t(:report_header_supplier),
        I18n.t(:report_header_product),
        I18n.t(:report_header_unit_size),
        I18n.t(:report_header_variant),
        I18n.t(:report_header_weight),
        I18n.t(:report_header_total_ordered),
        I18n.t(:report_header_total_max),
      ]
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
