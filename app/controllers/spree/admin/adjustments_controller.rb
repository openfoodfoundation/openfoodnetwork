module Spree
  module Admin
    class AdjustmentsController < ::Admin::ResourceController
      belongs_to 'spree/order', find_by: :number
      create.after :update_totals
      update.after :update_totals
      destroy.after :update_totals

      prepend_before_action :set_included_tax, only: [:create, :update]
      before_action :set_default_tax_rate, only: :edit
      before_action :enable_updates, only: :update

      private

      def collection
        parent.adjustments.eligible
      end

      # Choose a default tax rate to show on the edit form. The adjustment stores its included
      # tax in dollars, but doesn't store the source of the tax (ie. TaxRate that generated it).
      # We guess which tax rate here, choosing:
      # 1. A tax rate that will compute to the same amount as the existing tax
      # 2. If that's not present, the first tax rate that's valid for the current order
      # When we have to go with 2, we show an error message to ask the admin to check that the
      # correct tax is being applied.
      def set_default_tax_rate
        return if @adjustment.included_tax <= 0

        tax_rates = TaxRate.match(@order)
        tax_rate_with_matching_tax = find_tax_rate_with_matching_tax(tax_rates)
        tax_rate_valid_for_order = tax_rates.first.andand.id

        @tax_rate_id = tax_rate_with_matching_tax || tax_rate_valid_for_order

        return unless tax_rate_with_matching_tax.nil?

        @adjustment.errors.add :tax_rate_id, I18n.t(:adjustments_tax_rate_error)
      end

      def find_tax_rate_with_matching_tax(tax_rates)
        tax_rates_yielding_matching_tax = tax_rates.select do |tr|
          tr.compute_tax(@adjustment.amount) == @adjustment.included_tax
        end
        tax_rates_yielding_matching_tax.first.andand.id
      end

      def set_included_tax
        included_tax = 0
        if params[:tax_rate_id].present?
          tax_rate = TaxRate.find params[:tax_rate_id]
          amount = params[:adjustment][:amount].to_f
          included_tax = tax_rate.compute_tax amount
        end
        params[:adjustment][:included_tax] = included_tax
      end

      # Spree 2.0 keeps shipping fee adjustments open unless they are manually
      # closed. But open adjustments cannot be edited.
      # To preserve updates, like changing the amount of the shipping fee,
      # we close the adjustment first.
      #
      # The Spree admin interface allows to open and close adjustments manually
      # but we removed that functionality as it had no purpose for us.
      def enable_updates
        @adjustment.close
      end

      def permitted_resource_params
        params.require(:adjustment).permit(
          :label, :amount, :included_tax
        )
      end

      # This needs some additional test coverage in the controller and feature specs (see previous commit).
      # The spree specs here were not especially compatible, so left out.
      # All the specs around admin adjustments editing will need careful review anyway.
      def update_totals
        @order.reload.update!
      end
    end
  end
end
