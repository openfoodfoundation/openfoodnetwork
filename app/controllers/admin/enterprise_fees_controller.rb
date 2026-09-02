# frozen_string_literal: true

require 'open_food_network/order_cycle_permissions'

module Admin
  class EnterpriseFeesController < Admin::ResourceController
    before_action :load_enterprise_fee_set, only: :index
    before_action :load_data

    def index
      @include_calculators = params[:include_calculators].present?
      @enterprise = current_enterprise
      @enterprises = Enterprise.managed_by(spree_current_user).by_name

      blank_enterprise_fee = EnterpriseFee.new
      blank_enterprise_fee.enterprise = current_enterprise

      @collection = @collection.to_a
      3.times { @collection << blank_enterprise_fee }

      respond_to do |format|
        format.html
        format.json {
          render_as_json @collection, controller: self, include_calculators: @include_calculators
        }
      end
    end

    def for_order_cycle
      respond_to do |format|
        format.html
        format.json { render_as_json @collection, controller: self }
      end
    end

    def bulk_update
      # @enterprise_fees is set by Admin::ResourceController, see `collection` to check
      # how enterprise fees are scoped
      @enterprise_fee_set = EnterpriseFeesBulkUpdate.new(
        enterprise_fee_bulk_params, @enterprise_fees
      )

      if @enterprise_fee_set.save
        flash[:success] = I18n.t(:enterprise_fees_update_notice)
        redirect_to redirect_path
      else
        redirect_to redirect_path,
                    flash: { error: @enterprise_fee_set.errors.full_messages.to_sentence }
      end
    end

    private

    def load_enterprise_fee_set
      @enterprise_fee_set = Sets::EnterpriseFeeSet.new collection:
    end

    def load_data
      @calculators = EnterpriseFee.calculators.sort_by(&:name)
      @tax_categories = Spree::TaxCategory.order('is_default DESC, name ASC')
    end

    def collection
      case action
      when :for_order_cycle
        order_cycle = OrderCycle.find_by(id: params[:order_cycle_id]) if params[:order_cycle_id]
        coordinator = Enterprise.find_by(id: params[:coordinator_id]) if params[:coordinator_id]
        order_cycle ||= OrderCycle.new(coordinator:) if coordinator.present?
        enterprises = OpenFoodNetwork::OrderCyclePermissions.new(spree_current_user,
                                                                 order_cycle).visible_enterprises

        fees = EnterpriseFee.for_enterprises(enterprises).order('enterprise_id', 'fee_type', 'name')
        filter_fees(fees)
      else
        collection = EnterpriseFee.managed_by(spree_current_user).order('enterprise_id',
                                                                        'fee_type', 'name')
        collection = collection.for_enterprise(current_enterprise) if current_enterprise
        collection
      end
    end

    def filter_fees(fees)
      fees = fees.per_item if params[:per_item]
      fees = fees.per_order if params[:per_order]
      fees
    end

    def collection_actions
      [:index, :for_order_cycle, :bulk_update]
    end

    def current_enterprise
      Enterprise.find params[:enterprise_id] if params.key? :enterprise_id
    end

    def redirect_path
      if params.key? :enterprise_id
        return main_app.admin_enterprise_fees_path(enterprise_id: params[:enterprise_id])
      end

      main_app.admin_enterprise_fees_path
    end

    # Remove fees we are not allowed to update
    def enterprise_fee_bulk_params
      fee_id = @enterprise_fees.map(&:id)
      collection = params.dig(:sets_enterprise_fee_set, :collection_attributes)
      matching = collection.values.select { |value| fee_id.include?(value[:id]) }
      matching = matching.map do |fee_param|
        fee_param.permit(
          :id, :enterprise_id, :fee_type, :name, :tax_category_id,
          :inherits_tax_category, :calculator_type,
          { calculator_attributes: PermittedAttributes::Calculator.attributes }
        )
      end
      # Rebuilding the expected parameters for the EnterpriseFeeSet
      parameters = {
        collection_attributes: {}
      }
      matching.each_with_index { |fee_param, i|
        parameters[:collection_attributes][i.to_s] = fee_param
      }
      parameters
    end
  end
end
