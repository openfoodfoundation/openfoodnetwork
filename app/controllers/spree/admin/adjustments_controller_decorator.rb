module Spree
  module Admin
    AdjustmentsController.class_eval do
      before_filter :set_included_tax, only: [:create, :update]
      before_filter :set_default_tax_rate, only: :edit

      private

      def set_default_tax_rate
        if @adjustment.included_tax > 0 && TaxRate.count == 1
          @tax_rate_id = TaxRate.first.id
        end
      end


      def set_included_tax
        if params[:tax_rate_id].present?
          tax_rate = TaxRate.find params[:tax_rate_id]
          amount = params[:adjustment][:amount].to_f
          params[:adjustment][:included_tax] = tax_rate.compute_tax amount

        else
          params[:adjustment][:included_tax] = 0
        end
      end
    end
  end
end
