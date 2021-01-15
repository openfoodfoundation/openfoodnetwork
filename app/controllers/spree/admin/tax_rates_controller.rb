module Spree
  module Admin
    class TaxRatesController < ::Admin::ResourceController
      before_action :load_data

      def update
        return super unless amount_changed? && associated_adjustments?

        # If a TaxRate is modified in production and the amount is changed, we need to clone
        # and soft-delete it to preserve associated data on previous orders. For example; previous
        # orders will have adjustments created with that rate. Those old orders will keep the
        # rate they had when they were created, and new orders will have the new rate applied.

        cloned_rate = clone_tax_rate(@tax_rate)
        cloned_rate.assign_attributes(permitted_resource_params)

        if cloned_rate.save
          @tax_rate.destroy

          redirect_to location_after_save,
                      flash: { success: flash_message_for(cloned_rate, :successfully_updated) }
        else
          redirect_to spree.edit_admin_tax_rate_path(@tax_rate),
                      flash: { error: cloned_rate.errors.full_messages.to_sentence }
        end
      end

      private

      def amount_changed?
        BigDecimal(permitted_resource_params[:amount]) != @tax_rate.amount
      end

      def associated_adjustments?
        Spree::Adjustment.where(originator: @tax_rate).exists?
      end

      def clone_tax_rate(tax_rate)
        cloned_rate = tax_rate.deep_dup
        cloned_rate.calculator = tax_rate.calculator.deep_dup
        cloned_rate
      end

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
