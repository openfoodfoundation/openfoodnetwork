module Admin
  class EnterprisesController < ResourceController
    before_filter :load_enterprise_set, :only => :index
    before_filter :load_countries, :except => :index
    before_filter :load_methods_and_fees, :only => [:new, :edit, :update, :create]
    before_filter :check_can_change_sells, only: :update
    before_filter :check_can_change_bulk_sells, only: :bulk_update
    before_filter :override_owner, only: :create
    before_filter :check_can_change_owner, only: :update
    before_filter :check_can_change_bulk_owner, only: :bulk_update

    helper 'spree/products'
    include OrderCyclesHelper

    def for_order_cycle
      @collection = order_cycle_permitted_enterprises
    end


    def bulk_update
      @enterprise_set = EnterpriseSet.new(params[:enterprise_set])
      if @enterprise_set.save
        flash[:success] = 'Enterprises updated successfully'
        redirect_to main_app.admin_enterprises_path
      else
        render :index
      end
    end


    protected

    def build_resource_with_address
      enterprise = build_resource_without_address
      enterprise.address = Spree::Address.new
      enterprise.address.country = Spree::Country.find_by_id(Spree::Config[:default_country_id])
      enterprise
    end
    alias_method_chain :build_resource, :address


    private

    def load_enterprise_set
      @enterprise_set = EnterpriseSet.new :collection => collection
    end

    def load_countries
      @countries = Spree::Country.order(:name)
    end

    def collection
      # TODO was ordered with is_distributor DESC as well, not sure why or how we want ot sort this now
      Enterprise.managed_by(spree_current_user).order('is_primary_producer ASC, name')
    end

    def collection_actions
      [:index, :for_order_cycle, :bulk_update]
    end

    def load_methods_and_fees
      @payment_methods = Spree::PaymentMethod.managed_by(spree_current_user).sort_by!{ |pm| [(@enterprise.payment_methods.include? pm) ? 0 : 1, pm.name] }
      @shipping_methods = Spree::ShippingMethod.managed_by(spree_current_user).sort_by!{ |sm| [(@enterprise.shipping_methods.include? sm) ? 0 : 1, sm.name] }
      @enterprise_fees = EnterpriseFee.managed_by(spree_current_user).for_enterprise(@enterprise).order(:fee_type, :name).all
    end

    def check_can_change_bulk_sells
      unless spree_current_user.admin?
        params[:enterprise_set][:collection_attributes].each do |i, enterprise_params|
          enterprise_params.delete :sells
        end
      end
    end

    def check_can_change_sells
      params[:enterprise].delete :sells unless spree_current_user.admin?
    end

    def override_owner
      params[:enterprise][:owner_id] = spree_current_user.id unless spree_current_user.admin?
    end

    def check_can_change_owner
      unless ( spree_current_user == @enterprise.owner ) || spree_current_user.admin?
        params[:enterprise].delete :owner_id
      end
    end

    def check_can_change_bulk_owner
      unless spree_current_user.admin?
        params[:enterprise_set][:collection_attributes].each do |i, enterprise_params|
          enterprise_params.delete :owner_id
        end
      end
    end

    # Overriding method on Spree's resource controller
    def location_after_save
      if params[:enterprise].key? :producer_properties_attributes
        main_app.admin_enterprises_path
      else
        main_app.edit_admin_enterprise_path(@enterprise)
      end
    end
  end
end
