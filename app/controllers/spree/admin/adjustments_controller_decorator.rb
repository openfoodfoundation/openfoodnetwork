module Spree
  module Admin
    AdjustmentsController.class_eval do
      prepend_before_filter :set_included_tax, only: [:create, :update]
      before_filter :set_default_tax_rate, only: :edit


      private

      # Choose a default tax rate to show on the edit form. The adjustment stores its included
      # tax in dollars, but doesn't store the source of the tax (ie. TaxRate that generated it).
      # We guess which tax rate here, choosing:
      # 1. A tax rate that will compute to the same amount as the existing tax
      # 2. If that's not present, the first tax rate that's valid for the current order
      # When we have to go with 2, we show an error message to ask the admin to check that the
      # correct tax is being applied.
      def set_default_tax_rate
        if @adjustment.included_tax > 0
          trs = TaxRate.match(@order)
          tr_yielding_matching_tax = trs.select { |tr| tr.compute_tax(@adjustment.amount) == @adjustment.included_tax }.first.andand.id
          tr_valid_for_order = TaxRate.match(@order).first.andand.id

          @tax_rate_id = tr_yielding_matching_tax || tr_valid_for_order

          if tr_yielding_matching_tax.nil?
            @adjustment.errors.add :tax_rate_id, "^Please check that the tax rate for this adjustment is correct."
          end
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
