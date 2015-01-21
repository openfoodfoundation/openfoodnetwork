module Admin
  class EnterpriseGroupsController < ResourceController
    before_filter :load_countries, :except => :index

    def index
    end

    def move_up
      @enterprise_group = EnterpriseGroup.find params[:enterprise_group_id]
      @enterprise_group.move_higher
      redirect_to main_app.admin_enterprise_groups_path
    end

    def move_down
      @enterprise_group = EnterpriseGroup.find params[:enterprise_group_id]
      @enterprise_group.move_lower
      redirect_to main_app.admin_enterprise_groups_path
    end

    protected

    def build_resource_with_address
      enterprise_group = build_resource_without_address
      enterprise_group.address = Spree::Address.new
      enterprise_group.address.country = Spree::Country.find_by_id(Spree::Config[:default_country_id])
      enterprise_group
    end
    alias_method_chain :build_resource, :address

    private

    def load_countries
      @countries = Spree::Country.order(:name)
    end

    def collection
      EnterpriseGroup.by_position
    end
  end
end
