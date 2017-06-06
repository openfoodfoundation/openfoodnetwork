module Admin
  class EnterpriseGroupsController < ResourceController
    before_filter :load_data, except: :index
    before_filter :load_object_data, only: [:new, :edit, :create, :update]

    def index
      @enterprise_groups = @enterprise_groups.managed_by(spree_current_user)
    end

    def move_up
      EnterpriseGroup.with_isolation_level_serializable do
        @enterprise_group = find_resource
        @enterprise_group.move_higher
      end
      redirect_to main_app.admin_enterprise_groups_path
    end

    def move_down
      EnterpriseGroup.with_isolation_level_serializable do
        @enterprise_group = find_resource
        @enterprise_group.move_lower
      end
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

    # Overriding method on Spree's resource controller,
    # so that resources are found using permalink.
    # The ! version is important to raise a RecordNotFound error.
    def find_resource
      permalink = params[:id] || params[:enterprise_group_id]
      EnterpriseGroup.find_by_permalink!(permalink)
    end

    private

    def load_data
      @countries = Spree::Country.order(:name)
      @enterprises = Enterprise.activated
    end

    def load_object_data
      @owner_email = @enterprise_group.andand.owner.andand.email || ""
    end

    def collection
      EnterpriseGroup.by_position
    end
  end
end
