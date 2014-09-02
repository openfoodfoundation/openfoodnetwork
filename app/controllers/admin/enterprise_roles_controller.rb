module Admin
  class EnterpriseRolesController < ResourceController
    def index
      @enterprise_roles = EnterpriseRole.by_user_email
      @users = Spree::User.order('spree_users.email')
      @my_enterprises = @all_enterprises = Enterprise.by_name
    end

    def create
      @enterprise_role = EnterpriseRole.new params[:enterprise_role]

      if @enterprise_role.save
        render text: Api::Admin::EnterpriseRoleSerializer.new(@enterprise_role).to_json

      else
        render status: 400, json: {errors: @enterprise_role.errors.full_messages.join(', ')}
      end
    end

    def destroy
      @enterprise_role = EnterpriseRole.find params[:id]
      @enterprise_role.destroy
      render nothing: true
    end
  end
end
