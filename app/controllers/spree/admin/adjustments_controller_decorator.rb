module Spree
  module Admin
    AdjustmentsController.class_eval do
      before_filter :set_included_tax, only: :create

      private

      def set_included_tax
        if params[:tax_rate_id].present?
          tax_rate = TaxRate.find params[:tax_rate_id]
          amount = params[:adjustment][:amount].to_f
          params[:adjustment][:included_tax] = tax_rate.compute_tax amount
        end
      end
    end
  end
end
