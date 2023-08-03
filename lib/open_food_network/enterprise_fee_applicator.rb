# frozen_string_literal: true

module OpenFoodNetwork
  EnterpriseFeeApplicator = Struct.new(:enterprise_fee, :variant, :role) do
    def create_line_item_adjustment(line_item)
      create_adjustment(line_item_adjustment_label, line_item)
    end

    def create_order_adjustment(order)
      create_adjustment(order_adjustment_label, order)
    end

    private

    def create_adjustment(label, adjustable)
      adjustment = enterprise_fee.create_adjustment(
        label, adjustable, true, "closed", tax_category(adjustable)
      )

      AdjustmentMetadata.create! adjustment: adjustment, enterprise: enterprise_fee.enterprise,
                                 fee_name: enterprise_fee.name, fee_type: enterprise_fee.fee_type,
                                 enterprise_role: role
    end

    def line_item_adjustment_label
      "#{variant.product.name} - #{base_adjustment_label}"
    end

    def order_adjustment_label
      "#{I18n.t(:enterprise_fee_whole_order)} - #{base_adjustment_label}"
    end

    def base_adjustment_label
      I18n.t(:enterprise_fee_by_name, name: enterprise_fee.name, role: role,
                                      enterprise_name: enterprise_fee.enterprise.name)
    end

    def tax_category(target)
      if target.is_a?(Spree::LineItem) && enterprise_fee.inherits_tax_category?
        target.variant.tax_category
      else
        enterprise_fee.tax_category
      end
    end
  end
end
