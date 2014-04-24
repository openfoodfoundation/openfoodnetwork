module Admin
  class EnterprisesController < ResourceController
    before_filter :load_enterprise_set, :only => :index
    before_filter :load_countries, :except => :index
    create.after :grant_management

    helper 'spree/products'

    def bulk_update
      @enterprise_set = EnterpriseSet.new(params[:enterprise_set])
      if @enterprise_set.save
        redirect_to main_app.admin_enterprises_path, :notice => 'Distributor collection times updated.'
      else
        render :index
      end
    end


    private

    # When an enterprise user creates another enterprise, it is granted management
    # permission for it
    def grant_management
      unless spree_current_user.has_spree_role? 'admin'
        spree_current_user.enterprise_roles.create(enterprise: @object)
      end
    end

    def load_enterprise_set
      @enterprise_set = EnterpriseSet.new :collection => collection
    end

    def load_countries
      @countries = Spree::Country.order(:name)
    end

    def collection
      Enterprise.managed_by(spree_current_user).order('is_distributor DESC, is_primary_producer ASC, name')
    end

    def collection_actions
      [:index, :bulk_update]
    end
  end
end
