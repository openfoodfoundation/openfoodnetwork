module Spree
  module Admin
    class TaxRatesController < ResourceController
      before_action :load_data

      private

      def load_data
        @available_zones = Zone.order(:name)
        @available_categories = TaxCategory.order(:name)
        @calculators = TaxRate.calculators.sort_by(&:name)
      end

      def permitted_resource_params
        params.require(:tax_rate).permit(
          :name, :amount, :included_in_price, :zone_id,
          :tax_category_id, :show_rate_in_label, :calculator_type
        )
      end
    end
  end
end
