module Admin
  class EnterprisesController < ResourceController
    before_filter :load_enterprise_set, :only => :index
    before_filter :load_countries, :except => :index

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
    def load_enterprise_set
      @enterprise_set = EnterpriseSet.new :enterprises => collection
    end

    def load_countries
      @countries = Spree::Country.order(:name)
    end

    def collection
      super.order('is_primary_producer DESC, is_distributor ASC, name')
    end
  end
end
