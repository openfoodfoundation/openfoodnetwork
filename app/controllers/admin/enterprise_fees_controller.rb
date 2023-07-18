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
      # Forms has strong parameters, so we don't need to validate them in controller
      @enterprise_fee_set = EnterpriseFeesBulkUpdate.new(params)

      if @enterprise_fee_set.save
        redirect_to redirect_path, notice: I18n.t(:enterprise_fees_update_notice)
      else
        redirect_to redirect_path,
                    flash: { error: @enterprise_fee_set.errors.full_messages.to_sentence }
      end
    end

    private

    def load_enterprise_fee_set
      @enterprise_fee_set = Sets::EnterpriseFeeSet.new collection: collection
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
        order_cycle ||= OrderCycle.new(coordinator: coordinator) if coordinator.present?
        enterprises = OpenFoodNetwork::OrderCyclePermissions.new(spree_current_user,
                                                                 order_cycle).visible_enterprises
        EnterpriseFee.for_enterprises(enterprises).order('enterprise_id', 'fee_type', 'name')
      else
        collection = EnterpriseFee.managed_by(spree_current_user).order('enterprise_id',
                                                                        'fee_type', 'name')
        collection = collection.for_enterprise(current_enterprise) if current_enterprise
        collection
      end
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
  end
end
