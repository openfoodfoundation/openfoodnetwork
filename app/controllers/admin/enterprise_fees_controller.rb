# frozen_string_literal: true

require 'open_food_network/order_cycle_permissions'

module Admin
  class EnterpriseFeesController < Admin::ResourceController
    before_action :load_enterprise_fee_set, only: :index
    before_action :load_data
    before_action :check_enterprise_fee_input, only: [:bulk_update]
    before_action :check_calculators_compatibility_with_taxes, only: [:bulk_update]

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
      @enterprise_fee_set = Sets::EnterpriseFeeSet.new(enterprise_fee_bulk_params)

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

    def enterprise_fee_bulk_params
      params.require(:sets_enterprise_fee_set).permit(
        collection_attributes: [
          :id, :enterprise_id, :fee_type, :name, :tax_category_id,
          :inherits_tax_category, :calculator_type,
          { calculator_attributes: PermittedAttributes::Calculator.attributes }
        ]
      )
    end

    def check_enterprise_fee_input
      enterprise_fee_bulk_params['collection_attributes'].each do |_, fee_row|
        enterprise_fees = fee_row['calculator_attributes']&.slice(
          :preferred_flat_percent, :preferred_amount,
          :preferred_first_item, :preferred_additional_item,
          :preferred_minimal_amount, :preferred_normal_amount,
          :preferred_discount_amount, :preferred_per_unit, :preferred_max_items, :preffered_currency
        )

        next unless enterprise_fees

        enterprise_fees.each do |_, enterprise_amount|
          unless enterprise_amount.nil? || Float(enterprise_amount, exception: false)
            flash[:error] = I18n.t(:calculator_preferred_value_error)
            return redirect_to redirect_path
          end
        end
      end
    end

    def check_calculators_compatibility_with_taxes
      enterprise_fee_bulk_params['collection_attributes'].each do |_, enterprise_fee|
        next unless enterprise_fee['inherits_tax_category'] == "true"
        next unless EnterpriseFee::PER_ORDER_CALCULATORS.include?(enterprise_fee['calculator_type'])

        flash[:error] = I18n.t(
          'activerecord.errors.models.enterprise_fee.inherit_tax_requires_per_item_calculator'
        )
        return redirect_to redirect_path
      end
    end
  end
end
