module OpenFoodNetwork
  class EnterpriseFeeApplicator < Struct.new(:enterprise_fee, :variant, :role)
    def create_line_item_adjustment(line_item)
      a = enterprise_fee.create_locked_adjustment(adjustment_label, line_item.order, line_item, true)
      AdjustmentMetadata.create! adjustment: a, enterprise: enterprise_fee.enterprise, fee_name: enterprise_fee.name, fee_type: enterprise_fee.fee_type, enterprise_role: role
    end


    private

    def adjustment_label
      "#{variant.product.name} - #{enterprise_fee.fee_type} fee by #{role} #{enterprise_fee.enterprise.name}"
    end
  end
end

