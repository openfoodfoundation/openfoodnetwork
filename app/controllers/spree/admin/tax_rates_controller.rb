# frozen_string_literal: true

module Spree
  module Admin
    class TaxRatesController < ::Admin::ResourceController
      before_action :load_data

      delegate :transition_rate!, :updated_rate, to: :updater

      def update
        return super unless requires_transition?

        transition_tax_rate
      end

      private

      def requires_transition?
        (included_changed? || amount_changed?) && associated_adjustments?
      end

      def included_changed?
        ActiveRecord::Type::Boolean.new.cast(
          permitted_resource_params[:included_in_price]
        ) != @tax_rate.included_in_price
      end

      def amount_changed?
        BigDecimal(permitted_resource_params[:amount]) != @tax_rate.amount
      end

      def associated_adjustments?
        Spree::Adjustment.where(originator: @tax_rate).exists?
      end

      def transition_tax_rate
        if transition_rate!
          redirect_to location_after_save,
                      flash: { success: flash_message_for(updated_rate, :successfully_updated) }
        else
          redirect_to spree.edit_admin_tax_rate_path(@tax_rate),
                      flash: { error: updated_rate.errors.full_messages.to_sentence }
        end
      end

      def updater
        @updater ||= TaxRateUpdater.new(@tax_rate, permitted_resource_params)
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
