module Admin
  class EnterpriseFeesController < ResourceController
    before_filter :load_enterprise_fee_set, :only => :index
    before_filter :load_data
    before_filter :do_not_destroy_referenced_fees, :only => :destroy


    def index
      @include_calculators = params[:include_calculators].present?
      @enterprise = current_enterprise
      @enterprises = Enterprise.managed_by(spree_current_user).by_name

      blank_enterprise_fee = EnterpriseFee.new
      blank_enterprise_fee.enterprise = current_enterprise
      3.times { @collection << blank_enterprise_fee }

      respond_to do |format|
        format.html
        format.json { render_as_json @collection, controller: self, include_calculators: @include_calculators }
        # format.json { @presented_collection = @collection.each_with_index.map { |ef, i| EnterpriseFeePresenter.new(self, ef, i) } }
      end
    end

    def for_order_cycle
      respond_to do |format|
        format.html
        format.json { render_as_json @collection, controller: self }
      end
    end

    def bulk_update
      @enterprise_fee_set = EnterpriseFeeSet.new(params[:enterprise_fee_set])
      if @enterprise_fee_set.save
        redirect_path = main_app.admin_enterprise_fees_path
        if params.key? :enterprise_id
          redirect_path = main_app.admin_enterprise_fees_path(enterprise_id: params[:enterprise_id])
        end
        redirect_to redirect_path, :notice => 'Your enterprise fees have been updated.'

      else
        render :index
      end
    end


    private

    def do_not_destroy_referenced_fees
      product_distribution = ProductDistribution.where(:enterprise_fee_id => @object).first
      if product_distribution
        p = product_distribution.product
        error = "That enterprise fee cannot be deleted as it is referenced by a product distribution: #{p.id} - #{p.name}."

        respond_with(@object) do |format|
          format.html do
            flash[:error] = error
            redirect_to collection_url
          end
          format.js { render text: error, status: 403 }
        end
      end
    end

    def load_enterprise_fee_set
      @enterprise_fee_set = EnterpriseFeeSet.new :collection => collection
    end

    def load_data
      @calculators = EnterpriseFee.calculators.sort_by(&:name)
      @tax_categories = Spree::TaxCategory.order('is_default DESC, name ASC')
    end

    def collection
      case action
      when :for_order_cycle
        order_cycle = OrderCycle.find_by_id(params[:order_cycle_id]) if params[:order_cycle_id]
        coordinator = Enterprise.find_by_id(params[:coordinator_id]) if params[:coordinator_id]
        order_cycle = OrderCycle.new(coordinator: coordinator) if order_cycle.nil? && coordinator.present?
        enterprises = OpenFoodNetwork::OrderCyclePermissions.new(spree_current_user, order_cycle).visible_enterprises
        return EnterpriseFee.for_enterprises(enterprises).order('enterprise_id', 'fee_type', 'name')
      else
        collection = EnterpriseFee.managed_by(spree_current_user).order('enterprise_id', 'fee_type', 'name')
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

  end
end
