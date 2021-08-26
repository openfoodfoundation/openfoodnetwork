# frozen_string_literal: true

module Admin
  class EnterpriseGroupsController < Admin::ResourceController
    before_action :load_data, except: :index
    before_action :load_object_data, only: [:new, :edit, :create, :update]

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

    def build_resource
      enterprise_group = super
      enterprise_group.address = Spree::Address.new
      enterprise_group.address.country = DefaultCountry.country
      enterprise_group
    end

    # Overriding method on Spree's resource controller,
    # so that resources are found using permalink.
    # The ! version is important to raise a RecordNotFound error.
    def find_resource
      permalink = params[:id] || params[:enterprise_group_id]
      EnterpriseGroup.find_by!(permalink: permalink)
    end

    private

    def load_data
      @countries = Spree::Country.order(:name)
      @enterprises = Enterprise.activated
    end

    def load_object_data
      @owner_email = @enterprise_group&.owner&.email || ""
    end

    def collection
      EnterpriseGroup.by_position
    end

    def permitted_resource_params
      params.require(:enterprise_group).permit(
        :name, :description, :long_description, :logo, :promo_image, :on_front_page,
        :owner_id, :permalink, :email, :website, :facebook, :instagram, :linkedin, :twitter,
        enterprise_ids: [], address_attributes: PermittedAttributes::Address.attributes
      )
    end
  end
end
