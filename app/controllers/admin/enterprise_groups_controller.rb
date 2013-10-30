module Admin
  class EnterpriseGroupsController < ResourceController
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


    private

    def collection
      EnterpriseGroup.by_position
    end

  end
end
