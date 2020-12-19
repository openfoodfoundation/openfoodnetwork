module OpenFoodNetwork
  class EnterpriseFeeApplicator < Struct.new(:enterprise_fee, :variant, :role)
    def create_line_item_adjustment(line_item)
      # This all needs a big refactor after it's working correctly...
      create_adjustment(line_item_adjustment_label, line_item.order, enterprise_fee, line_item)
    end

    def create_order_adjustment(order)
      create_adjustment(order_adjustment_label, order, enterprise_fee, order)
    end

    private

    def create_adjustment(label, order, source, adjustable)
      adjustment = adjustable.create_adjustment(label, order, source, adjustable, true)

      AdjustmentMetadata.create! adjustment: adjustment, enterprise: enterprise_fee.enterprise, fee_name: enterprise_fee.name, fee_type: enterprise_fee.fee_type, enterprise_role: role
    end

    def line_item_adjustment_label
      "#{variant.product.name} - #{base_adjustment_label}"
    end

    def order_adjustment_label
      "#{I18n.t(:enterprise_fee_whole_order)} - #{base_adjustment_label}"
    end

    def base_adjustment_label
      I18n.t(:enterprise_fee_by, type: enterprise_fee.fee_type, role: role, enterprise_name: enterprise_fee.enterprise.name)
    end
  end
end
